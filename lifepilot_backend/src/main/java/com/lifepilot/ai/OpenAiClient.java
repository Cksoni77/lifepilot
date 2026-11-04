package com.lifepilot.ai;

import com.fasterxml.jackson.databind.JsonNode;
import java.time.Duration;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientResponseException;

@Component
public class OpenAiClient {
    private final String apiKey;
    private final String model;
    private final RestClient restClient;

    public OpenAiClient(
            @Value("${app.openai.api-key}") String apiKey,
            @Value("${app.openai.model}") String model,
            @Value("${app.openai.timeout-seconds}") long timeoutSeconds) {
        this.apiKey = apiKey;
        this.model = model;
        JdkClientHttpRequestFactory requestFactory = new JdkClientHttpRequestFactory();
        requestFactory.setReadTimeout(Duration.ofSeconds(timeoutSeconds));
        this.restClient = RestClient.builder().baseUrl("https://api.openai.com/v1")
                .requestFactory(requestFactory).build();
    }

    public boolean isConfigured() {
        return !apiKey.isBlank();
    }

    public String respond(String message, String userContext) {
        Object request = java.util.Map.of(
                "model", model,
                "input", List.of(
                        java.util.Map.of("role", "system", "content", List.of(
                                java.util.Map.of("type", "input_text",
                                        "text", "Answer using only the supplied user context. Do not invent dates, availability, or actions. "
                                                + "Return JSON with keys message, intent, relevantTaskIds, recommendations, "
                                                + "suggestedActions, explanation, requiresConfirmation. Suggested actions are proposals only; "
                                                + "never claim an action has been performed."))),
                        java.util.Map.of("role", "user", "content", List.of(
                                java.util.Map.of("type", "input_text",
                                        "text", "User request: " + message + "\nSaved context: " + userContext)))),
                "text", java.util.Map.of("format", java.util.Map.of("type", "json_object")));
        JsonNode response = requestWithRetry(request);
        if (response == null) {
            throw new IllegalStateException("AI provider returned an empty response");
        }
        return response.path("output").findValuesAsText("text").stream()
                .filter(text -> !text.isBlank()).findFirst()
                .orElseThrow(() -> new IllegalStateException("AI provider returned no response text"));
    }

    private JsonNode requestWithRetry(Object request) {
        for (int attempt = 0; attempt < 2; attempt++) {
            try {
                return restClient.post().uri("/responses")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Authorization", "Bearer " + apiKey)
                        .body(request)
                        .retrieve().body(JsonNode.class);
            } catch (RestClientResponseException exception) {
                HttpStatusCode status = exception.getStatusCode();
                if (attempt == 1 || (status.value() != 429 && !status.is5xxServerError())) {
                    throw exception;
                }
                pauseBeforeRetry();
            } catch (ResourceAccessException exception) {
                if (attempt == 1) throw exception;
                pauseBeforeRetry();
            }
        }
        throw new IllegalStateException("AI provider request did not complete");
    }

    private void pauseBeforeRetry() {
        try {
            Thread.sleep(200);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("AI provider retry was interrupted", exception);
        }
    }
}
