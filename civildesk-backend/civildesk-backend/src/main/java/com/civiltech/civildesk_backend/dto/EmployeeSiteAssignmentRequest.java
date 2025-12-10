package com.civiltech.civildesk_backend.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeSiteAssignmentRequest {

    @NotNull(message = "Employee ID is required")
    private Long employeeId;

    @NotNull(message = "Site ID is required")
    private Long siteId;

    private LocalDate assignmentDate;
    private LocalDate endDate;
    private Boolean isPrimary = false;
    private Boolean isActive = true;

    // For bulk assignment
    private List<Long> employeeIds;
    private List<Long> siteIds;
}

