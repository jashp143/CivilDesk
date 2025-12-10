package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.Task;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TaskReviewRequest {

    @NotNull(message = "Status is required")
    private Task.TaskStatus status;

    private String reviewNote;
}
