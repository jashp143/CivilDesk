-- =============================================================================
-- BROADCAST MESSAGES MIGRATION
-- Add broadcast_messages table for admin/HR announcements
-- =============================================================================
-- Run this migration after the base schema is set up
-- 
-- Usage:
--   psql -U postgres -d civildesk -f add_broadcast_messages_migration.sql
--   Or use pgAdmin Query Tool
-- =============================================================================

-- Start transaction for safe execution
BEGIN;

-- =============================================================================
-- SECTION 1: CREATE BROADCAST MESSAGES TABLE
-- =============================================================================

-- Create broadcast_messages table
CREATE TABLE IF NOT EXISTS broadcast_messages (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'NORMAL',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    CONSTRAINT fk_broadcast_created_by FOREIGN KEY (created_by) 
        REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_broadcast_updated_by FOREIGN KEY (updated_by) 
        REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_priority CHECK (priority IN (
        'LOW', 'NORMAL', 'HIGH', 'URGENT'
    ))
);

-- =============================================================================
-- SECTION 2: CREATE INDEXES
-- =============================================================================

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_broadcast_created_at ON broadcast_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_broadcast_is_active ON broadcast_messages(is_active);
CREATE INDEX IF NOT EXISTS idx_broadcast_priority ON broadcast_messages(priority);
CREATE INDEX IF NOT EXISTS idx_broadcast_deleted ON broadcast_messages(deleted);
CREATE INDEX IF NOT EXISTS idx_broadcast_active_created ON broadcast_messages(is_active, created_at DESC) WHERE deleted = FALSE;

-- =============================================================================
-- SECTION 3: ADD COMMENTS
-- =============================================================================

COMMENT ON TABLE broadcast_messages IS 'Broadcast messages/announcements sent by admins/HR to all employees';
COMMENT ON COLUMN broadcast_messages.title IS 'Title of the broadcast message';
COMMENT ON COLUMN broadcast_messages.message IS 'Content/body of the broadcast message';
COMMENT ON COLUMN broadcast_messages.priority IS 'Priority level: LOW, NORMAL, HIGH, URGENT';
COMMENT ON COLUMN broadcast_messages.is_active IS 'Whether the broadcast is currently active/visible';
COMMENT ON COLUMN broadcast_messages.created_by IS 'User ID of the admin/HR who created the broadcast';
COMMENT ON COLUMN broadcast_messages.updated_by IS 'User ID of the admin/HR who last updated the broadcast';
COMMENT ON COLUMN broadcast_messages.deleted IS 'Soft delete flag';

-- =============================================================================
-- SECTION 4: COMMIT TRANSACTION
-- =============================================================================

COMMIT;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

