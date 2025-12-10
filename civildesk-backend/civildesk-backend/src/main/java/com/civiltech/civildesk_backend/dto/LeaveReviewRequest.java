package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.Leave;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LeaveReviewRequest {

    @NotNull(message = "Status is required")
    private Leave.LeaveStatus status;

    private String reviewNote;
}
