package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.model.SalarySlip;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SalarySlipRepository extends JpaRepository<SalarySlip, Long> {
    
    Optional<SalarySlip> findByEmployeeAndYearAndMonth(Employee employee, Integer year, Integer month);
    
    List<SalarySlip> findByEmployeeId(Long employeeId);
    
    List<SalarySlip> findByEmployeeIdOrderByYearDescMonthDesc(Long employeeId);
    
    @Query("SELECT s FROM SalarySlip s WHERE s.employee.id = :employeeId AND s.year = :year AND s.month = :month")
    Optional<SalarySlip> findSalarySlipByEmployeeAndPeriod(
            @Param("employeeId") Long employeeId,
            @Param("year") Integer year,
            @Param("month") Integer month);
    
    @Query("SELECT s FROM SalarySlip s WHERE s.employee.employeeId = :employeeId ORDER BY s.year DESC, s.month DESC")
    List<SalarySlip> findByEmployeeEmployeeId(@Param("employeeId") String employeeId);
    
    @Query("SELECT s FROM SalarySlip s WHERE s.year = :year AND s.month = :month")
    List<SalarySlip> findByYearAndMonth(@Param("year") Integer year, @Param("month") Integer month);
    
    @Query("SELECT s FROM SalarySlip s WHERE s.status = :status")
    List<SalarySlip> findByStatus(@Param("status") SalarySlip.SalarySlipStatus status);
}

