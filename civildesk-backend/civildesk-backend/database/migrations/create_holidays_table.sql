-- Create holidays table for managing company holidays
-- This table stores holiday definitions that automatically mark normalized attendance for all employees

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

-- Index for date lookups (most common query)
CREATE INDEX IF NOT EXISTS idx_holidays_date ON holidays(date);

-- Index for active holidays
CREATE INDEX IF NOT EXISTS idx_holidays_active ON holidays(is_active) WHERE is_active = TRUE;

-- Index for date range queries
CREATE INDEX IF NOT EXISTS idx_holidays_date_active ON holidays(date, is_active) WHERE is_active = TRUE AND deleted = FALSE;

-- Add comment to table
COMMENT ON TABLE holidays IS 'Stores company holidays. When a holiday is defined, normalized attendance is automatically marked for all employees.';

-- Add comment to columns
COMMENT ON COLUMN holidays.date IS 'The date of the holiday (must be unique)';
COMMENT ON COLUMN holidays.name IS 'Name of the holiday (e.g., "Republic Day", "Independence Day")';
COMMENT ON COLUMN holidays.description IS 'Optional description of the holiday';
COMMENT ON COLUMN holidays.is_active IS 'Whether the holiday is currently active';
COMMENT ON COLUMN holidays.deleted IS 'Soft delete flag';

-- Verify table creation
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'holidays'
ORDER BY ordinal_position;

