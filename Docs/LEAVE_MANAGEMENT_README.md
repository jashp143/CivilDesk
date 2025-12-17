# Leave Management System - Implementation Guide

## Overview

A comprehensive leave management system has been implemented for the Civildesk application, allowing employees to apply for leaves and administrators/HR to review and manage them.

## Features Implemented

### Employee Side Features

1. **Leave Application Form**
   - Multiple leave types (Sick, Casual, Annual, Medical, Emergency, etc.)
   - Date range selection with half-day option
   - Contact number during leave
   - Hand over responsibility to other employees (multi-select)
   - Reason for leave
   - Medical certificate upload for medical leaves
   - Form validation

2. **My Leaves Screen**
   - View all leave applications
   - Card-based UI with status indicators
   - Edit/Delete functionality (only for PENDING leaves)
   - Detailed leave information
   - Pull-to-refresh

3. **My Responsibilities Screen**
   - View leaves where current employee is assigned responsibilities
   - Shows active and upcoming responsibilities
   - Contact information of employees on leave
   - Detailed responsibility information

### Admin/HR Side Features

1. **Leave Management Screen**
   - Card view of all employee leaves
   - Responsive grid layout (1-3 columns based on screen width)
   - Advanced filtering options:
     - Filter by status (Pending, Approved, Rejected, Cancelled)
     - Filter by leave type
     - Filter by department
   - Quick status overview
   - Pull-to-refresh

2. **Leave Detail Screen**
   - Comprehensive leave information display
   - Employee details
   - Leave duration and type
   - Contact information
   - Handover responsibilities list
   - Reason for leave
   - Medical certificate viewer (for medical leaves)
   - Approve/Reject functionality with optional notes
   - Review history

### Backend Features

1. **RESTful API Endpoints**
   - `POST /api/leaves` - Apply for leave
   - `PUT /api/leaves/{id}` - Update leave (only PENDING)
   - `DELETE /api/leaves/{id}` - Delete leave (only PENDING)
   - `GET /api/leaves/my-leaves` - Get employee's leaves
   - `GET /api/leaves/my-responsibilities` - Get assigned responsibilities
   - `GET /api/leaves` - Get all leaves (with filters)
   - `GET /api/leaves/{id}` - Get leave details
   - `PUT /api/leaves/{id}/review` - Approve/Reject leave
   - `GET /api/leaves/types` - Get all leave types
   - `GET /api/leaves/statuses` - Get all statuses

2. **Business Logic**
   - Automatic leave days calculation
   - Half-day leave validation
   - Medical certificate requirement for medical leaves
   - Status-based edit/delete restrictions
   - Role-based access control
   - Soft delete implementation

## Database Schema

The `leaves` table includes:
- Employee information (foreign key)
- Leave type (enum)
- Date range (start_date, end_date)
- Half-day support (is_half_day, half_day_period)
- Contact information
- Handover responsibilities (employee IDs)
- Reason and medical certificate URL
- Status tracking
- Review information (reviewer, timestamp, notes)
- Audit fields (created_at, updated_at, deleted)

## Installation Steps

### 1. Database Migration

Run the SQL migration script to create the leaves table:

```bash
cd civildesk-backend/civildesk-backend/database/migrations
psql -U your_username -d your_database -f create_leaves_table.sql
```

To rollback (if needed):
```bash
psql -U your_username -d your_database -f ROLLBACK_create_leaves_table.sql
```

### 2. Backend Dependencies

No additional dependencies required. The implementation uses existing Spring Boot libraries.

### 3. Frontend Dependencies

#### Employee Frontend

Add to `pubspec.yaml` (if not already present):
```yaml
dependencies:
  file_picker: ^6.0.0
  intl: ^0.18.0
```

Run:
```bash
cd civildesk_employee_frontend
flutter pub get
```

#### Admin Frontend

Add to `pubspec.yaml` (if not already present):
```yaml
dependencies:
  url_launcher: ^6.2.0
  intl: ^0.18.0
```

Run:
```bash
cd civildesk_frontend
flutter pub get
```

### 4. Update Routes (if needed)

#### Employee App Routes

Check `lib/routes/app_router.dart` and ensure routes exist:
- `/leaves` - LeavesScreen
- Add route for ResponsibilitiesScreen if needed

#### Admin App Routes

Check `lib/routes/app_router.dart` and add route:
- `/leaves-management` - LeavesManagementScreen

## Usage Guide

### For Employees

1. **Apply for Leave**
   - Navigate to Leaves screen
   - Click "Apply Leave" button
   - Fill in all required fields:
     - Select leave type
     - Choose date range
     - Toggle half-day if needed (select period)
     - Enter contact number
     - Select employees for handover (optional)
     - Write reason
     - Upload medical certificate (if medical leave)
   - Submit application

2. **Edit/Delete Leave**
   - Only possible when status is PENDING
   - Click on the leave card
   - Use Edit or Delete buttons
   - Confirm action

3. **View Responsibilities**
   - Access from side navigation or leave screen
   - See all leaves where you're assigned
   - View employee contact information
   - Check leave duration and reason

### For Admin/HR

1. **View All Leaves**
   - Navigate to Leave Management screen
   - See all employee leave applications in card view
   - Use filters to narrow down leaves:
     - Status filter (Pending, Approved, Rejected)
     - Leave type filter
     - Department filter
   - Click "Clear All" to reset filters

2. **Review Leave Application**
   - Click on any leave card
   - Review all details
   - Click "APPROVE" or "REJECT" button
   - Optionally add a note for the employee
   - Confirm action

3. **View Medical Certificates**
   - For medical leaves, click "View Certificate" button
   - Opens in external browser/viewer

## Leave Types

The system supports the following leave types:
- **Sick Leave** - For illness
- **Casual Leave** - For personal reasons
- **Annual Leave** - Planned vacation/holiday
- **Maternity Leave** - For maternity purposes
- **Paternity Leave** - For paternity purposes
- **Medical Leave** - For medical treatment (requires certificate)
- **Emergency Leave** - For urgent situations
- **Unpaid Leave** - Without pay
- **Compensatory Off** - For overtime work

## Leave Status Flow

```
PENDING → APPROVED ✓
        → REJECTED ✗
        → CANCELLED (by employee while PENDING)
```

### Status Rules

- **PENDING**: Can be edited/deleted by employee, can be reviewed by admin/HR
- **APPROVED**: Cannot be edited/deleted, review complete
- **REJECTED**: Cannot be edited/deleted, review complete
- **CANCELLED**: Soft-deleted by employee

## API Examples

### Apply for Leave

```bash
POST /api/leaves
Authorization: Bearer <token>
Content-Type: application/json

{
  "leaveType": "SICK_LEAVE",
  "startDate": "2025-12-15",
  "endDate": "2025-12-16",
  "isHalfDay": false,
  "contactNumber": "9876543210",
  "handoverEmployeeIds": [5, 12],
  "reason": "Feeling unwell and need rest"
}
```

### Approve Leave

```bash
PUT /api/leaves/123/review
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "APPROVED",
  "reviewNote": "Approved. Take care and get well soon."
}
```

### Get Leaves with Filters

```bash
GET /api/leaves?status=PENDING&department=Engineering
Authorization: Bearer <token>
```

## Permissions

### Employee Permissions
- Apply for leave
- View own leaves
- Edit/Delete own PENDING leaves
- View assigned responsibilities

### Admin/HR Permissions
- View all leaves
- Filter leaves by status, type, department
- Review (Approve/Reject) leaves
- View all employee information
- Add review notes

## UI/UX Features

### Employee Side
- Intuitive form with validation
- Real-time status updates
- Color-coded status badges
- Swipe-to-refresh
- Responsive card layout
- Easy edit/delete for pending leaves

### Admin Side
- Responsive grid layout (adapts to screen size)
- Advanced filtering system
- Quick status overview
- Detailed information display
- One-click approve/reject
- Review notes support
- Professional card design

## Error Handling

The system includes comprehensive error handling:
- Form validation errors
- Network errors
- Authorization errors
- Business logic errors (e.g., trying to edit approved leave)
- Database errors

All errors are displayed with user-friendly messages.

## Future Enhancements (Optional)

1. Leave balance tracking
2. Email notifications for status changes
3. Leave calendar view
4. Bulk approval
5. Leave statistics and reports
6. Leave policy rules engine
7. Mobile push notifications
8. Leave carry-forward
9. Public holiday integration
10. Team leave calendar

## Testing Checklist

### Employee Tests
- [ ] Apply for different leave types
- [ ] Apply for half-day leave
- [ ] Upload medical certificate
- [ ] Select multiple handover employees
- [ ] Edit pending leave
- [ ] Delete pending leave
- [ ] Try to edit approved leave (should fail)
- [ ] View responsibilities

### Admin Tests
- [ ] View all leaves
- [ ] Filter by status
- [ ] Filter by leave type
- [ ] Filter by department
- [ ] Clear filters
- [ ] Approve leave
- [ ] Reject leave
- [ ] Add review notes
- [ ] View medical certificate
- [ ] View handover employees

## Troubleshooting

### Issue: Leaves not showing
- Check if backend is running
- Verify JWT token is valid
- Check network connectivity
- Verify user has correct role

### Issue: Cannot upload medical certificate
- Check file picker permissions
- Verify file format (PDF, JPG, PNG)
- Check upload endpoint configuration

### Issue: Cannot approve/reject
- Verify user has ADMIN or HR_MANAGER role
- Check if leave status is PENDING
- Verify API endpoint is accessible

## Support

For issues or questions:
1. Check this README
2. Review API documentation
3. Check backend logs
4. Contact development team

## License

Copyright © 2025 Civildesk. All rights reserved.
