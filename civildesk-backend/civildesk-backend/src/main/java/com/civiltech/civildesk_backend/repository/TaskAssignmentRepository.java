package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.TaskAssignment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TaskAssignmentRepository extends JpaRepository<TaskAssignment, Long> {

    // Eager fetch employee to avoid N+1 queries when displaying task assignments
    @EntityGraph(attributePaths = {"employee"})
    List<TaskAssignment> findByTaskIdAndDeletedFalse(Long taskId);

    @EntityGraph(attributePaths = {"task", "task.assignedBy"})
    List<TaskAssignment> findByEmployeeIdAndDeletedFalse(Long employeeId);

    @Query("SELECT ta FROM TaskAssignment ta LEFT JOIN FETCH ta.employee WHERE ta.task.id = :taskId AND ta.employee.id = :employeeId AND ta.deleted = false")
    Optional<TaskAssignment> findByTaskIdAndEmployeeId(@Param("taskId") Long taskId, @Param("employeeId") Long employeeId);

    @Query("SELECT ta FROM TaskAssignment ta LEFT JOIN FETCH ta.employee WHERE ta.task.id = :taskId AND ta.deleted = false")
    List<TaskAssignment> findAllByTaskId(@Param("taskId") Long taskId);
    
    // New method with full eager loading for task details view
    @Query("SELECT ta FROM TaskAssignment ta LEFT JOIN FETCH ta.employee LEFT JOIN FETCH ta.task t LEFT JOIN FETCH t.assignedBy WHERE ta.task.id = :taskId AND ta.deleted = false")
    List<TaskAssignment> findAllByTaskIdWithFullDetails(@Param("taskId") Long taskId);
    
    /**
     * Batch query to find all assignments for multiple tasks.
     * Used to avoid N+1 queries when converting multiple tasks to responses.
     * 
     * @param taskIds List of task IDs
     * @return List of task assignments with employees eagerly loaded
     */
    @EntityGraph(attributePaths = {"employee"})
    @Query("SELECT ta FROM TaskAssignment ta WHERE ta.task.id IN :taskIds AND ta.deleted = false")
    List<TaskAssignment> findByTaskIds(@Param("taskIds") List<Long> taskIds);
}
