package com.lifepilot.habit;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HabitCompletionRepository extends JpaRepository<HabitCompletion, UUID> {
    List<HabitCompletion> findAllByHabit_IdOrderByCompletedOnAsc(UUID habitId);
    List<HabitCompletion> findTop30ByHabit_IdOrderByCompletedOnDesc(UUID habitId);
    Optional<HabitCompletion> findByHabit_IdAndCompletedOn(UUID habitId, LocalDate completedOn);
    long countByHabit_IdAndCompletedOnBetween(UUID habitId, LocalDate start, LocalDate end);
}
