package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.model.SalarySlip;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SalarySlipRepository extends JpaRepository<SalarySlip, Long> {
    
    @Query("SELECT s FROM SalarySlip s JOIN FETCH s.employee WHERE s.deleted = false AND s.employee = :employee AND s.year = :year AND s.month = :month")
    Optional<SalarySlip> findByEmployeeAndYearAndMonth(@Param("employee") Employee employee, @Param("year") Integer year, @Param("month") Integer month);
    
    @Query("SELECT s FROM SalarySlip s JOIN FETCH s.employee WHERE s.deleted = false AND s.employee.id = :employeeId")
    List<SalarySlip> findByEmployeeId(@Param("employeeId") Long employeeId);
    
    @Query("SELECT s FROM SalarySlip s JOIN FETCH s.employee WHERE s.deleted = false AND s.employee.id = :employeeId ORDER BY s.year DESC, s.month DESC")
    List<SalarySlip> findByEmployeeIdOrderByYearDescMonthDesc(@Param("employeeId") Long employeeId);
    
    @Query("SELECT s FROM SalarySlip s JOIN FETCH s.employee WHERE s.deleted = false AND s.employee.id = :employeeId AND s.year = :year AND s.month = :month")
    Optional<SalarySlip> findSalarySlipByEmployeeAndPeriod(
            @Param("employeeId") Long employeeId,
            @Param("year") Integer year,
            @Param("month") Integer month);
    
    @Query("SELECT s FROM SalarySlip s JOIN FETCH s.employee WHERE s.deleted = false AND s.employee.employeeId = :employeeId ORDER BY s.year DESC, s.month DESC")
    List<SalarySlip> findByEmployeeEmployeeId(@Param("employeeId") String employeeId);
    
    @Query("SELECT s FROM SalarySlip s JOIN FETCH s.employee WHERE s.deleted = false AND s.year = :year AND s.month = :month")
    List<SalarySlip> findByYearAndMonth(@Param("year") Integer year, @Param("month") Integer month);
    
    @Query("SELECT s FROM SalarySlip s JOIN FETCH s.employee WHERE s.deleted = false AND s.status = :status")
    List<SalarySlip> findByStatus(@Param("status") SalarySlip.SalarySlipStatus status);
    
    @Query("SELECT s FROM SalarySlip s JOIN FETCH s.employee WHERE s.id = :id AND s.deleted = false")
    Optional<SalarySlip> findByIdWithEmployee(@Param("id") Long id);
    
    @Query("SELECT DISTINCT s FROM SalarySlip s JOIN FETCH s.employee WHERE s.deleted = false")
    List<SalarySlip> findAllWithEmployee();
    
    @Query("SELECT s FROM SalarySlip s JOIN FETCH s.employee WHERE s.deleted = false ORDER BY s.year DESC, s.month DESC")
    Page<SalarySlip> findAllWithEmployeePaginated(Pageable pageable);
    
    @Query("SELECT s FROM SalarySlip s JOIN FETCH s.employee WHERE s.deleted = false AND s.year = :year AND s.month = :month ORDER BY s.year DESC, s.month DESC")
    Page<SalarySlip> findByYearAndMonthPaginated(@Param("year") Integer year, @Param("month") Integer month, Pageable pageable);
    
    @Query("SELECT s FROM SalarySlip s JOIN FETCH s.employee WHERE s.deleted = false AND s.employee.id = :employeeId AND s.year = :year AND s.month = :month AND s.status = 'FINALIZED'")
    Optional<SalarySlip> findFinalizedByEmployeeAndPeriod(
            @Param("employeeId") Long employeeId,
            @Param("year") Integer year,
            @Param("month") Integer month);
    
    @Query("SELECT s FROM SalarySlip s JOIN FETCH s.employee WHERE s.deleted = false AND s.employee.id = :employeeId AND s.year = :year AND s.month = :month AND s.status = 'DRAFT' ORDER BY s.createdAt DESC")
    List<SalarySlip> findDraftByEmployeeAndPeriod(
            @Param("employeeId") Long employeeId,
            @Param("year") Integer year,
            @Param("month") Integer month);
}

