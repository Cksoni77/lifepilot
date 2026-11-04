package com.lifepilot.user;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.LocalTime;

public final class UserPreferencesDtos {
    private UserPreferencesDtos() {}

    public record PreferencesRequest(
            @NotBlank @Size(max = 80) String timezone,
            @NotBlank @Pattern(regexp = "light|dark|system") String theme,
            boolean notificationsEnabled,
            boolean reminderEnabled,
            LocalTime dailyStartTime,
            LocalTime dailyEndTime) {}

    public record PreferencesResponse(
            String timezone,
            String theme,
            boolean notificationsEnabled,
            boolean reminderEnabled,
            LocalTime dailyStartTime,
            LocalTime dailyEndTime) {}
}
