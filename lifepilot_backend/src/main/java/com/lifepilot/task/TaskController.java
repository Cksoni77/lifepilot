package com.lifepilot.task;

import jakarta.validation.Valid;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/tasks")
public class TaskController {
    private final TaskService taskService;

    public TaskController(TaskService taskService) {
        this.taskService = taskService;
    }

    @GetMapping
    public List<TaskDtos.TaskResponse> list(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String sort) {
        return taskService.list(search, status, sort);
    }

    @GetMapping("/today")
    public List<TaskDtos.TaskResponse> today() {
        return taskService.list(null, "today", null);
    }

    @GetMapping("/overdue")
    public List<TaskDtos.TaskResponse> overdue() {
        return taskService.list(null, "overdue", null);
    }

    @GetMapping("/upcoming")
    public List<TaskDtos.TaskResponse> upcoming() {
        return taskService.list(null, "pending", "dueDate").stream()
                .filter(task -> task.dueDate() != null
                        && !task.dueDate().toLocalDate().isBefore(LocalDate.now(ZoneOffset.UTC)))
                .toList();
    }

    @GetMapping("/{id}")
    public TaskDtos.TaskResponse get(@PathVariable UUID id) {
        return taskService.get(id);
    }

    @PostMapping
    public TaskDtos.TaskResponse create(@Valid @RequestBody TaskDtos.TaskRequest request) {
        return taskService.create(request);
    }

    @PutMapping("/{id}")
    public TaskDtos.TaskResponse update(
            @PathVariable UUID id, @Valid @RequestBody TaskDtos.TaskRequest request) {
        return taskService.update(id, request);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable UUID id) {
        taskService.delete(id);
    }

    @PatchMapping("/{id}/complete")
    public TaskDtos.TaskResponse complete(
            @PathVariable UUID id, @RequestBody CompletionRequest request) {
        return taskService.complete(id, request.completed());
    }

    public record CompletionRequest(boolean completed) {}
}
