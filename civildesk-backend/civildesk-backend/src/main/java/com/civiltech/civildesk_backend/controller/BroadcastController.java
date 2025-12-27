package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.dto.ApiResponse;
import com.civiltech.civildesk_backend.dto.BroadcastMessageRequest;
import com.civiltech.civildesk_backend.dto.BroadcastMessageResponse;
import com.civiltech.civildesk_backend.service.BroadcastService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/broadcasts")
@CrossOrigin(origins = "*")
public class BroadcastController {

    @Autowired
    private BroadcastService broadcastService;

    // Create broadcast message (Admin/HR only)
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<BroadcastMessageResponse>> createBroadcast(
            @RequestBody BroadcastMessageRequest request) {
        try {
            BroadcastMessageResponse response = broadcastService.createBroadcast(request);
            return ResponseEntity.ok(
                    ApiResponse.success("Broadcast message created successfully and notifications sent to all employees", response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error creating broadcast: " + e.getMessage(), 
                            HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    // Update broadcast message (Admin/HR only)
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<BroadcastMessageResponse>> updateBroadcast(
            @PathVariable Long id,
            @RequestBody BroadcastMessageRequest request) {
        try {
            BroadcastMessageResponse response = broadcastService.updateBroadcast(id, request);
            return ResponseEntity.ok(
                    ApiResponse.success("Broadcast message updated successfully", response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error updating broadcast: " + e.getMessage(), 
                            HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    // Delete broadcast message (Admin/HR only)
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<Void>> deleteBroadcast(@PathVariable Long id) {
        try {
            broadcastService.deleteBroadcast(id);
            return ResponseEntity.ok(
                    ApiResponse.success("Broadcast message deleted successfully", null));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error deleting broadcast: " + e.getMessage(), 
                            HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    // Get broadcast by ID
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<BroadcastMessageResponse>> getBroadcastById(@PathVariable Long id) {
        try {
            BroadcastMessageResponse response = broadcastService.getBroadcastById(id);
            return ResponseEntity.ok(
                    ApiResponse.success("Broadcast message retrieved successfully", response));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("Broadcast message not found: " + e.getMessage(), 
                            HttpStatus.NOT_FOUND.value()));
        }
    }

    // Get all broadcast messages (Admin/HR only)
    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
    public ResponseEntity<ApiResponse<?>> getAllBroadcasts(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String sortDir) {
        try {
            // If pagination parameters are provided, return paginated response
            if (page != null && size != null) {
                Sort sort = Sort.by(Sort.Direction.fromString(sortDir != null ? sortDir : "DESC"), 
                        sortBy != null ? sortBy : "createdAt");
                Pageable pageable = PageRequest.of(page, size, sort);
                Page<BroadcastMessageResponse> pageResponse = broadcastService.getAllBroadcastsPaginated(pageable);
                return ResponseEntity.ok(
                        ApiResponse.success("Broadcast messages retrieved successfully", pageResponse));
            } else {
                // Return list for backward compatibility
                List<BroadcastMessageResponse> responses = broadcastService.getAllBroadcasts();
                return ResponseEntity.ok(
                        ApiResponse.success("Broadcast messages retrieved successfully", responses));
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving broadcast messages: " + e.getMessage(), 
                            HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    // Get active broadcast messages (for employees)
    @GetMapping("/active")
    public ResponseEntity<ApiResponse<?>> getActiveBroadcasts(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size) {
        try {
            // If pagination parameters are provided, return paginated response
            if (page != null && size != null) {
                Sort sort = Sort.by(Sort.Direction.DESC, "priority", "createdAt");
                Pageable pageable = PageRequest.of(page, size, sort);
                Page<BroadcastMessageResponse> pageResponse = broadcastService.getActiveBroadcastsPaginated(pageable);
                return ResponseEntity.ok(
                        ApiResponse.success("Active broadcast messages retrieved successfully", pageResponse));
            } else {
                // Return list for backward compatibility
                List<BroadcastMessageResponse> responses = broadcastService.getActiveBroadcasts();
                return ResponseEntity.ok(
                        ApiResponse.success("Active broadcast messages retrieved successfully", responses));
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error retrieving active broadcast messages: " + e.getMessage(), 
                            HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }
}

