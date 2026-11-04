package com.lifepilot.goal;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalRepository extends JpaRepository<GoalEntity, UUID> {
    List<GoalEntity> findAllByOwner_IdOrderByCreatedAtDesc(UUID ownerId);
    Optional<GoalEntity> findByIdAndOwner_Id(UUID id, UUID ownerId);
}
