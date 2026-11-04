package com.lifepilot.goal;

import com.lifepilot.security.CurrentUser;
import com.lifepilot.user.AppUserRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class GoalService {
    private final GoalRepository goals;
    private final AppUserRepository users;
    private final CurrentUser currentUser;

    public GoalService(GoalRepository goals, AppUserRepository users, CurrentUser currentUser) {
        this.goals = goals;
        this.users = users;
        this.currentUser = currentUser;
    }

    @Transactional(readOnly = true)
    public List<GoalDtos.GoalResponse> list() {
        return goals.findAllByOwner_IdOrderByCreatedAtDesc(currentUser.id()).stream()
                .map(GoalDtos.GoalResponse::from).toList();
    }

    @Transactional
    public GoalDtos.GoalResponse create(GoalDtos.GoalRequest request) {
        var owner = users.findById(currentUser.id()).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
        return GoalDtos.GoalResponse.from(goals.save(new GoalEntity(owner, request)));
    }

    @Transactional
    public GoalDtos.GoalResponse update(UUID id, GoalDtos.GoalRequest request) {
        GoalEntity goal = findOwned(id);
        goal.update(request);
        return GoalDtos.GoalResponse.from(goal);
    }

    @Transactional
    public GoalDtos.GoalResponse updateProgress(UUID id, double progress) {
        GoalEntity goal = findOwned(id);
        goal.setProgress(progress);
        return GoalDtos.GoalResponse.from(goal);
    }

    @Transactional
    public void delete(UUID id) { goals.delete(findOwned(id)); }

    private GoalEntity findOwned(UUID id) {
        return goals.findByIdAndOwner_Id(id, currentUser.id()).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.NOT_FOUND, "Goal not found"));
    }
}
