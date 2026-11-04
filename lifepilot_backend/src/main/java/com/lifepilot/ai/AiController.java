package com.lifepilot.ai;

import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ai")
public class AiController {
    private final AiService aiService;

    public AiController(AiService aiService) { this.aiService = aiService; }

    @PostMapping("/chat")
    public AiDtos.ChatResponse chat(@Valid @RequestBody AiDtos.ChatRequest request) {
        return aiService.chat(request);
    }

    @PostMapping("/daily-plan")
    public AiDtos.DailyPlanResponse dailyPlan() { return aiService.dailyPlan(); }
}
