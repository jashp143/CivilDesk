package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.Employee;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeRequest {

    // Employee ID (optional, will be auto-generated if not provided)
    private String employeeId;

    // Personal Information
    @NotBlank(message = "First name is required")
    private String firstName;

    @NotBlank(message = "Last name is required")
    private String lastName;

    private String middleName;

    private LocalDate dateOfBirth;

    private Employee.Gender gender;

    private Employee.MaritalStatus maritalStatus;

    private String bloodGroup;

    // Contact Information
    @NotBlank(message = "Email is required")
    @Email(message = "Email should be valid")
    private String email;

    @NotBlank(message = "Phone number is required")
    @Pattern(regexp = "^[6-9]\\d{9}$", message = "Invalid phone number")
    private String phoneNumber;

    private String alternatePhoneNumber;

    private String addressLine1;

    private String addressLine2;

    private String city;

    private String state;

    @Pattern(regexp = "^\\d{6}$", message = "Pincode must be exactly 6 digits")
    private String pincode;

    private String country = "India";

    // Identification Documents
    @NotBlank(message = "Aadhar number is required")
    @Pattern(regexp = "^\\d{12}$", message = "Aadhar must be exactly 12 digits")
    private String aadharNumber;

    @NotBlank(message = "PAN number is required")
    @Pattern(regexp = "^[A-Z]{5}[0-9]{4}[A-Z]{1}$", message = "Invalid PAN format")
    private String panNumber;

    private String uanNumber;

    private String esicNumber;

    // Work Information
    private String department;

    private String designation;

    private LocalDate joiningDate;

    private Employee.EmploymentType employmentType;

    private Long reportingManagerId;

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

    // Deduction Information
    private Double esic; // Percentage

    private Double professionalTax;

    // Bank Information
    private String bankName;

    private String bankAccountNumber;

    @Pattern(regexp = "^[A-Z]{4}0[A-Z0-9]{6}$", message = "Invalid IFSC code")
    private String ifscCode;

    private String bankBranch;

    // Emergency Contact
    private String emergencyContactName;

    @Pattern(regexp = "^[6-9]\\d{9}$", message = "Invalid phone number")
    private String emergencyContactPhone;

    private String emergencyContactRelation;

    // Documents (URLs)
    private String profilePhotoUrl;

    private String aadharDocumentUrl;

    private String panDocumentUrl;

    private String resumeUrl;

    private String offerLetterUrl;

    private String appointmentLetterUrl;

    private String otherDocumentsUrl;

    // Additional Information
    private String notes;

    private Boolean isActive;

    // User relationship (for creating employee with user)
    private Long userId;

    // Attendance Method - determines how employee marks attendance
    private com.civiltech.civildesk_backend.model.Employee.AttendanceMethod attendanceMethod;

    // Site assignments for GPS-based attendance
    private java.util.List<Long> assignedSiteIds;
}

