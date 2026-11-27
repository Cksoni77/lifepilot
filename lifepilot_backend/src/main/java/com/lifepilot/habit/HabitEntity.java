package com.lifepilot.habit;

import com.lifepilot.common.BaseEntity;
import com.lifepilot.user.AppUser;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "habits")
public class HabitEntity extends BaseEntity {
    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser owner;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(nullable = false, length = 2000)
    private String description = "";

    @Column(nullable = false, length = 20)
    private String frequency;

    @ElementCollection
    @CollectionTable(name = "habit_weekdays", joinColumns = @JoinColumn(name = "habit_id"))
    @Column(name = "weekday", nullable = false)
    private List<Integer> selectedWeekdays = new ArrayList<>();

    @Column(name = "target_duration")
    private Double targetDuration;

    @Column(name = "duration_unit", nullable = false, length = 20)
    private String durationUnit;

    @Column(nullable = false, length = 30)
    private String category;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    protected HabitEntity() {}

    public HabitEntity(AppUser owner, HabitDtos.HabitRequest request) {
        id = UUID.randomUUID();
        this.owner = owner;
        update(request);
    }

    public void update(HabitDtos.HabitRequest request) {
        name = request.name().trim();
        description = request.description() == null ? "" : request.description().trim();
        frequency = request.frequency().toLowerCase(java.util.Locale.ROOT);
        selectedWeekdays = request.selectedWeekdays() == null
                ? new ArrayList<>() : new ArrayList<>(request.selectedWeekdays());
        targetDuration = request.targetDuration();
        durationUnit = (request.durationUnit() == null ? "minutes" : request.durationUnit())
                .toLowerCase(java.util.Locale.ROOT);
        category = (request.category() == null ? "other" : request.category())
                .toLowerCase(java.util.Locale.ROOT);
        startDate = request.startDate();
    }

    public UUID getId() { return id; }
    public AppUser getOwner() { return owner; }
    public String getName() { return name; }
    public String getDescription() { return description; }
    public String getFrequency() { return frequency; }
    public List<Integer> getSelectedWeekdays() { return selectedWeekdays; }
    public Double getTargetDuration() { return targetDuration; }
    public String getDurationUnit() { return durationUnit; }
    public String getCategory() { return category; }
    public LocalDate getStartDate() { return startDate; }
}
