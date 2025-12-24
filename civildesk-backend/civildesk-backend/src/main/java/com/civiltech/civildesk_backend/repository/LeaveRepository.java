package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.Leave;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface LeaveRepository extends JpaRepository<Leave, Long> {

    // Find all leaves by employee ID
    List<Leave> findByEmployeeIdAndDeletedFalse(Long employeeId);

    // Find all leaves by employee ID and status
    List<Leave> findByEmployeeIdAndStatusAndDeletedFalse(Long employeeId, Leave.LeaveStatus status);

    // Find all leaves by status - eager fetch employee to avoid N+1
    @EntityGraph(attributePaths = {"employee"})
    List<Leave> findByStatusAndDeletedFalse(Leave.LeaveStatus status);

    // Find all non-deleted leaves - eager fetch employee
    @EntityGraph(attributePaths = {"employee"})
    List<Leave> findByDeletedFalse();
    
    // Override findById to include employee details
    @EntityGraph(attributePaths = {"employee"})
    @NonNull
    Optional<Leave> findById(@NonNull Long id);

    // Find leaves where employee is assigned responsibilities
    @Query("SELECT l FROM Leave l WHERE l.handoverEmployeeIds LIKE %:employeeId% AND l.deleted = false")
    List<Leave> findLeavesWithHandoverResponsibility(@Param("employeeId") String employeeId);

    // Find leaves by date range
    @Query("SELECT l FROM Leave l WHERE l.deleted = false AND " +
           "((l.startDate BETWEEN :startDate AND :endDate) OR " +
           "(l.endDate BETWEEN :startDate AND :endDate) OR " +
           "(l.startDate <= :startDate AND l.endDate >= :endDate))")
    List<Leave> findLeavesByDateRange(@Param("startDate") LocalDate startDate, 
                                       @Param("endDate") LocalDate endDate);

    // Find leaves by employee and date range
    @Query("SELECT l FROM Leave l WHERE l.employee.id = :employeeId AND l.deleted = false AND " +
           "((l.startDate BETWEEN :startDate AND :endDate) OR " +
           "(l.endDate BETWEEN :startDate AND :endDate) OR " +
           "(l.startDate <= :startDate AND l.endDate >= :endDate))")
    List<Leave> findLeavesByEmployeeAndDateRange(@Param("employeeId") Long employeeId,
                                                   @Param("startDate") LocalDate startDate,
                                                   @Param("endDate") LocalDate endDate);

    // Find all leaves by leave type
    List<Leave> findByLeaveTypeAndDeletedFalse(Leave.LeaveType leaveType);

    // Find leaves by department
    @Query("SELECT l FROM Leave l WHERE l.employee.department = :department AND l.deleted = false")
    List<Leave> findLeavesByDepartment(@Param("department") String department);
    
    // Paginated queries
    @EntityGraph(attributePaths = {"employee"})
    Page<Leave> findByDeletedFalse(Pageable pageable);
    
    @EntityGraph(attributePaths = {"employee"})
    Page<Leave> findByStatusAndDeletedFalse(Leave.LeaveStatus status, Pageable pageable);
    
    @EntityGraph(attributePaths = {"employee"})
    Page<Leave> findByLeaveTypeAndDeletedFalse(Leave.LeaveType leaveType, Pageable pageable);
    
    @Query("SELECT l FROM Leave l WHERE l.employee.department = :department AND l.deleted = false")
    Page<Leave> findLeavesByDepartment(@Param("department") String department, Pageable pageable);
}
