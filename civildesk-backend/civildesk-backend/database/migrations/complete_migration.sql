-- =============================================================================
-- COMPLETE DATABASE MIGRATION
-- Civildesk Employee Management System
-- =============================================================================
-- This single migration file consolidates all database migrations
-- Run this file to set up the complete database schema
-- 
-- Usage:
--   psql -U postgres -d civildesk -f complete_migration.sql
--   Or use pgAdmin Query Tool
-- =============================================================================

-- Start transaction for safe execution
BEGIN;

-- =============================================================================
-- SECTION 1: CREATE CORE TABLES
-- =============================================================================

-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id BIGSERIAL PRIMARY KEY,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    location VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    mode_of_travel VARCHAR(255) NOT NULL,
    assigned_by BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reviewed_at TIMESTAMP,
    review_note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    CONSTRAINT fk_assigned_by FOREIGN KEY (assigned_by) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_status CHECK (status IN (
        'PENDING', 'APPROVED', 'REJECTED'
    )),
    CONSTRAINT chk_dates CHECK (end_date >= start_date)
);

-- Create task_assignments table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS task_assignments (
    id BIGSERIAL PRIMARY KEY,
    task_id BIGINT NOT NULL,
    employee_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    CONSTRAINT fk_task FOREIGN KEY (task_id) 
        REFERENCES tasks(id) ON DELETE CASCADE,
    CONSTRAINT fk_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON DELETE CASCADE,
    CONSTRAINT uk_task_employee UNIQUE (task_id, employee_id)
);

-- Create indexes for tasks
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_by ON tasks(assigned_by);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_start_date ON tasks(start_date);
CREATE INDEX IF NOT EXISTS idx_tasks_end_date ON tasks(end_date);
CREATE INDEX IF NOT EXISTS idx_tasks_deleted ON tasks(deleted);
CREATE INDEX IF NOT EXISTS idx_task_assignments_task_id ON task_assignments(task_id);
CREATE INDEX IF NOT EXISTS idx_task_assignments_employee_id ON task_assignments(employee_id);
CREATE INDEX IF NOT EXISTS idx_task_assignments_deleted ON task_assignments(deleted);

-- Create leaves table
CREATE TABLE IF NOT EXISTS leaves (
    id BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    leave_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_half_day BOOLEAN NOT NULL DEFAULT FALSE,
    half_day_period VARCHAR(20),
    contact_number VARCHAR(15) NOT NULL,
    handover_employee_ids TEXT,
    reason TEXT NOT NULL,
    medical_certificate_url VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reviewed_by BIGINT,
    reviewed_at TIMESTAMP,
    review_note TEXT,
    total_days DOUBLE PRECISION,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    CONSTRAINT fk_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON DELETE CASCADE,
    CONSTRAINT fk_reviewed_by FOREIGN KEY (reviewed_by) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_leave_type CHECK (leave_type IN (
        'SICK_LEAVE', 'CASUAL_LEAVE', 'ANNUAL_LEAVE', 
        'MATERNITY_LEAVE', 'PATERNITY_LEAVE', 'MEDICAL_LEAVE', 
        'EMERGENCY_LEAVE', 'UNPAID_LEAVE', 'COMPENSATORY_OFF'
    )),
    CONSTRAINT chk_half_day_period CHECK (half_day_period IN (
        'FIRST_HALF', 'SECOND_HALF'
    )),
    CONSTRAINT chk_status CHECK (status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'
    )),
    CONSTRAINT chk_dates CHECK (end_date >= start_date)
);

-- Create indexes for leaves
CREATE INDEX IF NOT EXISTS idx_leaves_employee_id ON leaves(employee_id);
CREATE INDEX IF NOT EXISTS idx_leaves_status ON leaves(status);
CREATE INDEX IF NOT EXISTS idx_leaves_leave_type ON leaves(leave_type);
CREATE INDEX IF NOT EXISTS idx_leaves_start_date ON leaves(start_date);
CREATE INDEX IF NOT EXISTS idx_leaves_end_date ON leaves(end_date);
CREATE INDEX IF NOT EXISTS idx_leaves_reviewed_by ON leaves(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_leaves_deleted ON leaves(deleted);
CREATE INDEX IF NOT EXISTS idx_leaves_employee_status ON leaves(employee_id, status) WHERE deleted = false;

-- Add comments to leaves table
COMMENT ON TABLE leaves IS 'Stores employee leave applications and their approval status';
COMMENT ON COLUMN leaves.employee_id IS 'Foreign key to employees table';
COMMENT ON COLUMN leaves.leave_type IS 'Type of leave being requested';
COMMENT ON COLUMN leaves.start_date IS 'Start date of the leave';
COMMENT ON COLUMN leaves.end_date IS 'End date of the leave';
COMMENT ON COLUMN leaves.is_half_day IS 'Whether this is a half day leave';
COMMENT ON COLUMN leaves.half_day_period IS 'First or second half of the day for half day leaves';
COMMENT ON COLUMN leaves.contact_number IS 'Contact number of employee during leave';
COMMENT ON COLUMN leaves.handover_employee_ids IS 'Comma-separated IDs of employees to handle responsibilities';
COMMENT ON COLUMN leaves.reason IS 'Reason for taking leave';
COMMENT ON COLUMN leaves.medical_certificate_url IS 'URL to medical certificate (for medical leaves)';
COMMENT ON COLUMN leaves.status IS 'Current status of the leave application';
COMMENT ON COLUMN leaves.reviewed_by IS 'User ID of admin/HR who reviewed the leave';
COMMENT ON COLUMN leaves.reviewed_at IS 'Timestamp when the leave was reviewed';
COMMENT ON COLUMN leaves.review_note IS 'Optional note from reviewer for the employee';
COMMENT ON COLUMN leaves.total_days IS 'Total number of days for this leave';
COMMENT ON COLUMN leaves.deleted IS 'Soft delete flag';

-- Update trigger for leaves updated_at
CREATE OR REPLACE FUNCTION update_leaves_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_leaves_updated_at
    BEFORE UPDATE ON leaves
    FOR EACH ROW
    EXECUTE FUNCTION update_leaves_updated_at();

-- Create expenses table
CREATE TABLE IF NOT EXISTS expenses (
    id BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    expense_date DATE NOT NULL,
    category VARCHAR(50) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    description TEXT NOT NULL,
    receipt_urls TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reviewed_by BIGINT,
    reviewed_at TIMESTAMP,
    review_note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    CONSTRAINT fk_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON DELETE CASCADE,
    CONSTRAINT fk_reviewed_by FOREIGN KEY (reviewed_by) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_category CHECK (category IN (
        'TRAVEL', 'MEALS', 'ACCOMMODATION', 'SUPPLIES', 
        'EQUIPMENT', 'COMMUNICATION', 'TRANSPORTATION', 
        'ENTERTAINMENT', 'TRAINING', 'OTHER'
    )),
    CONSTRAINT chk_status CHECK (status IN (
        'PENDING', 'APPROVED', 'REJECTED'
    )),
    CONSTRAINT chk_amount CHECK (amount > 0)
);

-- Create indexes for expenses
CREATE INDEX IF NOT EXISTS idx_expenses_employee_id ON expenses(employee_id);
CREATE INDEX IF NOT EXISTS idx_expenses_status ON expenses(status);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_expense_date ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_reviewed_by ON expenses(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_expenses_deleted ON expenses(deleted);
CREATE INDEX IF NOT EXISTS idx_expenses_employee_status ON expenses(employee_id, status) WHERE deleted = false;

-- Add comments to expenses table
COMMENT ON TABLE expenses IS 'Stores employee expense applications and their approval status';
COMMENT ON COLUMN expenses.employee_id IS 'Foreign key to employees table';
COMMENT ON COLUMN expenses.expense_date IS 'Date when the expense was incurred';
COMMENT ON COLUMN expenses.category IS 'Category of the expense';
COMMENT ON COLUMN expenses.amount IS 'Amount of the expense';
COMMENT ON COLUMN expenses.description IS 'Description of the expense';
COMMENT ON COLUMN expenses.receipt_urls IS 'Comma-separated URLs of receipt files';
COMMENT ON COLUMN expenses.status IS 'Current status of the expense application';
COMMENT ON COLUMN expenses.reviewed_by IS 'User ID of admin/HR who reviewed the expense';
COMMENT ON COLUMN expenses.reviewed_at IS 'Timestamp when the expense was reviewed';
COMMENT ON COLUMN expenses.review_note IS 'Optional note from reviewer for the employee';
COMMENT ON COLUMN expenses.deleted IS 'Soft delete flag';

-- Update trigger for expenses updated_at
CREATE OR REPLACE FUNCTION update_expenses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_expenses_updated_at
    BEFORE UPDATE ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_expenses_updated_at();

-- Create overtimes table
CREATE TABLE IF NOT EXISTS overtimes (
    id BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reviewed_by BIGINT,
    reviewed_at TIMESTAMP,
    review_note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    CONSTRAINT fk_employee_overtime FOREIGN KEY (employee_id) 
        REFERENCES employees(id) ON DELETE CASCADE,
    CONSTRAINT fk_reviewed_by_overtime FOREIGN KEY (reviewed_by) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_status_overtime CHECK (status IN (
        'PENDING', 'APPROVED', 'REJECTED'
    )),
    CONSTRAINT chk_time_range CHECK (end_time > start_time)
);

-- Create indexes for overtimes
CREATE INDEX IF NOT EXISTS idx_overtimes_employee_id ON overtimes(employee_id);
CREATE INDEX IF NOT EXISTS idx_overtimes_status ON overtimes(status);
CREATE INDEX IF NOT EXISTS idx_overtimes_date ON overtimes(date);
CREATE INDEX IF NOT EXISTS idx_overtimes_reviewed_by ON overtimes(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_overtimes_deleted ON overtimes(deleted);
CREATE INDEX IF NOT EXISTS idx_overtimes_employee_status ON overtimes(employee_id, status) WHERE deleted = false;

-- Add comments to overtimes table
COMMENT ON TABLE overtimes IS 'Stores employee overtime applications and their approval status';
COMMENT ON COLUMN overtimes.employee_id IS 'Foreign key to employees table';
COMMENT ON COLUMN overtimes.date IS 'Date for which overtime is requested (present or future)';
COMMENT ON COLUMN overtimes.start_time IS 'Start time of overtime period';
COMMENT ON COLUMN overtimes.end_time IS 'End time of overtime period';
COMMENT ON COLUMN overtimes.reason IS 'Reason for requesting overtime';
COMMENT ON COLUMN overtimes.status IS 'Current status of the overtime application';
COMMENT ON COLUMN overtimes.reviewed_by IS 'User ID of admin/HR who reviewed the overtime';
COMMENT ON COLUMN overtimes.reviewed_at IS 'Timestamp when the overtime was reviewed';
COMMENT ON COLUMN overtimes.review_note IS 'Optional note from reviewer for the employee';
COMMENT ON COLUMN overtimes.deleted IS 'Soft delete flag';

-- Update trigger for overtimes updated_at
CREATE OR REPLACE FUNCTION update_overtimes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_overtimes_updated_at
    BEFORE UPDATE ON overtimes
    FOR EACH ROW
    EXECUTE FUNCTION update_overtimes_updated_at();

-- Create holidays table
CREATE TABLE IF NOT EXISTS holidays (
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

-- Create indexes for holidays
CREATE INDEX IF NOT EXISTS idx_holidays_date ON holidays(date);
CREATE INDEX IF NOT EXISTS idx_holidays_active ON holidays(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_holidays_date_active ON holidays(date, is_active) WHERE is_active = TRUE AND deleted = FALSE;

-- Add comments to holidays table
COMMENT ON TABLE holidays IS 'Stores company holidays. When a holiday is defined, normalized attendance is automatically marked for all employees.';
COMMENT ON COLUMN holidays.date IS 'The date of the holiday (must be unique)';
COMMENT ON COLUMN holidays.name IS 'Name of the holiday (e.g., "Republic Day", "Independence Day")';
COMMENT ON COLUMN holidays.description IS 'Optional description of the holiday';
COMMENT ON COLUMN holidays.is_active IS 'Whether the holiday is currently active';
COMMENT ON COLUMN holidays.deleted IS 'Soft delete flag';

-- =============================================================================
-- SECTION 2: CREATE SITES AND GPS ATTENDANCE TABLES
-- =============================================================================

-- Create sites table for construction sites
CREATE TABLE IF NOT EXISTS sites (
    id BIGSERIAL PRIMARY KEY,
    site_code VARCHAR(50) NOT NULL UNIQUE,
    site_name VARCHAR(255) NOT NULL,
    description TEXT,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    
    -- Location Center Point
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    
    -- Geofence Configuration
    geofence_type VARCHAR(20) DEFAULT 'RADIUS', -- RADIUS or POLYGON
    geofence_radius_meters INTEGER DEFAULT 100, -- For circular geofence
    geofence_polygon TEXT, -- JSON array of coordinates for polygon geofence
    
    -- Site Status
    is_active BOOLEAN DEFAULT TRUE,
    start_date DATE,
    end_date DATE,
    
    -- Shift Configuration
    shift_start_time TIME,
    shift_end_time TIME,
    lunch_start_time TIME,
    lunch_end_time TIME,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);

-- Create employee_site_assignments table
CREATE TABLE IF NOT EXISTS employee_site_assignments (
    id BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    site_id BIGINT NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    assignment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(employee_id, site_id, assignment_date)
);

-- Add attendance method to employees table
ALTER TABLE employees ADD COLUMN IF NOT EXISTS attendance_method VARCHAR(30) DEFAULT 'FACE_RECOGNITION';

-- Add GPS-related columns to attendance table
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8);
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8);
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS device_id VARCHAR(255);
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS device_name VARCHAR(255);
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS is_mock_location BOOLEAN DEFAULT FALSE;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS network_status VARCHAR(20); -- ONLINE, OFFLINE
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS site_id BIGINT REFERENCES sites(id);
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS distance_from_site DECIMAL(10, 2); -- Distance in meters
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS punch_type VARCHAR(20); -- CHECK_IN, LUNCH_OUT, LUNCH_IN, CHECK_OUT
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS is_inside_geofence BOOLEAN DEFAULT TRUE;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) DEFAULT 'SYNCED'; -- SYNCED, PENDING
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS offline_timestamp TIMESTAMP; -- Original timestamp from offline punch

-- Create GPS attendance logs for detailed tracking (all 4 punches per day)
CREATE TABLE IF NOT EXISTS gps_attendance_logs (
    id BIGSERIAL PRIMARY KEY,
    attendance_id BIGINT REFERENCES attendance(id) ON DELETE CASCADE,
    employee_id BIGINT NOT NULL REFERENCES employees(id),
    site_id BIGINT REFERENCES sites(id),
    
    -- Punch Details
    punch_type VARCHAR(20) NOT NULL, -- CHECK_IN, LUNCH_OUT, LUNCH_IN, CHECK_OUT
    punch_time TIMESTAMP NOT NULL,
    server_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- GPS Data
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    accuracy_meters DECIMAL(10, 2),
    altitude DECIMAL(10, 2),
    
    -- Device Information
    device_id VARCHAR(255),
    device_name VARCHAR(255),
    device_model VARCHAR(255),
    os_version VARCHAR(50),
    app_version VARCHAR(20),
    
    -- Validation
    is_mock_location BOOLEAN DEFAULT FALSE,
    is_inside_geofence BOOLEAN DEFAULT TRUE,
    distance_from_site DECIMAL(10, 2),
    
    -- Network
    network_status VARCHAR(20), -- ONLINE, OFFLINE
    ip_address VARCHAR(50),
    
    -- Sync
    sync_status VARCHAR(20) DEFAULT 'SYNCED',
    offline_timestamp TIMESTAMP,
    synced_at TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for sites and GPS attendance
CREATE INDEX IF NOT EXISTS idx_sites_active ON sites(is_active);
CREATE INDEX IF NOT EXISTS idx_sites_location ON sites(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_employee_site_assignments_employee ON employee_site_assignments(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_site_assignments_site ON employee_site_assignments(site_id);
CREATE INDEX IF NOT EXISTS idx_employee_site_assignments_active ON employee_site_assignments(is_active);
CREATE INDEX IF NOT EXISTS idx_gps_attendance_logs_employee ON gps_attendance_logs(employee_id);
CREATE INDEX IF NOT EXISTS idx_gps_attendance_logs_site ON gps_attendance_logs(site_id);
CREATE INDEX IF NOT EXISTS idx_gps_attendance_logs_punch_time ON gps_attendance_logs(punch_time);
CREATE INDEX IF NOT EXISTS idx_gps_attendance_logs_punch_type ON gps_attendance_logs(punch_type);
CREATE INDEX IF NOT EXISTS idx_attendance_site ON attendance(site_id);
CREATE INDEX IF NOT EXISTS idx_attendance_punch_type ON attendance(punch_type);

-- Add comment on attendance_method
COMMENT ON COLUMN employees.attendance_method IS 'Attendance marking method: FACE_RECOGNITION or GPS_BASED';

-- =============================================================================
-- SECTION 3: ADD EMPLOYEE REGISTRATION FIELDS
-- =============================================================================

-- Add Identification fields
ALTER TABLE employees
ADD COLUMN IF NOT EXISTS uan_number VARCHAR(12),
ADD COLUMN IF NOT EXISTS esic_number VARCHAR(17);

-- Add new Salary Structure fields
ALTER TABLE employees
ADD COLUMN IF NOT EXISTS conveyance DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS uniform_and_safety DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS bonus DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS food_allowance DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS other_allowance DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS overtime_rate DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS epf_employee DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS epf_employer DOUBLE PRECISION;

-- Add Deduction fields
ALTER TABLE employees
ADD COLUMN IF NOT EXISTS esic DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS professional_tax DOUBLE PRECISION;

-- Add comments for documentation
COMMENT ON COLUMN employees.uan_number IS 'Universal Account Number for EPF';
COMMENT ON COLUMN employees.esic_number IS 'Employee State Insurance Corporation number';
COMMENT ON COLUMN employees.conveyance IS 'Conveyance allowance in rupees';
COMMENT ON COLUMN employees.uniform_and_safety IS 'Uniform and safety allowance in rupees';
COMMENT ON COLUMN employees.bonus IS 'Bonus amount in rupees';
COMMENT ON COLUMN employees.food_allowance IS 'Food allowance in rupees';
COMMENT ON COLUMN employees.other_allowance IS 'Other allowance in rupees';
COMMENT ON COLUMN employees.overtime_rate IS 'Overtime rate per hour in rupees';
COMMENT ON COLUMN employees.epf_employee IS 'EPF contribution percentage for employee';
COMMENT ON COLUMN employees.epf_employer IS 'EPF contribution percentage for employer';
COMMENT ON COLUMN employees.esic IS 'ESIC contribution percentage';
COMMENT ON COLUMN employees.professional_tax IS 'Professional tax amount in rupees';

-- =============================================================================
-- SECTION 4: ADD ATTENDANCE COLUMNS
-- =============================================================================

-- Add working_hours column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'working_hours'
    ) THEN
        ALTER TABLE attendance 
        ADD COLUMN working_hours DOUBLE PRECISION NULL;
        
        RAISE NOTICE 'Column working_hours added successfully';
    ELSE
        RAISE NOTICE 'Column working_hours already exists, skipping...';
    END IF;
END $$;

-- Add overtime_hours column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'overtime_hours'
    ) THEN
        ALTER TABLE attendance 
        ADD COLUMN overtime_hours DOUBLE PRECISION NULL;
        
        RAISE NOTICE 'Column overtime_hours added successfully';
    ELSE
        RAISE NOTICE 'Column overtime_hours already exists, skipping...';
    END IF;
END $$;

-- Add lunch_out_time column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'lunch_out_time'
    ) THEN
        ALTER TABLE attendance 
        ADD COLUMN lunch_out_time TIMESTAMP NULL;
        
        RAISE NOTICE 'Column lunch_out_time added successfully';
    ELSE
        RAISE NOTICE 'Column lunch_out_time already exists, skipping...';
    END IF;
END $$;

-- Add lunch_in_time column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'attendance' 
        AND column_name = 'lunch_in_time'
    ) THEN
        ALTER TABLE attendance 
        ADD COLUMN lunch_in_time TIMESTAMP NULL;
        
        RAISE NOTICE 'Column lunch_in_time added successfully';
    ELSE
        RAISE NOTICE 'Column lunch_in_time already exists, skipping...';
    END IF;
END $$;

-- Add comments for attendance columns
COMMENT ON COLUMN attendance.working_hours IS 'Calculated office working hours (always <= 8 hours)';
COMMENT ON COLUMN attendance.overtime_hours IS 'Calculated overtime hours';
COMMENT ON COLUMN attendance.lunch_out_time IS 'Time when employee went for lunch break';
COMMENT ON COLUMN attendance.lunch_in_time IS 'Time when employee returned from lunch break';

-- =============================================================================
-- SECTION 5: CREATE INDEXES FOR ATTENDANCE
-- =============================================================================

-- Index for employee_id and date range queries
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date 
ON attendance(employee_id, date);

-- Index for date queries
CREATE INDEX IF NOT EXISTS idx_attendance_date 
ON attendance(date);

-- Index for employee_id queries
CREATE INDEX IF NOT EXISTS idx_attendance_employee_id 
ON attendance(employee_id);

-- Index for status queries
CREATE INDEX IF NOT EXISTS idx_attendance_status 
ON attendance(status);

-- Composite index for employee and status
CREATE INDEX IF NOT EXISTS idx_attendance_employee_status 
ON attendance(employee_id, status);

-- =============================================================================
-- SECTION 6: ADD COMPOSITE INDEXES FOR OPTIMIZATION
-- =============================================================================

-- Composite index for filtered attendance queries
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date_status 
ON attendance(employee_id, date, status) 
WHERE deleted = false;

-- Composite index for date-based status queries
CREATE INDEX IF NOT EXISTS idx_attendance_date_status 
ON attendance(date, status) 
WHERE deleted = false;

-- Composite index for tasks by assignee, status, and date
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_by_status_date 
ON tasks(assigned_by, status, start_date) 
WHERE deleted = false;

-- Composite index for task assignments
CREATE INDEX IF NOT EXISTS idx_task_assignments_task_employee 
ON task_assignments(task_id, employee_id) 
WHERE deleted = false;

-- Composite index for employee leave queries
CREATE INDEX IF NOT EXISTS idx_leaves_employee_status_dates
ON leaves(employee_id, status, start_date, end_date)
WHERE deleted = false;

-- Composite index for leave status with date range
CREATE INDEX IF NOT EXISTS idx_leaves_status_dates
ON leaves(status, start_date, end_date)
WHERE deleted = false;

-- Composite index for expense queries
CREATE INDEX IF NOT EXISTS idx_expenses_employee_status_date
ON expenses(employee_id, status, expense_date)
WHERE deleted = false;

-- Composite index for overtime queries
CREATE INDEX IF NOT EXISTS idx_overtimes_employee_status_date
ON overtimes(employee_id, status, date)
WHERE deleted = false;

-- Composite index for GPS attendance queries
CREATE INDEX IF NOT EXISTS idx_gps_attendance_employee_site_time
ON gps_attendance_logs(employee_id, site_id, punch_time)
WHERE deleted = false;

-- Composite index for active employees by department/designation
CREATE INDEX IF NOT EXISTS idx_employees_active_department
ON employees(department, designation)
WHERE is_active = true AND deleted = false;

-- Index for employee lookup by employee_id
CREATE INDEX IF NOT EXISTS idx_employees_employee_id
ON employees(employee_id)
WHERE is_active = true AND deleted = false;

-- Composite index for salary slips (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'salary_slips') THEN
        CREATE INDEX IF NOT EXISTS idx_salary_slips_employee_period
        ON salary_slips(employee_id, year, month)
        WHERE deleted = false;
    END IF;
END $$;

-- Index for holiday date queries
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'holidays') THEN
        CREATE INDEX IF NOT EXISTS idx_holidays_date
        ON holidays(date)
        WHERE deleted = false;
    END IF;
END $$;

-- Index for active sites
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'sites') THEN
        CREATE INDEX IF NOT EXISTS idx_sites_active
        ON sites(is_active)
        WHERE deleted = false;
    END IF;
END $$;

-- =============================================================================
-- SECTION 7: REMOVE CONSTRAINTS
-- =============================================================================

-- Remove mode_of_travel check constraint to allow free-form text input
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS chk_mode_of_travel;
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_mode_of_travel_check;

-- Increase the VARCHAR length to accommodate longer text entries
ALTER TABLE tasks ALTER COLUMN mode_of_travel TYPE VARCHAR(255);

-- =============================================================================
-- SECTION 8: ANALYZE TABLES FOR OPTIMIZATION
-- =============================================================================

-- Analyze tables to update statistics
ANALYZE attendance;
ANALYZE employees;
ANALYZE tasks;
ANALYZE task_assignments;
ANALYZE leaves;
ANALYZE expenses;
ANALYZE overtimes;
ANALYZE gps_attendance_logs;
ANALYZE sites;
ANALYZE employee_site_assignments;
ANALYZE holidays;

-- =============================================================================
-- VERIFICATION
-- =============================================================================

-- Verify all tables were created
DO $$
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name IN (
        'tasks', 'task_assignments', 'leaves', 'expenses', 
        'overtimes', 'holidays', 'sites', 'employee_site_assignments', 
        'gps_attendance_logs'
    );
    
    IF table_count >= 9 THEN
        RAISE NOTICE 'Migration completed successfully! All tables created.';
    ELSE
        RAISE WARNING 'Some tables may not have been created. Please verify manually.';
    END IF;
END $$;

-- Commit the transaction
COMMIT;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================
-- All database migrations have been applied successfully.
-- 
-- Created Tables:
--   - tasks
--   - task_assignments
--   - leaves
--   - expenses
--   - overtimes
--   - holidays
--   - sites
--   - employee_site_assignments
--   - gps_attendance_logs
--
-- Modified Tables:
--   - employees (added registration fields and attendance_method)
--   - attendance (added GPS fields, working hours, overtime hours, lunch times)
--   - tasks (removed mode_of_travel constraint)
--
-- Indexes:
--   - All necessary indexes have been created for optimal query performance
--
-- Next Steps:
--   1. Verify the migration by checking table structures
--   2. Test application functionality
--   3. Consider running optional optimizations (partitioning, archival) separately
-- =============================================================================

