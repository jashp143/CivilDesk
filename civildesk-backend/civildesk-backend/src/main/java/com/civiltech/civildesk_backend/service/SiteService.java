package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.*;
import com.civiltech.civildesk_backend.exception.BadRequestException;
import com.civiltech.civildesk_backend.exception.ResourceNotFoundException;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.model.EmployeeSiteAssignment;
import com.civiltech.civildesk_backend.model.Site;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import com.civiltech.civildesk_backend.repository.EmployeeSiteAssignmentRepository;
import com.civiltech.civildesk_backend.repository.SiteRepository;
import org.hibernate.Hibernate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class SiteService {

    @Autowired
    private SiteRepository siteRepository;

    @Autowired
    private EmployeeSiteAssignmentRepository assignmentRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private GeofenceService geofenceService;

    // ==================== Site CRUD ====================

    @Transactional
    @CacheEvict(value = "sites", allEntries = true)
    public SiteResponse createSite(SiteRequest request) {
        // Generate site code if not provided
        String siteCode = request.getSiteCode();
        if (siteCode == null || siteCode.isEmpty()) {
            siteCode = generateSiteCode();
        }

        // Check for duplicate site code
        if (siteRepository.existsBySiteCode(siteCode)) {
            throw new BadRequestException("Site with code " + siteCode + " already exists");
        }

        Site site = new Site();
        updateSiteFromRequest(site, request);
        site.setSiteCode(siteCode);

        site = siteRepository.save(site);
        return SiteResponse.fromEntity(site);
    }

    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "site", key = "#id"),
        @CacheEvict(value = "sites", allEntries = true)
    })
    public SiteResponse updateSite(@NonNull Long id, SiteRequest request) {
        Site site = siteRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Site not found with id: " + id));

        // Check for duplicate site code if changed
        if (request.getSiteCode() != null && !request.getSiteCode().equals(site.getSiteCode())) {
            if (siteRepository.existsBySiteCode(request.getSiteCode())) {
                throw new BadRequestException("Site with code " + request.getSiteCode() + " already exists");
            }
            site.setSiteCode(request.getSiteCode());
        }

        updateSiteFromRequest(site, request);
        // Spring Data JPA save() always returns a non-null entity
        Site savedSite = siteRepository.save(site);
        return SiteResponse.fromEntity(savedSite);
    }

    @Transactional(readOnly = true)
    @Cacheable(value = "site", key = "#id")
    public SiteResponse getSiteById(@NonNull Long id) {
        Site site = siteRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Site not found with id: " + id));
        
        // Ensure entity is fully initialized (not a proxy) before caching
        // This prevents LazyInitializationException when entity is retrieved from cache
        Hibernate.initialize(site);
        
        SiteResponse response = SiteResponse.fromEntity(site);
        response.setAssignedEmployeeCount(assignmentRepository.countActiveEmployeesBySiteId(id).intValue());
        return response;
    }

    public SiteResponse getSiteBySiteCode(String siteCode) {
        Site site = siteRepository.findBySiteCode(siteCode)
                .orElseThrow(() -> new ResourceNotFoundException("Site not found with code: " + siteCode));
        
        SiteResponse response = SiteResponse.fromEntity(site);
        response.setAssignedEmployeeCount(assignmentRepository.countActiveEmployeesBySiteId(site.getId()).intValue());
        return response;
    }

    @Transactional(readOnly = true)
    public Page<SiteResponse> getAllSites(Pageable pageable) {
        // Use optimized query to fetch sites with employee counts in a single query
        // This eliminates N+1 query problem
        Page<Object[]> results = siteRepository.findAllWithEmployeeCounts(pageable);
        
        return results.map(result -> {
            Site site = (Site) result[0];
            Long employeeCount = (Long) result[1];
            SiteResponse response = SiteResponse.fromEntity(site);
            response.setAssignedEmployeeCount(employeeCount.intValue());
            return response;
        });
    }

    @Transactional(readOnly = true)
    @Cacheable(value = "sites", key = "'active'")
    public List<SiteResponse> getActiveSites() {
        // Use optimized query to fetch active sites with employee counts in a single query
        // This eliminates N+1 query problem
        List<Object[]> results = siteRepository.findActiveSitesWithEmployeeCounts();
        
        return results.stream()
                .map(result -> {
                    Site site = (Site) result[0];
                    Long employeeCount = (Long) result[1];
                    SiteResponse response = SiteResponse.fromEntity(site);
                    response.setAssignedEmployeeCount(employeeCount.intValue());
                    return response;
                })
                .collect(Collectors.toList());
    }

    public Page<SiteResponse> searchSites(String search, Pageable pageable) {
        return siteRepository.searchSites(search, pageable).map(SiteResponse::fromEntity);
    }

    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "site", key = "#id"),
        @CacheEvict(value = "sites", allEntries = true)
    })
    public void deleteSite(@NonNull Long id) {
        Site site = siteRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Site not found with id: " + id));
        
        // Soft delete - deactivate instead of hard delete
        site.setIsActive(false);
        siteRepository.save(site);
    }

    // ==================== Site Assignment ====================

    @Transactional
    public EmployeeSiteAssignmentResponse assignEmployeeToSite(EmployeeSiteAssignmentRequest request) {
        Employee employee = employeeRepository.findById(Objects.requireNonNull(request.getEmployeeId(), "Employee ID cannot be null"))
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found with id: " + request.getEmployeeId()));

        Site site = siteRepository.findById(Objects.requireNonNull(request.getSiteId(), "Site ID cannot be null"))
                .orElseThrow(() -> new ResourceNotFoundException("Site not found with id: " + request.getSiteId()));

        LocalDate assignmentDate = request.getAssignmentDate() != null ? request.getAssignmentDate() : LocalDate.now();

        // Check if an active assignment already exists
        assignmentRepository.findByEmployeeIdAndSiteIdAndIsActiveTrue(employee.getId(), site.getId())
                .ifPresent(existing -> {
                    throw new BadRequestException("Employee is already assigned to this site");
                });

        // Check if an assignment exists with the same employee, site, and assignment date (active or inactive)
        // If found, reactivate it instead of creating a new one to avoid unique constraint violation
        Optional<EmployeeSiteAssignment> existingAssignment = assignmentRepository
                .findByEmployeeIdAndSiteIdAndAssignmentDate(employee.getId(), site.getId(), assignmentDate);

        EmployeeSiteAssignment assignment;
        if (existingAssignment.isPresent()) {
            // Reactivate existing assignment
            assignment = existingAssignment.get();
            assignment.setIsActive(true);
            assignment.setEndDate(request.getEndDate());
            assignment.setIsPrimary(request.getIsPrimary());
        } else {
            // Create new assignment
            assignment = new EmployeeSiteAssignment();
            assignment.setEmployee(employee);
            assignment.setSite(site);
            assignment.setAssignmentDate(assignmentDate);
            assignment.setEndDate(request.getEndDate());
            assignment.setIsPrimary(request.getIsPrimary());
            assignment.setIsActive(true);
        }

        // If this is primary assignment, remove primary from other assignments
        if (Boolean.TRUE.equals(request.getIsPrimary())) {
            final EmployeeSiteAssignment finalAssignment = assignment;
            assignmentRepository.findPrimaryAssignmentByEmployeeId(employee.getId())
                    .ifPresent(existing -> {
                        if (!existing.getId().equals(finalAssignment.getId())) {
                            existing.setIsPrimary(false);
                            assignmentRepository.save(existing);
                        }
                    });
        }

        EmployeeSiteAssignment savedAssignment = assignmentRepository.save(assignment);
        return EmployeeSiteAssignmentResponse.fromEntity(savedAssignment);
    }

    @Transactional
    public void removeEmployeeFromSite(@NonNull Long assignmentId) {
        EmployeeSiteAssignment assignment = assignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Assignment not found with id: " + assignmentId));

        assignment.setIsActive(false);
        assignment.setEndDate(LocalDate.now());
        assignmentRepository.save(assignment);
    }

    public List<EmployeeSiteAssignmentResponse> getEmployeeAssignments(Long employeeId) {
        return assignmentRepository.findByEmployeeIdAndIsActiveTrue(employeeId).stream()
                .map(EmployeeSiteAssignmentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<EmployeeSiteAssignmentResponse> getSiteEmployees(Long siteId) {
        return assignmentRepository.findBySiteIdWithEmployees(siteId).stream()
                .map(EmployeeSiteAssignmentResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<SiteResponse> getAssignedSitesForEmployee(String employeeId) {
        return assignmentRepository.findByEmployeeCode(employeeId).stream()
                .map(assignment -> SiteResponse.fromEntity(assignment.getSite()))
                .collect(Collectors.toList());
    }

    // ==================== Nearby Sites ====================

    public List<SiteResponse> findNearbySites(double latitude, double longitude, double radiusMeters) {
        Map<String, Double> bbox = geofenceService.getBoundingBox(latitude, longitude, radiusMeters);
        
        List<Site> sites = siteRepository.findSitesInBoundingBox(
                bbox.get("minLat"), bbox.get("maxLat"),
                bbox.get("minLon"), bbox.get("maxLon")
        );

        // Filter by exact distance
        return sites.stream()
                .filter(site -> geofenceService.calculateDistance(
                        latitude, longitude, site.getLatitude(), site.getLongitude()) <= radiusMeters)
                .map(SiteResponse::fromEntity)
                .collect(Collectors.toList());
    }

    // ==================== Helper Methods ====================

    private void updateSiteFromRequest(Site site, SiteRequest request) {
        site.setSiteName(request.getSiteName());
        site.setDescription(request.getDescription());
        site.setAddress(request.getAddress());
        site.setCity(request.getCity());
        site.setState(request.getState());
        site.setPincode(request.getPincode());
        site.setLatitude(request.getLatitude());
        site.setLongitude(request.getLongitude());
        site.setGeofenceType(request.getGeofenceType());
        site.setGeofenceRadiusMeters(request.getGeofenceRadiusMeters());
        site.setGeofencePolygon(request.getGeofencePolygon());
        site.setIsActive(request.getIsActive());
        site.setStartDate(request.getStartDate());
        site.setEndDate(request.getEndDate());
        site.setShiftStartTime(request.getShiftStartTime());
        site.setShiftEndTime(request.getShiftEndTime());
        site.setLunchStartTime(request.getLunchStartTime());
        site.setLunchEndTime(request.getLunchEndTime());
    }

    private String generateSiteCode() {
        return "SITE-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }
}

