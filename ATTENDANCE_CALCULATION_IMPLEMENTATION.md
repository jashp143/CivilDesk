# Attendance Calculation Implementation

## Overview

This document describes the implementation of attendance calculation rules for working hours and overtime calculation in the Civildesk system.

## Implementation Details

### 1. Attendance Calculation Service

**File:** `AttendanceCalculationService.java`

A dedicated service that implements all attendance calculation rules:

- **Standard Working Days:** Monday to Saturday (weekdays 1-6)
- **Non-Working Days:** Sunday (weekday 7) - all hours are overtime
- **Standard Office Hours:** 09:00 AM to 18:00 PM
- **Standard Working Hours:** 8 hours per day (excluding lunch)

### 2. Check-In Time Rules

- **08:00-09:15 AM:** Treated as 09:00 AM (no late penalty)
- **00:01-08:00 AM:** Counted as overtime (morning overtime)
- **After 09:15 AM:** Deduct exact minutes late from working time
  - Example: 09:16 → deduct 16 minutes
  - Example: 09:30 → deduct 30 minutes

### 3. Check-Out Time Rules

- **18:00-19:00:** Treated as 18:00
- **Before 18:00:** Deduct exact minutes early from working time
- **After 19:00:** Counted as overtime (evening overtime)

### 4. Lunch Break Rules

- **Window:** 11:00 AM to 16:00 PM
- **Minimum:** 1 hour (if less than 1 hour, treat as 1 hour)
- **Maximum:** If more than 1 hour, deduct the extra time from working hours
- **Compulsory:** If no lunch-out/lunch-in recorded, deduct 1 hour automatically

### 5. Overtime Calculation

- **Morning Overtime:** Work between 00:01-08:00 AM
- **Evening Overtime:** Work after 19:00 PM (7:00 PM)
- **Sunday/Holiday Work:** All working hours are considered overtime

## Database Changes

### New Columns Added to Attendance Table

1. **working_hours** (DOUBLE PRECISION)
   - Calculated office working hours (always <= 8 hours)
   - Stored in hours (e.g., 8.0, 7.5, 6.25)

2. **overtime_hours** (DOUBLE PRECISION)
   - Calculated overtime hours
   - Stored in hours (e.g., 2.0, 1.5, 0.5)

### Migration Scripts

- **File:** `database/migrations/add_working_hours_to_attendance.sql`
- **File:** `src/main/resources/db/migration/add_working_hours_to_attendance.sql`

Both scripts add the new columns with proper null handling and documentation.

## Code Changes

### 1. Attendance Model

**File:** `Attendance.java`

Added fields:
```java
@Column(name = "working_hours")
private Double workingHours;

@Column(name = "overtime_hours")
private Double overtimeHours;
```

### 2. AttendanceResponse DTO

**File:** `AttendanceResponse.java`

Added fields:
```java
private Double workingHours;
private Double overtimeHours;
```

### 3. AttendanceService

**File:** `AttendanceService.java`

Updated to:
- Inject `AttendanceCalculationService`
- Calculate working hours and overtime when:
  - Attendance is marked (if both check-in and check-out are present)
  - Check-out is performed
  - Punch times are updated
- Include calculated values in response

## Calculation Logic Flow

1. **Check if Sunday:** If Sunday, all hours are overtime, return (0 working hours, total hours as overtime)

2. **Normalize Check-In Time:**
   - 08:00-09:15 → 09:00
   - 00:01-08:00 → 09:00 (for working hours), overtime calculated separately
   - After 09:15 → Keep original (late penalty applied)

3. **Normalize Check-Out Time:**
   - 18:00-19:00 → 18:00
   - Before 18:00 → Keep original (early penalty applied)
   - After 19:00 → Keep original (overtime calculated separately)

4. **Calculate Lunch Break:**
   - Always 1 hour deducted
   - Extra time (if > 1 hour) deducted separately from working hours

5. **Calculate Overtime:**
   - Morning: 00:01-08:00 (from check-in to 08:00)
   - Evening: After 19:00 (from 19:00 to check-out)

6. **Calculate Working Hours:**
   - Total time between normalized check-in and check-out
   - Subtract 1 hour lunch break
   - Subtract extra lunch time (if any)
   - Subtract late check-in penalty (if after 09:15)
   - Subtract early check-out penalty (if before 18:00)
   - Cap at 8 hours maximum
   - Ensure non-negative

## Usage

The calculation is automatically performed when:
- An employee checks out
- Attendance is marked with both check-in and check-out times
- Punch times are manually updated by admin

The calculated values are:
- Stored in the database
- Included in API responses
- Available for reporting and payroll

## Example Calculations

### Example 1: Standard Day
- Check-in: 09:00 AM
- Lunch: 12:00-13:00 (1 hour)
- Check-out: 18:00 PM
- **Working Hours:** 8.0 hours
- **Overtime:** 0.0 hours

### Example 2: Late Check-In
- Check-in: 09:30 AM
- Lunch: 12:00-13:00 (1 hour)
- Check-out: 18:00 PM
- **Working Hours:** 7.5 hours (8.0 - 0.5 late)
- **Overtime:** 0.0 hours

### Example 3: Early Check-Out
- Check-in: 09:00 AM
- Lunch: 12:00-13:00 (1 hour)
- Check-out: 17:30 PM
- **Working Hours:** 7.5 hours (8.0 - 0.5 early)
- **Overtime:** 0.0 hours

### Example 4: Evening Overtime
- Check-in: 09:00 AM
- Lunch: 12:00-13:00 (1 hour)
- Check-out: 20:00 PM
- **Working Hours:** 8.0 hours (capped at 8)
- **Overtime:** 1.0 hours (19:00-20:00)

### Example 5: Morning Overtime
- Check-in: 07:00 AM
- Lunch: 12:00-13:00 (1 hour)
- Check-out: 18:00 PM
- **Working Hours:** 8.0 hours
- **Overtime:** 1.0 hours (07:00-08:00)

### Example 6: Sunday Work
- Check-in: 09:00 AM
- Check-out: 18:00 PM
- **Working Hours:** 0.0 hours
- **Overtime:** 9.0 hours (all hours on Sunday)

### Example 7: Extended Lunch
- Check-in: 09:00 AM
- Lunch: 12:00-14:00 (2 hours)
- Check-out: 18:00 PM
- **Working Hours:** 7.0 hours (8.0 - 1.0 extra lunch)
- **Overtime:** 0.0 hours

## Testing

To test the implementation:

1. Run the database migration script
2. Mark attendance with various scenarios
3. Verify calculated values in the database
4. Check API responses include working hours and overtime

## Notes

- Working hours are always capped at 8 hours maximum
- Working hours cannot be negative
- Overtime is calculated separately and can exceed 8 hours
- Sunday work is always 100% overtime
- Lunch break is always deducted (minimum 1 hour)
- Extra lunch time is deducted from working hours

