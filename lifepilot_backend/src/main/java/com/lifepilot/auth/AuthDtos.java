package com.lifepilot.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public final class AuthDtos {
    private AuthDtos() {}

    public record RegisterRequest(
            @NotBlank @Size(max = 120) String name,
            @NotBlank @Email @Size(max = 320) String email,
            @NotBlank @Size(min = 12, max = 72) String password) {}

    public record LoginRequest(
            @NotBlank @Email String email,
            @NotBlank String password) {}

    public record RefreshRequest(@NotBlank String refreshToken) {}

    public record UserResponse(UUID id, String name, String email) {}

    public record AuthResponse(String accessToken, String refreshToken, UserResponse user) {}

    public record ProfileRequest(@NotBlank @Size(max = 120) String name) {}

    public record EmailRequest(@NotBlank @Email @Size(max = 320) String email) {}

    public record TokenRequest(@NotBlank String token) {}

    public record PasswordResetRequest(
            @NotBlank String token,
            @NotBlank @Size(min = 12, max = 72) String newPassword) {}
}
