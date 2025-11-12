# Database Migration Guide: Add Lunch Times to Attendance

This guide explains how to run the SQL migration to add lunch time tracking to the attendance table.

## Quick Start

### Option 1: Using pgAdmin (Easiest)

1. **Open pgAdmin** and connect to your PostgreSQL server
2. **Navigate to Database**
   - Expand "Databases" → `civildesk`
   - Right-click on `civildesk` → Select "Query Tool"
3. **Run Migration**
   - Open file: `civildesk-backend/civildesk-backend/database/migrations/add_lunch_times_to_attendance.sql`
   - Copy all contents (Ctrl+A, Ctrl+C)
   - Paste into Query Tool (Ctrl+V)
   - Click "Execute" button or press **F5**
4. **Check Results**
   - Look at the "Messages" tab
   - You should see: `Migration completed successfully!`

### Option 2: Using psql Command Line

```bash
# Navigate to the migrations directory
cd civildesk-backend/civildesk-backend/database/migrations

# Run the migration
psql -U postgres -d civildesk -f add_lunch_times_to_attendance.sql
```

**Windows PowerShell:**
```powershell
cd civildesk-backend\civildesk-backend\database\migrations
psql -U postgres -d civildesk -f add_lunch_times_to_attendance.sql
```

### Option 3: Direct SQL (Copy-Paste)

If you prefer, you can copy and paste this simplified version:

```sql
-- Simple version (safe to run multiple times)
ALTER TABLE attendance 
ADD COLUMN IF NOT EXISTS lunch_out_time TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS lunch_in_time TIMESTAMP NULL;
```

## Verify Migration

After running the migration, verify it worked:

```sql
-- Check columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'attendance' 
  AND column_name IN ('lunch_out_time', 'lunch_in_time');
```

**Expected Output:**
```
column_name      | data_type                  | is_nullable
-----------------|----------------------------|-------------
lunch_out_time   | timestamp without time zone | YES
lunch_in_time    | timestamp without time zone | YES
```

## What This Migration Does

- ✅ Adds `lunch_out_time` column (nullable TIMESTAMP)
- ✅ Adds `lunch_in_time` column (nullable TIMESTAMP)
- ✅ Safe to run multiple times (idempotent)
- ✅ Does not affect existing data
- ✅ Includes verification steps

## Rollback (If Needed)

If you need to remove these columns:

```sql
ALTER TABLE attendance 
DROP COLUMN IF EXISTS lunch_out_time,
DROP COLUMN IF EXISTS lunch_in_time;
```

Or use the rollback script:
```bash
psql -U postgres -d civildesk -f ROLLBACK_add_lunch_times.sql
```

## Troubleshooting

### "Table attendance does not exist"
**Solution:** Run your Spring Boot application first. It will create the table automatically.

### "Permission denied"
**Solution:** Connect as the `postgres` superuser or a user with ALTER TABLE permissions.

### "Column already exists"
**Solution:** This is fine! The migration checks for existing columns and skips them. Your database is already up to date.

## Files Location

- **Migration Script:** `civildesk-backend/civildesk-backend/database/migrations/add_lunch_times_to_attendance.sql`
- **Rollback Script:** `civildesk-backend/civildesk-backend/database/migrations/ROLLBACK_add_lunch_times.sql`
- **Documentation:** `civildesk-backend/civildesk-backend/database/migrations/README.md`

## Next Steps

After running the migration:
1. ✅ Restart your Spring Boot application
2. ✅ Test the attendance marking feature
3. ✅ Verify lunch times are being saved correctly

