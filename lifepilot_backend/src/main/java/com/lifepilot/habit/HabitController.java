package com.lifepilot.habit;

import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/habits")
public class HabitController {
    private final HabitService habitService;

    public HabitController(HabitService habitService) {
        this.habitService = habitService;
    }

    @GetMapping
    public List<HabitDtos.HabitResponse> list() { return habitService.list(); }

    @PostMapping
    public HabitDtos.HabitResponse create(@Valid @RequestBody HabitDtos.HabitRequest request) {
        return habitService.create(request);
    }

    @PutMapping("/{id}")
    public HabitDtos.HabitResponse update(
            @PathVariable UUID id, @Valid @RequestBody HabitDtos.HabitRequest request) {
        return habitService.update(id, request);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable UUID id) { habitService.delete(id); }

    @PostMapping("/{id}/complete")
    public HabitDtos.HabitResponse complete(
            @PathVariable UUID id, @Valid @RequestBody HabitDtos.CompletionRequest request) {
        return habitService.complete(id, request.date());
    }

    @DeleteMapping("/{id}/completions")
    public HabitDtos.HabitResponse undo(
            @PathVariable UUID id, @RequestParam LocalDate date) {
        return habitService.undo(id, date);
    }

    @GetMapping("/{id}/history")
    public List<LocalDate> history(@PathVariable UUID id) {
        return habitService.history(id);
    }

    @GetMapping("/statistics")
    public HabitDtos.HabitStatistics statistics() { return habitService.statistics(); }
}
