package com.civiltech.civildesk_backend.dto;

import lombok.Data;

@Data
public class AttendanceRequest {
    private String employeeId;
    private String recognitionMethod = "FACE_RECOGNITION";
    private Double faceRecognitionConfidence;
    private String attendanceType; // "PUNCH_IN", "LUNCH_OUT", "LUNCH_IN", "PUNCH_OUT"
}

