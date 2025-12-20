package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.dto.ApiResponse;
import com.civiltech.civildesk_backend.dto.FaceRecognitionResponse;
import com.civiltech.civildesk_backend.service.FaceRecognitionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Objects;

@RestController
@RequestMapping("/api/face")
@CrossOrigin(origins = "*")
public class FaceRecognitionController {

    @Autowired
    private FaceRecognitionService faceRecognitionService;

    @PostMapping("/register")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<FaceRecognitionResponse>> registerFace(
            @RequestParam("employee_id") String employeeId,
            @RequestParam("video") MultipartFile videoFile) {
        try {
            if (videoFile.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Video file is required"));
            }

            FaceRecognitionResponse response = faceRecognitionService.registerFace(employeeId, videoFile);
            
            if (response != null && response.isSuccess()) {
                return ResponseEntity.ok(
                        ApiResponse.success("Face registered successfully", response));
            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(ApiResponse.error("Face registration failed", response, HttpStatus.BAD_REQUEST.value()));
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error registering face: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @PostMapping("/detect")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<FaceRecognitionResponse>> detectFaces(
            @RequestParam("image") MultipartFile imageFile) {
        try {
            if (imageFile.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Image file is required"));
            }

            FaceRecognitionResponse response = faceRecognitionService.detectFaces(imageFile);
            
            return ResponseEntity.ok(
                    ApiResponse.success("Faces detected successfully", response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error detecting faces: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @PostMapping("/detect-annotated")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<byte[]> detectFacesAnnotated(
            @RequestParam("image") MultipartFile imageFile) {
        try {
            if (imageFile.isEmpty()) {
                return ResponseEntity.badRequest().build();
            }

            byte[] annotatedImage = faceRecognitionService.detectFacesAnnotated(imageFile);
            
            if (annotatedImage != null) {
                return ResponseEntity.ok()
                        .contentType(Objects.requireNonNull(MediaType.IMAGE_JPEG, "MediaType.IMAGE_JPEG cannot be null"))
                        .body(annotatedImage);
            } else {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Boolean>> checkHealth() {
        boolean isHealthy = faceRecognitionService.checkServiceHealth();
        if (isHealthy) {
            return ResponseEntity.ok(
                    ApiResponse.success("Face recognition service is healthy", true));
        } else {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(ApiResponse.error("Face recognition service is unavailable", false, HttpStatus.SERVICE_UNAVAILABLE.value()));
        }
    }
}

