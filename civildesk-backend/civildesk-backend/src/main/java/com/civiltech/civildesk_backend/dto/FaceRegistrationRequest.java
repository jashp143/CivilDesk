package com.civiltech.civildesk_backend.dto;

import lombok.Data;

@Data
public class FaceRegistrationRequest {
    private String employeeId;
    // Video file will be sent as multipart/form-data
}

