package com.civiltech.civildesk_backend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Entity
@Table(name = "employees", uniqueConstraints = {
    @UniqueConstraint(columnNames = "email"),
    @UniqueConstraint(columnNames = "aadhar_number"),
    @UniqueConstraint(columnNames = "pan_number"),
    @UniqueConstraint(columnNames = "employee_id")
})
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@AllArgsConstructor
public class Employee extends BaseEntity {

    // Employee ID
    @NotBlank(message = "Employee ID is required")
    @Column(name = "employee_id", nullable = false, unique = true)
    private String employeeId;

    // User relationship (One-to-One)
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // Personal Information
    @NotBlank(message = "First name is required")
    @Column(name = "first_name", nullable = false)
    private String firstName;

    @NotBlank(message = "Last name is required")
    @Column(name = "last_name", nullable = false)
    private String lastName;

    @Column(name = "middle_name")
    private String middleName;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    @Enumerated(EnumType.STRING)
    @Column(name = "gender")
    private Gender gender;

    @Enumerated(EnumType.STRING)
    @Column(name = "marital_status")
    private MaritalStatus maritalStatus;

    @Column(name = "blood_group", length = 5)
    private String bloodGroup;

    @Column(name = "profile_photo_url")
    private String profilePhotoUrl;

    // Contact Information
    @NotBlank(message = "Email is required")
    @Email(message = "Email should be valid")
    @Column(nullable = false, unique = true)
    private String email;

    @NotBlank(message = "Phone number is required")
    @Pattern(regexp = "^[6-9]\\d{9}$", message = "Invalid phone number")
    @Column(name = "phone_number", nullable = false, length = 10)
    private String phoneNumber;

    @Column(name = "alternate_phone_number", length = 10)
    private String alternatePhoneNumber;

    @Column(name = "address_line_1")
    private String addressLine1;

    @Column(name = "address_line_2")
    private String addressLine2;

    @Column(name = "city")
    private String city;

    @Column(name = "state")
    private String state;

    @Column(name = "pincode", length = 6)
    private String pincode;

    @Column(name = "country", length = 50)
    private String country = "India";

    // Identification Documents
    @NotBlank(message = "Aadhar number is required")
    @Pattern(regexp = "^\\d{12}$", message = "Aadhar must be exactly 12 digits")
    @Column(name = "aadhar_number", nullable = false, unique = true, length = 12)
    private String aadharNumber;

    @NotBlank(message = "PAN number is required")
    @Pattern(regexp = "^[A-Z]{5}[0-9]{4}[A-Z]{1}$", message = "Invalid PAN format")
    @Column(name = "pan_number", nullable = false, unique = true, length = 10)
    private String panNumber;

    @Column(name = "uan_number", length = 12)
    private String uanNumber;

    @Column(name = "esic_number", length = 17)
    private String esicNumber;

    // Work Information
    @Column(name = "department")
    private String department;

    @Column(name = "designation")
    private String designation;

    @Column(name = "joining_date")
    private LocalDate joiningDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "employment_type")
    private EmploymentType employmentType;

    @Column(name = "reporting_manager_id")
    private Long reportingManagerId;

    @Enumerated(EnumType.STRING)
    @Column(name = "employment_status")
    private EmploymentStatus employmentStatus = EmploymentStatus.ACTIVE;

    @Column(name = "work_location")
    private String workLocation;

    // Salary Information
    @Column(name = "basic_salary")
    private Double basicSalary;

    @Column(name = "house_rent_allowance")
    private Double houseRentAllowance;

    @Column(name = "conveyance")
    private Double conveyance;

    @Column(name = "uniform_and_safety")
    private Double uniformAndSafety;

    @Column(name = "bonus")
    private Double bonus;

    @Column(name = "food_allowance")
    private Double foodAllowance;

    @Column(name = "other_allowance")
    private Double otherAllowance;

    @Column(name = "overtime_rate")
    private Double overtimeRate;

    @Column(name = "epf_employee")
    private Double epfEmployee; // Percentage

    @Column(name = "epf_employer")
    private Double epfEmployer; // Percentage

    @Column(name = "total_salary")
    private Double totalSalary;

    // Deduction Information
    @Column(name = "esic")
    private Double esic; // Percentage

    @Column(name = "professional_tax")
    private Double professionalTax;

    // Bank Information
    @Column(name = "bank_name")
    private String bankName;

    @Column(name = "bank_account_number")
    private String bankAccountNumber;

    @Column(name = "ifsc_code", length = 11)
    private String ifscCode;

    @Column(name = "bank_branch")
    private String bankBranch;

    // Emergency Contact
    @Column(name = "emergency_contact_name")
    private String emergencyContactName;

    @Column(name = "emergency_contact_phone", length = 10)
    private String emergencyContactPhone;

    @Column(name = "emergency_contact_relation")
    private String emergencyContactRelation;

    // Documents
    @Column(name = "aadhar_document_url")
    private String aadharDocumentUrl;

    @Column(name = "pan_document_url")
    private String panDocumentUrl;

    @Column(name = "resume_url")
    private String resumeUrl;

    @Column(name = "offer_letter_url")
    private String offerLetterUrl;

    @Column(name = "appointment_letter_url")
    private String appointmentLetterUrl;

    @Column(name = "other_documents_url")
    private String otherDocumentsUrl;

    // Additional Information
    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    // Enums
    public enum Gender {
        MALE, FEMALE, OTHER
    }

    public enum MaritalStatus {
        SINGLE, MARRIED, DIVORCED, WIDOWED
    }

    public enum EmploymentType {
        FULL_TIME, PART_TIME, CONTRACT, INTERN
    }

    public enum EmploymentStatus {
        ACTIVE, INACTIVE, TERMINATED, ON_LEAVE
    }
}

