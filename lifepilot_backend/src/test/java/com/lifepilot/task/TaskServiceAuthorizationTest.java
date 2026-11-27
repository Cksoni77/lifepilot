package com.lifepilot.task;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.lifepilot.goal.GoalRepository;
import com.lifepilot.security.CurrentUser;
import com.lifepilot.user.AppUserRepository;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.server.ResponseStatusException;

class TaskServiceAuthorizationTest {
    @Mock private TaskRepository tasks;
    @Mock private AppUserRepository users;
    @Mock private GoalRepository goals;

    private AutoCloseable mocks;
    private UUID authenticatedUser;
    private TaskService service;

    @BeforeEach
    void setUp() {
        mocks = MockitoAnnotations.openMocks(this);
        authenticatedUser = UUID.randomUUID();
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(authenticatedUser, null, java.util.List.of()));
        service = new TaskService(tasks, users, goals, new CurrentUser());
    }

    @AfterEach
    void tearDown() throws Exception {
        SecurityContextHolder.clearContext();
        mocks.close();
    }

    @Test
    void taskLookupUsesAuthenticatedUserIdAndHidesOtherUsersTasks() {
        UUID taskId = UUID.randomUUID();
        when(tasks.findByIdAndOwner_Id(taskId, authenticatedUser)).thenReturn(Optional.empty());

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class, () -> service.get(taskId));

        assertEquals(HttpStatus.NOT_FOUND, exception.getStatusCode());
        verify(tasks).findByIdAndOwner_Id(taskId, authenticatedUser);
    }
}
