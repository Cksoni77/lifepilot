package com.lifepilot.habit;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "habit_completions",
        uniqueConstraints = @UniqueConstraint(columnNames = {"habit_id", "completed_on"}))
public class HabitCompletion {
    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "habit_id", nullable = false)
    private HabitEntity habit;

    @Column(name = "completed_on", nullable = false)
    private LocalDate completedOn;

    protected HabitCompletion() {}

    public HabitCompletion(HabitEntity habit, LocalDate completedOn) {
        id = UUID.randomUUID();
        this.habit = habit;
        this.completedOn = completedOn;
    }

    public UUID getId() { return id; }
    public LocalDate getCompletedOn() { return completedOn; }
}
