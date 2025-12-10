package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.Overtime;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OvertimeReviewRequest {

    @NotNull(message = "Status is required")
    private Overtime.OvertimeStatus status;

    private String reviewNote;
}
