package com.lifepilot.auth;

import com.lifepilot.auth.AuthDtos.AuthResponse;
import com.lifepilot.auth.AuthDtos.LoginRequest;
import com.lifepilot.auth.AuthDtos.ProfileRequest;
import com.lifepilot.auth.AuthDtos.RegisterRequest;
import com.lifepilot.auth.AuthDtos.UserResponse;
import com.lifepilot.security.CurrentUser;
import com.lifepilot.security.JwtService;
import com.lifepilot.user.AppUser;
import com.lifepilot.user.AppUserRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthService {
    private final AppUserRepository users;
    private final RefreshTokenRepository refreshTokens;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final CurrentUser currentUser;
    private final long refreshTokenDays;
    private final SecureRandom secureRandom = new SecureRandom();

    public AuthService(
            AppUserRepository users,
            RefreshTokenRepository refreshTokens,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            CurrentUser currentUser,
            @Value("${app.jwt.refresh-token-days}") long refreshTokenDays) {
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.currentUser = currentUser;
        this.refreshTokenDays = refreshTokenDays;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = request.email().trim().toLowerCase(java.util.Locale.ROOT);
        if (users.existsByEmail(email)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "An account with this email already exists");
        }
        AppUser user = users.save(new AppUser(
                email, request.name().trim(), passwordEncoder.encode(request.password())));
        return issue(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        String email = request.email().trim().toLowerCase(java.util.Locale.ROOT);
        AppUser user = users.findByEmail(email)
                .filter(account -> passwordEncoder.matches(request.password(), account.getPasswordHash()))
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Email or password is incorrect"));
        return issue(user);
    }

    @Transactional
    public AuthResponse refresh(String rawToken) {
        RefreshToken token = refreshTokens.findByTokenHash(hash(rawToken))
                .filter(value -> value.isUsableAt(OffsetDateTime.now(ZoneOffset.UTC)))
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Refresh token is invalid or expired"));
        token.revoke(OffsetDateTime.now(ZoneOffset.UTC));
        return issue(token.getUser());
    }

    @Transactional
    public void logout(String rawToken) {
        refreshTokens.findByTokenHash(hash(rawToken)).ifPresent(token ->
                token.revoke(OffsetDateTime.now(ZoneOffset.UTC)));
    }

    @Transactional(readOnly = true)
    public UserResponse me() {
        AppUser user = users.findById(currentUser.id()).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        return toResponse(user);
    }

    @Transactional
    public UserResponse updateProfile(ProfileRequest request) {
        AppUser user = users.findById(currentUser.id()).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        user.updateProfile(request.name().trim());
        return toResponse(user);
    }

    private AuthResponse issue(AppUser user) {
        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        String rawRefreshToken = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        OffsetDateTime expiresAt = OffsetDateTime.now(ZoneOffset.UTC).plusDays(refreshTokenDays);
        refreshTokens.save(new RefreshToken(user, hash(rawRefreshToken), expiresAt));
        return new AuthResponse(jwtService.issueAccessToken(user.getId()), rawRefreshToken, toResponse(user));
    }

    private UserResponse toResponse(AppUser user) {
        return new UserResponse(user.getId(), user.getName(), user.getEmail());
    }

    private String hash(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is required by the Java runtime", exception);
        }
    }
}
