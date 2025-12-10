package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.Expense;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface ExpenseRepository extends JpaRepository<Expense, Long> {

    // Find all expenses by employee ID
    List<Expense> findByEmployeeIdAndDeletedFalse(Long employeeId);

    // Find all expenses by employee ID and status
    List<Expense> findByEmployeeIdAndStatusAndDeletedFalse(Long employeeId, Expense.ExpenseStatus status);

    // Find all expenses by status
    List<Expense> findByStatusAndDeletedFalse(Expense.ExpenseStatus status);

    // Find all non-deleted expenses
    List<Expense> findByDeletedFalse();

    // Find expenses by date range
    @Query("SELECT e FROM Expense e WHERE e.deleted = false AND " +
           "e.expenseDate BETWEEN :startDate AND :endDate")
    List<Expense> findExpensesByDateRange(@Param("startDate") LocalDate startDate, 
                                          @Param("endDate") LocalDate endDate);

    // Find expenses by employee and date range
    @Query("SELECT e FROM Expense e WHERE e.employee.id = :employeeId AND e.deleted = false AND " +
           "e.expenseDate BETWEEN :startDate AND :endDate")
    List<Expense> findExpensesByEmployeeAndDateRange(@Param("employeeId") Long employeeId,
                                                       @Param("startDate") LocalDate startDate,
                                                       @Param("endDate") LocalDate endDate);

    // Find all expenses by category
    List<Expense> findByCategoryAndDeletedFalse(Expense.ExpenseCategory category);

    // Find expenses by department
    @Query("SELECT e FROM Expense e WHERE e.employee.department = :department AND e.deleted = false")
    List<Expense> findExpensesByDepartment(@Param("department") String department);
}
