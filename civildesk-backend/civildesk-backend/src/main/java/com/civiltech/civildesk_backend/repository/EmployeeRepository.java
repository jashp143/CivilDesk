package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.Employee;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EmployeeRepository extends JpaRepository<Employee, Long> {
    
    // Find by employee ID
    Optional<Employee> findByEmployeeIdAndDeletedFalse(String employeeId);
    
    // Find by email
    Optional<Employee> findByEmailAndDeletedFalse(String email);
    
    // Check existence
    boolean existsByEmailAndDeletedFalse(String email);
    boolean existsByAadharNumberAndDeletedFalse(String aadharNumber);
    boolean existsByPanNumberAndDeletedFalse(String panNumber);
    boolean existsByEmployeeIdAndDeletedFalse(String employeeId);
    
    // Check existence excluding current employee (for updates)
    boolean existsByEmailAndDeletedFalseAndIdNot(String email, Long id);
    boolean existsByAadharNumberAndDeletedFalseAndIdNot(String aadharNumber, Long id);
    boolean existsByPanNumberAndDeletedFalseAndIdNot(String panNumber, Long id);
    boolean existsByEmployeeIdAndDeletedFalseAndIdNot(String employeeId, Long id);
    
    // Find by user ID
    Optional<Employee> findByUserIdAndDeletedFalse(Long userId);
    
    // Search and filter
    @Query("SELECT e FROM Employee e WHERE e.deleted = false AND " +
           "(LOWER(e.firstName) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(e.lastName) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(e.employeeId) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(e.email) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(e.department) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(e.designation) LIKE LOWER(CONCAT('%', :search, '%')))")
    Page<Employee> searchEmployees(@Param("search") String search, Pageable pageable);
    
    // Find by department
    Page<Employee> findByDepartmentAndDeletedFalse(String department, Pageable pageable);
    
    // Find by designation
    Page<Employee> findByDesignationAndDeletedFalse(String designation, Pageable pageable);
    
    // Find by employment status
    Page<Employee> findByEmploymentStatusAndDeletedFalse(Employee.EmploymentStatus status, Pageable pageable);
    
    // Find by employment type
    Page<Employee> findByEmploymentTypeAndDeletedFalse(Employee.EmploymentType type, Pageable pageable);
    
    // Combined search with filters
    @Query("SELECT e FROM Employee e WHERE e.deleted = false " +
           "AND (:search IS NULL OR :search = '' OR " +
           "LOWER(e.firstName) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(e.lastName) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(e.employeeId) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(e.email) LIKE LOWER(CONCAT('%', :search, '%'))) " +
           "AND (:department IS NULL OR :department = '' OR LOWER(e.department) = LOWER(:department)) " +
           "AND (:designation IS NULL OR :designation = '' OR LOWER(e.designation) = LOWER(:designation)) " +
           "AND (:status IS NULL OR e.employmentStatus = :status) " +
           "AND (:type IS NULL OR e.employmentType = :type)")
    Page<Employee> findWithFilters(
            @Param("search") String search,
            @Param("department") String department,
            @Param("designation") String designation,
            @Param("status") Employee.EmploymentStatus status,
            @Param("type") Employee.EmploymentType type,
            Pageable pageable
    );
    
    // Count active employees
    long countByEmploymentStatusAndDeletedFalse(Employee.EmploymentStatus status);
    
    // Get all active employees
    List<Employee> findByEmploymentStatusAndDeletedFalse(Employee.EmploymentStatus status);
}

