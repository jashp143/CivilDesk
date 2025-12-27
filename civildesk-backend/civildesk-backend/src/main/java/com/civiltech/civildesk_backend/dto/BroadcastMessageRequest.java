package com.civiltech.civildesk_backend.dto;

import com.civiltech.civildesk_backend.model.BroadcastMessage;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BroadcastMessageRequest {
    
    @NotBlank(message = "Title is required")
    private String title;
    
    @NotBlank(message = "Message is required")
    private String message;
    
    @NotNull(message = "Priority is required")
    private BroadcastMessage.Priority priority;
    
    private Boolean isActive = true;
}

