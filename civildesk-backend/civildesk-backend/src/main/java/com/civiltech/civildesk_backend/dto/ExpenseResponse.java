package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.Expense;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExpenseResponse {

    private Long id;
    private Long employeeId;
    private String employeeName;
    private String employeeEmail;
    private String employeeId_str;
    private String department;
    private String designation;
    private LocalDate expenseDate;
    private Expense.ExpenseCategory category;
    private String categoryDisplay;
    private BigDecimal amount;
    private String description;
    private List<String> receiptUrls;
    private Expense.ExpenseStatus status;
    private String statusDisplay;
    private ReviewerInfo reviewedBy;
    private LocalDateTime reviewedAt;
    private String reviewNote;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ReviewerInfo {
        private Long id;
        private String name;
        private String email;
        private String role;
    }
}
