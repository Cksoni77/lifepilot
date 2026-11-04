package com.lifepilot.ai;

import com.lifepilot.task.TaskDtos;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class RecommendationEngine {
    private final double priorityWeight;
    private final double urgencyWeight;
    private final double deadlineWeight;
    private final double goalRelevanceWeight;

    public RecommendationEngine(
            @Value("${app.recommendations.priority-weight:0.30}") double priorityWeight,
            @Value("${app.recommendations.urgency-weight:0.30}") double urgencyWeight,
            @Value("${app.recommendations.deadline-weight:0.20}") double deadlineWeight,
            @Value("${app.recommendations.goal-relevance-weight:0.20}") double goalRelevanceWeight) {
        double total = priorityWeight + urgencyWeight + deadlineWeight + goalRelevanceWeight;
        if (priorityWeight < 0 || urgencyWeight < 0 || deadlineWeight < 0
                || goalRelevanceWeight < 0 || Math.abs(total - 1.0) > 0.0001) {
            throw new IllegalArgumentException("Recommendation weights must be non-negative and sum to 1");
        }
        this.priorityWeight = priorityWeight;
        this.urgencyWeight = urgencyWeight;
        this.deadlineWeight = deadlineWeight;
        this.goalRelevanceWeight = goalRelevanceWeight;
    }

    public List<ScoredTask> rank(List<TaskDtos.TaskResponse> tasks) {
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        return tasks.stream().filter(task -> !task.completed())
                .map(task -> score(task, today))
                .sorted(Comparator.comparingDouble(ScoredTask::score).reversed())
                .toList();
    }

    private ScoredTask score(TaskDtos.TaskResponse task, LocalDate today) {
        double priority = switch (task.priority().toLowerCase(java.util.Locale.ROOT)) {
            case "high" -> 100;
            case "medium" -> 60;
            default -> 30;
        };
        LocalDate due = task.dueDate() == null ? null : task.dueDate().toLocalDate();
        long days = due == null ? Long.MAX_VALUE : ChronoUnit.DAYS.between(today, due);
        double urgency = due == null ? 0 : days < 0 ? 100 : days == 0 ? 90
                : days <= 2 ? 75 : days <= 7 ? 55 : days <= 30 ? 35 : 15;
        double deadline = due == null ? 0 : days <= 0 ? 100
                : Math.max(0, 100.0 / (days + 1));
        double goalRelevance = task.goalId() == null ? 0 : 100;
        double score = priorityWeight * priority + urgencyWeight * urgency
                + deadlineWeight * deadline + goalRelevanceWeight * goalRelevance;
        String explanation = due != null && days < 0
                ? "This task is overdue."
                : due != null && days <= 2
                        ? "This task has an approaching deadline."
                        : "This task is ranked using its saved priority and due date.";
        if (task.estimatedMinutes() != null) {
            explanation += " Estimated time: " + task.estimatedMinutes() + " minutes.";
        }
        return new ScoredTask(task, Math.round(score * 100.0) / 100.0, explanation);
    }

    public record ScoredTask(TaskDtos.TaskResponse task, double score, String explanation) {}
}
