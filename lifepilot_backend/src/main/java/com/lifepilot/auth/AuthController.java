package com.lifepilot.auth;

import com.lifepilot.auth.AuthDtos.AuthResponse;
import com.lifepilot.auth.AuthDtos.EmailRequest;
import com.lifepilot.auth.AuthDtos.LoginRequest;
import com.lifepilot.auth.AuthDtos.PasswordResetRequest;
import com.lifepilot.auth.AuthDtos.ProfileRequest;
import com.lifepilot.auth.AuthDtos.RefreshRequest;
import com.lifepilot.auth.AuthDtos.RegisterRequest;
import com.lifepilot.auth.AuthDtos.TokenRequest;
import com.lifepilot.auth.AuthDtos.UserResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api")
public class AuthController {
    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/auth/register")
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/auth/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @PostMapping("/auth/refresh")
    public AuthResponse refresh(@Valid @RequestBody RefreshRequest request) {
        return authService.refresh(request.refreshToken());
    }

    @PostMapping("/auth/logout")
    public void logout(@Valid @RequestBody RefreshRequest request) {
        authService.logout(request.refreshToken());
    }

    @PostMapping("/auth/forgot-password")
    public void forgotPassword(@Valid @RequestBody EmailRequest request) {
        throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                "Email delivery is not configured; no password-reset email was sent");
    }

    @PostMapping("/auth/reset-password")
    public void resetPassword(@Valid @RequestBody PasswordResetRequest request) {
        throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                "Email delivery is not configured; the password was not changed");
    }

    @PostMapping("/auth/verify-email")
    public void verifyEmail(@Valid @RequestBody TokenRequest request) {
        throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                "Email verification is not configured; the address was not verified");
    }

    @GetMapping("/users/me")
    public UserResponse me() {
        return authService.me();
    }

    @PutMapping("/users/me")
    public UserResponse updateProfile(@Valid @RequestBody ProfileRequest request) {
        return authService.updateProfile(request);
    }
}
