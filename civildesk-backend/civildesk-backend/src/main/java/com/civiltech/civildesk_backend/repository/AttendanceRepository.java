package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.Attendance;
import com.civiltech.civildesk_backend.model.Employee;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface AttendanceRepository extends JpaRepository<Attendance, Long> {
    
    @EntityGraph(attributePaths = {"employee"})
    Optional<Attendance> findByEmployeeAndDate(Employee employee, LocalDate date);
    
    List<Attendance> findByEmployeeId(Long employeeId);
    
    @EntityGraph(attributePaths = {"employee"})
    List<Attendance> findByEmployeeIdAndDateBetween(Long employeeId, LocalDate startDate, LocalDate endDate);
    
    @EntityGraph(attributePaths = {"employee"})
    Page<Attendance> findByEmployeeIdAndDateBetween(Long employeeId, LocalDate startDate, LocalDate endDate, Pageable pageable);
    
    @Query("SELECT a FROM Attendance a WHERE a.employee.id = :employeeId AND a.date = :date")
    Optional<Attendance> findTodayAttendance(@Param("employeeId") Long employeeId, @Param("date") LocalDate date);
    
    // Eager fetch employee for dashboard/reports that show attendance with employee info
    @Query("SELECT a FROM Attendance a LEFT JOIN FETCH a.employee WHERE a.date = :date")
    List<Attendance> findAllByDate(@Param("date") LocalDate date);
    
    @Query("SELECT a FROM Attendance a LEFT JOIN FETCH a.employee e WHERE a.date = :date ORDER BY e.employeeId ASC")
    Page<Attendance> findAllByDate(@Param("date") LocalDate date, Pageable pageable);
    
    // New optimized query for admin attendance list view
    @Query("SELECT a FROM Attendance a LEFT JOIN FETCH a.employee e WHERE a.date BETWEEN :startDate AND :endDate ORDER BY a.date DESC, e.firstName ASC")
    List<Attendance> findAllByDateRangeWithEmployee(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    @Query("SELECT COUNT(a) FROM Attendance a WHERE a.employee.id = :employeeId AND a.status = 'PRESENT' AND a.date BETWEEN :startDate AND :endDate")
    Long countPresentDays(@Param("employeeId") Long employeeId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    @Query("SELECT a FROM Attendance a LEFT JOIN FETCH a.employee WHERE a.employee.employeeId = :employeeId AND a.date BETWEEN :startDate AND :endDate ORDER BY a.date ASC")
    List<Attendance> findEmployeeAttendanceForAnalytics(@Param("employeeId") String employeeId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    @Query("SELECT COALESCE(SUM(a.workingHours), 0.0) FROM Attendance a WHERE a.employee.employeeId = :employeeId AND a.date BETWEEN :startDate AND :endDate")
    Double sumWorkingHours(@Param("employeeId") String employeeId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    @Query("SELECT COALESCE(SUM(a.overtimeHours), 0.0) FROM Attendance a WHERE a.employee.employeeId = :employeeId AND a.date BETWEEN :startDate AND :endDate")
    Double sumOvertimeHours(@Param("employeeId") String employeeId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    @Query("SELECT COUNT(a) FROM Attendance a WHERE a.employee.employeeId = :employeeId AND a.status = 'PRESENT' AND a.date BETWEEN :startDate AND :endDate")
    Long countPresentDaysByEmployeeId(@Param("employeeId") String employeeId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    @Query("SELECT COUNT(a) FROM Attendance a WHERE a.employee.employeeId = :employeeId AND a.status = 'ABSENT' AND a.date BETWEEN :startDate AND :endDate")
    Long countAbsentDays(@Param("employeeId") String employeeId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    @Query("SELECT COUNT(a) FROM Attendance a WHERE a.employee.employeeId = :employeeId AND a.status = 'LATE' AND a.date BETWEEN :startDate AND :endDate")
    Long countLateDays(@Param("employeeId") String employeeId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    /**
     * Batch query to find existing attendances for multiple employees on a specific date.
     * Used for bulk operations to avoid N+1 queries.
     * 
     * @param employeeIds List of employee IDs
     * @param date The date to check
     * @return List of existing attendances
     */
    @Query("SELECT a FROM Attendance a WHERE a.employee.id IN :employeeIds AND a.date = :date AND a.deleted = false")
    List<Attendance> findByEmployeeIdsAndDate(@Param("employeeIds") List<Long> employeeIds, @Param("date") LocalDate date);
    
    // Count attendance by status for a specific date
    @Query("SELECT COUNT(a) FROM Attendance a WHERE a.date = :date AND a.status = 'PRESENT' AND a.deleted = false")
    Long countPresentByDate(@Param("date") LocalDate date);
    
    @Query("SELECT COUNT(a) FROM Attendance a WHERE a.date = :date AND a.status = 'ABSENT' AND a.deleted = false")
    Long countAbsentByDate(@Param("date") LocalDate date);
    
    @Query("SELECT COUNT(DISTINCT a.employee.id) FROM Attendance a WHERE a.date = :date AND a.deleted = false")
    Long countEmployeesWithAttendanceByDate(@Param("date") LocalDate date);
}

