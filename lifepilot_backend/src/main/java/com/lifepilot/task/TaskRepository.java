package com.lifepilot.task;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TaskRepository extends JpaRepository<TaskEntity, UUID> {
    List<TaskEntity> findAllByOwner_IdOrderByCreatedAtDesc(UUID ownerId);
    Optional<TaskEntity> findByIdAndOwner_Id(UUID id, UUID ownerId);
}
