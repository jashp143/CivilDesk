# Holiday Management Feature

## Overview
A comprehensive holiday management system that allows admins to define company holidays. When a holiday is created, normalized attendance is automatically marked for all employees with standard times (Check-in: 09:00, Lunch-out: 13:00, Lunch-in: 14:00, Check-out: 18:00) to ensure 8 working hours.

## Features Implemented

### Backend (Java Spring Boot)

#### 1. Database Schema
- **File**: `database/migrations/create_holidays_table.sql`
- Created `holidays` table with optimized indexes:
  - `idx_holidays_date` - For date lookups
  - `idx_holidays_active` - For active holiday queries
  - `idx_holidays_date_active` - Composite index for range queries
- Unique constraint on `date` column
- Soft delete support

#### 2. Model
- **File**: `model/Holiday.java`
- Extends `BaseEntity` for common fields
- Fields: `date`, `name`, `description`, `isActive`

#### 3. Repository
- **File**: `repository/HolidayRepository.java`
- Optimized queries for:
  - Finding holidays by date
  - Finding holidays in date range
  - Finding upcoming holidays
  - Active holiday filtering

#### 4. Service Layer
- **File**: `service/HolidayService.java`
- **Key Features**:
  - Create/Update/Delete holidays
  - Automatic normalized attendance marking
  - Sunday handling (no marking needed)
  - Attendance removal when holiday is deactivated/deleted

**Normalized Attendance Times**:
- Check-in: 09:00 AM
- Lunch-out: 13:00 PM
- Lunch-in: 14:00 PM
- Check-out: 18:00 PM
- Result: 8 working hours

**Sunday Logic**:
- If holiday falls on Sunday, no attendance is marked
- Sunday is already a non-working day
- System skips attendance marking automatically

#### 5. REST API Endpoints
- **File**: `controller/HolidayController.java`
- **Endpoints**:
  - `POST /api/holidays` - Create holiday
  - `PUT /api/holidays/{id}` - Update holiday
  - `DELETE /api/holidays/{id}` - Delete holiday
  - `GET /api/holidays/{id}` - Get holiday by ID
  - `GET /api/holidays/date/{date}` - Get holiday by date
  - `GET /api/holidays` - Get all active holidays
  - `GET /api/holidays/range?startDate=&endDate=` - Get holidays in range
  - `GET /api/holidays/upcoming` - Get upcoming holidays

### Frontend (Flutter)

#### 1. Models
- **File**: `lib/models/holiday.dart`
- `Holiday` class with JSON serialization

#### 2. State Management
- **File**: `lib/core/providers/holiday_provider.dart`
- Provider for managing holiday state
- CRUD operations with error handling

#### 3. UI Screen
- **File**: `lib/screens/admin/holiday_management_screen.dart`
- **Features**:
  - Beautiful, modern card-based design
  - Add/Edit/Delete holidays
  - Date picker with day of week display
  - Sunday warning indicator
  - Grouped by year
  - Color-coded cards (green for active, purple for Sunday, grey for inactive)
  - Info cards explaining normalized attendance
  - Empty and error states

#### 4. Navigation Integration
- Added to admin sidebar
- Route: `/admin/holidays`
- Icon: Event calendar icon
- Protected by admin route guard

## How It Works

### Creating a Holiday

1. **Admin selects date** from date picker
2. **System checks if Sunday**:
   - If Sunday: Shows warning that no attendance will be marked
   - If not Sunday: Proceeds normally
3. **Admin enters holiday name** (required)
4. **Admin enters description** (optional)
5. **Admin sets active status** (default: true)
6. **On save**:
   - Holiday is created in database
   - If active and not Sunday:
     - System gets all active employees
     - Creates/updates attendance for each employee with normalized times
     - Sets `recognitionMethod = "HOLIDAY"`
     - Calculates 8 working hours

### Updating a Holiday

1. **Date change**:
   - Removes normalized attendance from old date
   - Marks normalized attendance for new date (if active and not Sunday)
2. **Status change**:
   - Deactivating: Removes normalized attendance
   - Activating: Marks normalized attendance (if not Sunday)

### Deleting a Holiday

1. Removes normalized attendance for all employees
2. Soft deletes the holiday record

### Normalized Attendance Marking

**Process**:
1. Check if date is Sunday → Skip if true
2. Get all active employees
3. For each employee:
   - Check if attendance exists for date
   - Create or update attendance record
   - Set normalized times
   - Set status to PRESENT
   - Set recognitionMethod to "HOLIDAY"
   - Calculate working hours (should be 8.0)
   - Save attendance

**Attendance Record**:
```java
checkInTime: 09:00
lunchOutTime: 13:00
lunchInTime: 14:00
checkOutTime: 18:00
workingHours: 8.0
overtimeHours: 0.0
status: PRESENT
recognitionMethod: "HOLIDAY"
notes: "Holiday: Normalized attendance"
```

## UI/UX Features

### Visual Design
- **Color Coding**:
  - Green: Active holidays
  - Purple: Sunday holidays (non-working)
  - Grey: Inactive holidays
- **Card Layout**: Modern cards with gradients
- **Grouping**: Holidays grouped by year
- **Icons**: Calendar icons, status indicators
- **Responsive**: Works on all screen sizes

### User Experience
- **Date Picker**: Shows day of week
- **Sunday Warning**: Clear indicator when Sunday is selected
- **Info Cards**: Explains normalized attendance
- **Empty States**: Helpful messages
- **Error Handling**: Clear error messages
- **Confirmation Dialogs**: For delete operations
- **Success Messages**: Feedback after operations

## Example Scenarios

### Scenario 1: Republic Day (January 26)
- **Date**: January 26, 2024 (Friday)
- **Name**: "Republic Day"
- **Result**: 
  - Holiday created
  - All employees get normalized attendance:
    - Check-in: 09:00
    - Check-out: 18:00
    - Working hours: 8.0

### Scenario 2: Holiday on Sunday
- **Date**: January 28, 2024 (Sunday)
- **Name**: "Some Holiday"
- **Result**:
  - Holiday created
  - No attendance marked (Sunday is non-working)
  - System shows warning in UI

### Scenario 3: Deactivating Holiday
- **Action**: Deactivate existing holiday
- **Result**:
  - Holiday marked as inactive
  - Normalized attendance removed for all employees
  - Holiday still visible but marked as inactive

## Database Schema

```sql
CREATE TABLE holidays (
    id BIGSERIAL PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN DEFAULT FALSE,
    created_by BIGINT,
    updated_by BIGINT
);
```

## API Examples

### Create Holiday
```bash
POST /api/holidays
{
  "date": "2024-01-26",
  "name": "Republic Day",
  "description": "National holiday",
  "isActive": true
}
```

### Response
```json
{
  "success": true,
  "message": "Holiday created successfully and normalized attendance marked for all employees",
  "data": {
    "id": 1,
    "date": "2024-01-26",
    "name": "Republic Day",
    "description": "National holiday",
    "isActive": true,
    "createdAt": "2024-01-15T10:00:00",
    "updatedAt": "2024-01-15T10:00:00"
  }
}
```

## Performance Optimizations

1. **Database Indexes**: Optimized for date lookups and range queries
2. **Batch Operations**: All employees processed in single transaction
3. **Efficient Queries**: Uses indexed columns for fast retrieval
4. **Lazy Loading**: Data loaded only when needed

## Security

- **Role-Based Access**: Only ADMIN can create/update/delete holidays
- **HR_MANAGER**: Can view holidays
- **Validation**: Date uniqueness, required fields
- **Soft Delete**: Holidays can be restored if needed

## Testing Checklist

- [x] Create holiday on working day
- [x] Create holiday on Sunday (no marking)
- [x] Update holiday date
- [x] Update holiday status
- [x] Delete holiday
- [x] Verify normalized attendance times
- [x] Verify 8 working hours calculation
- [x] Test with multiple employees
- [x] Test inactive holiday
- [x] UI displays correctly
- [x] Error handling works

## Files Created/Modified

### Backend
- ✅ `database/migrations/create_holidays_table.sql` (NEW)
- ✅ `model/Holiday.java` (NEW)
- ✅ `repository/HolidayRepository.java` (NEW)
- ✅ `dto/HolidayRequest.java` (NEW)
- ✅ `dto/HolidayResponse.java` (NEW)
- ✅ `service/HolidayService.java` (NEW)
- ✅ `controller/HolidayController.java` (NEW)

### Frontend
- ✅ `lib/models/holiday.dart` (NEW)
- ✅ `lib/core/providers/holiday_provider.dart` (NEW)
- ✅ `lib/screens/admin/holiday_management_screen.dart` (NEW)
- ✅ `lib/core/constants/app_routes.dart` (MODIFIED)
- ✅ `lib/routes/app_router.dart` (MODIFIED)
- ✅ `lib/widgets/admin_layout.dart` (MODIFIED)
- ✅ `lib/main.dart` (MODIFIED)

## Deployment Steps

1. **Database Migration**:
   ```bash
   psql -U username -d civildesk -f create_holidays_table.sql
   ```

2. **Backend**: Rebuild and restart Spring Boot application

3. **Frontend**: Rebuild Flutter application

4. **Verify**: 
   - Check navigation menu for "Holidays"
   - Test creating a holiday
   - Verify attendance is marked correctly

## Future Enhancements

1. **Recurring Holidays**: Support for annual recurring holidays
2. **Bulk Import**: Import holidays from CSV/Excel
3. **Holiday Calendar View**: Calendar widget showing all holidays
4. **Notifications**: Notify employees of upcoming holidays
5. **Holiday Templates**: Pre-defined holiday templates
6. **Department-Specific Holidays**: Different holidays for different departments

## Summary

✅ **Complete holiday management system**
✅ **Automatic normalized attendance marking**
✅ **Sunday handling (no marking)**
✅ **Modern, beautiful UI**
✅ **Optimized database queries**
✅ **Role-based security**
✅ **Comprehensive error handling**

The system is production-ready and provides a seamless way to manage company holidays while ensuring all employees get proper attendance records! 🎉

