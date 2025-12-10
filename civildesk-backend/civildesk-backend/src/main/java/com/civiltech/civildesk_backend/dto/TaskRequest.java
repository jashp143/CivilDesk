package com.civiltech.civildesk_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TaskRequest {

    @NotEmpty(message = "At least one employee must be selected")
    @NotNull(message = "Employees are required")
    private List<Long> employeeIds;

    @NotNull(message = "Start date is required")
    private LocalDate startDate;

    @NotNull(message = "End date is required")
    private LocalDate endDate;

    @NotBlank(message = "Location is required")
    private String location;

    @NotBlank(message = "Task description is required")
    private String description;

    @NotBlank(message = "Mode of travel is required")
    private String modeOfTravel;
}
