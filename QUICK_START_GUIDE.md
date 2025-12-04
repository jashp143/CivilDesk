# Civildesk - Quick Start Guide

## 🚀 What's New?

Your Civildesk application has been successfully separated into **two independent frontends**:

1. **📊 Admin Application** (`civildesk_frontend`) - For administrators and HR managers
2. **👤 Employee Application** (`civildesk_employee_frontend`) - For employees

Both applications use the **same backend** and **database**.

---

## 📁 Folder Structure

```
Civildesk/
├── civildesk_frontend/              ← ADMIN APP
│   └── lib/
│       ├── screens/admin/           (Admin dashboards, employee management)
│       ├── screens/attendance/      (Attendance tracking for all)
│       └── main.dart                ("Civildesk Admin")
│
├── civildesk_employee_frontend/     ← EMPLOYEE APP (NEW!)
│   └── lib/
│       ├── screens/dashboard/       (Personal dashboard)
│       ├── screens/attendance/      (Self-service attendance)
│       ├── screens/profile/         (Personal profile)
│       ├── screens/leave/           (Leave management)
│       └── main.dart                ("Civildesk Employee")
│
├── civildesk-backend/               ← BACKEND (UPDATED)
│   └── civildesk-backend/
│       └── src/
│           └── controller/
│               └── AttendanceController.java  (Added employee endpoints)
│
└── Documentation/
    ├── DEPLOYMENT_GUIDE.md          (Full deployment guide)
    ├── FRONTEND_SEPARATION_SUMMARY.md (Detailed changes)
    └── QUICK_START_GUIDE.md         (This file)
```

---

## 🎯 Quick Start (Development)

### 1️⃣ Start Backend (Required for both apps)

```bash
cd civildesk-backend/civildesk-backend
mvn spring-boot:run
```

Backend runs on: `http://localhost:8080`

---

### 2️⃣ Option A: Run Admin Application

```bash
cd civildesk_frontend
flutter pub get
flutter run
```

**Login with:**
- **Role**: ADMIN or HR_MANAGER
- **Features**: Employee management, attendance tracking, reports

---

### 3️⃣ Option B: Run Employee Application

```bash
cd civildesk_employee_frontend
flutter pub get
flutter run
```

**Login with:**
- **Role**: EMPLOYEE
- **Features**: Self-attendance, personal dashboard, leave management

---

## 🔐 Authentication & Roles

| Role       | Admin App | Employee App | Features |
|------------|-----------|--------------|----------|
| **ADMIN**  | ✅ Yes    | ❌ No        | Full system access, employee management |
| **HR_MANAGER** | ✅ Yes | ❌ No    | Employee management, attendance tracking |
| **EMPLOYEE** | ❌ No   | ✅ Yes       | Self-service, personal dashboard |

### Login Restrictions:
- **Admin App**: Only ADMIN and HR_MANAGER can login (EMPLOYEE will see error)
- **Employee App**: Only EMPLOYEE can login (ADMIN/HR_MANAGER will see error)
- Each app uses **role-specific login endpoints** for security

---

## 🆕 What Changed?

### ✅ Admin Application (`civildesk_frontend`)
- **Updated**: App title changed to "Civildesk Admin"
- **Unchanged**: All existing features preserved
- **Access**: Only ADMIN and HR_MANAGER roles

### ✅ Employee Application (`civildesk_employee_frontend`)
- **NEW**: Complete application built from scratch
- **Created**: 25+ new files
- **Features**:
  - Personal dashboard with attendance stats
  - **View-only attendance** (marking done by Admin/HR)
  - Attendance history with date filtering
  - Profile viewing
  - Leave balance viewing
  - Dark mode support
  - Settings & logout

### ✅ Backend (`civildesk-backend`)
- **Added**: 3 new employee-specific endpoints
  - `POST /api/attendance/my-attendance/mark` - Mark own attendance
  - `GET /api/attendance/my-attendance` - Get own attendance history
  - `GET /api/attendance/my-attendance/today` - Get today's attendance
- **Updated**: `AttendanceController.java`, `AttendanceService.java`, `AttendanceRequest.java`
- **Security**: Role-based authorization with `@PreAuthorize("hasRole('EMPLOYEE')")`

### ✅ Database
- **No changes required** ✨
- Existing schema already supports the separation

---

## 📱 Employee App Features

### 1. Dashboard
- Welcome message with current date
- Today's attendance status (Check In, Lunch, Check Out)
- Quick stats (Present, Absent, Leaves, Attendance %)
- Quick action buttons

### 2. Attendance (View Only)
- **View Today's Attendance**: See check-in, lunch, and check-out times
- **View History**: Filter by date range, see all past records
- Status tracking (Present, Absent, Half Day, Leave)
- **Note**: Attendance is marked by Admin/HR through the Admin application

### 3. Profile
- Personal information (Name, Employee Code, Email, Department)
- Attendance summary statistics
- Attendance percentage

### 4. Leave Management
- View leave balance (Total, Used, Remaining)
- View pending requests
- Apply for leave (coming soon)

### 5. Settings
- Dark mode toggle
- Account information
- App version
- Logout

---

## 🔧 Configuration

### For Physical Devices

Update the IP address in both frontends:

**Admin App**: `civildesk_frontend/lib/core/constants/app_constants.dart`
**Employee App**: `civildesk_employee_frontend/lib/core/constants/app_constants.dart`

```dart
static String get baseUrl {
  // Replace with your computer's IP address
  return 'http://192.168.1.100:8080/api';
}
```

Find your IP:
- **Windows**: `ipconfig`
- **Mac/Linux**: `ifconfig` or `ip addr`

---

## 🧪 Testing

### Test Admin App:
1. Login as ADMIN ✅ (uses `/api/auth/login/admin`)
2. Login as HR_MANAGER ✅
3. Try to login as EMPLOYEE ❌ (should show: "Access denied. This app is for administrators and HR managers only. Please use the Employee app.")
4. Verify login screen shows "Admin Portal" badge
5. View employee list
6. View attendance dashboard

### Test Employee App:
1. Login as EMPLOYEE ✅ (uses `/api/auth/login/employee`)
2. Try to login as ADMIN ❌ (should show: "Access denied. This app is for employees only. Please use the Admin app.")
3. Try to login as HR_MANAGER ❌ (should show error)
4. Verify login screen shows "For Employees Only" badge
5. View today's attendance (should show times marked by admin)
6. View attendance history
7. Check profile

---

## 🐛 Troubleshooting

### "Connection refused" or "Network error"
- ✅ Check if backend is running on port 8080
- ✅ Verify IP address in `app_constants.dart`
- ✅ Check firewall settings

### "Access denied" error
- ✅ Verify user has correct role
- ✅ Check if using correct app (Admin vs Employee)

### "Failed to fetch data"
- ✅ Check backend logs for errors
- ✅ Verify database is running
- ✅ Check authentication token

---

## 📦 Building for Production

### Android APK:
```bash
# Admin App
cd civildesk_frontend
flutter build apk --release

# Employee App
cd civildesk_employee_frontend
flutter build apk --release
```

APK files will be in: `build/app/outputs/flutter-apk/`

### iOS:
```bash
flutter build ios --release
```

### Web:
```bash
flutter build web --release
```

---

## 📊 API Endpoints Summary

### Admin/HR Endpoints:
```
GET  /api/dashboard/admin              - Admin dashboard
GET  /api/dashboard/hr                 - HR dashboard
GET  /api/employees                    - List all employees
POST /api/employees                    - Create employee
GET  /api/attendance/daily             - Daily attendance
GET  /api/attendance/employee/{id}     - Employee attendance
```

### Employee Endpoints (NEW):
```
GET  /api/dashboard/employee           - Personal dashboard
GET  /api/attendance/my-attendance     - Get attendance history (view only)
GET  /api/attendance/my-attendance/today - Get today's attendance (view only)

Note: Attendance marking is done by Admin/HR through Admin application
```

---

## 📚 Documentation

For detailed information, see:
- **`DEPLOYMENT_GUIDE.md`** - Complete deployment instructions
- **`FRONTEND_SEPARATION_SUMMARY.md`** - Detailed technical changes
- **Backend README**: `civildesk-backend/civildesk-backend/README.md`

---

## 🎉 Summary

✅ **2 separate frontend applications** (Admin & Employee)  
✅ **1 shared backend** with role-based security  
✅ **Same database** for data consistency  
✅ **25+ new files** created for employee app  
✅ **3 new API endpoints** for employee features  
✅ **Complete documentation** for easy deployment  

---

## 🚀 Next Steps

1. **Test both applications** with different user roles
2. **Update IP addresses** if testing on physical devices
3. **Create test users** with different roles in database
4. **Review security settings** before production deployment
5. **Build APKs** for distribution

---

## 💡 Tips

- Use **Chrome** for admin app and **Android emulator** for employee app to test both simultaneously
- Create separate accounts for testing each role
- Check backend logs (`civildesk-backend/civildesk-backend/logs/`) for debugging
- Use `flutter clean` if you encounter build issues

---

## 📞 Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Review backend logs for errors
3. Verify all configuration files are correct
4. Ensure all dependencies are installed (`flutter pub get`)

---

**Happy coding! 🎉**

