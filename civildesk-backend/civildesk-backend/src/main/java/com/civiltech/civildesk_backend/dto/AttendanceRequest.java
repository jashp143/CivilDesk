package com.civiltech.civildesk_backend.dto;

import lombok.Data;

@Data
public class AttendanceRequest {
    private String employeeId;
    private String recognitionMethod = "FACE_RECOGNITION";
    private Double faceRecognitionConfidence;
    private String attendanceType; // "PUNCH_IN", "LUNCH_OUT", "LUNCH_IN", "PUNCH_OUT"
    private String action; // Alternative field name for attendanceType (for employee self-service: CHECK_IN, LUNCH_START, LUNCH_END, CHECK_OUT)
    private String remarks;
    
    // Map action to attendanceType if action is provided
    public String getAttendanceType() {
        if (action != null && !action.isEmpty()) {
            switch (action.toUpperCase()) {
                case "CHECK_IN":
                    return "PUNCH_IN";
                case "LUNCH_START":
                    return "LUNCH_OUT";
                case "LUNCH_END":
                    return "LUNCH_IN";
                case "CHECK_OUT":
                    return "PUNCH_OUT";
                default:
                    return action;
            }
        }
        return attendanceType != null ? attendanceType : "PUNCH_IN";
    }
}

