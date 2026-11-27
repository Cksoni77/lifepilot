package com.lifepilot.goal;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public final class GoalDtos {
    private GoalDtos() {}

    public record GoalRequest(
            @NotBlank @Size(max = 200) String title,
            @Size(max = 2000) String description,
            @Size(max = 80) String category,
            @DecimalMin("0.0") @DecimalMax("1.0") double progress,
            LocalDate targetDate,
            List<@NotBlank @Size(max = 200) String> milestones) {}

    public record ProgressRequest(
            @NotNull @DecimalMin("0.0") @DecimalMax("1.0") Double progress) {}

    public record GoalResponse(
            UUID id, String title, String description, String category, double progress,
            LocalDate targetDate, List<String> milestones) {
        static GoalResponse from(GoalEntity goal) {
            return new GoalResponse(goal.getId(), goal.getTitle(), goal.getDescription(),
                    goal.getCategory(), goal.getProgress(), goal.getTargetDate(),
                    List.copyOf(goal.getMilestones()));
        }
    }
}
