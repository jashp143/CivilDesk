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

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_overtimes_employee_id ON overtimes(employee_id);
CREATE INDEX IF NOT EXISTS idx_overtimes_status ON overtimes(status);
CREATE INDEX IF NOT EXISTS idx_overtimes_date ON overtimes(date);
CREATE INDEX IF NOT EXISTS idx_overtimes_reviewed_by ON overtimes(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_overtimes_deleted ON overtimes(deleted);

-- Create a composite index for common queries
CREATE INDEX IF NOT EXISTS idx_overtimes_employee_status ON overtimes(employee_id, status) WHERE deleted = false;

-- Add comments to the table and columns
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

-- Update trigger for updated_at
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

-- Grant permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON overtimes TO your_app_user;
-- GRANT USAGE, SELECT ON SEQUENCE overtimes_id_seq TO your_app_user;
