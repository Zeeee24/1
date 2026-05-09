-- Supabase Migration: Initial Schema for CineDream
-- Run this in the Supabase SQL Editor to set up all tables and RLS policies

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PROFILES TABLE
-- Stores user profile information linked to auth.users
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only read their own profile
CREATE POLICY "Users can read own profile" 
    ON public.profiles 
    FOR SELECT 
    USING (auth.uid() = id);

-- RLS Policy: Users can only update their own profile
CREATE POLICY "Users can update own profile" 
    ON public.profiles 
    FOR UPDATE 
    USING (auth.uid() = id);

-- RLS Policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile" 
    ON public.profiles 
    FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON public.profiles 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- WATCHLIST TABLE
-- Stores user's Watch Later list
-- ============================================
CREATE TABLE IF NOT EXISTS public.watchlist (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    media_id INTEGER NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('movie', 'tv')),
    title TEXT NOT NULL,
    poster_path TEXT,
    date_added TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, media_id, media_type)
);

-- Enable RLS on watchlist
ALTER TABLE public.watchlist ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only read their own watchlist
CREATE POLICY "Users can read own watchlist" 
    ON public.watchlist 
    FOR SELECT 
    USING (auth.uid() = user_id);

-- RLS Policy: Users can only insert into their own watchlist
CREATE POLICY "Users can insert own watchlist" 
    ON public.watchlist 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can only update their own watchlist
CREATE POLICY "Users can update own watchlist" 
    ON public.watchlist 
    FOR UPDATE 
    USING (auth.uid() = user_id);

-- RLS Policy: Users can only delete from their own watchlist
CREATE POLICY "Users can delete own watchlist" 
    ON public.watchlist 
    FOR DELETE 
    USING (auth.uid() = user_id);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_watchlist_user_id ON public.watchlist(user_id);
CREATE INDEX IF NOT EXISTS idx_watchlist_date_added ON public.watchlist(date_added DESC);

-- ============================================
-- WATCH HISTORY TABLE
-- Stores user's watch history
-- ============================================
CREATE TABLE IF NOT EXISTS public.watch_history (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    media_id INTEGER NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('movie', 'tv')),
    title TEXT NOT NULL,
    poster_path TEXT,
    season INTEGER,
    episode INTEGER,
    episode_title TEXT,
    date_watched TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    progress_seconds INTEGER DEFAULT 0,
    UNIQUE(user_id, media_id, media_type, season, episode)
);

-- Enable RLS on watch_history
ALTER TABLE public.watch_history ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only read their own history
CREATE POLICY "Users can read own history" 
    ON public.watch_history 
    FOR SELECT 
    USING (auth.uid() = user_id);

-- RLS Policy: Users can only insert into their own history
CREATE POLICY "Users can insert own history" 
    ON public.watch_history 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can only update their own history
CREATE POLICY "Users can update own history" 
    ON public.watch_history 
    FOR UPDATE 
    USING (auth.uid() = user_id);

-- RLS Policy: Users can only delete from their own history
CREATE POLICY "Users can delete own history" 
    ON public.watch_history 
    FOR DELETE 
    USING (auth.uid() = user_id);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_watch_history_user_id ON public.watch_history(user_id);
CREATE INDEX IF NOT EXISTS idx_watch_history_date_watched ON public.watch_history(date_watched DESC);

-- ============================================
-- RESUME POSITIONS TABLE
-- Stores user's resume positions for media
-- ============================================
CREATE TABLE IF NOT EXISTS public.resume_positions (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    media_id INTEGER NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('movie', 'tv')),
    season INTEGER,
    episode INTEGER,
    timestamp INTEGER NOT NULL DEFAULT 0,
    duration INTEGER,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, media_id, media_type, season, episode)
);

-- Enable RLS on resume_positions
ALTER TABLE public.resume_positions ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only read their own resume positions
CREATE POLICY "Users can read own resume positions" 
    ON public.resume_positions 
    FOR SELECT 
    USING (auth.uid() = user_id);

-- RLS Policy: Users can only insert their own resume positions
CREATE POLICY "Users can insert own resume positions" 
    ON public.resume_positions 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can only update their own resume positions
CREATE POLICY "Users can update own resume positions" 
    ON public.resume_positions 
    FOR UPDATE 
    USING (auth.uid() = user_id);

-- RLS Policy: Users can only delete their own resume positions
CREATE POLICY "Users can delete own resume positions" 
    ON public.resume_positions 
    FOR DELETE 
    USING (auth.uid() = user_id);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_resume_positions_user_id ON public.resume_positions(user_id);
CREATE INDEX IF NOT EXISTS idx_resume_positions_updated_at ON public.resume_positions(updated_at DESC);

-- Trigger to update updated_at timestamp on resume_positions
CREATE TRIGGER update_resume_positions_updated_at 
    BEFORE UPDATE ON public.resume_positions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STORAGE BUCKET FOR AVATARS
-- ============================================
-- Note: Create this bucket manually in Supabase Dashboard
-- Go to Storage -> New Bucket -> Name: "avatars"
-- Set public bucket and configure upload policies

-- Storage RLS policies (to be configured in Supabase Dashboard):
-- 1. Allow authenticated users to upload to their own folder
-- 2. Allow authenticated users to read any avatar
-- 3. Allow users to delete only their own avatar

-- ============================================
-- FUNCTION: Handle new user signup
-- Automatically creates a profile when a user signs up
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, name)
    VALUES (
        NEW.id, 
        COALESCE(NEW.raw_user_meta_data->>'name', 'User')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- GRANT PERMISSIONS
-- ============================================
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.watchlist TO authenticated;
GRANT ALL ON public.watch_history TO authenticated;
GRANT ALL ON public.resume_positions TO authenticated;

-- Grant sequence permissions
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE public.profiles IS 'User profiles linked to auth.users';
COMMENT ON TABLE public.watchlist IS 'User watch later list';
COMMENT ON TABLE public.watch_history IS 'User watch history with progress';
COMMENT ON TABLE public.resume_positions IS 'User resume positions for media playback';
