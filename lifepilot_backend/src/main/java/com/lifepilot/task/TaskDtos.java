package com.lifepilot.task;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.time.OffsetDateTime;
import java.util.UUID;

public final class TaskDtos {
    private TaskDtos() {}

    public record TaskRequest(
            @NotBlank @Size(max = 200) String title,
            @Size(max = 4000) String description,
            @NotNull TaskCategory category,
            @NotNull TaskPriority priority,
            OffsetDateTime dueAt,
            OffsetDateTime reminderAt,
            boolean reminderEnabled,
            @Positive Integer estimatedMinutes,
            UUID goalId) {}

    public record TaskResponse(
            UUID id, UUID goalId, String title, String description, String category, String priority,
            boolean completed, OffsetDateTime dueDate, OffsetDateTime reminderDate,
            boolean reminderEnabled, Integer estimatedMinutes, OffsetDateTime createdAt,
            OffsetDateTime completedAt) {
        public static TaskResponse from(TaskEntity task) {
            return new TaskResponse(task.getId(),
                    task.getGoal() == null ? null : task.getGoal().getId(),
                    task.getTitle(), task.getDescription(),
                    task.getCategory().name().toLowerCase(java.util.Locale.ROOT),
                    task.getPriority().name().toLowerCase(java.util.Locale.ROOT),
                    task.isCompleted(), task.getDueAt(), task.getReminderAt(),
                    task.isReminderEnabled(), task.getEstimatedMinutes(),
                    task.getCreatedAt(), task.getCompletedAt());
        }
    }
}
