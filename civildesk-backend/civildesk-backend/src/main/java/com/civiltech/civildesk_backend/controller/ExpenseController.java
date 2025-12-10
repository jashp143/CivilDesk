package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.annotation.RequiresRole;
import com.civiltech.civildesk_backend.dto.ApiResponse;
import com.civiltech.civildesk_backend.dto.ExpenseRequest;
import com.civiltech.civildesk_backend.dto.ExpenseResponse;
import com.civiltech.civildesk_backend.dto.ExpenseReviewRequest;
import com.civiltech.civildesk_backend.model.Expense;
import com.civiltech.civildesk_backend.service.ExpenseService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/expenses")
@CrossOrigin(origins = "*")
public class ExpenseController {

    @Autowired
    private ExpenseService expenseService;

    // Apply for expense
    @PostMapping
    public ResponseEntity<ApiResponse<ExpenseResponse>> applyExpense(@Valid @RequestBody ExpenseRequest request) {
        ExpenseResponse response = expenseService.applyExpense(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Expense application submitted successfully", response));
    }

    // Update expense
    @PutMapping("/{expenseId}")
    public ResponseEntity<ApiResponse<ExpenseResponse>> updateExpense(
            @PathVariable Long expenseId,
            @Valid @RequestBody ExpenseRequest request) {
        ExpenseResponse response = expenseService.updateExpense(expenseId, request);
        return ResponseEntity.ok(ApiResponse.success("Expense updated successfully", response));
    }

    // Delete expense
    @DeleteMapping("/{expenseId}")
    public ResponseEntity<ApiResponse<Void>> deleteExpense(@PathVariable Long expenseId) {
        expenseService.deleteExpense(expenseId);
        return ResponseEntity.ok(ApiResponse.success("Expense deleted successfully", null));
    }

    // Get my expenses (current employee)
    @GetMapping("/my-expenses")
    public ResponseEntity<ApiResponse<List<ExpenseResponse>>> getMyExpenses() {
        List<ExpenseResponse> expenses = expenseService.getMyExpenses();
        return ResponseEntity.ok(ApiResponse.success("Expenses fetched successfully", expenses));
    }

    // Get all expenses (Admin/HR only)
    @GetMapping
    @RequiresRole({"ADMIN", "HR_MANAGER"})
    public ResponseEntity<ApiResponse<List<ExpenseResponse>>> getAllExpenses(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String department) {
        
        List<ExpenseResponse> expenses;

        if (status != null && !status.isEmpty()) {
            try {
                Expense.ExpenseStatus expenseStatus = Expense.ExpenseStatus.valueOf(status.toUpperCase());
                expenses = expenseService.getExpensesByStatus(expenseStatus);
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Invalid status value", 400));
            }
        } else if (category != null && !category.isEmpty()) {
            try {
                Expense.ExpenseCategory expenseCategory = Expense.ExpenseCategory.valueOf(category.toUpperCase());
                expenses = expenseService.getExpensesByCategory(expenseCategory);
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Invalid category value", 400));
            }
        } else if (department != null && !department.isEmpty()) {
            expenses = expenseService.getExpensesByDepartment(department);
        } else {
            expenses = expenseService.getAllExpenses();
        }

        return ResponseEntity.ok(ApiResponse.success("Expenses fetched successfully", expenses));
    }

    // Get expense by ID
    @GetMapping("/{expenseId}")
    public ResponseEntity<ApiResponse<ExpenseResponse>> getExpenseById(@PathVariable Long expenseId) {
        ExpenseResponse expense = expenseService.getExpenseById(expenseId);
        return ResponseEntity.ok(ApiResponse.success("Expense fetched successfully", expense));
    }

    // Review expense (Approve/Reject) - Admin/HR only
    @PutMapping("/{expenseId}/review")
    @RequiresRole({"ADMIN", "HR_MANAGER"})
    public ResponseEntity<ApiResponse<ExpenseResponse>> reviewExpense(
            @PathVariable Long expenseId,
            @Valid @RequestBody ExpenseReviewRequest request) {
        ExpenseResponse response = expenseService.reviewExpense(expenseId, request);
        return ResponseEntity.ok(ApiResponse.success("Expense reviewed successfully", response));
    }

    // Get all expense categories
    @GetMapping("/categories")
    public ResponseEntity<ApiResponse<List<String>>> getExpenseCategories() {
        List<String> categories = List.of(
                "TRAVEL",
                "MEALS",
                "ACCOMMODATION",
                "SUPPLIES",
                "EQUIPMENT",
                "COMMUNICATION",
                "TRANSPORTATION",
                "ENTERTAINMENT",
                "TRAINING",
                "OTHER"
        );
        return ResponseEntity.ok(ApiResponse.success("Expense categories fetched successfully", categories));
    }

    // Get all expense statuses
    @GetMapping("/statuses")
    public ResponseEntity<ApiResponse<List<String>>> getExpenseStatuses() {
        List<String> statuses = List.of(
                "PENDING",
                "APPROVED",
                "REJECTED"
        );
        return ResponseEntity.ok(ApiResponse.success("Expense statuses fetched successfully", statuses));
    }
}
