-- BAWASA Issues Schema
-- This script creates the issues, issue_comments, and issue_attachments tables for the BAWASA mobile app
-- This schema integrates with the existing users table for issue reporting and management

-- Create issues table
CREATE TABLE IF NOT EXISTS issues (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    issue_number VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    issue_type VARCHAR(50) NOT NULL CHECK (issue_type IN (
        'water_leak', 'low_water_pressure', 'water_quality_issue', 
        'billing_dispute', 'meter_problem', 'service_interruption', 'other'
    )),
    priority VARCHAR(20) DEFAULT 'medium' NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status VARCHAR(20) DEFAULT 'open' NOT NULL CHECK (status IN (
        'open', 'in_progress', 'pending_customer', 'resolved', 'closed', 'cancelled'
    )),
    location_address TEXT,
    location_coordinates POINT, -- For GPS coordinates if available
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    estimated_resolution_date DATE,
    actual_resolution_date DATE,
    resolution_notes TEXT,
    assigned_to UUID REFERENCES auth.users(id), -- Staff member assigned to handle the issue
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    closed_at TIMESTAMP WITH TIME ZONE
);

-- Create issue_comments table for communication and updates
CREATE TABLE IF NOT EXISTS issue_comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    issue_id UUID REFERENCES issues(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    comment_type VARCHAR(20) DEFAULT 'update' NOT NULL CHECK (comment_type IN (
        'update', 'internal_note', 'customer_response', 'resolution_update'
    )),
    content TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT false NOT NULL, -- Internal comments not visible to customers
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create issue_attachments table for file uploads and photos
CREATE TABLE IF NOT EXISTS issue_attachments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    issue_id UUID REFERENCES issues(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL, -- Path to file in storage
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_type VARCHAR(20) DEFAULT 'image' NOT NULL CHECK (file_type IN ('image', 'document', 'video', 'audio', 'other')),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_issues_user_id ON issues(user_id);
CREATE INDEX IF NOT EXISTS idx_issues_issue_number ON issues(issue_number);
CREATE INDEX IF NOT EXISTS idx_issues_status ON issues(status);
CREATE INDEX IF NOT EXISTS idx_issues_priority ON issues(priority);
CREATE INDEX IF NOT EXISTS idx_issues_issue_type ON issues(issue_type);
CREATE INDEX IF NOT EXISTS idx_issues_assigned_to ON issues(assigned_to);
CREATE INDEX IF NOT EXISTS idx_issues_created_at ON issues(created_at);
CREATE INDEX IF NOT EXISTS idx_issues_estimated_resolution_date ON issues(estimated_resolution_date);

CREATE INDEX IF NOT EXISTS idx_issue_comments_issue_id ON issue_comments(issue_id);
CREATE INDEX IF NOT EXISTS idx_issue_comments_user_id ON issue_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_issue_comments_created_at ON issue_comments(created_at);
CREATE INDEX IF NOT EXISTS idx_issue_comments_comment_type ON issue_comments(comment_type);

CREATE INDEX IF NOT EXISTS idx_issue_attachments_issue_id ON issue_attachments(issue_id);
CREATE INDEX IF NOT EXISTS idx_issue_attachments_user_id ON issue_attachments(user_id);
CREATE INDEX IF NOT EXISTS idx_issue_attachments_file_type ON issue_attachments(file_type);

-- Create functions to automatically update timestamps
CREATE OR REPLACE FUNCTION update_issues_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION update_issue_comments_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update timestamps
CREATE TRIGGER update_issues_updated_at 
    BEFORE UPDATE ON issues 
    FOR EACH ROW 
    EXECUTE FUNCTION update_issues_updated_at_column();

CREATE TRIGGER update_issue_comments_updated_at 
    BEFORE UPDATE ON issue_comments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_issue_comments_updated_at_column();

-- Create function to automatically generate issue numbers
CREATE OR REPLACE FUNCTION generate_issue_number()
RETURNS TRIGGER AS $$
DECLARE
    issue_count INTEGER;
    new_issue_number VARCHAR(50);
BEGIN
    -- Get the count of issues for the current year
    SELECT COUNT(*) + 1 INTO issue_count
    FROM issues
    WHERE EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW());
    
    -- Generate issue number in format: ISS-YYYY-XXXX
    new_issue_number := 'ISS-' || EXTRACT(YEAR FROM NOW()) || '-' || LPAD(issue_count::TEXT, 4, '0');
    
    NEW.issue_number := new_issue_number;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically generate issue numbers
CREATE TRIGGER generate_issue_number_trigger
    BEFORE INSERT ON issues
    FOR EACH ROW
    EXECUTE FUNCTION generate_issue_number();

-- Create function to automatically update issue status timestamps
CREATE OR REPLACE FUNCTION update_issue_status_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    -- Update resolved_at when status changes to resolved
    IF NEW.status = 'resolved' AND OLD.status != 'resolved' THEN
        NEW.resolved_at = NOW();
    END IF;
    
    -- Update closed_at when status changes to closed
    IF NEW.status = 'closed' AND OLD.status != 'closed' THEN
        NEW.closed_at = NOW();
    END IF;
    
    -- Clear resolved_at and closed_at if status changes back
    IF NEW.status NOT IN ('resolved', 'closed') THEN
        NEW.resolved_at = NULL;
        NEW.closed_at = NULL;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update status timestamps
CREATE TRIGGER update_issue_status_timestamps_trigger
    BEFORE UPDATE ON issues
    FOR EACH ROW
    EXECUTE FUNCTION update_issue_status_timestamps();

-- Enable Row Level Security (RLS)
ALTER TABLE issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE issue_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE issue_attachments ENABLE ROW LEVEL SECURITY;

-- Create policies for RLS
-- Issues policies
CREATE POLICY "Users can view their own issues" ON issues
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own issues" ON issues
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own issues" ON issues
    FOR UPDATE USING (auth.uid() = user_id);

-- Staff can view all issues (for future use - when staff roles are implemented)
-- CREATE POLICY "Staff can view all issues" ON issues
--     FOR ALL USING (
--         EXISTS (
--             SELECT 1 FROM users 
--             WHERE users.auth_user_id = auth.uid() 
--             AND users.account_type IN ('admin', 'staff')
--         )
--     );

-- Issue comments policies
CREATE POLICY "Users can view comments for their issues" ON issue_comments
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM issues 
            WHERE issues.id = issue_comments.issue_id 
            AND issues.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert comments for their issues" ON issue_comments
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM issues 
            WHERE issues.id = issue_comments.issue_id 
            AND issues.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own comments" ON issue_comments
    FOR UPDATE USING (auth.uid() = user_id);

-- Issue attachments policies
CREATE POLICY "Users can view attachments for their issues" ON issue_attachments
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM issues 
            WHERE issues.id = issue_attachments.issue_id 
            AND issues.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert attachments for their issues" ON issue_attachments
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM issues 
            WHERE issues.id = issue_attachments.issue_id 
            AND issues.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own attachments" ON issue_attachments
    FOR DELETE USING (auth.uid() = user_id);

-- Create views for easier querying
CREATE OR REPLACE VIEW issues_with_user AS
SELECT 
    i.*,
    u.email as user_email,
    u.full_name as user_name,
    u.phone as user_phone,
    assigned_user.email as assigned_to_email,
    assigned_user.full_name as assigned_to_name
FROM issues i
LEFT JOIN users u ON i.user_id = u.auth_user_id
LEFT JOIN users assigned_user ON i.assigned_to = assigned_user.auth_user_id;

CREATE OR REPLACE VIEW issues_with_comments AS
SELECT 
    i.*,
    COALESCE(
        json_agg(
            json_build_object(
                'id', ic.id,
                'user_id', ic.user_id,
                'comment_type', ic.comment_type,
                'content', ic.content,
                'is_internal', ic.is_internal,
                'created_at', ic.created_at,
                'user_name', u.full_name,
                'user_email', u.email
            ) ORDER BY ic.created_at
        ) FILTER (WHERE ic.id IS NOT NULL),
        '[]'::json
    ) as comments
FROM issues i
LEFT JOIN issue_comments ic ON i.id = ic.issue_id
LEFT JOIN users u ON ic.user_id = u.auth_user_id
GROUP BY i.id;

CREATE OR REPLACE VIEW issues_with_attachments AS
SELECT 
    i.*,
    COALESCE(
        json_agg(
            json_build_object(
                'id', ia.id,
                'file_name', ia.file_name,
                'file_path', ia.file_path,
                'file_size', ia.file_size,
                'mime_type', ia.mime_type,
                'file_type', ia.file_type,
                'description', ia.description,
                'created_at', ia.created_at
            ) ORDER BY ia.created_at
        ) FILTER (WHERE ia.id IS NOT NULL),
        '[]'::json
    ) as attachments
FROM issues i
LEFT JOIN issue_attachments ia ON i.id = ia.issue_id
GROUP BY i.id;

-- Create a comprehensive view with all related data
CREATE OR REPLACE VIEW issues_complete AS
SELECT 
    i.*,
    u.email as user_email,
    u.full_name as user_name,
    u.phone as user_phone,
    assigned_user.email as assigned_to_email,
    assigned_user.full_name as assigned_to_name,
    COALESCE(
        json_agg(
            json_build_object(
                'id', ic.id,
                'user_id', ic.user_id,
                'comment_type', ic.comment_type,
                'content', ic.content,
                'is_internal', ic.is_internal,
                'created_at', ic.created_at,
                'comment_user_name', comment_user.full_name,
                'comment_user_email', comment_user.email
            ) ORDER BY ic.created_at
        ) FILTER (WHERE ic.id IS NOT NULL),
        '[]'::json
    ) as comments,
    COALESCE(
        json_agg(
            json_build_object(
                'id', ia.id,
                'file_name', ia.file_name,
                'file_path', ia.file_path,
                'file_size', ia.file_size,
                'mime_type', ia.mime_type,
                'file_type', ia.file_type,
                'description', ia.description,
                'created_at', ia.created_at
            ) ORDER BY ia.created_at
        ) FILTER (WHERE ia.id IS NOT NULL),
        '[]'::json
    ) as attachments
FROM issues i
LEFT JOIN users u ON i.user_id = u.auth_user_id
LEFT JOIN users assigned_user ON i.assigned_to = assigned_user.auth_user_id
LEFT JOIN issue_comments ic ON i.id = ic.issue_id
LEFT JOIN users comment_user ON ic.user_id = comment_user.auth_user_id
LEFT JOIN issue_attachments ia ON i.id = ia.issue_id
GROUP BY i.id, u.email, u.full_name, u.phone, assigned_user.email, assigned_user.full_name;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON issues TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON issue_comments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON issue_attachments TO authenticated;
GRANT SELECT ON issues_with_user TO authenticated;
GRANT SELECT ON issues_with_comments TO authenticated;
GRANT SELECT ON issues_with_attachments TO authenticated;
GRANT SELECT ON issues_complete TO authenticated;

-- Comments for documentation
COMMENT ON TABLE issues IS 'Stores customer issue reports and their status';
COMMENT ON COLUMN issues.id IS 'Unique identifier for each issue';
COMMENT ON COLUMN issues.user_id IS 'Reference to the user who reported the issue';
COMMENT ON COLUMN issues.issue_number IS 'Unique issue number for reference (auto-generated)';
COMMENT ON COLUMN issues.title IS 'Brief title describing the issue';
COMMENT ON COLUMN issues.description IS 'Detailed description of the issue';
COMMENT ON COLUMN issues.issue_type IS 'Category of the issue';
COMMENT ON COLUMN issues.priority IS 'Priority level: low, medium, high, urgent';
COMMENT ON COLUMN issues.status IS 'Current status of the issue';
COMMENT ON COLUMN issues.location_address IS 'Address where the issue occurred';
COMMENT ON COLUMN issues.location_coordinates IS 'GPS coordinates of the issue location';
COMMENT ON COLUMN issues.contact_phone IS 'Phone number for contact regarding this issue';
COMMENT ON COLUMN issues.contact_email IS 'Email for contact regarding this issue';
COMMENT ON COLUMN issues.estimated_resolution_date IS 'Expected date when issue will be resolved';
COMMENT ON COLUMN issues.actual_resolution_date IS 'Actual date when issue was resolved';
COMMENT ON COLUMN issues.resolution_notes IS 'Notes about how the issue was resolved';
COMMENT ON COLUMN issues.assigned_to IS 'Staff member assigned to handle this issue';
COMMENT ON COLUMN issues.resolved_at IS 'Timestamp when issue was marked as resolved';
COMMENT ON COLUMN issues.closed_at IS 'Timestamp when issue was closed';

COMMENT ON TABLE issue_comments IS 'Stores comments and updates for issues';
COMMENT ON COLUMN issue_comments.id IS 'Unique identifier for each comment';
COMMENT ON COLUMN issue_comments.issue_id IS 'Reference to the parent issue';
COMMENT ON COLUMN issue_comments.user_id IS 'Reference to the user who made the comment';
COMMENT ON COLUMN issue_comments.comment_type IS 'Type of comment: update, internal_note, customer_response, resolution_update';
COMMENT ON COLUMN issue_comments.content IS 'Content of the comment';
COMMENT ON COLUMN issue_comments.is_internal IS 'Whether this comment is internal (not visible to customers)';

COMMENT ON TABLE issue_attachments IS 'Stores file attachments for issues';
COMMENT ON COLUMN issue_attachments.id IS 'Unique identifier for each attachment';
COMMENT ON COLUMN issue_attachments.issue_id IS 'Reference to the parent issue';
COMMENT ON COLUMN issue_attachments.user_id IS 'Reference to the user who uploaded the file';
COMMENT ON COLUMN issue_attachments.file_name IS 'Original name of the uploaded file';
COMMENT ON COLUMN issue_attachments.file_path IS 'Path to the file in storage';
COMMENT ON COLUMN issue_attachments.file_size IS 'Size of the file in bytes';
COMMENT ON COLUMN issue_attachments.mime_type IS 'MIME type of the file';
COMMENT ON COLUMN issue_attachments.file_type IS 'Category of file: image, document, video, audio, other';
COMMENT ON COLUMN issue_attachments.description IS 'Optional description of the attachment';
