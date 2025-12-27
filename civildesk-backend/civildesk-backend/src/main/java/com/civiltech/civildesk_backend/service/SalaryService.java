package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.SalaryCalculationRequest;
import com.civiltech.civildesk_backend.dto.SalaryCalculationResponse;
import com.civiltech.civildesk_backend.dto.SalarySlipResponse;
import com.civiltech.civildesk_backend.exception.BadRequestException;
import com.civiltech.civildesk_backend.exception.ResourceNotFoundException;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.model.SalarySlip;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import com.civiltech.civildesk_backend.repository.SalarySlipRepository;
import com.civiltech.civildesk_backend.security.SecurityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Service
public class SalaryService {

    private static final Logger logger = LoggerFactory.getLogger(SalaryService.class);

    @Autowired
    private SalarySlipRepository salarySlipRepository;

    @Autowired
    private SalaryCalculationService calculationService;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private NotificationService notificationService;

    @Transactional
    // Spring Data JPA save() always returns a non-null entity
    public SalaryCalculationResponse calculateAndGenerateSlip(SalaryCalculationRequest request) {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        SalarySlip salarySlip = calculationService.calculateSalary(request, currentUserId);
        // Spring Data JPA save() always returns a non-null entity
        salarySlip = salarySlipRepository.save(salarySlip);
        
        // Reload with Employee to ensure it's properly initialized
        salarySlip = salarySlipRepository.findByIdWithEmployee(salarySlip.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Salary slip not found after save"));
        
        return buildCalculationResponse(salarySlip);
    }

    @Transactional(readOnly = true)
    public SalarySlipResponse getSalarySlipById(Long id) {
        SalarySlip salarySlip = salarySlipRepository.findByIdWithEmployee(id)
                .orElseThrow(() -> new ResourceNotFoundException("Salary slip not found with ID: " + id));
        
        if (Boolean.TRUE.equals(salarySlip.getDeleted())) {
            throw new ResourceNotFoundException("Salary slip not found with ID: " + id);
        }
        
        return mapToResponse(salarySlip);
    }

    @Transactional(readOnly = true)
    public SalarySlipResponse getSalarySlipByEmployeeAndPeriod(String employeeId, Integer year, Integer month) {
        Employee employee = employeeRepository.findByEmployeeIdAndDeletedFalse(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with ID: " + employeeId));
        
        // First, try to get FINALIZED slip (only one allowed per employee per month)
        Optional<SalarySlip> finalizedSlip = salarySlipRepository.findFinalizedByEmployeeAndPeriod(
                employee.getId(), year, month);
        
        if (finalizedSlip.isPresent()) {
            return mapToResponse(finalizedSlip.get());
        }
        
        // If no FINALIZED slip, get the most recent DRAFT slip
        List<SalarySlip> draftSlips = salarySlipRepository.findDraftByEmployeeAndPeriod(
                employee.getId(), year, month);
        
        if (!draftSlips.isEmpty()) {
            // Return the most recent DRAFT slip (already ordered by createdAt DESC)
            return mapToResponse(draftSlips.get(0));
        }
        
        throw new ResourceNotFoundException(
                String.format("Salary slip not found for employee %s for %d/%d", employeeId, month, year));
    }

    @Transactional(readOnly = true)
    public List<SalarySlipResponse> getEmployeeSalarySlips(String employeeId) {
        List<SalarySlip> salarySlips = salarySlipRepository.findByEmployeeEmployeeId(employeeId);
        return salarySlips.stream()
                .filter(slip -> !Boolean.TRUE.equals(slip.getDeleted()))
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public Employee getEmployeeByUserId(Long userId) {
        return employeeRepository.findByUserIdAndDeletedFalse(userId).orElse(null);
    }

    @Transactional(readOnly = true)
    public List<SalarySlipResponse> getMySalarySlips(String employeeId, Integer year, Integer month, String status) {
        List<SalarySlip> salarySlips = salarySlipRepository.findByEmployeeEmployeeId(employeeId);
        
        // Filter out deleted records and by status (only show FINALIZED and PAID slips to employees)
        salarySlips = salarySlips.stream()
                .filter(slip -> !Boolean.TRUE.equals(slip.getDeleted()))
                .filter(slip -> slip.getStatus() == SalarySlip.SalarySlipStatus.FINALIZED || 
                               slip.getStatus() == SalarySlip.SalarySlipStatus.PAID)
                .collect(Collectors.toList());
        
        // Filter by year if provided
        if (year != null) {
            salarySlips = salarySlips.stream()
                    .filter(slip -> slip.getYear().equals(year))
                    .collect(Collectors.toList());
        }
        
        // Filter by month if provided
        if (month != null) {
            salarySlips = salarySlips.stream()
                    .filter(slip -> slip.getMonth().equals(month))
                    .collect(Collectors.toList());
        }
        
        // Filter by status if provided
        if (status != null && !status.isEmpty()) {
            try {
                SalarySlip.SalarySlipStatus statusEnum = SalarySlip.SalarySlipStatus.valueOf(status.toUpperCase());
                salarySlips = salarySlips.stream()
                        .filter(slip -> slip.getStatus() == statusEnum)
                        .collect(Collectors.toList());
            } catch (IllegalArgumentException e) {
                // Invalid status, return empty list
                return List.of();
            }
        }
        
        // Sort by year and month descending (newest first)
        salarySlips.sort((a, b) -> {
            int yearCompare = b.getYear().compareTo(a.getYear());
            if (yearCompare != 0) return yearCompare;
            return b.getMonth().compareTo(a.getMonth());
        });
        
        return salarySlips.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<SalarySlipResponse> getAllSalarySlips(Integer year, Integer month) {
        List<SalarySlip> salarySlips;
        if (year != null && month != null) {
            salarySlips = salarySlipRepository.findByYearAndMonth(year, month);
        } else {
            salarySlips = salarySlipRepository.findAllWithEmployee();
        }
        // Repository queries already filter deleted = false, but adding extra safety check
        return salarySlips.stream()
                .filter(slip -> !Boolean.TRUE.equals(slip.getDeleted()))
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<SalarySlipResponse> getAllSalarySlipsPaginated(Integer year, Integer month, Pageable pageable) {
        Page<SalarySlip> salarySlips;
        if (year != null && month != null) {
            salarySlips = salarySlipRepository.findByYearAndMonthPaginated(year, month, pageable);
        } else {
            salarySlips = salarySlipRepository.findAllWithEmployeePaginated(pageable);
        }
        return salarySlips.map(this::mapToResponse);
    }

    @Transactional
    public SalarySlipResponse finalizeSalarySlip(Long id) {
        SalarySlip salarySlip = salarySlipRepository.findByIdWithEmployee(id)
                .orElseThrow(() -> new ResourceNotFoundException("Salary slip not found with ID: " + id));
        
        // Check if already deleted
        if (Boolean.TRUE.equals(salarySlip.getDeleted())) {
            throw new ResourceNotFoundException("Salary slip not found with ID: " + id);
        }
        
        // Check if already finalized
        if (salarySlip.getStatus() == SalarySlip.SalarySlipStatus.FINALIZED) {
            throw new BadRequestException("Salary slip is already finalized");
        }
        
        // Check if there's already a FINALIZED slip for this employee and period
        Optional<SalarySlip> existingFinalized = salarySlipRepository.findFinalizedByEmployeeAndPeriod(
                salarySlip.getEmployee().getId(),
                salarySlip.getYear(),
                salarySlip.getMonth()
        );
        
        if (existingFinalized.isPresent() && !existingFinalized.get().getId().equals(id)) {
            throw new BadRequestException(
                    String.format("A finalized salary slip already exists for employee %s for %s %d. " +
                            "Only one finalized salary slip is allowed per employee per month.",
                            salarySlip.getEmployee().getEmployeeId(),
                            salarySlip.getPeriodString(),
                            salarySlip.getYear())
            );
        }
        
        salarySlip.setStatus(SalarySlip.SalarySlipStatus.FINALIZED);
        salarySlip = salarySlipRepository.save(salarySlip);

        // Send notification to employee
        if (salarySlip.getEmployee() != null && salarySlip.getEmployee().getUser() != null 
                && salarySlip.getEmployee().getUser().getId() != null) {
            try {
                notificationService.notifyFinalizedSalarySlip(
                        salarySlip.getEmployee().getUser().getId(),
                        salarySlip.getId(),
                        salarySlip.getPeriodString()
                );
            } catch (Exception e) {
                logger.error("Failed to send salary slip finalized notification", e);
            }
        }
        
        return mapToResponse(salarySlip);
    }

    @Transactional
    public SalarySlipResponse updateSalarySlipStatus(Long id, SalarySlip.SalarySlipStatus status) {
        SalarySlip salarySlip = salarySlipRepository.findByIdWithEmployee(id)
                .orElseThrow(() -> new ResourceNotFoundException("Salary slip not found with ID: " + id));
        
        salarySlip.setStatus(status);
        salarySlip = salarySlipRepository.save(salarySlip);
        
        return mapToResponse(salarySlip);
    }

    @Transactional
    public void deleteSalarySlip(Long id) {
        SalarySlip salarySlip = salarySlipRepository.findByIdWithEmployee(id)
                .orElseThrow(() -> new ResourceNotFoundException("Salary slip not found with ID: " + id));
        
        // Check if already deleted
        if (Boolean.TRUE.equals(salarySlip.getDeleted())) {
            throw new BadRequestException("Salary slip is already deleted");
        }
        
        // Only allow deletion of DRAFT salary slips
        if (salarySlip.getStatus() != SalarySlip.SalarySlipStatus.DRAFT) {
            throw new BadRequestException("Only DRAFT salary slips can be deleted. Current status: " + salarySlip.getStatus());
        }
        
        salarySlip.setDeleted(true);
        salarySlipRepository.save(salarySlip);
    }

    /**
     * Generate salary slips in bulk for multiple employees asynchronously.
     * This method processes salary calculations in batches to avoid blocking the main thread.
     * 
     * @param requests List of salary calculation requests
     * @return CompletableFuture with list of generated salary slips
     */
    @Async("computeExecutor")
    @Transactional
    public CompletableFuture<List<SalarySlip>> generateBulkSalarySlipsAsync(List<SalaryCalculationRequest> requests) {
        List<SalarySlip> salarySlips = new ArrayList<>();
        Long currentUserId = SecurityUtils.getCurrentUserId();
        
        int batchSize = 50;
        for (int i = 0; i < requests.size(); i++) {
            SalaryCalculationRequest request = requests.get(i);
            try {
                SalarySlip salarySlip = calculationService.calculateSalary(request, currentUserId);
                // Spring Data JPA save() always returns a non-null entity
                SalarySlip savedSlip = salarySlipRepository.save(salarySlip);
                salarySlips.add(savedSlip);
                
                // Flush and clear every batchSize to manage memory
                if ((i + 1) % batchSize == 0) {
                    salarySlipRepository.flush();
                }
            } catch (Exception e) {
                // Log error but continue with other employees
                String employeeId = request != null ? request.getEmployeeId() : "unknown";
                System.err.println("Error calculating salary for employee " + 
                    employeeId + ": " + e.getMessage());
                // Continue with next employee
            }
        }
        
        // Final flush
        if (!salarySlips.isEmpty()) {
            salarySlipRepository.flush();
        }
        
        return CompletableFuture.completedFuture(salarySlips);
    }

    private SalaryCalculationResponse buildCalculationResponse(SalarySlip salarySlip) {
        SalarySlipResponse slipResponse = mapToResponse(salarySlip);
        
        SalaryCalculationResponse response = new SalaryCalculationResponse();
        response.setSalarySlip(slipResponse);
        
        SalaryCalculationResponse.CalculationBreakdown breakdown = new SalaryCalculationResponse.CalculationBreakdown();
        breakdown.setTotalDaysInMonth(salarySlip.getTotalDaysInMonth());
        breakdown.setWorkingDays(salarySlip.getWorkingDays());
        breakdown.setWeeklyOffs(salarySlip.getWeeklyOffs());
        breakdown.setTotalEffectiveWorkingHours(salarySlip.getTotalEffectiveWorkingHours());
        breakdown.setTotalOvertimeHours(salarySlip.getTotalOvertimeHours());
        breakdown.setRawPresentDays(salarySlip.getRawPresentDays());
        breakdown.setPresentDays(salarySlip.getPresentDays());
        breakdown.setAbsentDays(salarySlip.getAbsentDays());
        breakdown.setProrationFactor(salarySlip.getProrationFactor());
        breakdown.setDailyRate(salarySlip.getDailyRate());
        breakdown.setHourlyRate(salarySlip.getHourlyRate());
        breakdown.setOvertimeRate(salarySlip.getOvertimeRate());
        
        SalaryCalculationResponse.EarningsBreakdown earnings = new SalaryCalculationResponse.EarningsBreakdown();
        earnings.setBasicPay(salarySlip.getBasicPay());
        earnings.setHraAmount(salarySlip.getHraAmount());
        earnings.setMedicalAllowance(salarySlip.getMedicalAllowance());
        earnings.setConveyanceAllowance(salarySlip.getConveyanceAllowance());
        earnings.setUniformAndSafetyAllowance(salarySlip.getUniformAndSafetyAllowance());
        earnings.setBonus(salarySlip.getBonus());
        earnings.setFoodAllowance(salarySlip.getFoodAllowance());
        earnings.setSpecialAllowance(salarySlip.getSpecialAllowance());
        earnings.setOvertimePay(salarySlip.getOvertimePay());
        earnings.setTotalSpecialAllowance(salarySlip.getTotalSpecialAllowance());
        earnings.setOtherIncentive(salarySlip.getOtherIncentive());
        earnings.setEpfEmployerEarnings(salarySlip.getEpfEmployerEarnings());
        earnings.setTotalEarnings(salarySlip.getTotalEarnings());
        breakdown.setEarnings(earnings);
        
        SalaryCalculationResponse.DeductionsBreakdown deductions = new SalaryCalculationResponse.DeductionsBreakdown();
        deductions.setEpfEmployeeDeduction(salarySlip.getEpfEmployeeDeduction());
        deductions.setEpfEmployerDeduction(salarySlip.getEpfEmployerDeduction());
        deductions.setEsicDeduction(salarySlip.getEsicDeduction());
        deductions.setProfessionalTax(salarySlip.getProfessionalTax());
        deductions.setTds(salarySlip.getTds());
        deductions.setAdvanceSalaryRecovery(salarySlip.getAdvanceSalaryRecovery());
        deductions.setLoanRecovery(salarySlip.getLoanRecovery());
        deductions.setFuelAdvanceRecovery(salarySlip.getFuelAdvanceRecovery());
        deductions.setOtherDeductions(salarySlip.getOtherDeductions());
        deductions.setTotalStatutoryDeductions(salarySlip.getTotalStatutoryDeductions());
        deductions.setTotalOtherDeductions(salarySlip.getTotalOtherDeductions());
        deductions.setTotalDeductions(salarySlip.getTotalDeductions());
        breakdown.setDeductions(deductions);
        
        response.setBreakdown(breakdown);
        
        return response;
    }

    private SalarySlipResponse mapToResponse(SalarySlip salarySlip) {
        SalarySlipResponse response = new SalarySlipResponse();
        response.setId(salarySlip.getId());
        response.setEmployeeId(salarySlip.getEmployee().getEmployeeId());
        response.setEmployeeName(salarySlip.getEmployee().getFirstName() + " " + salarySlip.getEmployee().getLastName());
        response.setDepartment(salarySlip.getEmployee().getDepartment());
        response.setDesignation(salarySlip.getEmployee().getDesignation());
        response.setYear(salarySlip.getYear());
        response.setMonth(salarySlip.getMonth());
        response.setPeriodString(salarySlip.getPeriodString());
        response.setTotalDaysInMonth(salarySlip.getTotalDaysInMonth());
        response.setWorkingDays(salarySlip.getWorkingDays());
        response.setWeeklyOffs(salarySlip.getWeeklyOffs());
        response.setTotalEffectiveWorkingHours(salarySlip.getTotalEffectiveWorkingHours());
        response.setTotalOvertimeHours(salarySlip.getTotalOvertimeHours());
        response.setRawPresentDays(salarySlip.getRawPresentDays());
        response.setPresentDays(salarySlip.getPresentDays());
        response.setAbsentDays(salarySlip.getAbsentDays());
        response.setProrationFactor(salarySlip.getProrationFactor());
        response.setBasicPay(salarySlip.getBasicPay());
        response.setHraAmount(salarySlip.getHraAmount());
        response.setMedicalAllowance(salarySlip.getMedicalAllowance());
        response.setConveyanceAllowance(salarySlip.getConveyanceAllowance());
        response.setUniformAndSafetyAllowance(salarySlip.getUniformAndSafetyAllowance());
        response.setBonus(salarySlip.getBonus());
        response.setFoodAllowance(salarySlip.getFoodAllowance());
        response.setSpecialAllowance(salarySlip.getSpecialAllowance());
        response.setOvertimePay(salarySlip.getOvertimePay());
        response.setTotalSpecialAllowance(salarySlip.getTotalSpecialAllowance());
        response.setOtherIncentive(salarySlip.getOtherIncentive());
        response.setEpfEmployerEarnings(salarySlip.getEpfEmployerEarnings());
        response.setTotalEarnings(salarySlip.getTotalEarnings());
        response.setEpfEmployeeDeduction(salarySlip.getEpfEmployeeDeduction());
        response.setEpfEmployerDeduction(salarySlip.getEpfEmployerDeduction());
        response.setEsicDeduction(salarySlip.getEsicDeduction());
        response.setProfessionalTax(salarySlip.getProfessionalTax());
        response.setTds(salarySlip.getTds());
        response.setAdvanceSalaryRecovery(salarySlip.getAdvanceSalaryRecovery());
        response.setLoanRecovery(salarySlip.getLoanRecovery());
        response.setFuelAdvanceRecovery(salarySlip.getFuelAdvanceRecovery());
        response.setOtherDeductions(salarySlip.getOtherDeductions());
        response.setTotalStatutoryDeductions(salarySlip.getTotalStatutoryDeductions());
        response.setTotalOtherDeductions(salarySlip.getTotalOtherDeductions());
        response.setTotalDeductions(salarySlip.getTotalDeductions());
        response.setNetSalary(salarySlip.getNetSalary());
        response.setDailyRate(salarySlip.getDailyRate());
        response.setHourlyRate(salarySlip.getHourlyRate());
        response.setOvertimeRate(salarySlip.getOvertimeRate());
        response.setStatus(salarySlip.getStatus().name());
        response.setGeneratedBy(salarySlip.getGeneratedBy());
        response.setGeneratedAt(salarySlip.getGeneratedAt());
        response.setNotes(salarySlip.getNotes());
        response.setCreatedAt(salarySlip.getCreatedAt());
        response.setUpdatedAt(salarySlip.getUpdatedAt());
        
        return response;
    }
}

