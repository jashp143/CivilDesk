package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.EmployeeSiteAssignment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface EmployeeSiteAssignmentRepository extends JpaRepository<EmployeeSiteAssignment, Long> {

    // Eager fetch site to avoid N+1 when displaying employee's assigned sites
    @EntityGraph(attributePaths = {"site"})
    List<EmployeeSiteAssignment> findByEmployeeIdAndIsActiveTrue(Long employeeId);

    // Eager fetch employee to avoid N+1 when displaying site's assigned employees
    @EntityGraph(attributePaths = {"employee"})
    List<EmployeeSiteAssignment> findBySiteIdAndIsActiveTrue(Long siteId);

    @Query("SELECT a FROM EmployeeSiteAssignment a WHERE a.employee.id = :employeeId " +
           "AND a.isActive = true AND a.isPrimary = true")
    Optional<EmployeeSiteAssignment> findPrimaryAssignmentByEmployeeId(@Param("employeeId") Long employeeId);

    @Query("SELECT a FROM EmployeeSiteAssignment a WHERE a.employee.id = :employeeId " +
           "AND a.site.id = :siteId AND a.isActive = true")
    Optional<EmployeeSiteAssignment> findByEmployeeIdAndSiteIdAndIsActiveTrue(
            @Param("employeeId") Long employeeId, @Param("siteId") Long siteId);

    @Query("SELECT a FROM EmployeeSiteAssignment a WHERE a.employee.id = :employeeId " +
           "AND a.isActive = true AND " +
           "(a.endDate IS NULL OR a.endDate >= :date) AND " +
           "a.assignmentDate <= :date")
    List<EmployeeSiteAssignment> findActiveAssignmentsByEmployeeIdAndDate(
            @Param("employeeId") Long employeeId, @Param("date") LocalDate date);

    @Query("SELECT COUNT(a) FROM EmployeeSiteAssignment a WHERE a.site.id = :siteId AND a.isActive = true")
    Long countActiveEmployeesBySiteId(@Param("siteId") Long siteId);

    @Query("SELECT a FROM EmployeeSiteAssignment a JOIN FETCH a.employee JOIN FETCH a.site " +
           "WHERE a.site.id = :siteId AND a.isActive = true")
    List<EmployeeSiteAssignment> findBySiteIdWithEmployees(@Param("siteId") Long siteId);

    @Query("SELECT a FROM EmployeeSiteAssignment a JOIN FETCH a.site JOIN FETCH a.employee " +
           "WHERE a.employee.employeeId = :employeeId AND a.isActive = true")
    List<EmployeeSiteAssignment> findByEmployeeCode(@Param("employeeId") String employeeId);
}

