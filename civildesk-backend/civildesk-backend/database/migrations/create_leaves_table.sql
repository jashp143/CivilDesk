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

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_leaves_employee_id ON leaves(employee_id);
CREATE INDEX IF NOT EXISTS idx_leaves_status ON leaves(status);
CREATE INDEX IF NOT EXISTS idx_leaves_leave_type ON leaves(leave_type);
CREATE INDEX IF NOT EXISTS idx_leaves_start_date ON leaves(start_date);
CREATE INDEX IF NOT EXISTS idx_leaves_end_date ON leaves(end_date);
CREATE INDEX IF NOT EXISTS idx_leaves_reviewed_by ON leaves(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_leaves_deleted ON leaves(deleted);

-- Create a composite index for common queries
CREATE INDEX IF NOT EXISTS idx_leaves_employee_status ON leaves(employee_id, status) WHERE deleted = false;

-- Add comments to the table and columns
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

-- Update trigger for updated_at
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

-- Grant permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON leaves TO your_app_user;
-- GRANT USAGE, SELECT ON SEQUENCE leaves_id_seq TO your_app_user;
