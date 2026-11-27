package com.lifepilot.habit;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HabitRepository extends JpaRepository<HabitEntity, UUID> {
    List<HabitEntity> findAllByOwner_IdOrderByCreatedAtDesc(UUID ownerId);
    Optional<HabitEntity> findByIdAndOwner_Id(UUID id, UUID ownerId);
}
