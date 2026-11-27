package com.lifepilot.habit;

import com.lifepilot.security.CurrentUser;
import com.lifepilot.user.AppUserRepository;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class HabitService {
    private final HabitRepository habits;
    private final HabitCompletionRepository completions;
    private final AppUserRepository users;
    private final CurrentUser currentUser;

    public HabitService(HabitRepository habits, HabitCompletionRepository completions,
            AppUserRepository users, CurrentUser currentUser) {
        this.habits = habits;
        this.completions = completions;
        this.users = users;
        this.currentUser = currentUser;
    }

    @Transactional(readOnly = true)
    public List<HabitDtos.HabitResponse> list() {
        return habits.findAllByOwner_IdOrderByCreatedAtDesc(currentUser.id()).stream()
                .map(this::response).toList();
    }

    @Transactional
    public HabitDtos.HabitResponse create(HabitDtos.HabitRequest request) {
        validate(request);
        var owner = users.findById(currentUser.id()).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
        HabitEntity habit = habits.save(new HabitEntity(owner, request));
        syncCompletions(habit, request.completedDates());
        return response(habit);
    }

    @Transactional
    public HabitDtos.HabitResponse update(UUID id, HabitDtos.HabitRequest request) {
        validate(request);
        HabitEntity habit = findOwned(id);
        habit.update(request);
        syncCompletions(habit, request.completedDates());
        return response(habit);
    }

    @Transactional
    public void delete(UUID id) {
        habits.delete(findOwned(id));
    }

    @Transactional
    public HabitDtos.HabitResponse complete(UUID id, LocalDate date) {
        HabitEntity habit = findOwned(id);
        if (date.isBefore(habit.getStartDate()) || !isScheduled(habit, date)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "This habit is not scheduled on that date");
        }
        if (completions.findByHabit_IdAndCompletedOn(id, date).isEmpty()) {
            completions.save(new HabitCompletion(habit, date));
        }
        return response(habit);
    }

    @Transactional
    public HabitDtos.HabitResponse undo(UUID id, LocalDate date) {
        HabitEntity habit = findOwned(id);
        completions.findByHabit_IdAndCompletedOn(id, date).ifPresent(completions::delete);
        return response(habit);
    }

    @Transactional(readOnly = true)
    public List<LocalDate> history(UUID id) {
        HabitEntity habit = findOwned(id);
        return completions.findAllByHabit_IdOrderByCompletedOnAsc(habit.getId()).stream()
                .map(HabitCompletion::getCompletedOn).toList();
    }

    @Transactional(readOnly = true)
    public HabitDtos.HabitStatistics statistics() {
        List<HabitEntity> owned = habits.findAllByOwner_IdOrderByCreatedAtDesc(currentUser.id());
        LocalDate today = LocalDate.now();
        LocalDate monday = today.with(DayOfWeek.MONDAY);
        int scheduled = 0;
        int completed = 0;
        for (HabitEntity habit : owned) {
            for (LocalDate day = monday; !day.isAfter(today); day = day.plusDays(1)) {
                if (day.isBefore(habit.getStartDate()) || !isScheduled(habit, day)) continue;
                scheduled++;
                if (completions.findByHabit_IdAndCompletedOn(habit.getId(), day).isPresent()) completed++;
            }
        }
        return new HabitDtos.HabitStatistics(owned.size(), completed, scheduled);
    }

    private HabitEntity findOwned(UUID id) {
        return habits.findByIdAndOwner_Id(id, currentUser.id()).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.NOT_FOUND, "Habit not found"));
    }

    private HabitDtos.HabitResponse response(HabitEntity habit) {
        List<LocalDate> dates = completions.findAllByHabit_IdOrderByCompletedOnAsc(habit.getId())
                .stream().map(HabitCompletion::getCompletedOn).toList();
        return new HabitDtos.HabitResponse(habit.getId(), habit.getName(), habit.getDescription(),
                "customdays".equals(habit.getFrequency()) ? "customDays" : habit.getFrequency(),
                habit.getSelectedWeekdays(), habit.getTargetDuration(),
                habit.getDurationUnit(), habit.getCategory(), habit.getStartDate(), dates);
    }

    private void syncCompletions(HabitEntity habit, List<LocalDate> dates) {
        if (dates == null) return;
        List<LocalDate> current = completions.findAllByHabit_IdOrderByCompletedOnAsc(habit.getId())
                .stream().map(HabitCompletion::getCompletedOn).toList();
        current.stream().filter(date -> !dates.contains(date))
                .forEach(date -> completions.findByHabit_IdAndCompletedOn(habit.getId(), date)
                        .ifPresent(completions::delete));
        dates.stream().filter(date -> !date.isBefore(habit.getStartDate()))
                .distinct().forEach(date -> completions.findByHabit_IdAndCompletedOn(habit.getId(), date)
                        .orElseGet(() -> completions.save(new HabitCompletion(habit, date))));
    }

    private void validate(HabitDtos.HabitRequest request) {
        if ("customDays".equalsIgnoreCase(request.frequency())
                && (request.selectedWeekdays() == null || request.selectedWeekdays().isEmpty())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Select at least one weekday for a custom schedule");
        }
        if (request.selectedWeekdays() != null
                && request.selectedWeekdays().stream().anyMatch(day -> day < 1 || day > 7)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Weekdays must be from 1 to 7");
        }
    }

    private boolean isScheduled(HabitEntity habit, LocalDate day) {
        return switch (habit.getFrequency().toLowerCase(java.util.Locale.ROOT)) {
            case "weekdays" -> day.getDayOfWeek().getValue() <= 5;
            case "weekends" -> day.getDayOfWeek().getValue() >= 6;
            case "customdays" -> habit.getSelectedWeekdays().contains(day.getDayOfWeek().getValue());
            default -> true;
        };
    }
}
