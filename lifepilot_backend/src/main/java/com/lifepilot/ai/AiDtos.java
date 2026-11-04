package com.lifepilot.ai;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

public final class AiDtos {
    private AiDtos() {}

    public record ChatRequest(
            @NotBlank @Size(max = 4000) String message,
            UUID conversationId) {}

    public record ChatResponse(
            String message,
            String intent,
            List<UUID> relevantTaskIds,
            List<String> recommendations,
            List<String> suggestedActions,
            String explanation,
            boolean requiresConfirmation,
            boolean providerAvailable) {}

    public record DailyPlanResponse(
            List<RecommendationEngine.ScoredTask> rankedTasks,
            List<String> scheduledItems,
            List<String> questions,
            String explanation) {}
}
