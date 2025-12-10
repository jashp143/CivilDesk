package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.Task;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {

    // Eager fetch assignedBy to avoid N+1 on list queries
    @EntityGraph(attributePaths = {"assignedBy"})
    List<Task> findByDeletedFalseOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = {"assignedBy"})
    List<Task> findByStatusAndDeletedFalse(Task.TaskStatus status);

    @Query("SELECT t FROM Task t LEFT JOIN FETCH t.assignedBy WHERE t.deleted = false AND t.startDate >= :startDate AND t.endDate <= :endDate ORDER BY t.createdAt DESC")
    List<Task> findByDateRange(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);

    @Query("SELECT DISTINCT t FROM Task t LEFT JOIN FETCH t.assignedBy JOIN TaskAssignment ta ON t.id = ta.task.id WHERE ta.employee.id = :employeeId AND t.deleted = false AND ta.deleted = false ORDER BY t.createdAt DESC")
    List<Task> findByEmployeeId(@Param("employeeId") Long employeeId);

    @Query("SELECT DISTINCT t FROM Task t LEFT JOIN FETCH t.assignedBy JOIN TaskAssignment ta ON t.id = ta.task.id WHERE ta.employee.id = :employeeId AND t.status = :status AND t.deleted = false AND ta.deleted = false ORDER BY t.createdAt DESC")
    List<Task> findByEmployeeIdAndStatus(@Param("employeeId") Long employeeId, @Param("status") Task.TaskStatus status);

    @Query("SELECT t FROM Task t LEFT JOIN FETCH t.assignedBy WHERE t.assignedBy.id = :userId AND t.deleted = false ORDER BY t.createdAt DESC")
    List<Task> findByAssignedBy(@Param("userId") Long userId);
    
    // Override findById to eager load assignedBy
    @EntityGraph(attributePaths = {"assignedBy"})
    Optional<Task> findById(Long id);
}
