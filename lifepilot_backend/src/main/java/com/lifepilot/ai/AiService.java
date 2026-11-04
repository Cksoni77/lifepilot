package com.lifepilot.ai;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.lifepilot.goal.GoalRepository;
import com.lifepilot.habit.HabitCompletionRepository;
import com.lifepilot.habit.HabitRepository;
import com.lifepilot.security.CurrentUser;
import com.lifepilot.task.TaskDtos;
import com.lifepilot.task.TaskRepository;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClientException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class AiService {
    private static final Logger logger = LoggerFactory.getLogger(AiService.class);

    private final TaskRepository tasks;
    private final HabitRepository habits;
    private final HabitCompletionRepository completions;
    private final GoalRepository goals;
    private final CurrentUser currentUser;
    private final RecommendationEngine recommendations;
    private final OpenAiClient openAi;
    private final ObjectMapper objectMapper;

    public AiService(TaskRepository tasks, HabitRepository habits, GoalRepository goals,
            HabitCompletionRepository completions, CurrentUser currentUser, RecommendationEngine recommendations,
            OpenAiClient openAi, ObjectMapper objectMapper) {
        this.tasks = tasks;
        this.habits = habits;
        this.completions = completions;
        this.goals = goals;
        this.currentUser = currentUser;
        this.recommendations = recommendations;
        this.openAi = openAi;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public AiDtos.ChatResponse chat(AiDtos.ChatRequest request) {
        UUID userId = currentUser.id();
        List<TaskDtos.TaskResponse> userTasks = taskResponses(userId);
        List<RecommendationEngine.ScoredTask> ranked = recommendations.rank(userTasks);
        String context = context(userId, userTasks);
        if (!openAi.isConfigured()) {
            return deterministicReply(request.message(), userTasks, ranked);
        }
        try {
            return parseResponse(openAi.respond(request.message(), context), userTasks);
        } catch (RestClientException | JsonProcessingException
                | IllegalArgumentException | IllegalStateException exception) {
            logger.warn("AI provider response unavailable or invalid ({})",
                    exception.getClass().getSimpleName());
            return deterministicReply(request.message(), userTasks, ranked);
        }
    }

    @Transactional(readOnly = true)
    public AiDtos.DailyPlanResponse dailyPlan() {
        UUID userId = currentUser.id();
        List<RecommendationEngine.ScoredTask> ranked =
                recommendations.rank(taskResponses(userId));
        return new AiDtos.DailyPlanResponse(ranked, List.of(),
                List.of("What hours are you available, and what fixed commitments should the plan avoid?"),
                "Tasks are ranked from saved priorities, deadlines, and estimated durations. "
                        + "No time slots were assigned because availability and calendar commitments are not configured.");
    }

    private List<TaskDtos.TaskResponse> taskResponses(UUID userId) {
        return tasks.findAllByOwner_IdOrderByCreatedAtDesc(userId).stream()
                .limit(100)
                .map(TaskDtos.TaskResponse::from).toList();
    }

    private String context(UUID userId, List<TaskDtos.TaskResponse> userTasks) {
        var userHabits = habits.findAllByOwner_IdOrderByCreatedAtDesc(userId).stream()
                .limit(50)
                .map(habit -> {
                    var recentDates = completions
                            .findTop30ByHabit_IdOrderByCompletedOnDesc(habit.getId()).stream()
                            .sorted(java.util.Comparator.comparing(
                                    value -> value.getCompletedOn()))
                            .map(value -> value.getCompletedOn().toString()).toList();
                    return java.util.Map.of(
                            "name", habit.getName(),
                            "frequency", habit.getFrequency(),
                            "startDate", habit.getStartDate().toString(),
                            "completionDates", recentDates);
                })
                .toList();
        var userGoals = goals.findAllByOwner_IdOrderByCreatedAtDesc(userId).stream().limit(50)
                .map(goal -> java.util.Map.of(
                        "title", goal.getTitle(),
                        "progress", goal.getProgress(),
                        "targetDate", goal.getTargetDate() == null ? "" : goal.getTargetDate().toString()))
                .toList();
        try {
            return objectMapper.writeValueAsString(java.util.Map.of(
                    "todayUtc", LocalDate.now(ZoneOffset.UTC).toString(),
                    "tasks", userTasks.stream().limit(50)
                            .map(task -> java.util.Map.of(
                                    "id", task.id(),
                                    "title", task.title(),
                                    "description", truncate(task.description(), 300),
                                    "priority", task.priority(),
                                    "completed", task.completed(),
                                    "dueDate", task.dueDate() == null ? "" : task.dueDate().toString(),
                                    "estimatedMinutes", task.estimatedMinutes() == null
                                            ? "" : task.estimatedMinutes(),
                                    "goalId", task.goalId() == null ? "" : task.goalId()))
                            .toList(),
                    "habits", userHabits,
                    "goals", userGoals));
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Could not serialize user context", exception);
        }
    }

    private AiDtos.ChatResponse deterministicReply(
            String message, List<TaskDtos.TaskResponse> userTasks,
            List<RecommendationEngine.ScoredTask> ranked) {
        String normalized = message.toLowerCase(java.util.Locale.ROOT);
        if (normalized.contains("today")) {
            LocalDate today = LocalDate.now(ZoneOffset.UTC);
            List<TaskDtos.TaskResponse> dueToday = userTasks.stream()
                    .filter(task -> !task.completed() && task.dueDate() != null
                            && task.dueDate().toLocalDate().equals(today)).toList();
            return new AiDtos.ChatResponse(
                    dueToday.isEmpty() ? "You have no saved pending tasks due today."
                            : "Your pending tasks due today: " + titles(dueToday),
                    "tasks_today", dueToday.stream().map(TaskDtos.TaskResponse::id).toList(),
                    List.of(), List.of(), "Based on your saved task due dates.", false, false);
        }
        if (normalized.contains("overdue")) {
            LocalDate today = LocalDate.now(ZoneOffset.UTC);
            List<TaskDtos.TaskResponse> overdue = userTasks.stream()
                    .filter(task -> !task.completed() && task.dueDate() != null
                            && task.dueDate().toLocalDate().isBefore(today)).toList();
            return new AiDtos.ChatResponse(
                    overdue.isEmpty() ? "You have no saved overdue tasks."
                            : "Your overdue tasks: " + titles(overdue),
                    "overdue_tasks", overdue.stream().map(TaskDtos.TaskResponse::id).toList(),
                    List.of(), List.of(), "Based on your saved task due dates.", false, false);
        }
        if (normalized.contains("priorit")) {
            List<String> lines = ranked.stream().limit(5)
                    .map(task -> task.task().title() + ": " + task.explanation()).toList();
            return new AiDtos.ChatResponse(
                    lines.isEmpty() ? "You have no pending tasks to prioritize."
                            : "Recommended order: " + String.join(" ", lines),
                    "prioritize_tasks", ranked.stream().limit(5)
                            .map(task -> task.task().id()).toList(),
                    lines, List.of(), "Sorted by saved priority and due dates.", false, false);
        }
        return new AiDtos.ChatResponse(
                "AI chat is not configured. I can still answer questions about your saved tasks "
                        + "for today, overdue tasks, or task priorities. Configure OPENAI_API_KEY to enable natural-language responses.",
                "unsupported_without_provider", List.of(), List.of(), List.of(),
                "No AI provider is configured; no external request was made.", false, false);
    }

    private AiDtos.ChatResponse parseResponse(
            String response, List<TaskDtos.TaskResponse> userTasks)
            throws JsonProcessingException {
        AiDtos.ChatResponse parsed = objectMapper.readValue(response, AiDtos.ChatResponse.class);
        if (parsed.message() == null || parsed.message().isBlank() || parsed.message().length() > 4000) {
            throw new IllegalArgumentException("AI response message is missing or too long");
        }
        java.util.Set<UUID> ownedTaskIds = userTasks.stream()
                .map(TaskDtos.TaskResponse::id).collect(java.util.stream.Collectors.toSet());
        List<UUID> validTaskIds = parsed.relevantTaskIds() == null ? List.of()
                : parsed.relevantTaskIds().stream().filter(ownedTaskIds::contains).distinct().toList();
        List<String> actions = parsed.suggestedActions() == null ? List.of()
                : parsed.suggestedActions().stream().filter(value -> value != null && !value.isBlank())
                        .limit(10).toList();
        return new AiDtos.ChatResponse(parsed.message(), parsed.intent(),
                validTaskIds,
                parsed.recommendations() == null ? List.of()
                        : parsed.recommendations().stream().filter(value -> value != null && !value.isBlank())
                                .limit(10).toList(),
                actions,
                parsed.explanation(),
                parsed.requiresConfirmation() || !actions.isEmpty(), true);
    }

    private String truncate(String text, int maxLength) {
        return text.length() <= maxLength ? text : text.substring(0, maxLength);
    }

    private String titles(List<TaskDtos.TaskResponse> tasks) {
        return String.join(", ", tasks.stream().map(TaskDtos.TaskResponse::title).toList());
    }
}
