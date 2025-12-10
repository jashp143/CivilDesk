package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.EmployeeSiteAssignment;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeSiteAssignmentResponse {

    private Long id;
    
    private Long employeeId;
    private String employeeCode;
    private String employeeName;
    
    private Long siteId;
    private String siteCode;
    private String siteName;
    
    private LocalDate assignmentDate;
    private LocalDate endDate;
    private Boolean isPrimary;
    private Boolean isActive;
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static EmployeeSiteAssignmentResponse fromEntity(EmployeeSiteAssignment assignment) {
        EmployeeSiteAssignmentResponse response = new EmployeeSiteAssignmentResponse();
        response.setId(assignment.getId());
        
        if (assignment.getEmployee() != null) {
            response.setEmployeeId(assignment.getEmployee().getId());
            response.setEmployeeCode(assignment.getEmployee().getEmployeeId());
            response.setEmployeeName(assignment.getEmployee().getFirstName() + " " + assignment.getEmployee().getLastName());
        }
        
        if (assignment.getSite() != null) {
            response.setSiteId(assignment.getSite().getId());
            response.setSiteCode(assignment.getSite().getSiteCode());
            response.setSiteName(assignment.getSite().getSiteName());
        }
        
        response.setAssignmentDate(assignment.getAssignmentDate());
        response.setEndDate(assignment.getEndDate());
        response.setIsPrimary(assignment.getIsPrimary());
        response.setIsActive(assignment.getIsActive());
        response.setCreatedAt(assignment.getCreatedAt());
        response.setUpdatedAt(assignment.getUpdatedAt());
        
        return response;
    }
}

