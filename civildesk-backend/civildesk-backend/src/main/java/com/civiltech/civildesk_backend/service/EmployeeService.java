package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.EmployeeRequest;
import com.civiltech.civildesk_backend.dto.EmployeeResponse;
import com.civiltech.civildesk_backend.exception.BadRequestException;
import com.civiltech.civildesk_backend.exception.ResourceNotFoundException;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.model.User;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import com.civiltech.civildesk_backend.repository.UserRepository;
import org.hibernate.Hibernate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.List;
import java.util.Objects;
import java.util.regex.Pattern;
import java.util.regex.Matcher;
import org.springframework.data.domain.PageRequest;

@Service
@Transactional
public class EmployeeService {

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private FaceRecognitionService faceRecognitionService;

    @Autowired
    private EmailService emailService;

    private static final SecureRandom random = new SecureRandom();
    private static final String UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    private static final String LOWER = "abcdefghijklmnopqrstuvwxyz";
    private static final String DIGITS = "0123456789";
    private static final String SPECIAL = "!@#$%&*";
    private static final String ALL_CHARS = UPPER + LOWER + DIGITS + SPECIAL;

    @Caching(evict = {
        @CacheEvict(value = "employees", allEntries = true),
        @CacheEvict(value = "dashboard", allEntries = true)
    })
    public EmployeeResponse createEmployee(EmployeeRequest request) {
        // Validate uniqueness
        validateUniqueness(request, null);

        // Get or create user
        User user;
        if (request.getUserId() != null) {
            Long userId = Objects.requireNonNull(request.getUserId(), "User ID cannot be null");
            user = userRepository.findById(userId)
                    .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));
        } else {
            // Create user if not provided - Super admin generates password for employee
            user = new User();
            user.setEmail(request.getEmail());
            
            // Generate secure password
            String generatedPassword = generateSecurePassword();
            user.setPassword(passwordEncoder.encode(generatedPassword));
            
            user.setFirstName(request.getFirstName());
            user.setLastName(request.getLastName());
            user.setRole(User.Role.EMPLOYEE);
            user.setIsActive(true);
            user.setEmailVerified(true); // Employees created by admin are pre-verified
            user = userRepository.save(user);

            // Send email with credentials to employee
            emailService.sendEmployeeRegistrationEmail(
                user.getEmail(),
                user.getFirstName(),
                generatedPassword
            );
        }

        // Generate employee ID if not provided
        String employeeId = request.getEmployeeId();
        if (employeeId == null || employeeId.isEmpty()) {
            employeeId = generateEmployeeId();
        }

        // Create employee
        Employee employee = mapToEntity(request);
        employee.setEmployeeId(employeeId);
        employee.setUser(user);
        employee.setEmploymentStatus(request.getEmploymentStatus() != null 
                ? request.getEmploymentStatus() 
                : Employee.EmploymentStatus.ACTIVE);
        employee.setIsActive(request.getIsActive() != null ? request.getIsActive() : true);

        // Calculate total salary
        calculateTotalSalary(employee);

        Employee savedEmployee = employeeRepository.save(employee);

        return mapToResponse(savedEmployee);
    }

    @Caching(evict = {
        @CacheEvict(value = "employee", key = "#id"),
        @CacheEvict(value = "employees", allEntries = true),
        @CacheEvict(value = "dashboard", allEntries = true)
    })
    public EmployeeResponse updateEmployee(Long id, EmployeeRequest request) {
        Long employeeId = Objects.requireNonNull(id, "Employee ID cannot be null");
        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with id: " + employeeId));

        if (employee.getDeleted()) {
            throw new ResourceNotFoundException("Employee not found with id: " + employeeId);
        }

        // Validate uniqueness excluding current employee
        validateUniqueness(request, employeeId);

        // Update fields
        updateEmployeeFields(employee, request);

        // Calculate total salary
        calculateTotalSalary(employee);

        Employee updatedEmployee = employeeRepository.save(employee);

        return mapToResponse(updatedEmployee);
    }

    @Transactional(readOnly = true)
    @Cacheable(value = "employee", key = "#id")
    public EmployeeResponse getEmployeeById(Long id) {
        Long employeeId = Objects.requireNonNull(id, "Employee ID cannot be null");
        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with id: " + employeeId));

        if (employee.getDeleted()) {
            throw new ResourceNotFoundException("Employee not found with id: " + employeeId);
        }

        // Ensure entity is fully initialized (not a proxy) before caching
        // This prevents LazyInitializationException when entity is retrieved from cache
        Hibernate.initialize(employee);

        return mapToResponse(employee);
    }

    @Transactional(readOnly = true)
    @Cacheable(value = "employee", key = "'empId:' + #employeeId")
    public EmployeeResponse getEmployeeByEmployeeId(String employeeId) {
        Employee employee = employeeRepository.findByEmployeeIdAndDeletedFalse(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with employee ID: " + employeeId));

        // Ensure entity is fully initialized (not a proxy) before caching
        // This prevents LazyInitializationException when entity is retrieved from cache
        Hibernate.initialize(employee);

        return mapToResponse(employee);
    }

    @Transactional(readOnly = true)
    public EmployeeResponse getEmployeeByUserId(Long userId) {
        Long nonNullUserId = Objects.requireNonNull(userId, "User ID cannot be null");
        Employee employee = employeeRepository.findByUserIdAndDeletedFalse(nonNullUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with user ID: " + nonNullUserId));

        // Ensure entity is fully initialized (not a proxy) before mapping
        // This prevents LazyInitializationException when entity is retrieved
        Hibernate.initialize(employee);

        return mapToResponse(employee);
    }

    @Transactional(readOnly = true)
    public Page<EmployeeResponse> getAllEmployees(Pageable pageable) {
        Pageable nonNullPageable = Objects.requireNonNull(pageable, "Pageable cannot be null");
        Page<Employee> employees = employeeRepository.findByDeletedFalse(nonNullPageable);
        return employees.map(this::mapToResponse);
    }

    @Transactional(readOnly = true)
    public Page<EmployeeResponse> searchEmployees(String search, Pageable pageable) {
        return employeeRepository.searchEmployees(search, pageable)
                .map(this::mapToResponse);
    }

    @Transactional(readOnly = true)
    public Page<EmployeeResponse> getEmployeesWithFilters(
            String search,
            String department,
            String designation,
            Employee.EmploymentStatus status,
            Employee.EmploymentType type,
            Pageable pageable
    ) {
        return employeeRepository.findWithFilters(search, department, designation, status, type, pageable)
                .map(this::mapToResponse);
    }

    @Caching(evict = {
        @CacheEvict(value = "employee", key = "#id"),
        @CacheEvict(value = "employees", allEntries = true),
        @CacheEvict(value = "dashboard", allEntries = true)
    })
    public void deleteEmployee(Long id) {
        Long employeeId = Objects.requireNonNull(id, "Employee ID cannot be null");
        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with id: " + employeeId));

        if (employee.getDeleted()) {
            throw new ResourceNotFoundException("Employee not found with id: " + employeeId);
        }

        // Delete face embeddings if they exist
        try {
            faceRecognitionService.deleteFaceEmbeddings(employee.getEmployeeId());
        } catch (Exception e) {
            // Log but don't fail the deletion if face service is unavailable
            System.err.println("Warning: Could not delete face embeddings for employee " + 
                employee.getEmployeeId() + ": " + e.getMessage());
        }

        // Soft delete
        employee.setDeleted(true);
        employee.setIsActive(false);
        employee.setEmploymentStatus(Employee.EmploymentStatus.TERMINATED);
        employeeRepository.save(employee);
    }

    /**
     * Generate or reset employee app credentials
     * Creates or updates the User account and sends credentials via email
     */
    public void generateEmployeeCredentials(Long id) {
        Long employeeId = Objects.requireNonNull(id, "Employee ID cannot be null");
        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with id: " + employeeId));

        if (employee.getDeleted()) {
            throw new ResourceNotFoundException("Employee not found with id: " + employeeId);
        }

        User user = employee.getUser();

        // If user doesn't exist, check if one exists with the same email
        if (user == null) {
            user = userRepository.findByEmailAndDeletedFalse(employee.getEmail()).orElse(null);
            
            // If no user exists with this email, create a new one
            if (user == null) {
                user = new User();
                user.setEmail(employee.getEmail());
                user.setFirstName(employee.getFirstName());
                user.setLastName(employee.getLastName());
                user.setRole(User.Role.EMPLOYEE);
                user.setIsActive(true);
                user.setEmailVerified(true); // Employees created by admin are pre-verified
            } else {
                // User exists but not linked to employee - update it
                user.setFirstName(employee.getFirstName());
                user.setLastName(employee.getLastName());
                user.setRole(User.Role.EMPLOYEE);
                user.setIsActive(true);
                user.setEmailVerified(true);
            }
        }

        // Generate new secure password
        String generatedPassword = generateSecurePassword();
        user.setPassword(passwordEncoder.encode(generatedPassword));
        user.setIsActive(true); // Ensure user is active
        
        // Save user
        user = userRepository.save(user);

        // Link user to employee if not already linked
        if (employee.getUser() == null) {
            employee.setUser(user);
            employeeRepository.save(employee);
        }

        // Send email with credentials
        try {
            emailService.sendEmployeeRegistrationEmail(
                user.getEmail(),
                user.getFirstName(),
                generatedPassword
            );
        } catch (Exception e) {
            // Log error but don't fail - credentials are still generated
            System.err.println("Warning: Could not send credentials email to " + 
                user.getEmail() + ": " + e.getMessage());
        }
    }

    private void validateUniqueness(EmployeeRequest request, Long excludeId) {
        if (excludeId == null) {
            // Creating new employee
            if (employeeRepository.existsByEmailAndDeletedFalse(request.getEmail())) {
                throw new BadRequestException("Email already exists");
            }
            if (employeeRepository.existsByAadharNumberAndDeletedFalse(request.getAadharNumber())) {
                throw new BadRequestException("Aadhar number already exists");
            }
            if (employeeRepository.existsByPanNumberAndDeletedFalse(request.getPanNumber())) {
                throw new BadRequestException("PAN number already exists");
            }
            if (request.getEmployeeId() != null && 
                employeeRepository.existsByEmployeeIdAndDeletedFalse(request.getEmployeeId())) {
                throw new BadRequestException("Employee ID already exists");
            }
        } else {
            // Updating existing employee
            if (request.getEmail() != null && 
                employeeRepository.existsByEmailAndDeletedFalseAndIdNot(request.getEmail(), excludeId)) {
                throw new BadRequestException("Email already exists");
            }
            if (request.getAadharNumber() != null && 
                employeeRepository.existsByAadharNumberAndDeletedFalseAndIdNot(request.getAadharNumber(), excludeId)) {
                throw new BadRequestException("Aadhar number already exists");
            }
            if (request.getPanNumber() != null && 
                employeeRepository.existsByPanNumberAndDeletedFalseAndIdNot(request.getPanNumber(), excludeId)) {
                throw new BadRequestException("PAN number already exists");
            }
            if (request.getEmployeeId() != null && !request.getEmployeeId().isEmpty() && 
                employeeRepository.existsByEmployeeIdAndDeletedFalseAndIdNot(request.getEmployeeId(), excludeId)) {
                throw new BadRequestException("Employee ID already exists");
            }
        }
    }

    private String generateEmployeeId() {
        String prefix = "CTS-EMP-";
        
        // Get all employee IDs matching the pattern (limit to recent ones for performance)
        List<String> existingIds = employeeRepository.findEmployeeIdsWithPattern(PageRequest.of(0, 1000));
        
        int maxNumber = 0;
        Pattern pattern = Pattern.compile("^CTS-EMP-(\\d+)$");
        
        // Find the maximum number from existing IDs
        for (String employeeId : existingIds) {
            Matcher matcher = pattern.matcher(employeeId);
            if (matcher.matches()) {
                try {
                    int number = Integer.parseInt(matcher.group(1));
                    if (number > maxNumber) {
                        maxNumber = number;
                    }
                } catch (NumberFormatException e) {
                    // Skip invalid format
                }
            }
        }
        
        // Increment by 1 for the next employee ID
        int nextNumber = maxNumber + 1;
        
        // Format with 4 digits (0001, 0002, etc.)
        String formattedNumber = String.format("%04d", nextNumber);
        
        return prefix + formattedNumber;
    }

    /**
     * Generate a secure random password (12 characters)
     * Includes uppercase, lowercase, digits, and special characters
     */
    private String generateSecurePassword() {
        StringBuilder password = new StringBuilder(12);
        
        // Ensure at least one character from each category
        password.append(UPPER.charAt(random.nextInt(UPPER.length())));
        password.append(LOWER.charAt(random.nextInt(LOWER.length())));
        password.append(DIGITS.charAt(random.nextInt(DIGITS.length())));
        password.append(SPECIAL.charAt(random.nextInt(SPECIAL.length())));
        
        // Fill the rest randomly
        for (int i = 4; i < 12; i++) {
            password.append(ALL_CHARS.charAt(random.nextInt(ALL_CHARS.length())));
        }
        
        // Shuffle the password
        char[] passwordArray = password.toString().toCharArray();
        for (int i = passwordArray.length - 1; i > 0; i--) {
            int j = random.nextInt(i + 1);
            char temp = passwordArray[i];
            passwordArray[i] = passwordArray[j];
            passwordArray[j] = temp;
        }
        
        return new String(passwordArray);
    }

    private Employee mapToEntity(EmployeeRequest request) {
        Employee employee = new Employee();
        employee.setFirstName(request.getFirstName());
        employee.setLastName(request.getLastName());
        employee.setMiddleName(request.getMiddleName());
        employee.setDateOfBirth(request.getDateOfBirth());
        employee.setGender(request.getGender());
        employee.setMaritalStatus(request.getMaritalStatus());
        employee.setBloodGroup(request.getBloodGroup());
        employee.setProfilePhotoUrl(request.getProfilePhotoUrl());
        employee.setEmail(request.getEmail());
        employee.setPhoneNumber(request.getPhoneNumber());
        employee.setAlternatePhoneNumber(request.getAlternatePhoneNumber());
        employee.setAddressLine1(request.getAddressLine1());
        employee.setAddressLine2(request.getAddressLine2());
        employee.setCity(request.getCity());
        employee.setState(request.getState());
        employee.setPincode(request.getPincode());
        employee.setCountry(request.getCountry());
        employee.setAadharNumber(request.getAadharNumber());
        employee.setPanNumber(request.getPanNumber());
        employee.setUanNumber(request.getUanNumber());
        employee.setEsicNumber(request.getEsicNumber());
        employee.setDepartment(request.getDepartment());
        employee.setDesignation(request.getDesignation());
        employee.setJoiningDate(request.getJoiningDate());
        employee.setEmploymentType(request.getEmploymentType());
        employee.setReportingManagerId(request.getReportingManagerId());
        employee.setWorkLocation(request.getWorkLocation());
        employee.setBasicSalary(request.getBasicSalary());
        employee.setHouseRentAllowance(request.getHouseRentAllowance());
        employee.setConveyance(request.getConveyance());
        employee.setUniformAndSafety(request.getUniformAndSafety());
        employee.setBonus(request.getBonus());
        employee.setFoodAllowance(request.getFoodAllowance());
        employee.setOtherAllowance(request.getOtherAllowance());
        employee.setOvertimeRate(request.getOvertimeRate());
        employee.setEpfEmployee(request.getEpfEmployee());
        employee.setEpfEmployer(request.getEpfEmployer());
        employee.setEsic(request.getEsic());
        employee.setProfessionalTax(request.getProfessionalTax());
        employee.setBankName(request.getBankName());
        employee.setBankAccountNumber(request.getBankAccountNumber());
        employee.setIfscCode(request.getIfscCode());
        employee.setBankBranch(request.getBankBranch());
        employee.setEmergencyContactName(request.getEmergencyContactName());
        employee.setEmergencyContactPhone(request.getEmergencyContactPhone());
        employee.setEmergencyContactRelation(request.getEmergencyContactRelation());
        employee.setAadharDocumentUrl(request.getAadharDocumentUrl());
        employee.setPanDocumentUrl(request.getPanDocumentUrl());
        employee.setResumeUrl(request.getResumeUrl());
        employee.setOfferLetterUrl(request.getOfferLetterUrl());
        employee.setAppointmentLetterUrl(request.getAppointmentLetterUrl());
        employee.setOtherDocumentsUrl(request.getOtherDocumentsUrl());
        employee.setNotes(request.getNotes());
        // Set attendance method (default to FACE_RECOGNITION if not specified)
        employee.setAttendanceMethod(request.getAttendanceMethod() != null 
                ? request.getAttendanceMethod() 
                : Employee.AttendanceMethod.FACE_RECOGNITION);
        return employee;
    }

    private void updateEmployeeFields(Employee employee, EmployeeRequest request) {
        if (request.getFirstName() != null) employee.setFirstName(request.getFirstName());
        if (request.getLastName() != null) employee.setLastName(request.getLastName());
        if (request.getMiddleName() != null) employee.setMiddleName(request.getMiddleName());
        if (request.getDateOfBirth() != null) employee.setDateOfBirth(request.getDateOfBirth());
        if (request.getGender() != null) employee.setGender(request.getGender());
        if (request.getMaritalStatus() != null) employee.setMaritalStatus(request.getMaritalStatus());
        if (request.getBloodGroup() != null) employee.setBloodGroup(request.getBloodGroup());
        if (request.getProfilePhotoUrl() != null) employee.setProfilePhotoUrl(request.getProfilePhotoUrl());
        if (request.getEmail() != null) employee.setEmail(request.getEmail());
        if (request.getPhoneNumber() != null) employee.setPhoneNumber(request.getPhoneNumber());
        if (request.getAlternatePhoneNumber() != null) employee.setAlternatePhoneNumber(request.getAlternatePhoneNumber());
        if (request.getAddressLine1() != null) employee.setAddressLine1(request.getAddressLine1());
        if (request.getAddressLine2() != null) employee.setAddressLine2(request.getAddressLine2());
        if (request.getCity() != null) employee.setCity(request.getCity());
        if (request.getState() != null) employee.setState(request.getState());
        if (request.getPincode() != null) employee.setPincode(request.getPincode());
        if (request.getCountry() != null) employee.setCountry(request.getCountry());
        if (request.getAadharNumber() != null) employee.setAadharNumber(request.getAadharNumber());
        if (request.getPanNumber() != null) employee.setPanNumber(request.getPanNumber());
        if (request.getUanNumber() != null) employee.setUanNumber(request.getUanNumber());
        if (request.getEsicNumber() != null) employee.setEsicNumber(request.getEsicNumber());
        if (request.getDepartment() != null) employee.setDepartment(request.getDepartment());
        if (request.getDesignation() != null) employee.setDesignation(request.getDesignation());
        if (request.getJoiningDate() != null) employee.setJoiningDate(request.getJoiningDate());
        if (request.getEmploymentType() != null) employee.setEmploymentType(request.getEmploymentType());
        if (request.getReportingManagerId() != null) employee.setReportingManagerId(request.getReportingManagerId());
        if (request.getEmploymentStatus() != null) employee.setEmploymentStatus(request.getEmploymentStatus());
        if (request.getWorkLocation() != null) employee.setWorkLocation(request.getWorkLocation());
        if (request.getBasicSalary() != null) employee.setBasicSalary(request.getBasicSalary());
        if (request.getHouseRentAllowance() != null) employee.setHouseRentAllowance(request.getHouseRentAllowance());
        if (request.getConveyance() != null) employee.setConveyance(request.getConveyance());
        if (request.getUniformAndSafety() != null) employee.setUniformAndSafety(request.getUniformAndSafety());
        if (request.getBonus() != null) employee.setBonus(request.getBonus());
        if (request.getFoodAllowance() != null) employee.setFoodAllowance(request.getFoodAllowance());
        if (request.getOtherAllowance() != null) employee.setOtherAllowance(request.getOtherAllowance());
        if (request.getOvertimeRate() != null) employee.setOvertimeRate(request.getOvertimeRate());
        if (request.getEpfEmployee() != null) employee.setEpfEmployee(request.getEpfEmployee());
        if (request.getEpfEmployer() != null) employee.setEpfEmployer(request.getEpfEmployer());
        if (request.getEsic() != null) employee.setEsic(request.getEsic());
        if (request.getProfessionalTax() != null) employee.setProfessionalTax(request.getProfessionalTax());
        if (request.getBankName() != null) employee.setBankName(request.getBankName());
        if (request.getBankAccountNumber() != null) employee.setBankAccountNumber(request.getBankAccountNumber());
        if (request.getIfscCode() != null) employee.setIfscCode(request.getIfscCode());
        if (request.getBankBranch() != null) employee.setBankBranch(request.getBankBranch());
        if (request.getEmergencyContactName() != null) employee.setEmergencyContactName(request.getEmergencyContactName());
        if (request.getEmergencyContactPhone() != null) employee.setEmergencyContactPhone(request.getEmergencyContactPhone());
        if (request.getEmergencyContactRelation() != null) employee.setEmergencyContactRelation(request.getEmergencyContactRelation());
        if (request.getAadharDocumentUrl() != null) employee.setAadharDocumentUrl(request.getAadharDocumentUrl());
        if (request.getPanDocumentUrl() != null) employee.setPanDocumentUrl(request.getPanDocumentUrl());
        if (request.getResumeUrl() != null) employee.setResumeUrl(request.getResumeUrl());
        if (request.getOfferLetterUrl() != null) employee.setOfferLetterUrl(request.getOfferLetterUrl());
        if (request.getAppointmentLetterUrl() != null) employee.setAppointmentLetterUrl(request.getAppointmentLetterUrl());
        if (request.getOtherDocumentsUrl() != null) employee.setOtherDocumentsUrl(request.getOtherDocumentsUrl());
        if (request.getNotes() != null) employee.setNotes(request.getNotes());
        if (request.getIsActive() != null) employee.setIsActive(request.getIsActive());
        if (request.getAttendanceMethod() != null) employee.setAttendanceMethod(request.getAttendanceMethod());
    }

    private void calculateTotalSalary(Employee employee) {
        double total = 0.0;
        if (employee.getBasicSalary() != null) total += employee.getBasicSalary();
        if (employee.getHouseRentAllowance() != null) total += employee.getHouseRentAllowance();
        if (employee.getConveyance() != null) total += employee.getConveyance();
        if (employee.getUniformAndSafety() != null) total += employee.getUniformAndSafety();
        if (employee.getBonus() != null) total += employee.getBonus();
        if (employee.getFoodAllowance() != null) total += employee.getFoodAllowance();
        if (employee.getOtherAllowance() != null) total += employee.getOtherAllowance();
        employee.setTotalSalary(total > 0 ? total : null);
    }

    private EmployeeResponse mapToResponse(Employee employee) {
        EmployeeResponse response = new EmployeeResponse();
        response.setId(employee.getId());
        response.setEmployeeId(employee.getEmployeeId());
        response.setUserId(employee.getUser() != null ? employee.getUser().getId() : null);
        response.setFirstName(employee.getFirstName());
        response.setLastName(employee.getLastName());
        response.setMiddleName(employee.getMiddleName());
        response.setDateOfBirth(employee.getDateOfBirth());
        response.setGender(employee.getGender());
        response.setMaritalStatus(employee.getMaritalStatus());
        response.setBloodGroup(employee.getBloodGroup());
        response.setProfilePhotoUrl(employee.getProfilePhotoUrl());
        response.setEmail(employee.getEmail());
        response.setPhoneNumber(employee.getPhoneNumber());
        response.setAlternatePhoneNumber(employee.getAlternatePhoneNumber());
        response.setAddressLine1(employee.getAddressLine1());
        response.setAddressLine2(employee.getAddressLine2());
        response.setCity(employee.getCity());
        response.setState(employee.getState());
        response.setPincode(employee.getPincode());
        response.setCountry(employee.getCountry());
        response.setAadharNumber(employee.getAadharNumber());
        response.setPanNumber(employee.getPanNumber());
        response.setUanNumber(employee.getUanNumber());
        response.setEsicNumber(employee.getEsicNumber());
        response.setDepartment(employee.getDepartment());
        response.setDesignation(employee.getDesignation());
        response.setJoiningDate(employee.getJoiningDate());
        response.setEmploymentType(employee.getEmploymentType());
        response.setReportingManagerId(employee.getReportingManagerId());
        
        // Set reporting manager name if exists
        if (employee.getReportingManagerId() != null) {
            Long managerId = Objects.requireNonNull(employee.getReportingManagerId(), "Reporting manager ID cannot be null");
            employeeRepository.findById(managerId)
                    .ifPresent(manager -> response.setReportingManagerName(
                            manager.getFirstName() + " " + manager.getLastName()));
        }
        
        response.setEmploymentStatus(employee.getEmploymentStatus());
        response.setWorkLocation(employee.getWorkLocation());
        response.setBasicSalary(employee.getBasicSalary());
        response.setHouseRentAllowance(employee.getHouseRentAllowance());
        response.setConveyance(employee.getConveyance());
        response.setUniformAndSafety(employee.getUniformAndSafety());
        response.setBonus(employee.getBonus());
        response.setFoodAllowance(employee.getFoodAllowance());
        response.setOtherAllowance(employee.getOtherAllowance());
        response.setOvertimeRate(employee.getOvertimeRate());
        response.setEpfEmployee(employee.getEpfEmployee());
        response.setEpfEmployer(employee.getEpfEmployer());
        response.setTotalSalary(employee.getTotalSalary());
        response.setEsic(employee.getEsic());
        response.setProfessionalTax(employee.getProfessionalTax());
        response.setBankName(employee.getBankName());
        response.setBankAccountNumber(employee.getBankAccountNumber());
        response.setIfscCode(employee.getIfscCode());
        response.setBankBranch(employee.getBankBranch());
        response.setEmergencyContactName(employee.getEmergencyContactName());
        response.setEmergencyContactPhone(employee.getEmergencyContactPhone());
        response.setEmergencyContactRelation(employee.getEmergencyContactRelation());
        response.setAadharDocumentUrl(employee.getAadharDocumentUrl());
        response.setPanDocumentUrl(employee.getPanDocumentUrl());
        response.setResumeUrl(employee.getResumeUrl());
        response.setOfferLetterUrl(employee.getOfferLetterUrl());
        response.setAppointmentLetterUrl(employee.getAppointmentLetterUrl());
        response.setOtherDocumentsUrl(employee.getOtherDocumentsUrl());
        response.setNotes(employee.getNotes());
        response.setIsActive(employee.getIsActive());
        response.setAttendanceMethod(employee.getAttendanceMethod());
        response.setCreatedAt(employee.getCreatedAt());
        response.setUpdatedAt(employee.getUpdatedAt());
        return response;
    }
}

