

-- Create table for storing FCM tokens
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    fcm_token TEXT NOT NULL,
    platform TEXT NOT NULL, -- 'android', 'iOS', 'web'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, platform)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_platform ON user_fcm_tokens(platform);

-- Enable Row Level Security (RLS)
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only access their own FCM tokens
CREATE POLICY "Users can view own FCM tokens" ON user_fcm_tokens
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own FCM tokens" ON user_fcm_tokens
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own FCM tokens" ON user_fcm_tokens
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own FCM tokens" ON user_fcm_tokens
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_user_fcm_tokens_updated_at
    BEFORE UPDATE ON user_fcm_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Optional: Create a view for easier querying
CREATE OR REPLACE VIEW user_fcm_tokens_view AS
SELECT 
    id,
    user_id,
    fcm_token,
    platform,
    created_at,
    updated_at,
    CASE 
        WHEN updated_at > created_at + INTERVAL '1 day' THEN 'updated'
        ELSE 'new'
    END as token_status
FROM user_fcm_tokens;

-- Grant necessary permissions
GRANT ALL ON user_fcm_tokens TO authenticated;
GRANT SELECT ON user_fcm_tokens_view TO authenticated;