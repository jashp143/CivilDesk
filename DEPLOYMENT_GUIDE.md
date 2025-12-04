# Civildesk - Deployment Guide

## Overview

Civildesk is now split into **two separate frontend applications** that share the same backend and database:

1. **Admin Application** (`civildesk_frontend`) - For administrators and HR managers
2. **Employee Application** (`civildesk_employee_frontend`) - For employees

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Applications                         │
├──────────────────────────┬──────────────────────────────┤
│  Admin Frontend          │  Employee Frontend           │
│  (civildesk_frontend)    │  (civildesk_employee_frontend)│
│                          │                              │
│  - Admin Dashboard       │  - Employee Dashboard        │
│  - Employee Management   │  - Personal Profile          │
│  - Attendance Tracking   │  - Self Attendance Marking   │
│  - Reports & Analytics   │  - Attendance History        │
│  - Settings              │  - Leave Management          │
│                          │  - Settings                  │
└──────────────────────────┴──────────────────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │   Backend (Spring Boot)│
              │   civildesk-backend    │
              │                        │
              │   - Authentication     │
              │   - Role-based Access  │
              │   - API Endpoints      │
              │   - Business Logic     │
              └────────────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │   PostgreSQL Database  │
              │                        │
              │   - Users (Roles)      │
              │   - Employees          │
              │   - Attendance         │
              │   - Leaves             │
              └────────────────────────┘
```

---

## Backend Setup

### 1. Database Configuration

The backend uses PostgreSQL. Make sure the database is set up:

```bash
cd civildesk-backend/civildesk-backend/database
# Run the setup SQL scripts
psql -U postgres -d civildesk -f setup.sql
```

### 2. Start Backend Server

```bash
cd civildesk-backend/civildesk-backend
mvn spring-boot:run
```

The backend will run on `http://localhost:8080`

### 3. Backend Endpoints

#### Authentication Endpoints
- `POST /api/auth/login` - User login (all roles - legacy endpoint)
- `POST /api/auth/login/admin` - Admin/HR login (ADMIN, HR_MANAGER only)
- `POST /api/auth/login/employee` - Employee login (EMPLOYEE only)
- `POST /api/auth/logout` - User logout
- `POST /api/auth/signup` - Admin signup
- `POST /api/auth/verify-otp` - OTP verification

#### Admin/HR Endpoints
- `GET /api/dashboard/admin` - Admin dashboard stats
- `GET /api/dashboard/hr` - HR dashboard stats
- `GET /api/employees` - List all employees
- `POST /api/employees` - Create employee
- `GET /api/attendance/daily` - Daily attendance overview
- `GET /api/attendance/employee/{employeeId}` - Employee attendance history

#### Employee Endpoints (New)
- `GET /api/dashboard/employee` - Employee dashboard stats
- `GET /api/attendance/my-attendance` - Get own attendance history (view only)
- `GET /api/attendance/my-attendance/today` - Get today's attendance (view only)

**Note**: Attendance marking is performed by Admin/HR through the Admin application only.

---

## Admin Frontend Setup

### 1. Install Dependencies

```bash
cd civildesk_frontend
flutter pub get
```

### 2. Configure Backend URL

The backend URL is configured in `lib/core/constants/app_constants.dart`:

```dart
static String get baseUrl {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080/api';  // Android emulator
  } else if (Platform.isIOS) {
    return 'http://localhost:8080/api';  // iOS simulator
  } else {
    return 'http://localhost:8080/api';  // Desktop/Web
  }
}
```

For physical devices, update with your computer's IP address:
```dart
return 'http://192.168.1.100:8080/api';
```

### 3. Run Admin Application

```bash
flutter run
```

### 4. Admin Features

- **Dashboard**: Overview of all employees, attendance, departments
- **Employee Management**: Add, edit, delete employees
- **Attendance Tracking**: View and manage attendance for all employees
- **Face Registration**: Register employee faces for facial recognition
- **Reports**: Generate attendance reports
- **User Roles**: ADMIN and HR_MANAGER roles can access this app

---

## Employee Frontend Setup

### 1. Install Dependencies

```bash
cd civildesk_employee_frontend
flutter pub get
```

### 2. Configure Backend URL

Same as admin frontend - edit `lib/core/constants/app_constants.dart`

### 3. Run Employee Application

```bash
flutter run
```

### 4. Employee Features

- **Dashboard**: Personal attendance summary and quick stats
- **Profile**: View personal information and attendance percentage
- **Attendance History**: View past attendance records with date filtering
  - View today's attendance status
  - View check-in/check-out times
  - Filter attendance by date range
  - See attendance statistics
  - **Note**: Attendance is marked by Admin/HR only
- **Leave Management**: View leave balance and apply for leaves (coming soon)
- **Settings**: Theme toggle, app info, logout

---

## User Roles & Access

### ADMIN
- Full access to admin application
- Can manage all employees
- Can view all attendance records
- Can generate reports
- Cannot access employee app

### HR_MANAGER
- Access to admin application (same as ADMIN)
- Can manage employees in their department
- Can view attendance records
- Cannot access employee app

### EMPLOYEE
- **Only** has access to employee application
- Can view own dashboard
- Can **view** own attendance (marking done by Admin/HR)
- Can view own attendance history
- Can apply for leaves
- Cannot access admin app
- Cannot mark or edit attendance

---

## Authentication Flow

### Admin/HR Manager Login
1. Open Admin App
2. See login screen with "Admin Portal" badge
3. Login with email and password
4. Backend validates role at `/api/auth/login/admin`
5. Frontend also validates role
6. If role is ADMIN or HR_MANAGER → Dashboard
7. If role is EMPLOYEE → Access denied with message: "This app is for administrators and HR managers only. Please use the Employee app."

### Employee Login
1. Open Employee App
2. See login screen with "For Employees Only" badge
3. Login with email and password
4. Backend validates role at `/api/auth/login/employee`
5. Frontend also validates role
6. If role is EMPLOYEE → Dashboard
7. If role is ADMIN or HR_MANAGER → Access denied with message: "This app is for employees only. Please use the Admin app."

---

## Database Schema

### Users Table
```sql
- id (Primary Key)
- email (Unique)
- password (Encrypted)
- first_name
- last_name
- role (ADMIN, HR_MANAGER, EMPLOYEE)
- is_active
- email_verified
```

### Employees Table
```sql
- id (Primary Key)
- employee_id (Unique)
- user_id (Foreign Key → Users)
- first_name
- last_name
- email
- department
- designation
- phone_number
- employment_status
- employment_type
```

### Attendance Table
```sql
- id (Primary Key)
- employee_id (Foreign Key → Employees)
- date
- check_in_time
- lunch_out_time
- lunch_in_time
- check_out_time
- status (PRESENT, ABSENT, HALF_DAY, LEAVE)
- recognition_method (MANUAL, FACE_RECOGNITION, SELF_SERVICE)
```

---

## Development Tips

### Running Multiple Apps Simultaneously

To test both apps at the same time:

1. **Backend**: `mvn spring-boot:run` (Port 8080)
2. **Admin App**: `flutter run -d chrome` (Use Chrome)
3. **Employee App**: `flutter run -d windows` (Use Windows/Desktop)

Or use different emulators:
```bash
# Terminal 1 - Admin App
cd civildesk_frontend
flutter run -d emulator-5554

# Terminal 2 - Employee App
cd civildesk_employee_frontend
flutter run -d emulator-5556
```

### Testing Credentials

Create test users with different roles:

```sql
-- Admin user
INSERT INTO users (email, password, first_name, last_name, role, email_verified)
VALUES ('admin@civildesk.com', '$2a$10$...', 'Admin', 'User', 'ADMIN', true);

-- Employee user
INSERT INTO users (email, password, first_name, last_name, role, email_verified)
VALUES ('employee@civildesk.com', '$2a$10$...', 'John', 'Doe', 'EMPLOYEE', true);
```

---

## Troubleshooting

### Backend Connection Issues

1. Check if backend is running: `http://localhost:8080/api/dashboard/admin`
2. Verify PostgreSQL is running
3. Check firewall settings
4. Update IP address in app_constants.dart for physical devices

### Authentication Errors

1. Ensure user has correct role
2. Check if email is verified (for ADMIN/HR_MANAGER)
3. Verify JWT token is being sent in headers
4. Check backend logs for detailed error messages

### Build Issues

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

## Production Deployment

### Backend
1. Build JAR: `mvn clean package`
2. Deploy to server (AWS, Azure, etc.)
3. Configure environment variables
4. Set up SSL/TLS
5. Configure database connection

### Frontend Apps
1. Build for production:
   - Android: `flutter build apk --release`
   - iOS: `flutter build ios --release`
   - Web: `flutter build web --release`
2. Upload to app stores or web hosting
3. Update API base URLs to production server

---

## Security Considerations

1. **Authentication**: JWT-based authentication
2. **Authorization**: Role-based access control (RBAC)
3. **Password**: Bcrypt encryption
4. **API Security**: All endpoints require authentication
5. **CORS**: Configured for specific origins in production
6. **SQL Injection**: Using parameterized queries
7. **XSS Protection**: Input validation on both frontend and backend

---

## Future Enhancements

1. Leave application workflow
2. Payroll management
3. Performance reviews
4. Document management
5. Push notifications
6. Biometric authentication
7. Offline mode
8. Multi-language support

---

## Support

For issues or questions:
- Check the documentation in the `docs/` folder
- Review backend logs in `logs/` folder
- Contact the development team

---

## License

Proprietary - All rights reserved

