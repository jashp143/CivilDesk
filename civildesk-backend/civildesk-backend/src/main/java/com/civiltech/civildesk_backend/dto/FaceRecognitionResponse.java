package com.civiltech.civildesk_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FaceRecognitionResponse {
    private boolean success;
    private List<DetectedFace> faces;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DetectedFace {
        private BoundingBox bbox;
        private double confidence;
        private boolean recognized;
        private String employeeId;
        private double matchConfidence;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BoundingBox {
        private int x1;
        private int y1;
        private int x2;
        private int y2;
    }
}

