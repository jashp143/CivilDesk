package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.annotation.RequiresRole;
import com.civiltech.civildesk_backend.dto.ApiResponse;
import com.civiltech.civildesk_backend.dto.TaskRequest;
import com.civiltech.civildesk_backend.dto.TaskResponse;
import com.civiltech.civildesk_backend.dto.TaskReviewRequest;
import com.civiltech.civildesk_backend.model.Task;
import com.civiltech.civildesk_backend.service.TaskService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tasks")
@CrossOrigin(origins = "*")
public class TaskController {

    @Autowired
    private TaskService taskService;

    // Assign task to employees (Admin/HR only)
    @PostMapping
    @RequiresRole({"ADMIN", "HR_MANAGER"})
    public ResponseEntity<ApiResponse<TaskResponse>> assignTask(@Valid @RequestBody TaskRequest request) {
        TaskResponse response = taskService.assignTask(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Task assigned successfully", response));
    }

    // Update task (Admin/HR only)
    @PutMapping("/{taskId}")
    @RequiresRole({"ADMIN", "HR_MANAGER"})
    public ResponseEntity<ApiResponse<TaskResponse>> updateTask(
            @PathVariable Long taskId,
            @Valid @RequestBody TaskRequest request) {
        TaskResponse response = taskService.updateTask(taskId, request);
        return ResponseEntity.ok(ApiResponse.success("Task updated successfully", response));
    }

    // Delete task (Admin/HR only)
    @DeleteMapping("/{taskId}")
    @RequiresRole({"ADMIN", "HR_MANAGER"})
    public ResponseEntity<ApiResponse<Void>> deleteTask(@PathVariable Long taskId) {
        taskService.deleteTask(taskId);
        return ResponseEntity.ok(ApiResponse.success("Task deleted successfully", null));
    }

    // Get my tasks (current employee)
    @GetMapping("/my-tasks")
    public ResponseEntity<ApiResponse<List<TaskResponse>>> getMyTasks() {
        List<TaskResponse> tasks = taskService.getMyTasks();
        return ResponseEntity.ok(ApiResponse.success("Tasks fetched successfully", tasks));
    }

    // Get all tasks (Admin/HR only)
    @GetMapping
    @RequiresRole({"ADMIN", "HR_MANAGER"})
    public ResponseEntity<ApiResponse<List<TaskResponse>>> getAllTasks(
            @RequestParam(required = false) String status) {
        
        List<TaskResponse> tasks;

        if (status != null && !status.isEmpty()) {
            try {
                Task.TaskStatus taskStatus = Task.TaskStatus.valueOf(status.toUpperCase());
                tasks = taskService.getTasksByStatus(taskStatus);
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Invalid status value", 400));
            }
        } else {
            tasks = taskService.getAllTasks();
        }

        return ResponseEntity.ok(ApiResponse.success("Tasks fetched successfully", tasks));
    }

    // Get task by ID
    @GetMapping("/{taskId}")
    public ResponseEntity<ApiResponse<TaskResponse>> getTaskById(@PathVariable Long taskId) {
        TaskResponse task = taskService.getTaskById(taskId);
        return ResponseEntity.ok(ApiResponse.success("Task fetched successfully", task));
    }

    // Review task (Approve/Reject) - Employee only
    @PutMapping("/{taskId}/review")
    public ResponseEntity<ApiResponse<TaskResponse>> reviewTask(
            @PathVariable Long taskId,
            @Valid @RequestBody TaskReviewRequest request) {
        TaskResponse response = taskService.reviewTask(taskId, request);
        return ResponseEntity.ok(ApiResponse.success("Task reviewed successfully", response));
    }

    // Get all task statuses
    @GetMapping("/statuses")
    public ResponseEntity<ApiResponse<List<String>>> getTaskStatuses() {
        List<String> statuses = List.of(
                "PENDING",
                "APPROVED",
                "REJECTED"
        );
        return ResponseEntity.ok(ApiResponse.success("Task statuses fetched successfully", statuses));
    }

    // Get all modes of travel
    @GetMapping("/modes-of-travel")
    public ResponseEntity<ApiResponse<List<String>>> getModesOfTravel() {
        List<String> modes = List.of(
                "CAR",
                "BIKE",
                "TRAIN",
                "BUS",
                "FLIGHT",
                "TAXI",
                "OTHER"
        );
        return ResponseEntity.ok(ApiResponse.success("Modes of travel fetched successfully", modes));
    }
}
