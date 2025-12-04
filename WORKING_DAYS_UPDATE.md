# Working Days Logic Update

## Overview
Updated the attendance system to reflect the new working days policy:
- **Monday to Saturday**: Working days
- **Sunday**: Non-working day (all hours worked on Sunday are counted as overtime)

## Changes Made

### Backend Changes

#### 1. AttendanceService.java
**File**: `civildesk-backend/civildesk-backend/src/main/java/com/civiltech/civildesk_backend/service/AttendanceService.java`

**Updated Method**: `calculateWorkingDays()`
- **Before**: Excluded both Saturday and Sunday
- **After**: Only excludes Sunday (Monday-Saturday are working days)

```java
// Updated logic
private int calculateWorkingDays(LocalDate startDate, LocalDate endDate) {
    int workingDays = 0;
    LocalDate currentDate = startDate;
    
    while (!currentDate.isAfter(endDate)) {
        DayOfWeek dayOfWeek = currentDate.getDayOfWeek();
        // Monday to Saturday are working days, Sunday is non-working day
        if (dayOfWeek != DayOfWeek.SUNDAY) {
            workingDays++;
        }
        currentDate = currentDate.plusDays(1);
    }
    
    return workingDays;
}
```

**Impact**:
- Working days calculation now includes Saturday
- Attendance percentage calculations are more accurate
- Total working days count includes Saturday

#### 2. AttendanceCalculationService.java
**File**: `civildesk-backend/civildesk-backend/src/main/java/com/civiltech/civildesk_backend/service/AttendanceCalculationService.java`

**Updated Comments**: Clarified that Sunday hours are counted as overtime
- Already had correct logic (Sunday hours = 100% overtime)
- Updated comments to clarify Monday-Saturday are working days

**Existing Logic** (No changes needed):
```java
// Check if it's Sunday - all hours worked on Sunday are considered overtime
// Monday to Saturday are working days, Sunday is non-working day
if (isSunday) {
    // For Sunday, all working hours are counted as overtime
    double totalMinutes = Duration.between(checkIn, checkOut).toMinutes();
    return new CalculationResult(0.0, totalMinutes / 60.0);
}
```

### Frontend Changes

#### 1. Attendance Analytics Screen
**File**: `civildesk_frontend/lib/screens/admin/attendance_analytics_screen.dart`

**Updates**:

1. **Sunday Highlighting in Daily Logs**:
   - Sunday entries now have a purple background tint
   - "Non-Working" badge displayed for Sunday entries
   - Purple color coding for Sunday overtime hours
   - Tooltip showing "All hours counted as OT" for Sunday entries

2. **Visual Indicators**:
   ```dart
   // Check if it's Sunday (non-working day)
   final isSunday = log.dayOfWeek.toUpperCase() == 'SUNDAY';
   
   // Sunday entries get purple background
   decoration: BoxDecoration(
     color: isSunday
         ? Colors.purple.withOpacity(0.05)
         : log.isLate 
             ? Colors.orange.withOpacity(0.05) 
             : null,
   ),
   ```

3. **Information Tooltip**:
   - Added info icon next to "Statistics" header
   - Tooltip explains: "Working days: Monday to Saturday. Sunday is non-working (all hours counted as overtime)."
   - Tooltip on "Working Days" stat card for additional context

4. **Overtime Display**:
   - Sunday overtime hours displayed in purple (instead of orange)
   - Clear visual distinction between regular overtime and Sunday overtime

## How It Works

### Working Hours Calculation

1. **Monday to Saturday**:
   - Normal working hours calculation applies
   - Standard 8-hour working day
   - Overtime calculated for:
     - Early check-in (before 8:00 AM)
     - Late check-out (after 7:00 PM)
   - Working hours stored in `working_hours` column
   - Overtime stored in `overtime_hours` column

2. **Sunday**:
   - All hours worked are counted as overtime
   - `working_hours` = 0
   - `overtime_hours` = total hours worked
   - Example: If employee works 6 hours on Sunday:
     - `working_hours` = 0.0
     - `overtime_hours` = 6.0

### Analytics Impact

1. **Total Working Days**:
   - Now includes Saturday
   - Example: Week with Monday-Sunday = 6 working days (not 5)

2. **Attendance Percentage**:
   - Based on Monday-Saturday working days
   - More accurate calculation with Saturday included

3. **Overtime Totals**:
   - Includes all Sunday hours as overtime
   - Regular overtime (early/late hours) still calculated separately

4. **Days Present Calculation**:
   - Based on `working_hours / 8`
   - Sunday doesn't contribute to days present (since working_hours = 0)

## Visual Changes in UI

### Daily Logs Table

**Sunday Entry Example**:
```
┌─────────────────────────────────────────────────────────┐
│ Jan 07, Sun  [Non-Working]                              │
│ ⏰ All hours counted as OT                              │
│                                                          │
│ Check In: 10:00 AM  |  Check Out: 4:00 PM              │
│ Hours: -  |  OT: 6.0h (purple)  |  Status: ✓           │
└─────────────────────────────────────────────────────────┘
```

**Saturday Entry Example** (Normal Working Day):
```
┌─────────────────────────────────────────────────────────┐
│ Jan 06, Sat                                             │
│                                                          │
│ Check In: 9:00 AM  |  Check Out: 6:00 PM               │
│ Hours: 8.0h  |  OT: 0.0h  |  Status: ✓                │
└─────────────────────────────────────────────────────────┘
```

### Statistics Cards

- **Working Days**: Now shows count including Saturday
- **Total Overtime**: Includes Sunday hours
- **Tooltip**: Explains working days policy on hover

## Testing Checklist

- [x] Saturday is counted as working day
- [x] Sunday is excluded from working days
- [x] Sunday hours are 100% overtime
- [x] Saturday hours calculated normally
- [x] Attendance percentage includes Saturday
- [x] UI shows Sunday as non-working day
- [x] Sunday entries highlighted in purple
- [x] Overtime totals include Sunday hours
- [x] Working days count includes Saturday

## Database Impact

**No database schema changes required**

The existing columns handle the new logic:
- `working_hours`: Already stores 0 for Sunday
- `overtime_hours`: Already stores all Sunday hours
- No migration needed

## Backward Compatibility

✅ **Fully backward compatible**

- Existing attendance records work correctly
- Sunday records already have `working_hours = 0`
- No data migration needed
- Only calculation logic updated

## Example Scenarios

### Scenario 1: Week with Sunday Work
- **Monday-Friday**: 8 hours each = 40 working hours
- **Saturday**: 8 hours = 8 working hours
- **Sunday**: 6 hours = 0 working hours, 6 overtime hours
- **Total**: 48 working hours, 6 overtime hours
- **Working Days**: 6 days (Mon-Sat)

### Scenario 2: Week without Sunday Work
- **Monday-Friday**: 8 hours each = 40 working hours
- **Saturday**: 8 hours = 8 working hours
- **Sunday**: No attendance
- **Total**: 48 working hours, 0 overtime hours
- **Working Days**: 6 days (Mon-Sat)

### Scenario 3: Partial Week
- **Monday-Wednesday**: 8 hours each = 24 working hours
- **Thursday-Sunday**: No attendance
- **Total**: 24 working hours, 0 overtime hours
- **Working Days**: 3 days (Mon-Wed)

## Migration Notes

**No migration required** - this is a logic-only change.

However, if you want to verify existing data:

```sql
-- Check Sunday attendance records
SELECT 
    date,
    employee_id,
    working_hours,
    overtime_hours,
    check_in_time,
    check_out_time
FROM attendance
WHERE EXTRACT(DOW FROM date) = 0  -- Sunday
ORDER BY date DESC
LIMIT 10;

-- Verify Sunday records have working_hours = 0
SELECT COUNT(*) 
FROM attendance 
WHERE EXTRACT(DOW FROM date) = 0 
  AND working_hours != 0;
-- Should return 0 if all Sunday records are correctly calculated
```

## Summary

✅ **Backend**: Updated working days calculation to include Saturday, exclude Sunday
✅ **Frontend**: Added visual indicators for Sunday (non-working day)
✅ **Logic**: Sunday hours already counted as overtime (no change needed)
✅ **UI/UX**: Clear visual distinction for Sunday entries
✅ **Compatibility**: Fully backward compatible, no data migration needed

The system now correctly reflects that:
- **Monday to Saturday** = Working days
- **Sunday** = Non-working day (all hours = overtime)

