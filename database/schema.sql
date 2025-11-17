-- ============================================================================
-- n8n User Data and Email Processing Database Schema
-- Optimized for 10-100 users with email automation and AI processing
-- ============================================================================

-- Drop tables if they exist (for clean reinstall)
DROP TABLE IF EXISTS ai_processing_queue CASCADE;
DROP TABLE IF EXISTS email_attachments CASCADE;
DROP TABLE IF EXISTS incoming_emails CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================================================
-- Users Table
-- Stores user information (name, email, phone)
-- ============================================================================

CREATE TABLE users (
    -- Primary key
    id SERIAL PRIMARY KEY,

    -- User information
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),

    -- Additional user fields (optional, customize as needed)
    company VARCHAR(255),
    role VARCHAR(100),
    status VARCHAR(50) DEFAULT 'active', -- active, inactive, suspended

    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_email_received_at TIMESTAMP,

    -- Preferences (stored as JSON for flexibility)
    preferences JSONB DEFAULT '{}'::jsonb,

    -- Constraints
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Indexes for fast lookups
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created ON users(created_at DESC);

-- ============================================================================
-- Incoming Emails Table
-- Stores all incoming emails for processing
-- ============================================================================

CREATE TABLE incoming_emails (
    -- Primary key
    id SERIAL PRIMARY KEY,

    -- Link to user
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,

    -- Email headers
    from_email VARCHAR(255) NOT NULL,
    from_name VARCHAR(255),
    to_email VARCHAR(255),
    to_name VARCHAR(255),
    cc TEXT, -- Comma-separated or JSON array
    bcc TEXT,
    subject TEXT,

    -- Email content
    body_text TEXT, -- Plain text version
    body_html TEXT, -- HTML version

    -- Email metadata
    message_id VARCHAR(500) UNIQUE, -- Unique email identifier
    thread_id VARCHAR(500), -- For email threads
    in_reply_to VARCHAR(500),
    references TEXT,

    -- Dates
    received_at TIMESTAMP DEFAULT NOW(),
    sent_at TIMESTAMP,

    -- Classification
    labels TEXT[] DEFAULT '{}', -- Array of labels/tags
    category VARCHAR(100), -- e.g., 'support', 'sales', 'inquiry'
    priority INTEGER DEFAULT 0, -- 0=normal, 1=high, -1=low

    -- AI Processing status
    processed BOOLEAN DEFAULT FALSE,
    processing_started_at TIMESTAMP,
    processing_completed_at TIMESTAMP,
    processing_duration_ms INTEGER, -- How long processing took

    -- AI Results (stored as JSONB for flexibility)
    ai_result JSONB,
    ai_sentiment VARCHAR(50), -- positive, negative, neutral
    ai_intent VARCHAR(100), -- question, complaint, feedback, etc.
    ai_confidence DECIMAL(5,2), -- 0.00 to 100.00
    ai_error TEXT,

    -- Flags
    has_attachments BOOLEAN DEFAULT FALSE,
    is_spam BOOLEAN DEFAULT FALSE,
    is_important BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,

    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_emails_user_id ON incoming_emails(user_id);
CREATE INDEX idx_emails_from ON incoming_emails(from_email);
CREATE INDEX idx_emails_to ON incoming_emails(to_email);
CREATE INDEX idx_emails_received ON incoming_emails(received_at DESC);
CREATE INDEX idx_emails_processed ON incoming_emails(processed, received_at DESC);
CREATE INDEX idx_emails_category ON incoming_emails(category);
CREATE INDEX idx_emails_message_id ON incoming_emails(message_id);

-- GIN index for JSONB ai_result (for querying JSON fields)
CREATE INDEX idx_emails_ai_result ON incoming_emails USING GIN (ai_result);

-- Full-text search index for subject and body
CREATE INDEX idx_emails_search ON incoming_emails USING GIN (
    to_tsvector('english', COALESCE(subject, '') || ' ' || COALESCE(body_text, ''))
);

-- ============================================================================
-- Email Attachments Table (Optional)
-- If you want to track attachments separately
-- ============================================================================

CREATE TABLE email_attachments (
    -- Primary key
    id SERIAL PRIMARY KEY,

    -- Link to email
    email_id INTEGER REFERENCES incoming_emails(id) ON DELETE CASCADE,

    -- Attachment information
    filename VARCHAR(500) NOT NULL,
    content_type VARCHAR(255), -- e.g., 'application/pdf', 'image/png'
    size_bytes BIGINT,

    -- Storage location
    storage_type VARCHAR(50) DEFAULT 'local', -- 'local', 'object_storage', 'base64'
    storage_path TEXT, -- Path or Object Storage key

    -- For inline storage (small files only)
    content_base64 TEXT, -- Base64 encoded content (for files <1MB)

    -- Metadata
    uploaded_at TIMESTAMP DEFAULT NOW(),

    -- Constraints
    CONSTRAINT positive_size CHECK (size_bytes >= 0)
);

CREATE INDEX idx_attachments_email_id ON email_attachments(email_id);
CREATE INDEX idx_attachments_content_type ON email_attachments(content_type);

-- ============================================================================
-- AI Processing Queue Table
-- Manages the queue of emails waiting for AI processing
-- ============================================================================

CREATE TABLE ai_processing_queue (
    -- Primary key
    id SERIAL PRIMARY KEY,

    -- Link to email
    email_id INTEGER REFERENCES incoming_emails(id) ON DELETE CASCADE,

    -- Queue management
    status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed, retry
    priority INTEGER DEFAULT 0, -- Higher number = higher priority

    -- Retry logic
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    next_retry_at TIMESTAMP,

    -- Processing info
    processor_name VARCHAR(100), -- Which AI model/service is used
    error_message TEXT,

    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,

    -- Constraints
    CONSTRAINT valid_status CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'retry'))
);

-- Indexes for queue processing
CREATE INDEX idx_queue_status ON ai_processing_queue(status, priority DESC, created_at ASC);
CREATE INDEX idx_queue_email_id ON ai_processing_queue(email_id);
CREATE INDEX idx_queue_next_retry ON ai_processing_queue(next_retry_at) WHERE status = 'retry';

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Auto-update updated_at on users table
CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Auto-update updated_at on incoming_emails table
CREATE TRIGGER emails_updated_at
    BEFORE UPDATE ON incoming_emails
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Update user's last_email_received_at when new email arrives
CREATE OR REPLACE FUNCTION update_user_last_email()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IS NOT NULL THEN
        UPDATE users
        SET last_email_received_at = NEW.received_at
        WHERE id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_last_email_trigger
    AFTER INSERT ON incoming_emails
    FOR EACH ROW
    EXECUTE FUNCTION update_user_last_email();

-- ============================================================================
-- Sample Data (Optional - for testing)
-- ============================================================================

-- Uncomment to insert sample data

-- INSERT INTO users (name, email, phone, company, role) VALUES
--     ('John Doe', 'john@example.com', '+1-555-0100', 'Acme Corp', 'Manager'),
--     ('Jane Smith', 'jane@example.com', '+1-555-0101', 'Tech Inc', 'Developer'),
--     ('Bob Johnson', 'bob@example.com', '+1-555-0102', 'StartupXYZ', 'Founder');

-- INSERT INTO incoming_emails (user_id, from_email, from_name, to_email, subject, body_text, category) VALUES
--     (1, 'support@service.com', 'Support Team', 'john@example.com',
--      'Welcome to our service', 'Thanks for signing up!', 'welcome'),
--     (2, 'billing@service.com', 'Billing', 'jane@example.com',
--      'Invoice #12345', 'Your invoice is ready', 'billing');

-- ============================================================================
-- Useful Queries for n8n Workflows
-- ============================================================================

-- Get all unprocessed emails
-- SELECT * FROM incoming_emails WHERE processed = FALSE ORDER BY priority DESC, received_at ASC;

-- Get emails for a specific user
-- SELECT * FROM incoming_emails WHERE user_id = 1 ORDER BY received_at DESC;

-- Get processing queue items ready to process
-- SELECT * FROM ai_processing_queue WHERE status = 'pending' ORDER BY priority DESC, created_at ASC LIMIT 10;

-- Full-text search in emails
-- SELECT * FROM incoming_emails WHERE to_tsvector('english', subject || ' ' || body_text) @@ to_tsquery('english', 'important & urgent');

-- Get user with their email count
-- SELECT u.*, COUNT(e.id) as email_count FROM users u LEFT JOIN incoming_emails e ON u.id = e.user_id GROUP BY u.id;

-- Get recent AI processing stats
-- SELECT DATE(completed_at) as date, COUNT(*) as processed, AVG(processing_duration_ms) as avg_duration_ms FROM incoming_emails WHERE processed = TRUE GROUP BY DATE(completed_at) ORDER BY date DESC;

-- ============================================================================
-- Database Complete!
-- ============================================================================

-- Grant permissions to n8n user (if needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO n8n;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO n8n;
