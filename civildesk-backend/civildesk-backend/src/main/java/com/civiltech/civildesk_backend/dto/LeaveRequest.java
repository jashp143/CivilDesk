package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.Leave;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LeaveRequest {

    @NotNull(message = "Leave type is required")
    private Leave.LeaveType leaveType;

    @NotNull(message = "Start date is required")
    private LocalDate startDate;

    @NotNull(message = "End date is required")
    private LocalDate endDate;

    @NotNull(message = "Is half day flag is required")
    private Boolean isHalfDay;

    private Leave.HalfDayPeriod halfDayPeriod;

    @NotBlank(message = "Contact number is required")
    private String contactNumber;

    private List<Long> handoverEmployeeIds;

    @NotBlank(message = "Reason is required")
    private String reason;

    private String medicalCertificateUrl;
}
