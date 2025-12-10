# Quick Setup Guide - Leave Management System

## Prerequisites

- PostgreSQL database running
- Spring Boot backend configured
- Flutter installed for frontend apps
- Database connection configured in backend

## Step-by-Step Setup

### 1. Database Migration (5 minutes)

```bash
# Navigate to migrations folder
cd civildesk-backend/civildesk-backend/database/migrations

# Run the migration (replace with your credentials)
psql -U postgres -d civildesk_db -f create_leaves_table.sql

# Expected output: 
# CREATE TABLE
# CREATE INDEX (multiple)
# CREATE FUNCTION
# CREATE TRIGGER
```

**Verify migration:**
```sql
-- Connect to your database and run:
SELECT table_name FROM information_schema.tables WHERE table_name = 'leaves';
-- Should return: leaves
```

### 2. Backend Setup (No changes needed!)

The backend is ready to use. Just ensure:
- ✅ `Leave.java` is in models folder
- ✅ `LeaveRepository.java` is in repository folder
- ✅ `LeaveService.java` is in service folder
- ✅ `LeaveController.java` is in controller folder
- ✅ DTOs are in dto folder

**Restart your Spring Boot application:**
```bash
cd civildesk-backend/civildesk-backend
./mvnw spring-boot:run
```

**Verify backend:**
- Check logs for: "Started CivildeskBackendApplication"
- Test endpoint: `GET http://localhost:8080/api/leaves/types`
- Should return list of leave types

### 3. Employee Frontend Setup (5 minutes)

```bash
# Navigate to employee app
cd civildesk_employee_frontend

# Install dependencies
flutter pub get

# Expected packages to be added:
# - file_picker (for medical certificate upload)
# - intl (for date formatting)
# - provider (already present)

# Run the app
flutter run -d chrome
# OR
flutter run -d windows
# OR for mobile
flutter run
```

**Verify:**
- ✅ App launches without errors
- ✅ Navigate to "Leaves" screen from sidebar
- ✅ Should see "Apply Leave" button
- ✅ No "Coming Soon" message

### 4. Admin Frontend Setup (5 minutes)

```bash
# Navigate to admin app
cd civildesk_frontend

# Install dependencies
flutter pub get

# Expected packages to be added:
# - url_launcher (for opening medical certificates)
# - intl (for date formatting)
# - provider (already present)

# Run the app
flutter run -d chrome
# OR
flutter run -d windows
```

**Add route for Leave Management screen:**

In `lib/routes/app_router.dart`, add this route:

```dart
case '/leaves-management':
  return MaterialPageRoute(
    builder: (_) => const LeavesManagementScreen(),
  );
```

And import:
```dart
import '../screens/admin/leaves_management_screen.dart';
```

**Add to navigation menu** (if needed):

In your admin sidebar/drawer, add:
```dart
ListTile(
  leading: Icon(Icons.event_note),
  title: Text('Leave Management'),
  onTap: () {
    Navigator.pushNamed(context, '/leaves-management');
  },
),
```

## Quick Test Flow

### Test 1: Employee Apply Leave (2 minutes)

1. Login as employee
2. Go to "Leaves" screen
3. Click "Apply Leave"
4. Fill form:
   - Leave Type: Sick Leave
   - Start Date: Tomorrow
   - End Date: Day after tomorrow
   - Contact: Your phone
   - Reason: "Test leave application"
5. Click "Submit"
6. Should see success message
7. Leave appears in list with PENDING status

### Test 2: Admin Review Leave (2 minutes)

1. Login as admin/HR
2. Go to "Leave Management" screen
3. Should see the test leave from employee
4. Click on the leave card
5. Review details
6. Click "APPROVE" button
7. Add note: "Approved for testing"
8. Confirm
9. Should see success message

### Test 3: Employee Check Status (1 minute)

1. Switch back to employee app
2. Go to "Leaves" screen
3. Pull down to refresh
4. Leave status should be APPROVED
5. Should see reviewer name and note
6. Edit/Delete buttons should be hidden

### Test 4: Responsibilities (2 minutes)

1. As employee, apply new leave
2. In "Hand over responsibility" select another employee
3. Submit leave
4. Login as the selected employee
5. Should see responsibility in "My Responsibilities" screen

## Troubleshooting

### Issue: "Table 'leaves' doesn't exist"

**Solution:**
```bash
# Run migration again
cd database/migrations
psql -U postgres -d civildesk_db -f create_leaves_table.sql
```

### Issue: "Cannot resolve symbol LeaveProvider"

**Solution:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
```

### Issue: "401 Unauthorized"

**Solution:**
- Ensure you're logged in
- Check JWT token is valid
- Verify user has correct role

### Issue: "File picker not working"

**Solution:**
```bash
# For web
flutter pub add file_picker
flutter run -d chrome

# For mobile - ensure permissions in:
# Android: AndroidManifest.xml
# iOS: Info.plist
```

### Issue: Backend compilation error

**Solution:**
- Ensure Java 17+ is installed
- Check all imports are correct
- Rebuild project: `./mvnw clean install`

## Verification Checklist

### Backend ✅
- [ ] Database migration completed
- [ ] No compilation errors
- [ ] Server starts successfully
- [ ] `/api/leaves/types` endpoint works

### Employee Frontend ✅
- [ ] No compilation errors
- [ ] LeaveProvider registered in main.dart
- [ ] Can navigate to Leaves screen
- [ ] Can open Apply Leave form
- [ ] Can submit leave application
- [ ] Can view leaves list

### Admin Frontend ✅
- [ ] No compilation errors
- [ ] LeaveProvider registered in main.dart
- [ ] Can navigate to Leave Management screen
- [ ] Can see all leaves
- [ ] Can open leave details
- [ ] Can approve/reject leaves

## Default Test Users

If you don't have test users, create them:

**Admin User:**
- Email: admin@civildesk.com
- Password: Admin@123
- Role: ADMIN

**Employee User:**
- Email: employee@civildesk.com
- Password: Employee@123
- Role: EMPLOYEE

## Feature Locations

### Backend
```
civildesk-backend/civildesk-backend/src/main/java/com/civiltech/civildesk_backend/
├── model/Leave.java
├── repository/LeaveRepository.java
├── service/LeaveService.java
├── controller/LeaveController.java
└── dto/
    ├── LeaveRequest.java
    ├── LeaveResponse.java
    └── LeaveReviewRequest.java
```

### Employee Frontend
```
civildesk_employee_frontend/lib/
├── models/
│   ├── leave.dart
│   └── employee.dart
├── core/
│   ├── services/
│   │   ├── leave_service.dart
│   │   └── employee_service.dart
│   └── providers/
│       └── leave_provider.dart
└── screens/leaves/
    ├── leaves_screen.dart
    ├── apply_leave_screen.dart
    └── responsibilities_screen.dart
```

### Admin Frontend
```
civildesk_frontend/lib/
├── models/leave.dart
├── core/
│   ├── services/leave_service.dart
│   └── providers/leave_provider.dart
└── screens/admin/
    ├── leaves_management_screen.dart
    └── leave_detail_screen.dart
```

## API Testing (Optional)

Use tools like Postman or curl:

**Get JWT Token:**
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"employee@civildesk.com","password":"Employee@123"}'
```

**Apply Leave:**
```bash
curl -X POST http://localhost:8080/api/leaves \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "leaveType": "SICK_LEAVE",
    "startDate": "2025-12-15",
    "endDate": "2025-12-16",
    "isHalfDay": false,
    "contactNumber": "9876543210",
    "reason": "Not feeling well"
  }'
```

**Get My Leaves:**
```bash
curl -X GET http://localhost:8080/api/leaves/my-leaves \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Performance Tips

1. **Database Indexing**: Already done in migration
2. **Pagination**: Consider for large datasets
3. **Caching**: Can add Redis for frequently accessed data
4. **Image Optimization**: Compress medical certificates

## Support Resources

- 📘 **Full Documentation**: LEAVE_MANAGEMENT_README.md
- 📋 **Implementation Details**: IMPLEMENTATION_SUMMARY.md
- 💾 **Database Scripts**: database/migrations/
- 🐛 **Troubleshooting**: See section above

## Estimated Setup Time

- ⏱️ Database Migration: 5 minutes
- ⏱️ Backend Setup: 2 minutes (restart)
- ⏱️ Employee Frontend: 5 minutes
- ⏱️ Admin Frontend: 5 minutes
- ⏱️ Testing: 10 minutes

**Total: ~30 minutes** for complete setup and testing

## Success Indicators

You'll know everything is working when:
- ✅ Employee can submit leave → see in list → status PENDING
- ✅ Admin can see leave → review → approve/reject
- ✅ Employee sees updated status → cannot edit anymore
- ✅ Responsibilities show up for assigned employees
- ✅ No errors in console/logs
- ✅ All UI elements display correctly

## Next Steps After Setup

1. Test all leave types
2. Test half-day leave
3. Test medical leave with certificate
4. Test filters in admin
5. Test with multiple employees
6. Configure email notifications (future)
7. Set up leave balance tracking (future)

---

**Ready to Start?** Follow steps 1-4 above in order! 🚀

**Need Help?** Check LEAVE_MANAGEMENT_README.md for detailed information.
