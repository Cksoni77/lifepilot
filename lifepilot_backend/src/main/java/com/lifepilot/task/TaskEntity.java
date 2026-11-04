package com.lifepilot.task;

import com.lifepilot.common.BaseEntity;
import com.lifepilot.goal.GoalEntity;
import com.lifepilot.user.AppUser;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "tasks")
public class TaskEntity extends BaseEntity {
    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser owner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "goal_id")
    private GoalEntity goal;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, length = 4000)
    private String description = "";

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TaskCategory category;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TaskPriority priority;

    @Column(nullable = false)
    private boolean completed;

    @Column(name = "due_at")
    private OffsetDateTime dueAt;

    @Column(name = "reminder_at")
    private OffsetDateTime reminderAt;

    @Column(name = "reminder_enabled", nullable = false)
    private boolean reminderEnabled;

    @Column(name = "estimated_minutes")
    private Integer estimatedMinutes;

    @Column(name = "completed_at")
    private OffsetDateTime completedAt;

    protected TaskEntity() {}

    public TaskEntity(AppUser owner, TaskDtos.TaskRequest request) {
        id = UUID.randomUUID();
        this.owner = owner;
        update(request);
    }

    public void update(TaskDtos.TaskRequest request) {
        title = request.title().trim();
        description = request.description() == null ? "" : request.description().trim();
        category = request.category();
        priority = request.priority();
        dueAt = request.dueAt();
        reminderAt = request.reminderAt();
        reminderEnabled = request.reminderEnabled();
        estimatedMinutes = request.estimatedMinutes();
    }

    public void setCompleted(boolean value) {
        completed = value;
        completedAt = value ? OffsetDateTime.now(java.time.ZoneOffset.UTC) : null;
    }

    public UUID getId() { return id; }
    public AppUser getOwner() { return owner; }
    public GoalEntity getGoal() { return goal; }
    public void setGoal(GoalEntity goal) { this.goal = goal; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public TaskCategory getCategory() { return category; }
    public TaskPriority getPriority() { return priority; }
    public boolean isCompleted() { return completed; }
    public OffsetDateTime getDueAt() { return dueAt; }
    public OffsetDateTime getReminderAt() { return reminderAt; }
    public boolean isReminderEnabled() { return reminderEnabled; }
    public Integer getEstimatedMinutes() { return estimatedMinutes; }
    public OffsetDateTime getCompletedAt() { return completedAt; }
}
