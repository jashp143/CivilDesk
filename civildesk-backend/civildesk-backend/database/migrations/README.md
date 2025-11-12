# Database Migration Scripts

This directory contains SQL migration scripts for the Civildesk database.

## Migration: Add Lunch Times to Attendance

### File: `add_lunch_times_to_attendance.sql`

This migration adds two new columns to the `attendance` table:
- `lunch_out_time` - Timestamp when employee went for lunch
- `lunch_in_time` - Timestamp when employee returned from lunch

## How to Run the Migration

### Method 1: Using pgAdmin (Recommended)

1. **Open pgAdmin**
   - Launch pgAdmin and connect to your PostgreSQL server

2. **Connect to Database**
   - Expand "Databases" in the left sidebar
   - Right-click on `civildesk` database
   - Select "Query Tool"

3. **Run the Migration**
   - Open the file `add_lunch_times_to_attendance.sql`
   - Copy the entire contents
   - Paste into the Query Tool
   - Click "Execute" (F5) or press F5

4. **Verify**
   - Check the "Messages" tab for success notifications
   - You should see: "Migration completed successfully!"

### Method 2: Using psql Command Line

```bash
# Connect to PostgreSQL
psql -U postgres -d civildesk

# Run the migration script
\i path/to/add_lunch_times_to_attendance.sql

# Or directly:
psql -U postgres -d civildesk -f add_lunch_times_to_attendance.sql
```

### Method 3: Using Spring Boot (Automatic)

If you have `spring.jpa.hibernate.ddl-auto=update` in your `application.properties`, 
Hibernate will automatically add the columns when you restart the application.

However, it's recommended to run the migration script manually for production environments.

## Verify Migration

After running the migration, verify the columns were added:

```sql
-- Check if columns exist
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'attendance'
  AND column_name IN ('lunch_out_time', 'lunch_in_time');

-- Expected output:
-- lunch_out_time | timestamp without time zone | YES
-- lunch_in_time  | timestamp without time zone | YES
```

## Rollback

If you need to rollback this migration, run:

```sql
-- Using pgAdmin Query Tool or psql
\i ROLLBACK_add_lunch_times.sql
```

**Warning:** This will permanently delete all lunch time data!

## Troubleshooting

### Error: "Table attendance does not exist"
- Make sure the `attendance` table has been created
- Run the Spring Boot application first to auto-create tables
- Or check if the table exists: `SELECT * FROM information_schema.tables WHERE table_name = 'attendance';`

### Error: "Column already exists"
- This is safe to ignore - the script checks for existing columns
- The migration is idempotent (can be run multiple times safely)

### Error: "Permission denied"
- Make sure you're connected as a user with ALTER TABLE permissions
- Try connecting as the `postgres` superuser

## Notes

- The migration is **idempotent** - safe to run multiple times
- Uses transactions for safe execution
- Includes verification steps
- Does not affect existing data

