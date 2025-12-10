-- Migration: Create Sites and GPS Attendance Tables
-- Date: 2024
-- Description: Adds site management and GPS-based attendance tracking

-- Create attendance_method enum type for employees
-- ALTER TABLE employees ADD COLUMN attendance_method VARCHAR(20) DEFAULT 'FACE_RECOGNITION';

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

-- Create indexes for performance
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

