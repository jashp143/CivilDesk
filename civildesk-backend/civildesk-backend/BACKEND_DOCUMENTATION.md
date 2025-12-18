# CivilDesk Backend Documentation

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Project Structure](#project-structure)
5. [Database Schema](#database-schema)
6. [API Endpoints](#api-endpoints)
7. [Authentication & Security](#authentication--security)
8. [Services & Business Logic](#services--business-logic)
9. [Face Recognition Service](#face-recognition-service)
10. [Configuration](#configuration)
11. [Deployment](#deployment)
12. [Development Guide](#development-guide)

---

## Overview

CivilDesk Backend is a comprehensive employee management system built with Spring Boot. It provides RESTful APIs for managing employees, attendance, leaves, tasks, expenses, salaries, and more. The system includes a separate Python-based face recognition service for biometric attendance tracking.

### Key Features

- **Employee Management**: Complete CRUD operations for employee records
- **Attendance Tracking**: Face recognition and GPS-based attendance marking
- **Leave Management**: Leave application, approval, and tracking
- **Task Management**: Task assignment and tracking
- **Expense Management**: Employee expense tracking and approval
- **Salary Management**: Salary calculation and slip generation
- **Dashboard Analytics**: Real-time statistics and reports
- **Face Recognition**: Biometric attendance using InsightFace
- **GPS Attendance**: Location-based attendance for field employees
- **Role-Based Access Control**: Admin, HR Manager, and Employee roles

---

## Architecture

### System Architecture

```
┌─────────────────┐
│   Frontend Apps  │
│  (Flutter/Web)   │
└────────┬─────────┘
         │
         │ HTTP/REST
         │
┌────────▼─────────────────────────────────────┐
│         Spring Boot Backend (Java)            │
│  ┌─────────────────────────────────────────┐ │
│  │  Controllers (REST API)                 │ │
│  └──────────────┬──────────────────────────┘ │
│                 │                            │
│  ┌──────────────▼──────────────────────────┐ │
│  │  Services (Business Logic)              │ │
│  └──────────────┬──────────────────────────┘ │
│                 │                            │
│  ┌──────────────▼──────────────────────────┐ │
│  │  Repositories (Data Access)            │ │
│  └──────────────┬──────────────────────────┘ │
└─────────────────┼────────────────────────────┘
                  │
         ┌────────┴────────┐
         │                 │
┌────────▼────────┐ ┌──────▼──────────────┐
│   PostgreSQL    │ │   Redis (Cache)     │
│   Database      │ │   (Optional)        │
└─────────────────┘ └─────────────────────┘
         │
         │
┌────────▼─────────────────────────────────────┐
│   Face Recognition Service (Python/FastAPI)  │
│  ┌─────────────────────────────────────────┐ │
│  │  InsightFace Engine                    │ │
│  │  - Face Detection                      │ │
│  │  - Face Recognition                    │ │
│  │  - Embedding Storage                   │ │
│  └─────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

### Component Layers

1. **Controller Layer**: Handles HTTP requests and responses
2. **Service Layer**: Contains business logic and orchestration
3. **Repository Layer**: Data access and persistence
4. **Model Layer**: Entity definitions and relationships
5. **Security Layer**: Authentication and authorization
6. **DTO Layer**: Data Transfer Objects for API communication

---

## Technology Stack

### Core Technologies

- **Java 17**: Programming language
- **Spring Boot 3.5.7**: Application framework
- **Spring Security**: Authentication and authorization
- **Spring Data JPA**: Database abstraction
- **PostgreSQL 15**: Relational database
- **Redis 7**: Caching (optional)
- **Maven**: Build tool
- **JWT (jjwt 0.12.3)**: Token-based authentication

### Additional Libraries

- **Lombok**: Reduces boilerplate code
- **Jakarta Validation**: Input validation
- **Spring Mail**: Email notifications
- **Dotenv Java**: Environment variable management
- **HikariCP**: Connection pooling

### Face Recognition Service

- **Python 3.8+**: Programming language
- **FastAPI**: Web framework
- **InsightFace**: Face recognition engine
- **OpenCV**: Image processing
- **ONNX Runtime**: Model inference (CPU/GPU)
- **PostgreSQL**: Database connection
- **Redis**: Caching (optional)

---

## Project Structure

```
civildesk-backend/
├── civildesk-backend/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/
│   │   │   │   └── com/civiltech/civildesk_backend/
│   │   │   │       ├── annotation/          # Custom annotations
│   │   │   │       │   └── RequiresRole.java
│   │   │   │       ├── config/              # Configuration classes
│   │   │   │       │   ├── AsyncConfig.java
│   │   │   │       │   ├── DotEnvConfig.java
│   │   │   │       │   ├── RedisConfig.java
│   │   │   │       │   ├── SecurityConfig.java
│   │   │   │       │   ├── WebConfig.java
│   │   │   │       │   └── WebMvcConfig.java
│   │   │   │       ├── controller/          # REST Controllers
│   │   │   │       │   ├── AttendanceController.java
│   │   │   │       │   ├── AuthController.java
│   │   │   │       │   ├── DashboardController.java
│   │   │   │       │   ├── EmployeeController.java
│   │   │   │       │   ├── ExpenseController.java
│   │   │   │       │   ├── FaceRecognitionController.java
│   │   │   │       │   ├── FileUploadController.java
│   │   │   │       │   ├── GpsAttendanceController.java
│   │   │   │       │   ├── HolidayController.java
│   │   │   │       │   ├── LeaveController.java
│   │   │   │       │   ├── OvertimeController.java
│   │   │   │       │   ├── SalaryController.java
│   │   │   │       │   ├── SiteController.java
│   │   │   │       │   └── TaskController.java
│   │   │   │       ├── dto/                 # Data Transfer Objects
│   │   │   │       │   ├── ApiResponse.java
│   │   │   │       │   ├── AuthResponse.java
│   │   │   │       │   ├── EmployeeRequest.java
│   │   │   │       │   ├── EmployeeResponse.java
│   │   │   │       │   └── ... (41 DTOs total)
│   │   │   │       ├── exception/           # Exception handlers
│   │   │   │       │   ├── BadRequestException.java
│   │   │   │       │   ├── GlobalExceptionHandler.java
│   │   │   │       │   ├── ResourceNotFoundException.java
│   │   │   │       │   └── UnauthorizedException.java
│   │   │   │       ├── model/               # Entity models
│   │   │   │       │   ├── Attendance.java
│   │   │   │       │   ├── BaseEntity.java
│   │   │   │       │   ├── Employee.java
│   │   │   │       │   ├── Expense.java
│   │   │   │       │   ├── Holiday.java
│   │   │   │       │   ├── Leave.java
│   │   │   │       │   ├── Overtime.java
│   │   │   │       │   ├── SalarySlip.java
│   │   │   │       │   ├── Site.java
│   │   │   │       │   ├── Task.java
│   │   │   │       │   └── User.java
│   │   │   │       ├── repository/          # JPA Repositories
│   │   │   │       │   ├── AttendanceRepository.java
│   │   │   │       │   ├── EmployeeRepository.java
│   │   │   │       │   ├── LeaveRepository.java
│   │   │   │       │   └── ... (14 repositories)
│   │   │   │       ├── security/            # Security components
│   │   │   │       │   ├── CustomUserDetailsService.java
│   │   │   │       │   ├── JwtAuthenticationFilter.java
│   │   │   │       │   ├── JwtTokenProvider.java
│   │   │   │       │   └── SecurityUtils.java
│   │   │   │       ├── service/             # Business logic services
│   │   │   │       │   ├── AttendanceService.java
│   │   │   │       │   ├── EmployeeService.java
│   │   │   │       │   ├── LeaveService.java
│   │   │   │       │   ├── TaskService.java
│   │   │   │       │   └── ... (18 services)
│   │   │   │       └── util/                # Utility classes
│   │   │   │           └── CommonUtils.java
│   │   │   └── resources/
│   │   │       ├── application.properties
│   │   │       ├── application-dev.properties
│   │   │       ├── application-prod.properties
│   │   │       └── db/migration/            # Database migrations
│   │   └── test/                            # Test files
│   ├── database/
│   │   ├── migrations/                      # SQL migration scripts
│   │   └── postgresql_optimization.conf
│   ├── pom.xml                              # Maven dependencies
│   └── README.md
├── docker-compose.yml                       # Docker services
├── Dockerfile                               # Backend container
└── deploy.sh                                # Deployment script
```

---

## Database Schema

### Core Tables

#### `users`
Stores user authentication and basic information.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| email | VARCHAR(255) | Unique email address |
| password | VARCHAR(255) | BCrypt hashed password |
| first_name | VARCHAR(100) | First name |
| last_name | VARCHAR(100) | Last name |
| role | VARCHAR(20) | ADMIN, HR_MANAGER, EMPLOYEE |
| is_active | BOOLEAN | Account status |
| email_verified | BOOLEAN | Email verification status |
| otp | VARCHAR(6) | OTP for email verification |
| otp_expiry | TIMESTAMP | OTP expiration time |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

#### `employees`
Stores comprehensive employee information.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| employee_id | VARCHAR(50) | Unique employee ID |
| user_id | BIGINT | Foreign key to users |
| first_name | VARCHAR(100) | First name |
| last_name | VARCHAR(100) | Last name |
| email | VARCHAR(255) | Email address |
| phone_number | VARCHAR(10) | Phone number |
| department | VARCHAR(100) | Department |
| designation | VARCHAR(100) | Job title |
| employment_type | VARCHAR(20) | FULL_TIME, PART_TIME, etc. |
| employment_status | VARCHAR(20) | ACTIVE, INACTIVE, etc. |
| attendance_method | VARCHAR(30) | FACE_RECOGNITION, GPS_BASED |
| basic_salary | DECIMAL | Basic salary |
| total_salary | DECIMAL | Total salary |
| aadhar_number | VARCHAR(12) | Aadhar number |
| pan_number | VARCHAR(10) | PAN number |
| bank_account_number | VARCHAR(50) | Bank account |
| ifsc_code | VARCHAR(11) | IFSC code |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

#### `attendance`
Stores attendance records with multiple punch types.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| employee_id | VARCHAR(50) | Foreign key to employees |
| attendance_date | DATE | Attendance date |
| check_in_time | TIMESTAMP | Check-in time |
| lunch_out_time | TIMESTAMP | Lunch break start |
| lunch_in_time | TIMESTAMP | Lunch break end |
| check_out_time | TIMESTAMP | Check-out time |
| working_hours | DECIMAL | Total working hours |
| recognition_method | VARCHAR(20) | FACE_RECOGNITION, GPS_BASED, MANUAL |
| face_recognition_confidence | DECIMAL | Confidence score (0-1) |
| status | VARCHAR(20) | PRESENT, ABSENT, LATE, etc. |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

#### `leaves`
Stores leave applications and approvals.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| employee_id | VARCHAR(50) | Foreign key to employees |
| leave_type | VARCHAR(50) | SICK_LEAVE, CASUAL_LEAVE, etc. |
| start_date | DATE | Leave start date |
| end_date | DATE | Leave end date |
| is_half_day | BOOLEAN | Half-day leave flag |
| half_day_period | VARCHAR(10) | FIRST_HALF, SECOND_HALF |
| reason | TEXT | Leave reason |
| medical_certificate_url | VARCHAR(500) | Medical certificate URL |
| status | VARCHAR(20) | PENDING, APPROVED, REJECTED, CANCELLED |
| reviewed_by | BIGINT | Foreign key to users (reviewer) |
| reviewed_at | TIMESTAMP | Review timestamp |
| reviewer_notes | TEXT | Reviewer comments |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

#### `tasks`
Stores task assignments.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| site_id | BIGINT | Foreign key to sites |
| title | VARCHAR(255) | Task title |
| description | TEXT | Task description |
| assigned_to | VARCHAR(50) | Foreign key to employees |
| assigned_by | BIGINT | Foreign key to users |
| due_date | DATE | Task due date |
| status | VARCHAR(20) | PENDING, APPROVED, REJECTED |
| mode_of_travel | VARCHAR(20) | CAR, BIKE, TRAIN, etc. |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

#### `expenses`
Stores employee expense claims.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| employee_id | VARCHAR(50) | Foreign key to employees |
| expense_type | VARCHAR(50) | TRAVEL, MEAL, ACCOMMODATION, etc. |
| amount | DECIMAL | Expense amount |
| description | TEXT | Expense description |
| receipt_url | VARCHAR(500) | Receipt image URL |
| status | VARCHAR(20) | PENDING, APPROVED, REJECTED |
| reviewed_by | BIGINT | Foreign key to users |
| reviewed_at | TIMESTAMP | Review timestamp |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

#### `salary_slips`
Stores generated salary slips.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| employee_id | VARCHAR(50) | Foreign key to employees |
| month | INTEGER | Month (1-12) |
| year | INTEGER | Year |
| basic_salary | DECIMAL | Basic salary |
| allowances | DECIMAL | Total allowances |
| deductions | DECIMAL | Total deductions |
| net_salary | DECIMAL | Net salary |
| pdf_url | VARCHAR(500) | PDF file URL |
| created_at | TIMESTAMP | Creation timestamp |

#### `sites`
Stores construction/work sites.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| name | VARCHAR(255) | Site name |
| address | TEXT | Site address |
| latitude | DECIMAL | GPS latitude |
| longitude | DECIMAL | GPS longitude |
| radius | DECIMAL | Geofence radius (meters) |
| is_active | BOOLEAN | Site status |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

#### `gps_attendance_logs`
Stores GPS-based attendance records.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| employee_id | VARCHAR(50) | Foreign key to employees |
| site_id | BIGINT | Foreign key to sites |
| latitude | DECIMAL | GPS latitude |
| longitude | DECIMAL | GPS longitude |
| accuracy | DECIMAL | GPS accuracy (meters) |
| attendance_type | VARCHAR(20) | CHECK_IN, CHECK_OUT |
| is_within_geofence | BOOLEAN | Within geofence flag |
| created_at | TIMESTAMP | Creation timestamp |

#### `holidays`
Stores company holidays.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| name | VARCHAR(255) | Holiday name |
| date | DATE | Holiday date |
| type | VARCHAR(20) | NATIONAL, REGIONAL, COMPANY |
| is_active | BOOLEAN | Holiday status |
| created_at | TIMESTAMP | Creation timestamp |

#### `overtime`
Stores overtime records.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| employee_id | VARCHAR(50) | Foreign key to employees |
| date | DATE | Overtime date |
| hours | DECIMAL | Overtime hours |
| rate | DECIMAL | Overtime rate per hour |
| amount | DECIMAL | Total overtime amount |
| status | VARCHAR(20) | PENDING, APPROVED, REJECTED |
| created_at | TIMESTAMP | Creation timestamp |

#### `refresh_tokens`
Stores JWT refresh tokens.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGSERIAL | Primary key |
| user_id | BIGINT | Foreign key to users |
| token | VARCHAR(500) | Refresh token |
| expiry_date | TIMESTAMP | Token expiration |
| is_revoked | BOOLEAN | Token revocation status |
| device_info | VARCHAR(500) | Device information |
| created_at | TIMESTAMP | Creation timestamp |

### Relationships

- `users` 1:1 `employees` (via user_id)
- `employees` 1:N `attendance` (via employee_id)
- `employees` 1:N `leaves` (via employee_id)
- `employees` 1:N `expenses` (via employee_id)
- `employees` 1:N `tasks` (via assigned_to)
- `sites` 1:N `tasks` (via site_id)
- `sites` 1:N `gps_attendance_logs` (via site_id)

---

## API Endpoints

### Base URL
```
http://localhost:8080/api
```

### Response Format

All API responses follow a standard format:

```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... },
  "timestamp": "2024-01-15T10:30:00",
  "statusCode": 200
}
```

### Authentication Endpoints

#### `POST /api/auth/signup`
Register a new admin user.

**Request Body:**
```json
{
  "email": "admin@example.com",
  "password": "password123",
  "confirmPassword": "password123",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Signup successful. Please verify your email with the OTP sent to your email address.",
  "data": null
}
```

#### `POST /api/auth/login`
Login for all users.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "rememberMe": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "refresh_token_here",
    "tokenType": "Bearer",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "ADMIN",
      "isActive": true
    }
  }
}
```

#### `POST /api/auth/login/admin`
Login specifically for ADMIN and HR_MANAGER roles.

#### `POST /api/auth/login/employee`
Login specifically for EMPLOYEE role.

#### `POST /api/auth/send-otp`
Send OTP for email verification.

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

#### `POST /api/auth/verify-otp`
Verify email with OTP.

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

#### `POST /api/auth/register`
Register a new user (admin function).

**Request Body:**
```json
{
  "email": "employee@example.com",
  "password": "password123",
  "firstName": "Jane",
  "lastName": "Smith",
  "role": "EMPLOYEE"
}
```

#### `POST /api/auth/logout`
Logout and revoke refresh token.

**Request Body:**
```json
{
  "refreshToken": "refresh_token_here"
}
```

#### `POST /api/auth/refresh`
Refresh access token.

**Request Body:**
```json
{
  "refreshToken": "refresh_token_here"
}
```

### Employee Endpoints

#### `POST /api/employees`
Create a new employee (Admin/HR only).

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "employeeId": "EMP001",
  "email": "employee@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "9876543210",
  "department": "Engineering",
  "designation": "Software Engineer",
  "employmentType": "FULL_TIME",
  "aadharNumber": "123456789012",
  "panNumber": "ABCDE1234F",
  "basicSalary": 50000,
  "attendanceMethod": "FACE_RECOGNITION"
}
```

#### `GET /api/employees`
Get all employees with pagination (Admin/HR only).

**Query Parameters:**
- `page` (default: 0)
- `size` (default: 10)
- `sortBy` (default: "id")
- `sortDir` (default: "ASC")

#### `GET /api/employees/{id}`
Get employee by ID.

#### `GET /api/employees/employee-id/{employeeId}`
Get employee by employee ID.

#### `GET /api/employees/user/{userId}`
Get employee by user ID.

#### `GET /api/employees/me`
Get current authenticated employee.

#### `GET /api/employees/search`
Search employees with filters (Admin/HR only).

**Query Parameters:**
- `search` - Search term
- `department` - Filter by department
- `designation` - Filter by designation
- `status` - Filter by employment status
- `type` - Filter by employment type
- `page`, `size`, `sortBy`, `sortDir`

#### `PUT /api/employees/{id}`
Update employee (Admin/HR only).

#### `DELETE /api/employees/{id}`
Delete employee (Admin only).

#### `POST /api/employees/{id}/generate-credentials`
Generate and send employee credentials via email (Admin/HR only).

### Attendance Endpoints

#### `POST /api/attendance/mark`
Mark attendance (with optional face recognition).

**Request (Multipart Form Data):**
- `image` (file, optional) - Face image for recognition
- `employee_id` (string, optional) - Employee ID
- `attendance_type` (string, optional) - CHECK_IN, LUNCH_OUT, LUNCH_IN, CHECK_OUT

**Response:**
```json
{
  "success": true,
  "message": "Attendance marked successfully",
  "data": {
    "id": 1,
    "employeeId": "EMP001",
    "attendanceDate": "2024-01-15",
    "checkInTime": "2024-01-15T09:00:00",
    "status": "PRESENT",
    "recognitionMethod": "FACE_RECOGNITION",
    "faceRecognitionConfidence": 0.95
  }
}
```

#### `POST /api/attendance/checkout`
Check out employee.

**Request Parameters:**
- `employee_id` (string, required)

#### `GET /api/attendance/today/{employeeId}`
Get today's attendance for an employee.

#### `GET /api/attendance/employee/{employeeId}`
Get employee attendance records.

**Query Parameters:**
- `startDate` (date, optional)
- `endDate` (date, optional)

#### `GET /api/attendance/daily`
Get daily attendance for all employees (Admin/HR only).

**Query Parameters:**
- `date` (date, optional, default: today)

#### `GET /api/attendance/my-attendance`
Get current employee's attendance records.

**Query Parameters:**
- `startDate` (date, optional)
- `endDate` (date, optional)
- `date` (date, optional)

#### `GET /api/attendance/my-attendance/today`
Get current employee's today's attendance.

#### `POST /api/attendance/my-attendance/mark`
Mark attendance for current employee.

#### `PUT /api/attendance/update-punch-time`
Update punch time (Admin/HR only).

**Request Parameters:**
- `attendance_id` (long, required)
- `punch_type` (string, required) - check_in, lunch_out, lunch_in, check_out
- `new_time` (datetime, required)

#### `POST /api/attendance/mark-absent`
Manually mark an employee as absent for a specific date (Admin/HR only).

**Request Parameters:**
- `employee_id` (string, required) - Employee ID
- `date` (date, required) - Date to mark absent (format: YYYY-MM-DD)

**Response:**
```json
{
  "success": true,
  "message": "Employee marked as absent successfully",
  "data": {
    "id": 123,
    "employeeId": "EMP001",
    "employeeName": "John Doe",
    "date": "2024-01-15",
    "status": "ABSENT",
    "recognitionMethod": "MANUAL",
    "notes": "Manually marked as absent by admin"
  }
}
```

#### `POST /api/attendance/bulk-mark-absent`
Bulk mark multiple employees as absent for a specific date (Admin/HR only).

**Request Body:**
```json
{
  "employee_ids": ["EMP001", "EMP002", "EMP003"],
  "date": "2024-01-15"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Bulk absent marking completed",
  "data": {
    "marked_count": 3,
    "total_requested": 3
  }
}
```

#### `POST /api/attendance/trigger-absent-marking`
Manually trigger absent marking for a specific date (Admin/HR only).
Useful for backfilling missing records or correcting data.

**Request Parameters:**
- `date` (date, optional) - Date to mark absent for (default: yesterday)

**Response:**
```json
{
  "success": true,
  "message": "Absent marking completed for date: 2024-01-15",
  "data": {
    "date": "2024-01-15",
    "absent_records_created": 5
  }
}
```

#### `GET /api/attendance/analytics/{employeeId}`
Get attendance analytics (Admin/HR only).

**Query Parameters:**
- `startDate` (date, required)
- `endDate` (date, required)

### Leave Endpoints

#### `POST /api/leaves`
Apply for leave.

**Request Body:**
```json
{
  "leaveType": "SICK_LEAVE",
  "startDate": "2024-01-20",
  "endDate": "2024-01-22",
  "isHalfDay": false,
  "reason": "Fever",
  "medicalCertificateUrl": "https://example.com/cert.pdf",
  "handoverResponsibilities": ["EMP002", "EMP003"]
}
```

#### `GET /api/leaves/my-leaves`
Get current employee's leaves.

#### `GET /api/leaves/my-responsibilities`
Get leaves where current employee has responsibilities.

#### `GET /api/leaves`
Get all leaves (Admin/HR only).

**Query Parameters:**
- `status` - Filter by status (PENDING, APPROVED, REJECTED, CANCELLED)
- `leaveType` - Filter by leave type
- `department` - Filter by department

#### `GET /api/leaves/{leaveId}`
Get leave by ID.

#### `PUT /api/leaves/{leaveId}`
Update leave (only if PENDING).

#### `DELETE /api/leaves/{leaveId}`
Delete leave (only if PENDING).

#### `PUT /api/leaves/{leaveId}/review`
Review leave (Approve/Reject) - Admin/HR only.

**Request Body:**
```json
{
  "status": "APPROVED",
  "reviewerNotes": "Approved as per policy"
}
```

#### `GET /api/leaves/types`
Get all leave types.

#### `GET /api/leaves/statuses`
Get all leave statuses.

### Task Endpoints

#### `POST /api/tasks`
Assign task (Admin/HR only).

**Request Body:**
```json
{
  "siteId": 1,
  "title": "Site Inspection",
  "description": "Inspect construction site",
  "assignedTo": "EMP001",
  "dueDate": "2024-01-25",
  "modeOfTravel": "CAR"
}
```

#### `GET /api/tasks/my-tasks`
Get current employee's tasks.

#### `GET /api/tasks`
Get all tasks (Admin/HR only).

**Query Parameters:**
- `status` - Filter by status (PENDING, APPROVED, REJECTED)

#### `GET /api/tasks/{taskId}`
Get task by ID.

#### `PUT /api/tasks/{taskId}`
Update task (Admin/HR only).

#### `DELETE /api/tasks/{taskId}`
Delete task (Admin/HR only).

#### `PUT /api/tasks/{taskId}/review`
Review task (Employee only).

**Request Body:**
```json
{
  "status": "APPROVED",
  "notes": "Task completed"
}
```

#### `GET /api/tasks/statuses`
Get all task statuses.

#### `GET /api/tasks/modes-of-travel`
Get all modes of travel.

### Expense Endpoints

#### `POST /api/expenses`
Create expense claim.

**Request Body:**
```json
{
  "expenseType": "TRAVEL",
  "amount": 1500.00,
  "description": "Taxi fare to site",
  "receiptUrl": "https://example.com/receipt.jpg"
}
```

#### `GET /api/expenses/my-expenses`
Get current employee's expenses.

#### `GET /api/expenses`
Get all expenses (Admin/HR only).

**Query Parameters:**
- `status` - Filter by status
- `employeeId` - Filter by employee

#### `GET /api/expenses/{expenseId}`
Get expense by ID.

#### `PUT /api/expenses/{expenseId}`
Update expense.

#### `PUT /api/expenses/{expenseId}/review`
Review expense (Approve/Reject) - Admin/HR only.

### Salary Endpoints

#### `GET /api/salaries/employee/{employeeId}`
Get employee salary details.

#### `GET /api/salaries/slips/{employeeId}`
Get employee salary slips.

**Query Parameters:**
- `month` (optional)
- `year` (optional)

#### `POST /api/salaries/generate-slip`
Generate salary slip (Admin/HR only).

**Request Body:**
```json
{
  "employeeId": "EMP001",
  "month": 1,
  "year": 2024
}
```

### Site Endpoints

#### `POST /api/sites`
Create site (Admin/HR only).

**Request Body:**
```json
{
  "name": "Construction Site A",
  "address": "123 Main Street",
  "latitude": 28.6139,
  "longitude": 77.2090,
  "radius": 100.0
}
```

#### `GET /api/sites`
Get all sites.

#### `GET /api/sites/{siteId}`
Get site by ID.

#### `PUT /api/sites/{siteId}`
Update site (Admin/HR only).

#### `DELETE /api/sites/{siteId}`
Delete site (Admin only).

### GPS Attendance Endpoints

#### `POST /api/gps-attendance/mark`
Mark GPS-based attendance.

**Request Body:**
```json
{
  "employeeId": "EMP001",
  "siteId": 1,
  "latitude": 28.6139,
  "longitude": 77.2090,
  "accuracy": 10.5,
  "attendanceType": "CHECK_IN"
}
```

#### `GET /api/gps-attendance/employee/{employeeId}`
Get GPS attendance logs for employee.

### Dashboard Endpoints

#### `GET /api/dashboard/admin`
Get admin dashboard statistics (Admin only).

**Response:**
```json
{
  "success": true,
  "data": {
    "totalEmployees": 150,
    "activeEmployees": 145,
    "todayAttendance": 140,
    "pendingLeaves": 5,
    "pendingExpenses": 3,
    "recentActivities": [...]
  }
}
```

#### `GET /api/dashboard/employee`
Get employee dashboard statistics.

#### `GET /api/dashboard/hr`
Get HR dashboard statistics (HR Manager only).

### File Upload Endpoints

#### `POST /api/upload`
Upload file.

**Request (Multipart Form Data):**
- `file` (file, required) - File to upload

**Response:**
```json
{
  "success": true,
  "data": {
    "url": "http://localhost:8080/uploads/filename.jpg"
  }
}
```

### Face Recognition Endpoints

#### `POST /api/face-recognition/register`
Register face for employee.

**Request (Multipart Form Data):**
- `employee_id` (string, required)
- `video` (file, required) - 10-second video

#### `POST /api/face-recognition/detect`
Detect faces in image.

**Request (Multipart Form Data):**
- `image` (file, required)

#### `POST /api/face-recognition/recognize`
Recognize faces in image.

**Request (Multipart Form Data):**
- `image` (file, required)

---

## Authentication & Security

### JWT Authentication

The system uses JWT (JSON Web Tokens) for authentication.

#### Token Structure

**Access Token:**
- Expiration: 24 hours (configurable)
- Contains: user ID, email, role, firstName, lastName
- Stored in: Authorization header as `Bearer <token>`

**Refresh Token:**
- Expiration: 7 days
- Stored in: database (`refresh_tokens` table)
- Used to: obtain new access tokens

#### Token Generation

```java
Map<String, Object> claims = new HashMap<>();
claims.put("id", user.getId());
claims.put("email", user.getEmail());
claims.put("role", user.getRole().name());
claims.put("firstName", user.getFirstName());
claims.put("lastName", user.getLastName());

String token = tokenProvider.generateTokenWithClaims(user.getEmail(), claims);
```

### Role-Based Access Control

Three roles are defined:

1. **ADMIN**: Full system access
2. **HR_MANAGER**: HR operations, employee management
3. **EMPLOYEE**: Limited access to own data

#### Role Annotations

```java
@PreAuthorize("hasRole('ADMIN')")
@PreAuthorize("hasRole('ADMIN') or hasRole('HR_MANAGER')")
@RequiresRole({"ADMIN", "HR_MANAGER"})
```

### Security Configuration

#### CORS Configuration
- Allowed origins: Configurable via `CORS_ALLOWED_ORIGINS`
- Allowed methods: GET, POST, PUT, DELETE, OPTIONS
- Allowed headers: All
- Credentials: Enabled

#### Password Encryption
- Algorithm: BCrypt
- Strength: 10 rounds

#### Security Filter Chain
1. JWT Authentication Filter
2. Username/Password Authentication
3. Role-based authorization

### Protected Endpoints

All endpoints except the following require authentication:
- `/api/auth/**` - Authentication endpoints
- `/api/public/**` - Public endpoints
- `/uploads/**` - Static file access

---

## Services & Business Logic

### AttendanceService

Handles attendance marking, calculation, and analytics.

**Key Methods:**
- `markAttendance(AttendanceRequest)` - Mark attendance
- `checkOut(String employeeId)` - Check out employee
- `getTodayAttendance(String employeeId)` - Get today's attendance
- `getEmployeeAttendance(String employeeId, LocalDate start, LocalDate end)` - Get attendance records
- `getDailyAttendance(LocalDate date)` - Get daily attendance for all employees
- `updatePunchTime(Long attendanceId, String punchType, LocalDateTime newTime)` - Update punch time
- `getAttendanceAnalytics(String employeeId, LocalDate start, LocalDate end)` - Get analytics

**Business Logic:**
- Automatic working hours calculation
- Late arrival detection
- Multiple punch types (check-in, lunch out/in, check-out)
- Face recognition confidence tracking
- Virtual absent records for missing attendance (past dates show as absent, today/future show as "Not Marked")
- Integration with leave and holiday systems

### AbsentAttendanceService

Handles automated and manual absent marking for employees who don't mark attendance.

**Key Methods:**
- `markAbsentForDate(LocalDate date)` - Mark absent for all employees without attendance on a specific date
- `markEmployeeAbsent(String employeeId, LocalDate date)` - Manually mark a single employee as absent
- `bulkMarkAbsent(List<String> employeeIds, LocalDate date)` - Bulk mark multiple employees as absent
- `isWorkingDay(LocalDate date)` - Check if a date is a working day (not Sunday or holiday)

**Scheduled Jobs:**
- **Daily at 11:59 PM**: Automatically marks absent for the current day
- **Daily at 9:00 AM**: Catch-up job to mark absent for the previous day (if not already marked)

**Business Logic:**
- **Automated Absent Marking:**
  - Runs daily via scheduled jobs
  - Only processes active employees
  - Skips Sundays (non-working days)
  - Skips holidays (checks holiday repository)
  - Checks for approved leaves (marks as ON_LEAVE instead of ABSENT)
  - Handles half-day leaves appropriately
  - Creates explicit absent records in database (Option A approach)

- **Leave Integration:**
  - Automatically checks if employee is on approved leave
  - Creates ON_LEAVE attendance records instead of ABSENT
  - Handles half-day leave periods (FIRST_HALF, SECOND_HALF)

- **Holiday Integration:**
  - Checks holiday repository before marking absent
  - Skips absent marking for holiday dates
  - Respects active/inactive holiday status

- **Manual Absent Marking:**
  - Allows admin/HR to manually mark employees as absent
  - Supports bulk operations for multiple employees
  - Prevents overriding existing PRESENT records (requires status update instead)
  - Can be triggered manually via API for backfilling or corrections

**Configuration:**
- Cutoff time: 11:59 PM (configurable via scheduled job cron expression)
- Working days: Monday to Saturday (Sunday excluded)
- Recognition method: "AUTO_ABSENT" for automated, "MANUAL" for admin-marked

**Error Handling:**
- Continues processing even if individual employee marking fails
- Logs errors for debugging
- Transactional operations ensure data consistency

### EmployeeService

Manages employee CRUD operations and credentials.

**Key Methods:**
- `createEmployee(EmployeeRequest)` - Create employee
- `updateEmployee(Long id, EmployeeRequest)` - Update employee
- `getEmployeeById(Long id)` - Get employee by ID
- `getAllEmployees(Pageable)` - Get all employees with pagination
- `getEmployeesWithFilters(...)` - Search employees
- `deleteEmployee(Long id)` - Delete employee
- `generateEmployeeCredentials(Long id)` - Generate and send credentials

**Business Logic:**
- Automatic employee ID generation
- User account creation for employees
- Email notification for credentials
- Salary calculation

### LeaveService

Manages leave applications and approvals.

**Key Methods:**
- `applyLeave(LeaveRequest)` - Apply for leave
- `updateLeave(Long leaveId, LeaveRequest)` - Update leave
- `deleteLeave(Long leaveId)` - Delete leave
- `getMyLeaves()` - Get current employee's leaves
- `getAllLeaves()` - Get all leaves (Admin/HR)
- `reviewLeave(Long leaveId, LeaveReviewRequest)` - Approve/Reject leave
- `getLeavesByStatus(LeaveStatus)` - Filter by status
- `getLeavesByType(LeaveType)` - Filter by type

**Business Logic:**
- Automatic leave days calculation
- Half-day leave validation
- Medical certificate requirement for medical leaves
- Status-based edit/delete restrictions
- Handover responsibilities tracking

### TaskService

Manages task assignments and tracking.

**Key Methods:**
- `assignTask(TaskRequest)` - Assign task
- `updateTask(Long taskId, TaskRequest)` - Update task
- `deleteTask(Long taskId)` - Delete task
- `getMyTasks()` - Get current employee's tasks
- `getAllTasks()` - Get all tasks (Admin/HR)
- `reviewTask(Long taskId, TaskReviewRequest)` - Review task

**Business Logic:**
- Site-based task assignment
- Task status workflow
- Employee task tracking

### SalaryCalculationService

Calculates employee salaries.

**Key Methods:**
- `calculateSalary(String employeeId, int month, int year)` - Calculate salary
- `generateSalarySlip(String employeeId, int month, int year)` - Generate slip

**Business Logic:**
- Basic salary calculation
- Allowance calculations (HRA, conveyance, etc.)
- Deduction calculations (EPF, ESIC, professional tax)
- Overtime calculations
- Net salary computation

### GeofenceService

Validates GPS coordinates against site geofences.

**Key Methods:**
- `isWithinGeofence(Double latitude, Double longitude, Long siteId)` - Check if within geofence
- `calculateDistance(Double lat1, Double lon1, Double lat2, Double lon2)` - Calculate distance

**Business Logic:**
- Haversine formula for distance calculation
- Geofence radius validation
- GPS accuracy consideration

### EmailService

Sends email notifications.

**Key Methods:**
- `sendOtpEmail(String email, String firstName, String otp)` - Send OTP email
- `sendCredentialsEmail(String email, String firstName, String password)` - Send credentials
- `sendLeaveNotification(...)` - Send leave notifications

**Configuration:**
- SMTP host: Configurable via `MAIL_HOST`
- Port: Configurable via `MAIL_PORT`
- Authentication: Username/password
- TLS: Enabled

---

## Face Recognition Service

### Overview

The Face Recognition Service is a separate Python-based microservice that handles biometric attendance. It uses InsightFace for face detection and recognition.

### Architecture

```
FastAPI Application
    │
    ├── Face Recognition Engine
    │   ├── InsightFace Model
    │   ├── Face Detection
    │   ├── Face Recognition
    │   └── Embedding Storage
    │
    ├── Database Connection
    │   └── PostgreSQL Pool
    │
    └── Redis Cache (Optional)
        └── Employee Data Cache
```

### Endpoints

#### `GET /health`
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "service": "face-recognition",
  "gpu_enabled": true
}
```

#### `POST /face/register`
Register face from video.

**Request (Multipart Form Data):**
- `employee_id` (string, required)
- `video` (file, required) - 10-15 second video

**Response:**
```json
{
  "success": true,
  "message": "Face registered successfully for John Doe",
  "employee_id": "EMP001",
  "name": "John_Doe"
}
```

#### `POST /face/detect`
Detect faces in image.

**Request (Multipart Form Data):**
- `image` (file, required)

**Response:**
```json
{
  "success": true,
  "faces": [
    {
      "bbox": {"x1": 100, "y1": 150, "x2": 200, "y2": 250},
      "confidence": 0.95,
      "recognized": true,
      "employee_id": "EMP001",
      "first_name": "John",
      "last_name": "Doe",
      "match_confidence": 0.92
    }
  ],
  "count": 1
}
```

#### `POST /face/recognize-stream`
Recognize faces in real-time video stream.

**Request (Multipart Form Data):**
- `image` (file, required) - Video frame
- `fast_mode` (boolean, optional, default: true)

**Response:**
```json
{
  "success": true,
  "faces": [...],
  "frame_processed": true
}
```

#### `POST /face/attendance/mark`
Mark attendance via face recognition.

**Request (Multipart Form Data):**
- `employee_id` (string, required)
- `punch_type` (string, required) - check_in, lunch_out, lunch_in, check_out
- `confidence` (float, required)

**Response:**
```json
{
  "success": true,
  "message": "Attendance marked successfully",
  "employee_id": "EMP001",
  "punch_type": "check_in",
  "attendance_id": 123
}
```

#### `PUT /face/attendance/update-punch-time`
Update punch time (admin function).

**Request (Multipart Form Data):**
- `attendance_id` (integer, required)
- `punch_type` (string, required)
- `new_time` (string, required) - ISO format: YYYY-MM-DD HH:MM:SS

#### `DELETE /face/embeddings/{employee_id}`
Delete face embeddings for employee.

#### `GET /face/embeddings/list`
List all registered face embeddings.

#### `POST /face/recognize-annotated`
Recognize faces and return annotated image.

**Response:** JPEG image with bounding boxes and names

### Configuration

**Environment Variables:**
- `SERVICE_PORT` - Service port (default: 8000)
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` - Database config
- `USE_GPU` - Enable GPU (default: True)
- `FACE_DETECTION_THRESHOLD` - Detection threshold (default: 0.65)
- `FACE_MATCHING_THRESHOLD` - Matching threshold (default: 0.6)
- `VIDEO_CAPTURE_DURATION` - Video duration in seconds (default: 15)
- `REDIS_ENABLED` - Enable Redis caching (default: True)

### Face Recognition Process

1. **Registration:**
   - Capture 10-15 second video
   - Extract frames from video
   - Detect faces in each frame
   - Extract embeddings
   - Average embeddings
   - Store as `firstname_lastname:embeddings`

2. **Recognition:**
   - Capture image/frame
   - Detect faces
   - Extract embeddings
   - Compare with stored embeddings (cosine similarity)
   - Return matches above threshold

3. **Optimization:**
   - Thread pool for CPU-intensive operations
   - Redis caching for employee data
   - Fast mode for real-time processing
   - GPU acceleration (if available)

### Performance

- **CPU**: ~10-15 FPS for detection and recognition
- **GPU (NVIDIA RTX 3060)**: ~30-45 FPS
- **Face Registration**: ~10-15 seconds per employee
- **Recognition Latency**: ~100-200ms per frame

---

## Configuration

### Environment Variables

Create a `.env` file in `civildesk-backend/civildesk-backend/`:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=civildesk
DB_USERNAME=postgres
DB_PASSWORD=your_password

# JWT Configuration
JWT_SECRET=your_secret_key_at_least_256_bits_long
JWT_EXPIRATION=86400000
JWT_REFRESH_EXPIRATION=604800000

# Server Configuration
SERVER_PORT=8080

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8081

# Face Recognition Service
FACE_SERVICE_URL=http://localhost:8000

# Email Configuration
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_app_password
MAIL_FROM=noreply@civildesk.com
EMAIL_ENABLED=true

# Redis Configuration (Optional)
REDIS_ENABLED=true
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# Spring Profile
SPRING_PROFILES_ACTIVE=dev
```

### Application Properties

Configuration is loaded in this order:
1. `.env` file (highest priority)
2. `application.properties` (defaults)
3. System environment variables

### Database Configuration

**Connection Pool (HikariCP):**
- Maximum pool size: 20
- Minimum idle: 5
- Connection timeout: 30 seconds
- Idle timeout: 10 minutes
- Max lifetime: 30 minutes

**JPA/Hibernate:**
- DDL auto: `update` (creates/updates tables)
- Show SQL: `true` (development)
- Batch size: 50
- Format SQL: `true`

### Redis Configuration

Redis is optional but recommended for production:
- Caching employee data
- Session storage
- Rate limiting

If Redis is disabled, the system falls back to in-memory cache.

---

## Deployment

### Docker Deployment

#### Using Docker Compose

```bash
cd civildesk-backend
docker-compose up -d
```

This starts:
- PostgreSQL database
- Redis cache
- Spring Boot backend

#### Manual Docker Build

```bash
# Build image
docker build -t civildesk-backend:latest .

# Run container
docker run -d \
  --name civildesk-backend \
  -p 8080:8080 \
  --env-file .env \
  civildesk-backend:latest
```

### Production Deployment

#### Prerequisites
- Java 17 installed
- PostgreSQL 15+ running
- Redis 7+ running (optional)
- Maven 3.6+ installed

#### Steps

1. **Build Application:**
```bash
cd civildesk-backend/civildesk-backend
mvn clean package -DskipTests
```

2. **Create .env file:**
```bash
cp .env.example .env
# Edit .env with production values
```

3. **Run Application:**
```bash
java -jar target/civildesk-backend-*.jar
```

#### Systemd Service

Create `/etc/systemd/system/civildesk-backend.service`:

```ini
[Unit]
Description=CivilDesk Backend Service
After=network.target postgresql.service

[Service]
Type=simple
User=civildesk
WorkingDirectory=/opt/civildesk-backend
ExecStart=/usr/bin/java -jar civildesk-backend.jar
EnvironmentFile=/opt/civildesk-backend/.env
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable civildesk-backend
sudo systemctl start civildesk-backend
```

### Face Recognition Service Deployment

#### Using Docker

```bash
cd face-recognition-service
docker build -t face-recognition-service:latest .
docker run -d \
  --name face-recognition-service \
  -p 8000:8000 \
  --env-file .env \
  face-recognition-service:latest
```

#### Manual Deployment

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run service
python main.py
```

Or using uvicorn:
```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

### AWS Deployment

See `Docs/AWS_DEPLOYMENT_GUIDE.md` for detailed AWS deployment instructions.

---

## Development Guide

### Prerequisites

- Java 17 JDK
- Maven 3.6+
- PostgreSQL 15+
- IDE (IntelliJ IDEA, Eclipse, VS Code)
- Git

### Setup Development Environment

1. **Clone Repository:**
```bash
git clone <repository-url>
cd Civildesk/civildesk-backend
```

2. **Database Setup:**
```bash
# Create database
createdb civildesk

# Run migrations (if any)
psql -U postgres -d civildesk -f database/migrations/complete_migration.sql
```

3. **Create .env file:**
```bash
cp .env.example .env
# Edit .env with your local configuration
```

4. **Build Project:**
```bash
cd civildesk-backend
mvn clean install
```

5. **Run Application:**
```bash
mvn spring-boot:run
```

Or run `CivildeskBackendApplication.java` from your IDE.

### Code Structure Guidelines

#### Controller Layer
- Handle HTTP requests/responses
- Validate input using `@Valid`
- Use `@PreAuthorize` for authorization
- Return `ApiResponse<T>` wrapper

#### Service Layer
- Implement business logic
- Handle transactions
- Call repositories for data access
- Throw custom exceptions

#### Repository Layer
- Extend `JpaRepository<Entity, ID>`
- Use method naming conventions for queries
- Use `@Query` for complex queries

#### DTO Layer
- Separate request/response DTOs
- Use validation annotations
- Map between entities and DTOs

### Testing

#### Unit Tests
```bash
mvn test
```

#### Integration Tests
```bash
mvn verify
```

### Code Style

- Follow Java naming conventions
- Use Lombok to reduce boilerplate
- Add JavaDoc for public methods
- Keep methods focused and small

### Database Migrations

Migrations are located in `src/main/resources/db/migration/`.

Hibernate auto-update is enabled in development. For production, use Flyway or manual SQL scripts.

### Debugging

1. Enable SQL logging in `application-dev.properties`:
```properties
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
```

2. Use IDE debugger
3. Check application logs in console
4. Use Postman/curl for API testing

### Common Issues

#### Database Connection Error
- Check PostgreSQL is running
- Verify credentials in `.env`
- Check database exists

#### Port Already in Use
- Change `SERVER_PORT` in `.env`
- Or kill process using port 8080

#### JWT Token Expired
- Use refresh token endpoint
- Or login again

#### Face Recognition Service Not Responding
- Check service is running on port 8000
- Verify `FACE_SERVICE_URL` in `.env`
- Check service logs

---

## Additional Resources

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Spring Security Documentation](https://spring.io/projects/spring-security)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [JWT.io](https://jwt.io/) - JWT token decoder
- [InsightFace Documentation](https://github.com/deepinsight/insightface)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)

---

## Support

For issues, questions, or contributions, please contact the development team or create an issue in the repository.

---

**Last Updated:** January 2024
**Version:** 1.0.0

