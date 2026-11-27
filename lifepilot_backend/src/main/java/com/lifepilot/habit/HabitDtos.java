package com.lifepilot.habit;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public final class HabitDtos {
    private HabitDtos() {}

    public record HabitRequest(
            @NotBlank @Size(max = 200) String name,
            @Size(max = 2000) String description,
            @NotBlank String frequency,
            List<Integer> selectedWeekdays,
            @Positive Double targetDuration,
            String durationUnit,
            String category,
            @NotNull LocalDate startDate,
            List<LocalDate> completedDates) {}

    public record HabitResponse(
            UUID id, String name, String description, String frequency,
            List<Integer> selectedWeekdays, Double targetDuration, String durationUnit,
            String category, LocalDate startDate, List<LocalDate> completedDates) {}

    public record CompletionRequest(@NotNull LocalDate date) {}

    public record HabitStatistics(
            int totalHabits, int completedThisWeek, int scheduledThisWeek) {}
}
