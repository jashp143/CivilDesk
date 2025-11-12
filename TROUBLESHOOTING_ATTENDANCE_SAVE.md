# Troubleshooting: Attendance Records Not Saving to Database

If attendance records are not appearing in PostgreSQL, follow these steps:

## Step 1: Check Backend Logs

When you mark attendance, check your Spring Boot console logs. You should see:
- `=== Marking Attendance ===`
- Employee ID and details
- `Saving attendance record...`
- `Attendance saved successfully! ID: X`

**If you see errors**, note them down.

## Step 2: Verify Database Columns Exist

The attendance table needs `lunch_out_time` and `lunch_in_time` columns. Run this in pgAdmin:

```sql
-- Check if lunch columns exist
SELECT 
    column_name, 
    data_type
FROM information_schema.columns
WHERE table_name = 'attendance' 
  AND column_name IN ('lunch_out_time', 'lunch_in_time');
```

**If columns are missing**, run the migration:
```sql
-- Run this migration
ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS lunch_out_time TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS lunch_in_time TIMESTAMP NULL;
```

## Step 3: Check Database Connection

Verify your `.env` file has correct database credentials:
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=civildesk
DB_USERNAME=postgres
DB_PASSWORD=your_password
```

## Step 4: Check for SQL Errors

In your Spring Boot logs, look for:
- `Hibernate: insert into attendance...`
- Any constraint violation errors
- Any foreign key errors

## Step 5: Verify Employee Exists

Make sure the employee ID being sent exists in the database:
```sql
SELECT id, employee_id, first_name, last_name, deleted
FROM employees
WHERE employee_id = 'YOUR_EMPLOYEE_ID' AND deleted = false;
```

## Step 6: Check Transaction Status

The `@Transactional` annotation should commit automatically. Check if there are any rollback messages in logs.

## Step 7: Manual Test

Try inserting a record manually to test:
```sql
-- First, get an employee ID
SELECT id FROM employees WHERE deleted = false LIMIT 1;

-- Then insert (replace EMPLOYEE_ID with actual ID from above)
INSERT INTO attendance (
    employee_id, 
    date, 
    check_in_time, 
    status, 
    recognition_method,
    created_at,
    updated_at,
    deleted
) VALUES (
    EMPLOYEE_ID,  -- Replace with actual employee ID
    CURRENT_DATE,
    NOW(),
    'PRESENT',
    'MANUAL',
    NOW(),
    NOW(),
    false
);

-- Check if it was inserted
SELECT * FROM attendance ORDER BY created_at DESC LIMIT 1;
```

## Step 8: Check Hibernate DDL Auto

In `application.properties`, ensure:
```properties
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
```

This will:
- Auto-create/update tables
- Show SQL queries in console

## Common Issues:

### Issue 1: Missing Columns
**Symptom**: Error about `lunch_out_time` or `lunch_in_time` column not existing
**Solution**: Run the migration script

### Issue 2: Employee Not Found
**Symptom**: "Employee not found with ID: XXX" in logs
**Solution**: Verify employee exists and `employee_id` matches exactly

### Issue 3: Constraint Violation
**Symptom**: Unique constraint error on `(employee_id, date)`
**Solution**: This is normal - it means a record already exists for today. The system should update it, not create a new one.

### Issue 4: Transaction Rollback
**Symptom**: No error but record not saved
**Solution**: Check for exceptions in logs that might cause rollback

## Quick Diagnostic Query

Run this to see the current state:
```sql
-- Check table structure
\d attendance

-- Check recent records
SELECT * FROM attendance ORDER BY created_at DESC LIMIT 5;

-- Check if lunch columns exist
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'attendance' 
  AND column_name LIKE '%lunch%';
```

## Next Steps

1. **Check backend console logs** when marking attendance
2. **Run the diagnostic query** to check table structure
3. **Run the migration** if columns are missing
4. **Share the error messages** if you see any

