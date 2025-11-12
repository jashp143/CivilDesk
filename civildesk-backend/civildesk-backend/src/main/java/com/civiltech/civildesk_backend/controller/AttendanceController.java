package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.dto.ApiResponse;
import com.civiltech.civildesk_backend.dto.AttendanceRequest;
import com.civiltech.civildesk_backend.dto.AttendanceResponse;
import com.civiltech.civildesk_backend.dto.FaceRecognitionResponse;
import com.civiltech.civildesk_backend.service.AttendanceService;
import com.civiltech.civildesk_backend.service.FaceRecognitionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/attendance")
@CrossOrigin(origins = "*")
public class AttendanceController {

    @Autowired
    private AttendanceService attendanceService;

    @Autowired
    private FaceRecognitionService faceRecognitionService;

    @PostMapping("/mark")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<AttendanceResponse>> markAttendance(
            @RequestParam(value = "image", required = false) MultipartFile imageFile,
            @RequestParam(value = "employee_id", required = false) String employeeId,
            @RequestParam(value = "attendance_type", required = false) String attendanceType) {
        try {
            AttendanceRequest request = new AttendanceRequest();
            
            // If image is provided, try face recognition first
            if (imageFile != null && !imageFile.isEmpty()) {
                FaceRecognitionResponse recognitionResponse = faceRecognitionService.detectFaces(imageFile);
                
                if (recognitionResponse != null && recognitionResponse.isSuccess() && 
                    recognitionResponse.getFaces() != null && !recognitionResponse.getFaces().isEmpty()) {
                    
                    // Find recognized face
                    FaceRecognitionResponse.DetectedFace recognizedFace = recognitionResponse.getFaces().stream()
                            .filter(FaceRecognitionResponse.DetectedFace::isRecognized)
                            .findFirst()
                            .orElse(null);
                    
                    if (recognizedFace != null) {
                        // Face recognition successful
                        request.setEmployeeId(recognizedFace.getEmployeeId());
                        request.setRecognitionMethod("FACE_RECOGNITION");
                        request.setFaceRecognitionConfidence(recognizedFace.getMatchConfidence());
                        request.setAttendanceType(attendanceType);
                    } else if (employeeId != null) {
                        // Face recognition failed but employee_id provided - use it as fallback
                        request.setEmployeeId(employeeId);
                        request.setRecognitionMethod("FACE_RECOGNITION"); // Still using face recognition method since image was sent
                        request.setAttendanceType(attendanceType);
                    } else {
                        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                                .body(ApiResponse.error("No recognized face found in the image and no employee_id provided"));
                    }
                } else {
                    // Face detection failed - fall back to employee_id if provided
                    if (employeeId != null) {
                        request.setEmployeeId(employeeId);
                        request.setRecognitionMethod("FACE_RECOGNITION"); // Still using face recognition method since image was sent
                        request.setAttendanceType(attendanceType);
                    } else {
                        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                                .body(ApiResponse.error("Face detection failed and no employee_id provided"));
                    }
                }
            } else if (employeeId != null) {
                // Manual attendance marking (no image, only employee_id)
                request.setEmployeeId(employeeId);
                request.setRecognitionMethod("MANUAL");
                request.setAttendanceType(attendanceType);
            } else {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Either image file or employee_id is required"));
            }
            
            AttendanceResponse response = attendanceService.markAttendance(request);
            return ResponseEntity.ok(
                    ApiResponse.success("Attendance marked successfully", response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error marking attendance: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @PostMapping("/checkout")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<AttendanceResponse>> checkOut(
            @RequestParam("employee_id") String employeeId) {
        try {
            AttendanceResponse response = attendanceService.checkOut(employeeId);
            return ResponseEntity.ok(
                    ApiResponse.success("Check-out successful", response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error during check-out: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @GetMapping("/today/{employeeId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<AttendanceResponse>> getTodayAttendance(
            @PathVariable String employeeId) {
        try {
            AttendanceResponse response = attendanceService.getTodayAttendance(employeeId);
            if (response != null) {
                return ResponseEntity.ok(
                        ApiResponse.success("Today's attendance retrieved successfully", response));
            } else {
                return ResponseEntity.ok(
                        ApiResponse.success("No attendance record for today", null));
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving attendance: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @GetMapping("/employee/{employeeId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<AttendanceResponse>>> getEmployeeAttendance(
            @PathVariable String employeeId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        try {
            if (startDate == null) {
                startDate = LocalDate.now().minusMonths(1);
            }
            if (endDate == null) {
                endDate = LocalDate.now();
            }
            
            List<AttendanceResponse> responses = attendanceService.getEmployeeAttendance(
                    employeeId, startDate, endDate);
            return ResponseEntity.ok(
                    ApiResponse.success("Attendance records retrieved successfully", responses));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving attendance: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @GetMapping("/daily")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<List<AttendanceResponse>>> getDailyAttendance(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        try {
            if (date == null) {
                date = LocalDate.now();
            }
            
            List<AttendanceResponse> responses = attendanceService.getDailyAttendance(date);
            return ResponseEntity.ok(
                    ApiResponse.success("Daily attendance retrieved successfully", responses));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving daily attendance: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }
}

