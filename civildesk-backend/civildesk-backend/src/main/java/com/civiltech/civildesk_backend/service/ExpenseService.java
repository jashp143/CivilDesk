package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.ExpenseRequest;
import com.civiltech.civildesk_backend.dto.ExpenseResponse;
import com.civiltech.civildesk_backend.dto.ExpenseReviewRequest;
import com.civiltech.civildesk_backend.exception.BadRequestException;
import com.civiltech.civildesk_backend.exception.ResourceNotFoundException;
import com.civiltech.civildesk_backend.exception.UnauthorizedException;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.model.Expense;
import com.civiltech.civildesk_backend.model.User;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import com.civiltech.civildesk_backend.repository.ExpenseRepository;
import com.civiltech.civildesk_backend.security.SecurityUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class ExpenseService {

    @Autowired
    private ExpenseRepository expenseRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    // Apply for expense
    @CacheEvict(value = "expenses", allEntries = true)
    public ExpenseResponse applyExpense(ExpenseRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Find employee for current user
        Employee employee = employeeRepository.findByUserIdAndDeletedFalse(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found for current user"));

        // Validate expense date
        if (request.getExpenseDate().isAfter(java.time.LocalDate.now())) {
            throw new BadRequestException("Expense date cannot be in the future");
        }

        // Create expense entity
        Expense expense = new Expense();
        expense.setEmployee(employee);
        expense.setExpenseDate(request.getExpenseDate());
        expense.setCategory(request.getCategory());
        expense.setAmount(request.getAmount());
        expense.setDescription(request.getDescription());
        expense.setStatus(Expense.ExpenseStatus.PENDING);

        // Convert receipt URLs list to comma-separated string
        if (request.getReceiptUrls() != null && !request.getReceiptUrls().isEmpty()) {
            String receiptUrls = String.join(",", request.getReceiptUrls());
            expense.setReceiptUrls(receiptUrls);
        }

        expense = expenseRepository.save(expense);

        return convertToResponse(expense);
    }

    // Update expense (only if status is PENDING)
    @Caching(evict = {
        @CacheEvict(value = "expenses", key = "#expenseId"),
        @CacheEvict(value = "expenses", allEntries = true)
    })
    public ExpenseResponse updateExpense(@NonNull Long expenseId, ExpenseRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        Expense expense = expenseRepository.findById(expenseId)
                .orElseThrow(() -> new ResourceNotFoundException("Expense not found with id: " + expenseId));

        // Check if expense belongs to current user
        if (!expense.getEmployee().getUser().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("You are not authorized to update this expense");
        }

        // Check if expense is in PENDING status
        if (expense.getStatus() != Expense.ExpenseStatus.PENDING) {
            throw new BadRequestException("Cannot update expense that is not in PENDING status");
        }

        // Validate expense date
        if (request.getExpenseDate().isAfter(java.time.LocalDate.now())) {
            throw new BadRequestException("Expense date cannot be in the future");
        }

        // Update expense
        expense.setExpenseDate(request.getExpenseDate());
        expense.setCategory(request.getCategory());
        expense.setAmount(request.getAmount());
        expense.setDescription(request.getDescription());

        // Convert receipt URLs list to comma-separated string
        if (request.getReceiptUrls() != null && !request.getReceiptUrls().isEmpty()) {
            String receiptUrls = String.join(",", request.getReceiptUrls());
            expense.setReceiptUrls(receiptUrls);
        } else {
            expense.setReceiptUrls(null);
        }

        expense = expenseRepository.save(expense);

        return convertToResponse(expense);
    }

    // Delete expense (only if status is PENDING)
    @Caching(evict = {
        @CacheEvict(value = "expenses", key = "#expenseId"),
        @CacheEvict(value = "expenses", allEntries = true)
    })
    public void deleteExpense(@NonNull Long expenseId) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        Expense expense = expenseRepository.findById(expenseId)
                .orElseThrow(() -> new ResourceNotFoundException("Expense not found with id: " + expenseId));

        // Check if expense belongs to current user
        if (!expense.getEmployee().getUser().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("You are not authorized to delete this expense");
        }

        // Check if expense is in PENDING status
        if (expense.getStatus() != Expense.ExpenseStatus.PENDING) {
            throw new BadRequestException("Cannot delete expense that is not in PENDING status");
        }

        // Soft delete
        expense.setDeleted(true);
        expenseRepository.save(expense);
    }

    // Get all expenses for current employee
    @Cacheable(value = "expenses", key = "'my-expenses:' + T(com.civiltech.civildesk_backend.security.SecurityUtils).getCurrentUserId()")
    @Transactional(readOnly = true)
    public List<ExpenseResponse> getMyExpenses() {
        User currentUser = SecurityUtils.getCurrentUser();
        
        Employee employee = employeeRepository.findByUserIdAndDeletedFalse(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found for current user"));

        List<Expense> expenses = expenseRepository.findByEmployeeIdAndDeletedFalse(employee.getId());
        
        return expenses.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get all expenses (Admin/HR only)
    @Cacheable(value = "expenses", key = "'all-expenses'")
    @Transactional(readOnly = true)
    public List<ExpenseResponse> getAllExpenses() {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can view all expenses");
        }

        List<Expense> expenses = expenseRepository.findByDeletedFalse();
        
        return expenses.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get expenses by status (Admin/HR only)
    @Cacheable(value = "expenses", key = "'expenses-status:' + #status")
    @Transactional(readOnly = true)
    public List<ExpenseResponse> getExpensesByStatus(Expense.ExpenseStatus status) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can filter expenses");
        }

        List<Expense> expenses = expenseRepository.findByStatusAndDeletedFalse(status);
        
        return expenses.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get expenses by category (Admin/HR only)
    public List<ExpenseResponse> getExpensesByCategory(Expense.ExpenseCategory category) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can filter expenses");
        }

        List<Expense> expenses = expenseRepository.findByCategoryAndDeletedFalse(category);
        
        return expenses.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get expenses by department (Admin/HR only)
    public List<ExpenseResponse> getExpensesByDepartment(String department) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can filter expenses");
        }

        List<Expense> expenses = expenseRepository.findExpensesByDepartment(department);
        
        return expenses.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get expense by ID
    @Cacheable(value = "expenses", key = "#expenseId")
    @Transactional(readOnly = true)
    public ExpenseResponse getExpenseById(@NonNull Long expenseId) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        Expense expense = expenseRepository.findById(expenseId)
                .orElseThrow(() -> new ResourceNotFoundException("Expense not found with id: " + expenseId));

        // Check authorization
        boolean isOwnExpense = expense.getEmployee().getUser().getId().equals(currentUser.getId());
        boolean isAdminOrHR = currentUser.getRole() == User.Role.ADMIN || 
                              currentUser.getRole() == User.Role.HR_MANAGER;

        if (!isOwnExpense && !isAdminOrHR) {
            throw new UnauthorizedException("You are not authorized to view this expense");
        }

        return convertToResponse(expense);
    }

    // Review expense (Approve/Reject) - Admin/HR only
    @Caching(evict = {
        @CacheEvict(value = "expenses", key = "#expenseId"),
        @CacheEvict(value = "expenses", allEntries = true)
    })
    public ExpenseResponse reviewExpense(@NonNull Long expenseId, ExpenseReviewRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();
        
        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can review expenses");
        }

        Expense expense = expenseRepository.findById(expenseId)
                .orElseThrow(() -> new ResourceNotFoundException("Expense not found with id: " + expenseId));

        // Check if expense is in PENDING status
        if (expense.getStatus() != Expense.ExpenseStatus.PENDING) {
            throw new BadRequestException("Can only review expenses in PENDING status");
        }

        // Validate status
        if (request.getStatus() != Expense.ExpenseStatus.APPROVED && 
            request.getStatus() != Expense.ExpenseStatus.REJECTED) {
            throw new BadRequestException("Status must be either APPROVED or REJECTED");
        }

        // Update expense
        expense.setStatus(request.getStatus());
        expense.setReviewedBy(currentUser);
        expense.setReviewedAt(LocalDateTime.now());
        expense.setReviewNote(request.getReviewNote());

        expense = expenseRepository.save(expense);

        return convertToResponse(expense);
    }

    // Helper method to convert Expense entity to ExpenseResponse
    private ExpenseResponse convertToResponse(Expense expense) {
        ExpenseResponse response = new ExpenseResponse();
        response.setId(expense.getId());
        response.setEmployeeId(expense.getEmployee().getId());
        response.setEmployeeName(expense.getEmployee().getFirstName() + " " + expense.getEmployee().getLastName());
        response.setEmployeeEmail(expense.getEmployee().getEmail());
        response.setEmployeeId_str(expense.getEmployee().getEmployeeId());
        response.setDepartment(expense.getEmployee().getDepartment());
        response.setDesignation(expense.getEmployee().getDesignation());
        response.setExpenseDate(expense.getExpenseDate());
        response.setCategory(expense.getCategory());
        response.setCategoryDisplay(expense.getCategory().getDisplayName());
        response.setAmount(expense.getAmount());
        response.setDescription(expense.getDescription());
        response.setStatus(expense.getStatus());
        response.setStatusDisplay(expense.getStatus().getDisplayName());
        response.setCreatedAt(expense.getCreatedAt());
        response.setUpdatedAt(expense.getUpdatedAt());

        // Convert receipt URLs from comma-separated string to list
        if (expense.getReceiptUrls() != null && !expense.getReceiptUrls().isEmpty()) {
            List<String> receiptUrls = Arrays.asList(expense.getReceiptUrls().split(","));
            response.setReceiptUrls(receiptUrls);
        } else {
            response.setReceiptUrls(new ArrayList<>());
        }

        // Set reviewer info
        if (expense.getReviewedBy() != null) {
            ExpenseResponse.ReviewerInfo reviewerInfo = new ExpenseResponse.ReviewerInfo();
            reviewerInfo.setId(expense.getReviewedBy().getId());
            reviewerInfo.setName(expense.getReviewedBy().getFirstName() + " " + expense.getReviewedBy().getLastName());
            reviewerInfo.setEmail(expense.getReviewedBy().getEmail());
            reviewerInfo.setRole(expense.getReviewedBy().getRole().name());
            response.setReviewedBy(reviewerInfo);
            response.setReviewedAt(expense.getReviewedAt());
            response.setReviewNote(expense.getReviewNote());
        }

        return response;
    }
}
