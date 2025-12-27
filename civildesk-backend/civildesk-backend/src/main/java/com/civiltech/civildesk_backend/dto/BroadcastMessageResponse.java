package com.civiltech.civildesk_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BroadcastMessageResponse {
    
    private Long id;
    private String title;
    private String message;
    private String priority;
    private String priorityDisplay;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Creator information
    private CreatorInfo createdBy;
    
    // Updater information (if updated)
    private CreatorInfo updatedBy;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreatorInfo {
        private Long id;
        private String name;
        private String email;
        private String role;
    }
}

