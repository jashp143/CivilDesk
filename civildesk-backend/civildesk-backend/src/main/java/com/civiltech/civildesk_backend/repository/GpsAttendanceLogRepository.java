package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.GpsAttendanceLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface GpsAttendanceLogRepository extends JpaRepository<GpsAttendanceLog, Long> {

    @Query("SELECT g FROM GpsAttendanceLog g WHERE g.employee.employeeId = :employeeId " +
           "AND DATE(g.punchTime) = :date ORDER BY g.punchTime ASC")
    List<GpsAttendanceLog> findByEmployeeIdAndDate(
            @Param("employeeId") String employeeId, @Param("date") LocalDate date);

    @Query("SELECT g FROM GpsAttendanceLog g WHERE g.employee.employeeId = :employeeId " +
           "AND g.punchTime BETWEEN :startDateTime AND :endDateTime ORDER BY g.punchTime ASC")
    List<GpsAttendanceLog> findByEmployeeIdAndDateRange(
            @Param("employeeId") String employeeId,
            @Param("startDateTime") LocalDateTime startDateTime,
            @Param("endDateTime") LocalDateTime endDateTime);

    @Query("SELECT g FROM GpsAttendanceLog g WHERE g.site.id = :siteId " +
           "AND DATE(g.punchTime) = :date ORDER BY g.punchTime DESC")
    List<GpsAttendanceLog> findBySiteIdAndDate(
            @Param("siteId") Long siteId, @Param("date") LocalDate date);

    @Query("SELECT g FROM GpsAttendanceLog g WHERE DATE(g.punchTime) = :date ORDER BY g.punchTime DESC")
    List<GpsAttendanceLog> findByDate(@Param("date") LocalDate date);

    @Query("SELECT g FROM GpsAttendanceLog g WHERE g.punchTime BETWEEN :startDateTime AND :endDateTime " +
           "ORDER BY g.punchTime DESC")
    Page<GpsAttendanceLog> findByDateRange(
            @Param("startDateTime") LocalDateTime startDateTime,
            @Param("endDateTime") LocalDateTime endDateTime,
            Pageable pageable);

    @Query("SELECT g FROM GpsAttendanceLog g WHERE g.site.id = :siteId " +
           "AND g.punchTime BETWEEN :startDateTime AND :endDateTime ORDER BY g.punchTime DESC")
    List<GpsAttendanceLog> findBySiteIdAndDateRange(
            @Param("siteId") Long siteId,
            @Param("startDateTime") LocalDateTime startDateTime,
            @Param("endDateTime") LocalDateTime endDateTime);

    @Query("SELECT g FROM GpsAttendanceLog g WHERE g.employee.employeeId = :employeeId " +
           "AND DATE(g.punchTime) = :date AND g.punchType = :punchType")
    List<GpsAttendanceLog> findByEmployeeIdAndDateAndPunchType(
            @Param("employeeId") String employeeId,
            @Param("date") LocalDate date,
            @Param("punchType") GpsAttendanceLog.PunchType punchType);

    @Query("SELECT g FROM GpsAttendanceLog g WHERE g.syncStatus = 'PENDING'")
    List<GpsAttendanceLog> findPendingSyncLogs();

    // For map dashboard - get all punches with location for a date
    @Query("SELECT g FROM GpsAttendanceLog g JOIN FETCH g.employee JOIN FETCH g.site " +
           "WHERE DATE(g.punchTime) = :date ORDER BY g.punchTime DESC")
    List<GpsAttendanceLog> findAllPunchesForDateWithDetails(@Param("date") LocalDate date);

    // For map dashboard - get all punches within date range
    @Query("SELECT g FROM GpsAttendanceLog g JOIN FETCH g.employee " +
           "WHERE g.punchTime BETWEEN :startDateTime AND :endDateTime " +
           "ORDER BY g.punchTime DESC")
    List<GpsAttendanceLog> findAllPunchesForDateRangeWithDetails(
            @Param("startDateTime") LocalDateTime startDateTime,
            @Param("endDateTime") LocalDateTime endDateTime);

    // Count punches by type for a date
    @Query("SELECT g.punchType, COUNT(g) FROM GpsAttendanceLog g " +
           "WHERE DATE(g.punchTime) = :date GROUP BY g.punchType")
    List<Object[]> countPunchesByTypeForDate(@Param("date") LocalDate date);
}

