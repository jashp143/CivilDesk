package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.Attendance;
import com.civiltech.civildesk_backend.model.Employee;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface AttendanceRepository extends JpaRepository<Attendance, Long> {
    
    Optional<Attendance> findByEmployeeAndDate(Employee employee, LocalDate date);
    
    List<Attendance> findByEmployeeId(Long employeeId);
    
    List<Attendance> findByEmployeeIdAndDateBetween(Long employeeId, LocalDate startDate, LocalDate endDate);
    
    @Query("SELECT a FROM Attendance a WHERE a.employee.id = :employeeId AND a.date = :date")
    Optional<Attendance> findTodayAttendance(@Param("employeeId") Long employeeId, @Param("date") LocalDate date);
    
    @Query("SELECT a FROM Attendance a WHERE a.date = :date")
    List<Attendance> findAllByDate(@Param("date") LocalDate date);
    
    @Query("SELECT COUNT(a) FROM Attendance a WHERE a.employee.id = :employeeId AND a.status = 'PRESENT' AND a.date BETWEEN :startDate AND :endDate")
    Long countPresentDays(@Param("employeeId") Long employeeId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    @Query("SELECT a FROM Attendance a WHERE a.employee.employeeId = :employeeId AND a.date BETWEEN :startDate AND :endDate ORDER BY a.date ASC")
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
}

