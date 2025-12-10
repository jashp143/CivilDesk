package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.Task;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TaskResponse {

    private Long id;
    private LocalDate startDate;
    private LocalDate endDate;
    private String location;
    private String description;
    private String modeOfTravel;
    private String modeOfTravelDisplay;
    private Task.TaskStatus status;
    private String statusDisplay;
    private AssignedByInfo assignedBy;
    private LocalDateTime reviewedAt;
    private String reviewNote;
    private List<AssignedEmployeeInfo> assignedEmployees;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AssignedByInfo {
        private Long id;
        private String name;
        private String email;
        private String role;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AssignedEmployeeInfo {
        private Long id;
        private String name;
        private String employeeId;
        private String email;
        private String designation;
        private String department;
    }
}
