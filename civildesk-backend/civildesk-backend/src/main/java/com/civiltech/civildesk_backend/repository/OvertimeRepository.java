package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.Overtime;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface OvertimeRepository extends JpaRepository<Overtime, Long> {

    // Find all overtimes by employee ID
    List<Overtime> findByEmployeeIdAndDeletedFalse(Long employeeId);

    // Find all overtimes by employee ID and status
    List<Overtime> findByEmployeeIdAndStatusAndDeletedFalse(Long employeeId, Overtime.OvertimeStatus status);

    // Find all overtimes by status
    List<Overtime> findByStatusAndDeletedFalse(Overtime.OvertimeStatus status);

    // Find all non-deleted overtimes
    List<Overtime> findByDeletedFalse();

    // Find overtimes by date range
    @Query("SELECT o FROM Overtime o WHERE o.deleted = false AND o.date BETWEEN :startDate AND :endDate")
    List<Overtime> findOvertimesByDateRange(@Param("startDate") LocalDate startDate, 
                                             @Param("endDate") LocalDate endDate);

    // Find overtimes by employee and date range
    @Query("SELECT o FROM Overtime o WHERE o.employee.id = :employeeId AND o.deleted = false AND o.date BETWEEN :startDate AND :endDate")
    List<Overtime> findOvertimesByEmployeeAndDateRange(@Param("employeeId") Long employeeId,
                                                        @Param("startDate") LocalDate startDate,
                                                        @Param("endDate") LocalDate endDate);

    // Find overtimes by department
    @Query("SELECT o FROM Overtime o WHERE o.employee.department = :department AND o.deleted = false")
    List<Overtime> findOvertimesByDepartment(@Param("department") String department);
}
