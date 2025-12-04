# Attendance Calculation - Final Implementation

## Overview
This document describes the final, corrected attendance calculation logic implemented in `AttendanceCalculationService.java`.

---

## Business Rules Summary

### 1. Standard Working Hours
- **Office Hours:** 09:00 AM to 18:00 PM
- **Standard Working Hours:** 8 hours per day (excluding lunch)
- **Working Days:** Monday to Saturday (weekdays 1-6)
- **Non-Working Days:** Sunday (weekday 7) - all hours are overtime

### 2. Check-In Time Rules
- **08:00-09:15 AM (inclusive):** Treated as 09:00 AM (no late penalty)
- **00:01-08:00 AM:** Counted as overtime (morning overtime)
- **After 09:15 AM (09:16+):** Deduct exact minutes late from working time
  - Example: 09:16 → deduct 16 minutes
  - Example: 09:30 → deduct 30 minutes

### 3. Check-Out Time Rules
- **18:00-19:00:** Treated as 18:00 (no penalty)
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

---

## Calculation Flow

### Step 1: Check for Sunday
If the date is Sunday, all hours between check-in and check-out are overtime.

### Step 2: Normalize Check-In Time
```java
- 08:00-09:15 (inclusive) → Normalize to 09:00 (no penalty)
- 00:01-08:00 → Normalize to 09:00 (overtime calculated separately)
- 09:16+ → Keep original time (late penalty applies)
```

### Step 3: Normalize Check-Out Time
```java
- 18:00-19:00 → Normalize to 18:00 (no penalty)
- Before 18:00 → Keep original (early penalty applies)
- After 19:00 → Keep original (overtime calculated separately)
```

### Step 4: Calculate Lunch Break
```java
- Always deduct 1 hour for lunch
- If lunch > 1 hour, extra time is deducted separately
- If no lunch recorded, still deduct 1 hour (compulsory)
```

### Step 5: Calculate Overtime
```java
Morning Overtime:
- If check-in between 00:01-08:00: Calculate from check-in to 08:00

Evening Overtime:
- If check-out after 19:00: Calculate from 19:00 to check-out
```

### Step 6: Calculate Working Hours
**Key Fix:** Uses standard office hours (9:00-18:00) as base, not actual check-in time.

```java
1. Start with standard period: 9:00 to 18:00 = 9.0 hours
2. Subtract lunch break: 9.0 - 1.0 = 8.0 hours
3. Subtract extra lunch time (if any)
4. Apply late check-in penalty (if after 09:15)
   - Deduct minutes late from 09:00
5. Apply early check-out penalty (if before 18:00)
   - Deduct minutes early before 18:00
6. Cap at 8 hours maximum
7. Ensure non-negative
```

---

## Test Cases

### Test Case 1: Standard Day
**Input:**
- Check in: 09:00 AM
- Lunch out: 13:00
- Lunch in: 14:00
- Check out: 18:00

**Calculation:**
1. Normalized check-in: 09:00 (grace period)
2. Normalized check-out: 18:00 (grace period)
3. Standard hours: 9:00-18:00 = 9.0 hours
4. Subtract lunch: 9.0 - 1.0 = 8.0 hours
5. No penalties
6. **Result: Working Hours = 8.0h, Overtime = 0.0h**

---

### Test Case 2: Late Check-In
**Input:**
- Check in: 09:30 AM
- Lunch out: 13:00
- Lunch in: 14:00
- Check out: 18:00

**Calculation:**
1. Normalized check-in: 09:30 (late, after 09:15)
2. Normalized check-out: 18:00 (grace period)
3. Standard hours: 9:00-18:00 = 9.0 hours
4. Subtract lunch: 9.0 - 1.0 = 8.0 hours
5. Late penalty: 09:30 is 30 minutes late → 8.0 - 0.5 = 7.5 hours
6. **Result: Working Hours = 7.5h, Overtime = 0.0h**

---

### Test Case 3: Grace Period Boundary (09:15)
**Input:**
- Check in: 09:15 AM
- Lunch out: 13:00
- Lunch in: 14:00
- Check out: 18:00

**Calculation:**
1. Normalized check-in: 09:00 (09:15 is in grace period, inclusive)
2. Normalized check-out: 18:00 (grace period)
3. Standard hours: 9:00-18:00 = 9.0 hours
4. Subtract lunch: 9.0 - 1.0 = 8.0 hours
5. No penalties (treated as on-time)
6. **Result: Working Hours = 8.0h, Overtime = 0.0h**

---

### Test Case 4: Early Check-Out
**Input:**
- Check in: 09:00 AM
- Lunch out: 13:00
- Lunch in: 14:00
- Check out: 17:30

**Calculation:**
1. Normalized check-in: 09:00 (grace period)
2. Normalized check-out: 17:30 (early, before 18:00)
3. Standard hours: 9:00-18:00 = 9.0 hours
4. Subtract lunch: 9.0 - 1.0 = 8.0 hours
5. Early penalty: 17:30 is 30 minutes early → 8.0 - 0.5 = 7.5 hours
6. **Result: Working Hours = 7.5h, Overtime = 0.0h**

---

### Test Case 5: Extended Lunch
**Input:**
- Check in: 09:00 AM
- Lunch out: 13:00
- Lunch in: 14:30 (1.5 hours)
- Check out: 18:00

**Calculation:**
1. Normalized check-in: 09:00 (grace period)
2. Normalized check-out: 18:00 (grace period)
3. Standard hours: 9:00-18:00 = 9.0 hours
4. Subtract lunch: 9.0 - 1.0 = 8.0 hours
5. Extra lunch: 0.5 hours → 8.0 - 0.5 = 7.5 hours
6. **Result: Working Hours = 7.5h, Overtime = 0.0h**

---

### Test Case 6: Evening Overtime
**Input:**
- Check in: 09:00 AM
- Lunch out: 13:00
- Lunch in: 14:00
- Check out: 20:00

**Calculation:**
1. Normalized check-in: 09:00 (grace period)
2. Normalized check-out: 20:00 (after 19:00)
3. Standard hours: 9:00-18:00 = 9.0 hours
4. Subtract lunch: 9.0 - 1.0 = 8.0 hours
5. No penalties for working hours
6. Evening overtime: 19:00 to 20:00 = 1.0 hour
7. **Result: Working Hours = 8.0h, Overtime = 1.0h**

---

### Test Case 7: Morning Overtime
**Input:**
- Check in: 07:00 AM
- Lunch out: 13:00
- Lunch in: 14:00
- Check out: 18:00

**Calculation:**
1. Normalized check-in: 09:00 (early check-in normalized)
2. Normalized check-out: 18:00 (grace period)
3. Standard hours: 9:00-18:00 = 9.0 hours
4. Subtract lunch: 9.0 - 1.0 = 8.0 hours
5. Morning overtime: 07:00 to 08:00 = 1.0 hour
6. **Result: Working Hours = 8.0h, Overtime = 1.0h**

---

### Test Case 8: Sunday Work
**Input:**
- Date: Sunday
- Check in: 09:00 AM
- Check out: 18:00

**Calculation:**
1. Sunday detected → All hours are overtime
2. Total time: 9.0 hours
3. **Result: Working Hours = 0.0h, Overtime = 9.0h**

---

## Key Implementation Details

### Fixed Bug: Working Hours Calculation
**Before (Buggy):**
- Used actual check-in time as base
- Double-counted late arrivals

**After (Fixed):**
- Uses standard office hours (9:00-18:00) as base
- Applies penalties correctly without double-counting

### Code Structure
```java
calculateAttendance()
  ├── Check for Sunday
  ├── normalizeCheckInTime()
  ├── normalizeCheckOutTime()
  ├── calculateLunchBreak()
  ├── calculateExtraLunchTime()
  ├── calculateMorningOvertime()
  ├── calculateEveningOvertime()
  └── calculateOfficeWorkingHours() ← Fixed logic here
```

### Working Hours Formula
```
Working Hours = 
  Standard Period (9:00-18:00 = 9h)
  - Lunch Break (1h)
  - Extra Lunch Time (if > 1h)
  - Late Check-In Penalty (if after 09:15)
  - Early Check-Out Penalty (if before 18:00)
  Capped at 8 hours maximum
```

---

## Constants

```java
OFFICE_START_TIME = 09:00 AM
OFFICE_END_TIME = 18:00 PM
STANDARD_WORKING_HOURS = 8 hours

GRACE_PERIOD_START = 08:00 AM
GRACE_PERIOD_END = 09:15 AM (inclusive)
LATE_CHECK_IN_START = 09:16 AM

CHECK_OUT_GRACE_START = 18:00 PM
CHECK_OUT_GRACE_END = 19:00 PM
EVENING_OVERTIME_START = 19:00 PM

STANDARD_LUNCH_HOURS = 1 hour
```

---

## Output Format

The calculation returns a `CalculationResult` object containing:
- **workingHours** (double): Office working hours (always ≤ 8.0)
- **overtimeHours** (double): Total overtime hours

Both values are stored in the database and displayed in the frontend.

---

## Notes

1. Working hours are always capped at 8 hours maximum
2. Working hours cannot be negative
3. Overtime is calculated separately and can exceed 8 hours
4. Sunday work is always 100% overtime
5. Lunch break is always deducted (minimum 1 hour)
6. Extra lunch time is deducted from working hours
7. Late check-in and early check-out penalties are applied correctly

