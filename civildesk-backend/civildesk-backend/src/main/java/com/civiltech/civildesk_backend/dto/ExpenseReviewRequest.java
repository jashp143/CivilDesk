package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.Expense;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExpenseReviewRequest {

    @NotNull(message = "Status is required")
    private Expense.ExpenseStatus status;

    private String reviewNote;
}
