package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.dto.TaskRequest;
import com.civiltech.civildesk_backend.dto.TaskResponse;
import com.civiltech.civildesk_backend.dto.TaskReviewRequest;
import com.civiltech.civildesk_backend.exception.BadRequestException;
import com.civiltech.civildesk_backend.exception.ResourceNotFoundException;
import com.civiltech.civildesk_backend.exception.UnauthorizedException;
import com.civiltech.civildesk_backend.model.Employee;
import com.civiltech.civildesk_backend.model.Task;
import com.civiltech.civildesk_backend.model.TaskAssignment;
import com.civiltech.civildesk_backend.model.User;
import com.civiltech.civildesk_backend.repository.EmployeeRepository;
import com.civiltech.civildesk_backend.repository.TaskAssignmentRepository;
import com.civiltech.civildesk_backend.repository.TaskRepository;
import com.civiltech.civildesk_backend.security.SecurityUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
@Transactional
public class TaskService {

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private TaskAssignmentRepository taskAssignmentRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    // Assign task to employees (Admin/HR only)
    @CacheEvict(value = "tasks", allEntries = true)
    public TaskResponse assignTask(TaskRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();

        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can assign tasks");
        }

        // Validate dates
        validateTaskDates(request.getStartDate(), request.getEndDate());

        // Validate employees exist
        List<Employee> employees = new ArrayList<>();
        for (Long employeeId : request.getEmployeeIds()) {
            Employee employee = employeeRepository.findById(Objects.requireNonNull(employeeId, "Employee ID cannot be null"))
                    .orElseThrow(() -> new ResourceNotFoundException("Employee not found with id: " + employeeId));
            if (employee.getDeleted() != null && employee.getDeleted()) {
                throw new BadRequestException("Employee with id " + employeeId + " is deleted");
            }
            employees.add(employee);
        }

        // Create task
        Task task = new Task();
        task.setStartDate(request.getStartDate());
        task.setEndDate(request.getEndDate());
        task.setLocation(request.getLocation());
        task.setDescription(request.getDescription());
        task.setModeOfTravel(request.getModeOfTravel());
        task.setAssignedBy(currentUser);
        task.setStatus(Task.TaskStatus.PENDING);

        task = taskRepository.save(task);

        // Create task assignments
        for (Employee employee : employees) {
            TaskAssignment assignment = new TaskAssignment();
            assignment.setTask(task);
            assignment.setEmployee(employee);
            taskAssignmentRepository.save(assignment);
        }

        return convertToResponse(task);
    }

    // Update task (Admin/HR only, only if status is PENDING)
    @Caching(evict = {
        @CacheEvict(value = "tasks", key = "#taskId"),
        @CacheEvict(value = "tasks", allEntries = true)
    })
    public TaskResponse updateTask(@NonNull Long taskId, TaskRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();

        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can update tasks");
        }

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new ResourceNotFoundException("Task not found with id: " + taskId));

        // Check if task is in PENDING status
        if (task.getStatus() != Task.TaskStatus.PENDING) {
            throw new BadRequestException("Cannot update task that is not in PENDING status");
        }

        // Check if task was assigned by current user
        if (!task.getAssignedBy().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("You can only update tasks assigned by you");
        }

        // Validate dates
        validateTaskDates(request.getStartDate(), request.getEndDate());

        // Update task
        task.setStartDate(request.getStartDate());
        task.setEndDate(request.getEndDate());
        task.setLocation(request.getLocation());
        task.setDescription(request.getDescription());
        task.setModeOfTravel(request.getModeOfTravel());

        // Update task assignments
        // First, soft delete existing assignments
        List<TaskAssignment> existingAssignments = taskAssignmentRepository.findAllByTaskId(taskId);
        for (TaskAssignment assignment : existingAssignments) {
            assignment.setDeleted(true);
            taskAssignmentRepository.save(assignment);
        }

        // Create new assignments
        for (Long employeeId : request.getEmployeeIds()) {
            Employee employee = employeeRepository.findById(Objects.requireNonNull(employeeId, "Employee ID cannot be null"))
                    .orElseThrow(() -> new ResourceNotFoundException("Employee not found with id: " + employeeId));
            
            // Check if assignment already exists (not deleted)
            TaskAssignment existingAssignment = taskAssignmentRepository
                    .findByTaskIdAndEmployeeId(taskId, employeeId)
                    .orElse(null);
            
            if (existingAssignment != null) {
                existingAssignment.setDeleted(false);
                taskAssignmentRepository.save(existingAssignment);
            } else {
                TaskAssignment assignment = new TaskAssignment();
                assignment.setTask(task);
                assignment.setEmployee(employee);
                taskAssignmentRepository.save(assignment);
            }
        }

        task = taskRepository.save(task);

        return convertToResponse(task);
    }

    // Delete task (Admin/HR only, only if status is PENDING)
    @Caching(evict = {
        @CacheEvict(value = "tasks", key = "#taskId"),
        @CacheEvict(value = "tasks", allEntries = true)
    })
    public void deleteTask(@NonNull Long taskId) {
        User currentUser = SecurityUtils.getCurrentUser();

        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can delete tasks");
        }

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new ResourceNotFoundException("Task not found with id: " + taskId));

        // Check if task is in PENDING status
        if (task.getStatus() != Task.TaskStatus.PENDING) {
            throw new BadRequestException("Cannot delete task that is not in PENDING status");
        }

        // Check if task was assigned by current user
        if (!task.getAssignedBy().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("You can only delete tasks assigned by you");
        }

        // Soft delete task
        task.setDeleted(true);
        taskRepository.save(task);

        // Soft delete all task assignments
        List<TaskAssignment> assignments = taskAssignmentRepository.findAllByTaskId(taskId);
        for (TaskAssignment assignment : assignments) {
            assignment.setDeleted(true);
            taskAssignmentRepository.save(assignment);
        }
    }

    // Get all tasks assigned to current employee
    @Cacheable(value = "tasks", key = "'my-tasks:' + T(com.civiltech.civildesk_backend.security.SecurityUtils).getCurrentUserId()")
    @Transactional(readOnly = true)
    public List<TaskResponse> getMyTasks() {
        User currentUser = SecurityUtils.getCurrentUser();

        Employee employee = employeeRepository.findByUserIdAndDeletedFalse(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found for current user"));

        List<Task> tasks = taskRepository.findByEmployeeId(employee.getId());

        return tasks.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get tasks by status for current employee
    @Cacheable(value = "tasks", key = "'my-tasks-status:' + T(com.civiltech.civildesk_backend.security.SecurityUtils).getCurrentUserId() + ':' + #status")
    @Transactional(readOnly = true)
    public List<TaskResponse> getMyTasksByStatus(Task.TaskStatus status) {
        User currentUser = SecurityUtils.getCurrentUser();

        Employee employee = employeeRepository.findByUserIdAndDeletedFalse(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found for current user"));

        List<Task> tasks = taskRepository.findByEmployeeIdAndStatus(employee.getId(), status);

        return tasks.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    // Get all tasks (Admin/HR only) - shows all tasks assigned to all employees
    @Cacheable(value = "tasks", key = "'all-tasks'")
    @Transactional(readOnly = true)
    public List<TaskResponse> getAllTasks() {
        User currentUser = SecurityUtils.getCurrentUser();

        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can view all tasks");
        }

        List<Task> tasks = taskRepository.findByDeletedFalseOrderByCreatedAtDesc();

        // Batch fetch all assignments to avoid N+1 queries
        List<Long> taskIds = tasks.stream().map(Task::getId).toList();
        List<TaskAssignment> allAssignments = taskAssignmentRepository.findByTaskIds(taskIds);
        
        // Create a map of task ID to assignments for efficient lookup
        java.util.Map<Long, List<TaskAssignment>> assignmentsByTaskId = allAssignments.stream()
                .collect(Collectors.groupingBy(ta -> ta.getTask().getId()));

        return tasks.stream()
                .map(task -> convertToResponseWithAssignments(task, assignmentsByTaskId.getOrDefault(task.getId(), new ArrayList<>())))
                .collect(Collectors.toList());
    }

    // Get tasks by status (Admin/HR only)
    @Cacheable(value = "tasks", key = "'tasks-status:' + #status")
    @Transactional(readOnly = true)
    public List<TaskResponse> getTasksByStatus(Task.TaskStatus status) {
        User currentUser = SecurityUtils.getCurrentUser();

        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can filter tasks");
        }

        List<Task> tasks = taskRepository.findByStatusAndDeletedFalse(status);

        // Batch fetch all assignments to avoid N+1 queries
        List<Long> taskIds = tasks.stream().map(Task::getId).toList();
        List<TaskAssignment> allAssignments = taskAssignmentRepository.findByTaskIds(taskIds);
        
        // Create a map of task ID to assignments for efficient lookup
        java.util.Map<Long, List<TaskAssignment>> assignmentsByTaskId = allAssignments.stream()
                .collect(Collectors.groupingBy(ta -> ta.getTask().getId()));

        return tasks.stream()
                .map(task -> convertToResponseWithAssignments(task, assignmentsByTaskId.getOrDefault(task.getId(), new ArrayList<>())))
                .collect(Collectors.toList());
    }

    // Paginated methods
    @Transactional(readOnly = true)
    public Page<TaskResponse> getAllTasksPaginated(String status, Pageable pageable) {
        User currentUser = SecurityUtils.getCurrentUser();

        // Check if user has admin or HR role
        if (currentUser.getRole() != User.Role.ADMIN && currentUser.getRole() != User.Role.HR_MANAGER) {
            throw new UnauthorizedException("Only admin or HR can view all tasks");
        }

        Page<Task> tasks;
        
        if (status != null && !status.isEmpty()) {
            try {
                Task.TaskStatus taskStatus = Task.TaskStatus.valueOf(status.toUpperCase());
                tasks = taskRepository.findByStatusAndDeletedFalse(taskStatus, pageable);
            } catch (IllegalArgumentException e) {
                throw new BadRequestException("Invalid status value: " + status);
            }
        } else {
            tasks = taskRepository.findByDeletedFalseOrderByCreatedAtDesc(pageable);
        }

        // Batch fetch all assignments to avoid N+1 queries
        List<Long> taskIds = tasks.getContent().stream().map(Task::getId).toList();
        List<TaskAssignment> allAssignments = taskAssignmentRepository.findByTaskIds(taskIds);
        
        // Create a map of task ID to assignments for efficient lookup
        java.util.Map<Long, List<TaskAssignment>> assignmentsByTaskId = allAssignments.stream()
                .collect(Collectors.groupingBy(ta -> ta.getTask().getId()));

        return tasks.map(task -> convertToResponseWithAssignments(task, assignmentsByTaskId.getOrDefault(task.getId(), new ArrayList<>())));
    }

    // Get task by ID
    @Cacheable(value = "tasks", key = "#taskId")
    @Transactional(readOnly = true)
    public TaskResponse getTaskById(@NonNull Long taskId) {
        User currentUser = SecurityUtils.getCurrentUser();

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new ResourceNotFoundException("Task not found with id: " + taskId));

        // Check if user is authorized to view this task
        if (currentUser.getRole() == User.Role.EMPLOYEE) {
            Employee employee = employeeRepository.findByUserIdAndDeletedFalse(currentUser.getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Employee not found for current user"));

            // Check if task is assigned to this employee
            TaskAssignment assignment = taskAssignmentRepository
                    .findByTaskIdAndEmployeeId(taskId, employee.getId())
                    .orElse(null);

            if (assignment == null || (assignment.getDeleted() != null && assignment.getDeleted())) {
                throw new UnauthorizedException("You are not authorized to view this task");
            }
        }

        return convertToResponse(task);
    }

    // Review task (Approve/Reject) - Employee only
    @Caching(evict = {
        @CacheEvict(value = "tasks", key = "#taskId"),
        @CacheEvict(value = "tasks", allEntries = true)
    })
    public TaskResponse reviewTask(@NonNull Long taskId, TaskReviewRequest request) {
        User currentUser = SecurityUtils.getCurrentUser();

        if (currentUser.getRole() != User.Role.EMPLOYEE) {
            throw new UnauthorizedException("Only employees can review tasks");
        }

        Employee employee = employeeRepository.findByUserIdAndDeletedFalse(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Employee not found for current user"));

        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new ResourceNotFoundException("Task not found with id: " + taskId));

        // Check if task is assigned to this employee
        TaskAssignment assignment = taskAssignmentRepository
                .findByTaskIdAndEmployeeId(taskId, employee.getId())
                .orElse(null);

        if (assignment == null || (assignment.getDeleted() != null && assignment.getDeleted())) {
            throw new UnauthorizedException("You are not authorized to review this task");
        }

        // Check if task is in PENDING status
        if (task.getStatus() != Task.TaskStatus.PENDING) {
            throw new BadRequestException("Can only review tasks in PENDING status");
        }

        // Validate status
        if (request.getStatus() != Task.TaskStatus.APPROVED && 
            request.getStatus() != Task.TaskStatus.REJECTED) {
            throw new BadRequestException("Status must be either APPROVED or REJECTED");
        }

        // Update task
        task.setStatus(request.getStatus());
        task.setReviewedAt(LocalDateTime.now());
        task.setReviewNote(request.getReviewNote());

        task = taskRepository.save(task);

        return convertToResponse(task);
    }

    // Helper method to validate dates
    private void validateTaskDates(java.time.LocalDate startDate, java.time.LocalDate endDate) {
        if (endDate.isBefore(startDate)) {
            throw new BadRequestException("End date cannot be before start date");
        }
    }

    // Helper method to convert Task entity to TaskResponse
    private TaskResponse convertToResponse(Task task) {
        // Fetch assignments for this single task (used when converting individual tasks)
        List<TaskAssignment> assignments = taskAssignmentRepository.findByTaskIdAndDeletedFalse(task.getId());
        return convertToResponseWithAssignments(task, assignments);
    }
    
    // Helper method to convert Task entity to TaskResponse with pre-fetched assignments
    // This avoids N+1 queries when converting multiple tasks
    private TaskResponse convertToResponseWithAssignments(Task task, List<TaskAssignment> assignments) {
        TaskResponse response = new TaskResponse();
        response.setId(task.getId());
        response.setStartDate(task.getStartDate());
        response.setEndDate(task.getEndDate());
        response.setLocation(task.getLocation());
        response.setDescription(task.getDescription());
        response.setModeOfTravel(task.getModeOfTravel());
        response.setModeOfTravelDisplay(task.getModeOfTravel());
        response.setStatus(task.getStatus());
        response.setStatusDisplay(task.getStatus().getDisplayName());
        response.setReviewedAt(task.getReviewedAt());
        response.setReviewNote(task.getReviewNote());
        response.setCreatedAt(task.getCreatedAt());
        response.setUpdatedAt(task.getUpdatedAt());

        // Set assigned by info
        if (task.getAssignedBy() != null) {
            TaskResponse.AssignedByInfo assignedByInfo = new TaskResponse.AssignedByInfo();
            assignedByInfo.setId(task.getAssignedBy().getId());
            assignedByInfo.setName(task.getAssignedBy().getFirstName() + " " + task.getAssignedBy().getLastName());
            assignedByInfo.setEmail(task.getAssignedBy().getEmail());
            assignedByInfo.setRole(task.getAssignedBy().getRole().name());
            response.setAssignedBy(assignedByInfo);
        }

        // Set assigned employees using pre-fetched assignments
        List<TaskResponse.AssignedEmployeeInfo> assignedEmployees = new ArrayList<>();
        for (TaskAssignment assignment : assignments) {
            Employee emp = assignment.getEmployee();
            TaskResponse.AssignedEmployeeInfo info = new TaskResponse.AssignedEmployeeInfo();
            info.setId(emp.getId());
            info.setName(emp.getFirstName() + " " + emp.getLastName());
            info.setEmployeeId(emp.getEmployeeId());
            info.setEmail(emp.getEmail());
            info.setDesignation(emp.getDesignation());
            info.setDepartment(emp.getDepartment());
            assignedEmployees.add(info);
        }
        response.setAssignedEmployees(assignedEmployees);

        return response;
    }
}
