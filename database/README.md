# Database Guide for n8n Email Processing

This directory contains database schema and setup scripts for storing user data and processing emails with AI.

## Quick Start

### 1. Setup Database

After installing n8n, run:

```bash
cd ~/soloble-n8n/database
./setup-database.sh
```

This creates 4 tables:
- **users** - User information (name, email, phone)
- **incoming_emails** - Email content and AI processing results
- **email_attachments** - File attachments (optional)
- **ai_processing_queue** - Queue for AI processing

### 2. Connect to Database

```bash
# From your n8n-docker directory
cd ~/n8n-docker
docker compose exec postgres psql -U n8n -d n8n
```

### 3. Use in n8n Workflows

Add "Postgres" node in n8n and configure:
- **Host**: postgres
- **Database**: n8n
- **User**: n8n
- **Password**: (from your .env file)
- **Port**: 5432

## Database Tables

### users

Stores user contact information.

**Columns:**
- `id` - Primary key
- `name` - User's full name
- `email` - Email address (unique)
- `phone` - Phone number
- `company` - Company name (optional)
- `role` - User role (optional)
- `status` - active/inactive/suspended
- `preferences` - JSON preferences
- `created_at`, `updated_at` - Timestamps

**Example queries:**

```sql
-- Add a new user
INSERT INTO users (name, email, phone, company)
VALUES ('John Doe', 'john@example.com', '+1-555-0100', 'Acme Corp');

-- Find user by email
SELECT * FROM users WHERE email = 'john@example.com';

-- List all active users
SELECT id, name, email, company FROM users WHERE status = 'active';

-- Update user phone
UPDATE users SET phone = '+1-555-9999' WHERE email = 'john@example.com';
```

### incoming_emails

Stores all incoming emails with AI processing results.

**Columns:**
- `id` - Primary key
- `user_id` - Links to users table
- `from_email`, `from_name` - Sender info
- `to_email`, `to_name` - Recipient info
- `subject` - Email subject
- `body_text` - Plain text body
- `body_html` - HTML body
- `processed` - Boolean flag
- `ai_result` - JSON with AI analysis
- `ai_sentiment` - positive/negative/neutral
- `ai_intent` - question/complaint/feedback
- `category` - Email category
- `has_attachments` - Boolean flag
- Timestamps: `received_at`, `processing_started_at`, `processing_completed_at`

**Example queries:**

```sql
-- Insert a new email
INSERT INTO incoming_emails (user_id, from_email, to_email, subject, body_text, category)
VALUES (1, 'customer@example.com', 'support@yourapp.com',
        'Question about pricing', 'I have a question...', 'support');

-- Get unprocessed emails (for AI processing)
SELECT id, subject, body_text
FROM incoming_emails
WHERE processed = FALSE
ORDER BY received_at ASC
LIMIT 10;

-- Mark email as processed with AI result
UPDATE incoming_emails
SET processed = TRUE,
    processing_completed_at = NOW(),
    ai_result = '{"summary": "Customer asking about pricing", "action": "send_pricing_info"}',
    ai_sentiment = 'neutral',
    ai_intent = 'question'
WHERE id = 123;

-- Get all emails for a user
SELECT id, from_email, subject, received_at, processed
FROM incoming_emails
WHERE user_id = 1
ORDER BY received_at DESC;

-- Search emails by keyword (full-text search)
SELECT id, subject, body_text
FROM incoming_emails
WHERE to_tsvector('english', subject || ' ' || body_text) @@ to_tsquery('english', 'pricing & question');

-- Get emails by category
SELECT COUNT(*), category
FROM incoming_emails
GROUP BY category;

-- Get processing statistics
SELECT
    DATE(received_at) as date,
    COUNT(*) as total_emails,
    COUNT(*) FILTER (WHERE processed = TRUE) as processed,
    AVG(processing_duration_ms) as avg_duration_ms
FROM incoming_emails
GROUP BY DATE(received_at)
ORDER BY date DESC;
```

### ai_processing_queue

Manages the queue of emails waiting for AI processing.

**Columns:**
- `id` - Primary key
- `email_id` - Links to incoming_emails
- `status` - pending/processing/completed/failed/retry
- `priority` - Higher = more important
- `attempts` - Number of processing attempts
- `max_attempts` - Maximum retry attempts
- `error_message` - Error details if failed
- Timestamps: `created_at`, `started_at`, `completed_at`, `next_retry_at`

**Example queries:**

```sql
-- Add email to processing queue
INSERT INTO ai_processing_queue (email_id, priority)
VALUES (123, 5);

-- Get next items to process
SELECT q.id, q.email_id, e.subject, e.body_text
FROM ai_processing_queue q
JOIN incoming_emails e ON q.email_id = e.id
WHERE q.status = 'pending'
ORDER BY q.priority DESC, q.created_at ASC
LIMIT 10;

-- Mark as processing
UPDATE ai_processing_queue
SET status = 'processing', started_at = NOW()
WHERE id = 456;

-- Mark as completed
UPDATE ai_processing_queue
SET status = 'completed', completed_at = NOW()
WHERE id = 456;

-- Handle failed processing (schedule retry)
UPDATE ai_processing_queue
SET status = 'retry',
    attempts = attempts + 1,
    next_retry_at = NOW() + INTERVAL '5 minutes',
    error_message = 'AI service timeout'
WHERE id = 456;

-- Get items ready for retry
SELECT * FROM ai_processing_queue
WHERE status = 'retry' AND next_retry_at <= NOW()
ORDER BY priority DESC;
```

### email_attachments (Optional)

Stores information about email attachments.

**Columns:**
- `id` - Primary key
- `email_id` - Links to incoming_emails
- `filename` - Original filename
- `content_type` - MIME type (e.g., 'application/pdf')
- `size_bytes` - File size
- `storage_type` - 'local', 'object_storage', 'base64'
- `storage_path` - Path or Object Storage key
- `content_base64` - Base64 content (for small files <1MB)

**Example queries:**

```sql
-- Add attachment
INSERT INTO email_attachments (email_id, filename, content_type, size_bytes, storage_type, storage_path)
VALUES (123, 'invoice.pdf', 'application/pdf', 245678, 'object_storage', 'attachments/2025/01/invoice-123.pdf');

-- Get all attachments for an email
SELECT filename, content_type, size_bytes
FROM email_attachments
WHERE email_id = 123;

-- Find emails with PDF attachments
SELECT DISTINCT e.id, e.subject
FROM incoming_emails e
JOIN email_attachments a ON e.id = a.email_id
WHERE a.content_type = 'application/pdf';
```

## Common Workflows

### Workflow 1: Receive and Store Email

```
1. n8n Email Trigger (IMAP/Gmail/etc.)
2. Extract email data
3. Postgres Node - INSERT into incoming_emails
4. Get inserted ID
5. Add to ai_processing_queue
```

### Workflow 2: Process Emails with AI

```
1. n8n Schedule Trigger (every 5 minutes)
2. Postgres Node - SELECT from ai_processing_queue (status='pending')
3. For each email:
   a. Call AI API (OpenAI, Claude, etc.)
   b. Extract results
   c. Postgres Node - UPDATE incoming_emails (set processed=TRUE, ai_result)
   d. Postgres Node - UPDATE ai_processing_queue (set status='completed')
```

### Workflow 3: Send Automated Response

```
1. n8n Schedule Trigger (every 10 minutes)
2. Postgres Node - SELECT processed emails needing response
3. For each email:
   a. Generate response based on ai_result
   b. Send email via Gmail/SMTP
   c. Mark as responded in database
```

## Useful SQL Views

Create views for common queries:

```sql
-- View: Emails pending AI processing
CREATE VIEW emails_pending_ai AS
SELECT e.id, e.subject, e.from_email, e.received_at, q.priority
FROM incoming_emails e
JOIN ai_processing_queue q ON e.id = q.email_id
WHERE q.status = 'pending'
ORDER BY q.priority DESC, e.received_at ASC;

-- View: User email statistics
CREATE VIEW user_email_stats AS
SELECT
    u.id,
    u.name,
    u.email,
    COUNT(e.id) as total_emails,
    COUNT(*) FILTER (WHERE e.processed = TRUE) as processed_emails,
    MAX(e.received_at) as last_email_date
FROM users u
LEFT JOIN incoming_emails e ON u.id = e.user_id
GROUP BY u.id, u.name, u.email;

-- Usage: SELECT * FROM user_email_stats;
```

## Database Maintenance

### Backup

Database is automatically backed up daily (see BACKUP_GUIDE.md).

Manual backup:
```bash
cd ~/n8n-docker
docker compose exec -T postgres pg_dump -U n8n n8n > backup.sql
```

### Restore

```bash
cd ~/n8n-docker
cat backup.sql | docker compose exec -T postgres psql -U n8n -d n8n
```

### Cleanup Old Data

```sql
-- Delete emails older than 1 year
DELETE FROM incoming_emails
WHERE received_at < NOW() - INTERVAL '1 year';

-- Delete completed queue items older than 30 days
DELETE FROM ai_processing_queue
WHERE status = 'completed'
AND completed_at < NOW() - INTERVAL '30 days';

-- Archive old emails to separate table
CREATE TABLE incoming_emails_archive AS
SELECT * FROM incoming_emails
WHERE received_at < NOW() - INTERVAL '1 year';

DELETE FROM incoming_emails
WHERE received_at < NOW() - INTERVAL '1 year';
```

### Database Size

Check database size:
```sql
-- Total database size
SELECT pg_size_pretty(pg_database_size('n8n'));

-- Size by table
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Performance Tips

1. **Use indexes** - Already created for common queries
2. **Limit result sets** - Use `LIMIT` in n8n queries
3. **Archive old data** - Move old emails to archive table
4. **Use prepared statements** - n8n Postgres node does this automatically
5. **Monitor query performance** - Use `EXPLAIN ANALYZE`

## Security

1. **Never store passwords** - Use secure credential storage in n8n
2. **Sanitize inputs** - n8n Postgres node uses parameterized queries
3. **Limit permissions** - Default n8n user has full access, consider separate read-only user for reporting
4. **Backup regularly** - Already automated
5. **Encrypt sensitive data** - Use PostgreSQL pgcrypto extension if needed

## Troubleshooting

**Can't connect to database:**
```bash
# Check if PostgreSQL is running
docker compose ps

# Restart PostgreSQL
docker compose restart postgres

# View logs
docker compose logs postgres
```

**Schema changes not applying:**
```bash
# Drop and recreate (WARNING: deletes all data)
cd ~/soloble-n8n/database
./setup-database.sh
```

**Slow queries:**
```sql
-- Enable query logging
ALTER DATABASE n8n SET log_min_duration_statement = 1000; -- Log queries >1 second

-- Check slow queries
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

## Next Steps

1. **Setup database**: Run `./setup-database.sh`
2. **Create n8n workflows**: Use examples above
3. **Test with sample data**: Insert test emails
4. **Monitor performance**: Check database size regularly
5. **Setup alerts**: Use n8n to alert on failed processing

---

**Questions?** Check main [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) or open an issue.
