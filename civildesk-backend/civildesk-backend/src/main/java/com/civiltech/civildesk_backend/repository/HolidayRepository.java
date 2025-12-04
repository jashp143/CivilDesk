package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.Holiday;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface HolidayRepository extends JpaRepository<Holiday, Long> {
    
    // Find by date
    Optional<Holiday> findByDateAndDeletedFalse(LocalDate date);
    
    // Check if holiday exists for date
    boolean existsByDateAndDeletedFalse(LocalDate date);
    
    // Find active holidays
    List<Holiday> findByIsActiveTrueAndDeletedFalseOrderByDateAsc();
    
    // Find holidays in date range
    @Query("SELECT h FROM Holiday h WHERE h.deleted = false AND h.isActive = true AND h.date BETWEEN :startDate AND :endDate ORDER BY h.date ASC")
    List<Holiday> findActiveHolidaysInRange(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    // Find all holidays (including inactive) in date range
    @Query("SELECT h FROM Holiday h WHERE h.deleted = false AND h.date BETWEEN :startDate AND :endDate ORDER BY h.date ASC")
    List<Holiday> findAllHolidaysInRange(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    // Find upcoming holidays
    @Query("SELECT h FROM Holiday h WHERE h.deleted = false AND h.isActive = true AND h.date >= :fromDate ORDER BY h.date ASC")
    List<Holiday> findUpcomingHolidays(@Param("fromDate") LocalDate fromDate);
    
    // Count active holidays
    long countByIsActiveTrueAndDeletedFalse();
}

