package com.lifepilot.ai;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.lifepilot.task.TaskDtos;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class RecommendationEngineTest {
    private final RecommendationEngine engine = new RecommendationEngine(0.30, 0.30, 0.20, 0.20);

    @Test
    void ranksHigherPriorityAndUrgentTasksFirst() {
        OffsetDateTime today = OffsetDateTime.now(ZoneOffset.UTC)
                .toLocalDate().atStartOfDay().atOffset(ZoneOffset.UTC);
        TaskDtos.TaskResponse dueToday = task("high", "HIGH", today, null);
        TaskDtos.TaskResponse noDueDate = task("low", "LOW", null, null);

        List<RecommendationEngine.ScoredTask> ranked = engine.rank(List.of(noDueDate, dueToday));

        assertEquals(dueToday.id(), ranked.get(0).task().id());
        assertTrue(ranked.get(0).score() > ranked.get(ranked.size() - 1).score());
    }

    @Test
    void goalLinkedTaskUsesGoalRelevanceWeight() {
        TaskDtos.TaskResponse linked = task("medium", "MEDIUM", null, UUID.randomUUID());
        TaskDtos.TaskResponse unlinked = task("medium", "MEDIUM", null, null);

        List<RecommendationEngine.ScoredTask> ranked = engine.rank(List.of(linked, unlinked));
        assertTrue(ranked.get(0).score() > ranked.get(ranked.size() - 1).score());
    }

    @Test
    void rejectsWeightsThatDoNotSumToOne() {
        assertThrows(IllegalArgumentException.class,
                () -> new RecommendationEngine(0.3, 0.3, 0.3, 0.2));
    }

    private TaskDtos.TaskResponse task(
            String priority, String ignoredTitle, OffsetDateTime dueAt, UUID goalId) {
        return new TaskDtos.TaskResponse(
                UUID.randomUUID(), goalId, ignoredTitle, "", "personal", priority,
                false, dueAt, null, false, 25, dueAt, null);
    }
}
