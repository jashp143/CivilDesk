package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.FaceRecognitionResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Objects;

@Service
public class FaceRecognitionService {

    @Value("${face.recognition.service.url:http://localhost:8000}")
    private String faceServiceUrl;

    private final RestTemplate restTemplate;

    public FaceRecognitionService() {
        this.restTemplate = new RestTemplate();
    }

    public FaceRecognitionResponse registerFace(String employeeId, MultipartFile videoFile) throws IOException {
        String url = faceServiceUrl + "/face/register";
        
        // Create temporary file
        Path tempFile = Files.createTempFile("face_reg_", ".mp4");
        try {
            File file = Objects.requireNonNull(tempFile.toFile(), "Temporary file cannot be null");
            videoFile.transferTo(file);
            
            // Prepare request
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);
            
            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("video", new FileSystemResource(file));
            body.add("employee_id", employeeId);
            
            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);
            
            // Make request - Flask returns a different structure
            HttpMethod httpMethod = Objects.requireNonNull(HttpMethod.POST, "HTTP method cannot be null");
            ResponseEntity<java.util.Map<String, Object>> response = 
                restTemplate.exchange(url, httpMethod, requestEntity, 
                    new org.springframework.core.ParameterizedTypeReference<java.util.Map<String, Object>>() {});
            
            java.util.Map<String, Object> responseBody = response.getBody();
            FaceRecognitionResponse result = new FaceRecognitionResponse();
            if (responseBody != null && (Boolean) responseBody.getOrDefault("success", false)) {
                result.setSuccess(true);
            } else {
                result.setSuccess(false);
            }
            result.setFaces(java.util.Collections.emptyList());
            
            return result;
        } finally {
            // Clean up temp file
            Files.deleteIfExists(tempFile);
        }
    }

    public FaceRecognitionResponse detectFaces(MultipartFile imageFile) throws IOException {
        String url = faceServiceUrl + "/face/detect";
        
        // Create temporary file
        Path tempFile = Files.createTempFile("face_detect_", ".jpg");
        try {
            File file = Objects.requireNonNull(tempFile.toFile(), "Temporary file cannot be null");
            imageFile.transferTo(file);
            
            // Prepare request
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);
            
            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("image", new FileSystemResource(file));
            
            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);
            
            // Make request - Flask returns a different structure
            HttpMethod httpMethod = Objects.requireNonNull(HttpMethod.POST, "HTTP method cannot be null");
            ResponseEntity<java.util.Map<String, Object>> response = 
                restTemplate.exchange(url, httpMethod, requestEntity, 
                    new org.springframework.core.ParameterizedTypeReference<java.util.Map<String, Object>>() {});
            
            java.util.Map<String, Object> responseBody = response.getBody();
            FaceRecognitionResponse result = new FaceRecognitionResponse();
            
            if (responseBody != null && (Boolean) responseBody.getOrDefault("success", false)) {
                result.setSuccess(true);
                
                // Parse faces from response
                java.util.List<FaceRecognitionResponse.DetectedFace> faces = new java.util.ArrayList<>();
                @SuppressWarnings("unchecked")
                java.util.List<java.util.Map<String, Object>> facesList = 
                    (java.util.List<java.util.Map<String, Object>>) responseBody.get("faces");
                
                if (facesList != null) {
                    for (java.util.Map<String, Object> faceData : facesList) {
                        FaceRecognitionResponse.DetectedFace face = new FaceRecognitionResponse.DetectedFace();
                        
                        // Parse bounding box
                        @SuppressWarnings("unchecked")
                        java.util.Map<String, Object> bbox = (java.util.Map<String, Object>) faceData.get("bbox");
                        if (bbox != null) {
                            FaceRecognitionResponse.BoundingBox boundingBox = new FaceRecognitionResponse.BoundingBox();
                            boundingBox.setX1(((Number) bbox.get("x1")).intValue());
                            boundingBox.setY1(((Number) bbox.get("y1")).intValue());
                            boundingBox.setX2(((Number) bbox.get("x2")).intValue());
                            boundingBox.setY2(((Number) bbox.get("y2")).intValue());
                            face.setBbox(boundingBox);
                        }
                        
                        face.setConfidence(((Number) faceData.getOrDefault("confidence", 0.0)).doubleValue());
                        face.setRecognized((Boolean) faceData.getOrDefault("recognized", false));
                        face.setEmployeeId((String) faceData.get("employee_id"));
                        face.setMatchConfidence(((Number) faceData.getOrDefault("match_confidence", 0.0)).doubleValue());
                        
                        faces.add(face);
                    }
                }
                
                result.setFaces(faces);
            } else {
                result.setSuccess(false);
                result.setFaces(java.util.Collections.emptyList());
            }
            
            return result;
        } finally {
            // Clean up temp file
            Files.deleteIfExists(tempFile);
        }
    }

    public byte[] detectFacesAnnotated(MultipartFile imageFile) throws IOException {
        String url = faceServiceUrl + "/face/recognize-annotated";
        
        // Create temporary file
        Path tempFile = Files.createTempFile("face_annotate_", ".jpg");
        try {
            File file = Objects.requireNonNull(tempFile.toFile(), "Temporary file cannot be null");
            imageFile.transferTo(file);
            
            // Prepare request
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);
            
            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("image", new FileSystemResource(file));
            
            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);
            
            // Make request - returns image bytes
            HttpMethod httpMethod = Objects.requireNonNull(HttpMethod.POST, "HTTP method cannot be null");
            ResponseEntity<byte[]> response = restTemplate.exchange(
                url, 
                httpMethod, 
                requestEntity, 
                byte[].class
            );
            
            return response.getBody();
        } finally {
            // Clean up temp file
            Files.deleteIfExists(tempFile);
        }
    }

    public boolean checkServiceHealth() {
        try {
            String url = faceServiceUrl + "/health";
            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Delete face embeddings for an employee
     * @param employeeId The employee ID (employee_id field, not database ID)
     * @return true if deleted successfully, false if not found or error occurred
     */
    public boolean deleteFaceEmbeddings(String employeeId) {
        try {
            String url = faceServiceUrl + "/face/embeddings/" + employeeId;
            ResponseEntity<java.util.Map<String, Object>> response = restTemplate.exchange(
                url,
                Objects.requireNonNull(HttpMethod.DELETE, "HttpMethod.DELETE cannot be null"),
                null,
                new org.springframework.core.ParameterizedTypeReference<java.util.Map<String, Object>>() {}
            );
            
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                java.util.Map<String, Object> responseBody = Objects.requireNonNull(response.getBody(), "Response body cannot be null");
                return (Boolean) responseBody.getOrDefault("success", false);
            }
            return false;
        } catch (Exception e) {
            // If employee doesn't have face embeddings, that's okay - return false silently
            // Log the exception for debugging purposes
            System.err.println("Error deleting face embeddings for employee " + employeeId + ": " + e.getMessage());
            return false;
        }
    }
}

