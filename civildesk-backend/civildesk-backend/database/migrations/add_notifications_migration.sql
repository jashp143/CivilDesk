-- =============================================================================
-- NOTIFICATIONS MIGRATION
-- Add notifications table and update users table for FCM tokens
-- =============================================================================
-- Run this migration after the base schema is set up
-- 
-- Usage:
--   psql -U postgres -d civildesk -f add_notifications_migration.sql
--   Or use pgAdmin Query Tool
-- =============================================================================

-- Start transaction for safe execution
BEGIN;

-- =============================================================================
-- SECTION 1: UPDATE USERS TABLE
-- =============================================================================

-- Add FCM token fields to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(500),
ADD COLUMN IF NOT EXISTS fcm_token_updated_at TIMESTAMP;

-- =============================================================================
-- SECTION 2: CREATE NOTIFICATIONS TABLE
-- =============================================================================

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    data JSONB,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    CONSTRAINT fk_notification_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE
);

-- =============================================================================
-- SECTION 3: CREATE INDEXES
-- =============================================================================

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_user_created_at ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_deleted ON notifications(deleted);

-- =============================================================================
-- SECTION 4: COMMIT TRANSACTION
-- =============================================================================

COMMIT;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

