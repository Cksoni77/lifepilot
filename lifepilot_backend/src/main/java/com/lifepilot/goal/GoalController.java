package com.lifepilot.goal;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/goals")
public class GoalController {
    private final GoalService goalService;

    public GoalController(GoalService goalService) { this.goalService = goalService; }

    @GetMapping
    public List<GoalDtos.GoalResponse> list() { return goalService.list(); }

    @PostMapping
    public GoalDtos.GoalResponse create(@Valid @RequestBody GoalDtos.GoalRequest request) {
        return goalService.create(request);
    }

    @PutMapping("/{id}")
    public GoalDtos.GoalResponse update(
            @PathVariable UUID id, @Valid @RequestBody GoalDtos.GoalRequest request) {
        return goalService.update(id, request);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable UUID id) { goalService.delete(id); }

    @PatchMapping("/{id}/progress")
    public GoalDtos.GoalResponse updateProgress(
            @PathVariable UUID id, @Valid @RequestBody GoalDtos.ProgressRequest request) {
        return goalService.updateProgress(id, request.progress());
    }
}
