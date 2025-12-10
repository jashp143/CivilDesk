package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.Employee;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeResponse {

    private Long id;

    private String employeeId;

    private Long userId;

    // Personal Information
    private String firstName;

    private String lastName;

    private String middleName;

    private LocalDate dateOfBirth;

    private Employee.Gender gender;

    private Employee.MaritalStatus maritalStatus;

    private String bloodGroup;

    private String profilePhotoUrl;

    // Contact Information
    private String email;

    private String phoneNumber;

    private String alternatePhoneNumber;

    private String addressLine1;

    private String addressLine2;

    private String city;

    private String state;

    private String pincode;

    private String country;

    // Identification Documents
    private String aadharNumber;

    private String panNumber;

    private String uanNumber;

    private String esicNumber;

    // Work Information
    private String department;

    private String designation;

    private LocalDate joiningDate;

    private Employee.EmploymentType employmentType;

    private Long reportingManagerId;

    private String reportingManagerName;

    private Employee.EmploymentStatus employmentStatus;

    private String workLocation;

    // Salary Information
    private Double basicSalary;

    private Double houseRentAllowance;

    private Double conveyance;

    private Double uniformAndSafety;

    private Double bonus;

    private Double foodAllowance;

    private Double otherAllowance;

    private Double overtimeRate;

    private Double epfEmployee; // Percentage

    private Double epfEmployer; // Percentage

    private Double totalSalary;

    // Deduction Information
    private Double esic; // Percentage

    private Double professionalTax;

    // Bank Information
    private String bankName;

    private String bankAccountNumber;

    private String ifscCode;

    private String bankBranch;

    // Emergency Contact
    private String emergencyContactName;

    private String emergencyContactPhone;

    private String emergencyContactRelation;

    // Documents
    private String aadharDocumentUrl;

    private String panDocumentUrl;

    private String resumeUrl;

    private String offerLetterUrl;

    private String appointmentLetterUrl;

    private String otherDocumentsUrl;

    // Additional Information
    private String notes;

    private Boolean isActive;

    // Attendance Method
    private Employee.AttendanceMethod attendanceMethod;

    // Assigned Sites (for GPS-based attendance)
    private java.util.List<SiteResponse> assignedSites;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}

