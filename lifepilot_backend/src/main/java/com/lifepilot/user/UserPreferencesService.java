package com.lifepilot.user;

import com.lifepilot.security.CurrentUser;
import java.time.LocalTime;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserPreferencesService {
    private final JdbcTemplate jdbcTemplate;
    private final CurrentUser currentUser;

    public UserPreferencesService(JdbcTemplate jdbcTemplate, CurrentUser currentUser) {
        this.jdbcTemplate = jdbcTemplate;
        this.currentUser = currentUser;
    }

    @Transactional(readOnly = true)
    public UserPreferencesDtos.PreferencesResponse get() {
        UUID userId = currentUser.id();
        return jdbcTemplate.query(
                "SELECT timezone, theme, notifications_enabled, reminder_enabled, "
                        + "daily_start_time, daily_end_time FROM user_preferences WHERE user_id = ?",
                resultSet -> resultSet.next()
                        ? new UserPreferencesDtos.PreferencesResponse(
                                resultSet.getString("timezone"),
                                resultSet.getString("theme"),
                                resultSet.getBoolean("notifications_enabled"),
                                resultSet.getBoolean("reminder_enabled"),
                                resultSet.getObject("daily_start_time", LocalTime.class),
                                resultSet.getObject("daily_end_time", LocalTime.class))
                        : new UserPreferencesDtos.PreferencesResponse(
                                "UTC", "system", true, true, null, null),
                userId);
    }

    @Transactional
    public UserPreferencesDtos.PreferencesResponse update(
            UserPreferencesDtos.PreferencesRequest request) {
        jdbcTemplate.update(
                "INSERT INTO user_preferences (user_id, timezone, theme, notifications_enabled, "
                        + "reminder_enabled, daily_start_time, daily_end_time) VALUES (?, ?, ?, ?, ?, ?, ?) "
                        + "ON CONFLICT (user_id) DO UPDATE SET timezone = EXCLUDED.timezone, "
                        + "theme = EXCLUDED.theme, notifications_enabled = EXCLUDED.notifications_enabled, "
                        + "reminder_enabled = EXCLUDED.reminder_enabled, daily_start_time = EXCLUDED.daily_start_time, "
                        + "daily_end_time = EXCLUDED.daily_end_time, updated_at = now()",
                currentUser.id(), request.timezone(), request.theme(),
                request.notificationsEnabled(), request.reminderEnabled(),
                request.dailyStartTime(), request.dailyEndTime());
        return get();
    }
}
