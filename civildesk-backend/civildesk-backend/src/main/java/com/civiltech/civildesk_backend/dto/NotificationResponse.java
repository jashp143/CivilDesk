package com.civiltech.civildesk_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class NotificationResponse {
    private Long id;
    private String title;
    private String body;
    private String type;
    private Map<String, String> data;
    private Boolean isRead;
    private LocalDateTime createdAt;
    private LocalDateTime readAt;
}

