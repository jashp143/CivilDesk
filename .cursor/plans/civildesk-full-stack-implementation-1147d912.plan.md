<!-- 1147d912-738d-4ac9-a4f7-b6fe2a339b86 610392cb-7ef8-4e7a-98cb-5fffad40bd9d -->
# Civildesk - Complete Implementation Plan

## Phase 1: Project Foundation & Core Infrastructure

### 1.1 Flutter Project Setup

- Update `pubspec.yaml` with required dependencies (Provider, Dio, SharedPreferences, etc.)
- Configure classic light/dark theme system in `lib/core/theme/`
- Set up Provider state management architecture
- Create routing structure with role-based navigation
- Implement app constants and utilities

### 1.2 Spring Boot Backend Foundation

- Add JWT dependencies to `pom.xml` (io.jsonwebtoken)
- Configure Spring Security with JWT authentication
- Set up database connection (PostgreSQL)
- Create base entity classes and common utilities
- Implement exception handling and response DTOs

### 1.3 Python Face Recognition Service

- Create `civildesk-face-service/` directory structure
- Set up FastAPI application with CORS
- Configure InsightFace model loading
- Create basic face registration and recognition endpoints

## Phase 2: Authentication & Authorization

### 2.1 Backend Authentication

- Create User entity with roles (ADMIN, HR_MANAGER, EMPLOYEE)
- Implement JWT token generation and validation
- Create AuthController with login/register endpoints
- Set up role-based access control (RBAC) annotations

### 2.2 Flutter Authentication

- Create login screen (`lib/screens/common/login_screen.dart`)
- Implement Provider for auth state management
- Add token storage and auto-login functionality
- Create role-based route guards

## Phase 3: Employee Management Module

### 3.1 Backend Employee APIs

- Create Employee entity with all fields from PRD (personal info, work info, salary, etc.)
- Implement EmployeeRepository with JPA queries
- Create EmployeeController with CRUD operations
- Add validation for Aadhar, PAN, email uniqueness
- Implement employee search and filtering

### 3.2 Flutter Employee Management

- Create multi-step employee registration form (7 steps as per PRD)
- Implement employee list screen with search/filter
- Create employee detail view with tabs
- Add form validation for all fields
- Implement file upload for documents

## Phase 4: Dashboard Module

### 4.1 Backend Dashboard APIs

- Create dashboard stats endpoints (employee count, attendance stats, etc.)
- Implement aggregation queries for charts
- Add real-time attendance tracking endpoints

### 4.2 Flutter Dashboard

- Create admin dashboard with stats cards and charts
- Implement employee dashboard with personal stats
- Add quick action buttons
- Create reusable chart widgets

## Phase 5: Attendance & Face Recognition

### 5.1 Python Face Service

- Implement InsightFace face embedding extraction
- Create face registration endpoint (store embeddings)
- Implement face recognition endpoint with similarity matching
- Add liveness detection (basic)

### 5.2 Backend Attendance APIs

- Create Attendance entity (check-in/check-out, date, employee)
- Implement AttendanceController with check-in/out endpoints
- Add face recognition integration (call Python service)
- Create attendance history and reports endpoints

### 5.3 Flutter Attendance

- Create face check-in screen with camera integration
- Implement kiosk mode for admin tablets
- Create attendance history view
- Add real-time attendance tracking

## Phase 6: Salary Management

### 6.1 Backend Salary APIs

- Create Salary entity with components (basic, HRA, allowances, deductions)
- Implement salary calculation logic
- Create salary slip generation endpoint
- Add salary history tracking

### 6.2 Flutter Salary Module

- Create salary structure configuration screen
- Implement salary slip view and download
- Add salary history list

## Phase 7: Leave Management

### 7.1 Backend Leave APIs

- Create Leave entity (type, dates, status, employee)
- Implement leave request submission
- Create leave approval/rejection endpoints
- Add leave balance calculation

### 7.2 Flutter Leave Module

- Create leave application form
- Implement leave request list with filters
- Add leave approval screen for admins
- Create leave calendar view

## Phase 8: Testing & Polish

### 8.1 Testing

- Unit tests for backend services
- Widget tests for Flutter screens
- Integration tests for critical flows

### 8.2 Documentation

- API documentation (Swagger)
- Code comments and README files

## Key Files to Create/Modify

**Flutter:**

- `lib/core/theme/app_theme.dart` - Classic light/dark theme
- `lib/core/providers/auth_provider.dart` - Authentication state
- `lib/core/providers/employee_provider.dart` - Employee state
- `lib/screens/common/login_screen.dart`
- `lib/screens/admin/dashboard_screen.dart`
- `lib/screens/admin/employee_list_screen.dart`
- `lib/screens/admin/employee_registration_screen.dart`
- `lib/screens/employee/dashboard_screen.dart`
- `lib/screens/employee/attendance_screen.dart`

**Backend:**

- `src/main/java/com/civildesk/model/User.java`
- `src/main/java/com/civildesk/model/Employee.java`
- `src/main/java/com/civildesk/model/Attendance.java`
- `src/main/java/com/civildesk/controller/AuthController.java`
- `src/main/java/com/civildesk/controller/EmployeeController.java`
- `src/main/java/com/civildesk/config/SecurityConfig.java`
- `src/main/java/com/civildesk/security/JwtTokenProvider.java`

**Python Service:**

- `civildesk-face-service/app/main.py`
- `civildesk-face-service/app/services/face_recognition.py`
- `civildesk-face-service/app/routes/register.py`
- `civildesk-face-service/app/routes/recognize.p`

### To-dos

- [ ] Update Flutter dependencies (Provider, Dio, etc.) and configure classic light/dark theme system
- [ ] Add JWT dependencies, configure Spring Security, and set up PostgreSQL connection
- [ ] Create Python FastAPI service structure with InsightFace integration setup
- [ ] Implement JWT authentication, User entity, and AuthController with login/register
- [ ] Create login screen and auth Provider with token management
- [ ] Create Employee entity with all PRD fields and CRUD APIs
- [ ] Build multi-step employee registration form and employee list/detail screens
- [ ] Create dashboard stats endpoints and aggregation queries
- [ ] Build admin and employee dashboards with stats cards and charts
- [ ] Implement face registration and recognition endpoints using InsightFace
- [ ] Create Attendance entity and APIs with face recognition integration
- [ ] Build face check-in screen with camera and attendance history view
- [ ] Create Salary entity and calculation logic with slip generation
- [ ] Build salary structure configuration and salary slip screens
- [ ] Create Leave entity and approval workflow APIs
- [ ] Build leave application form and approval screens