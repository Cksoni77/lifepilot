package com.lifepilot.goal;

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
@Table(name = "goals")
public class GoalEntity extends BaseEntity {
    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser owner;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, length = 2000)
    private String description = "";

    @Column(nullable = false, length = 80)
    private String category;

    @Column(nullable = false)
    private double progress;

    @Column(name = "target_date")
    private LocalDate targetDate;

    @ElementCollection
    @CollectionTable(name = "goal_milestones", joinColumns = @JoinColumn(name = "goal_id"))
    @Column(name = "title", nullable = false, length = 200)
    private List<String> milestones = new ArrayList<>();

    protected GoalEntity() {}

    public GoalEntity(AppUser owner, GoalDtos.GoalRequest request) {
        id = UUID.randomUUID();
        this.owner = owner;
        update(request);
    }

    public void update(GoalDtos.GoalRequest request) {
        title = request.title().trim();
        description = request.description() == null ? "" : request.description().trim();
        category = request.category() == null ? "Personal" : request.category().trim();
        targetDate = request.targetDate();
        progress = request.progress();
        milestones = request.milestones() == null
                ? new ArrayList<>() : new ArrayList<>(request.milestones());
    }

    public void setProgress(double progress) { this.progress = progress; }
    public UUID getId() { return id; }
    public AppUser getOwner() { return owner; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public String getCategory() { return category; }
    public double getProgress() { return progress; }
    public LocalDate getTargetDate() { return targetDate; }
    public List<String> getMilestones() { return milestones; }
}
