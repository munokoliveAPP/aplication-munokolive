-- Create music_groups table
CREATE TABLE IF NOT EXISTS public.music_groups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    logo_url TEXT,
    social_link TEXT,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL
);

-- Enable RLS
ALTER TABLE public.music_groups ENABLE ROW LEVEL SECURITY;

-- Policy for reading (public access)
CREATE POLICY "Enable read access for all users" ON public.music_groups
    FOR SELECT USING (true);

-- Policy for inserting (authenticated users only - restricted via UI to admins)
CREATE POLICY "Enable insert for authenticated users" ON public.music_groups
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Policy for update (authenticated users only - ideally restricted to creator or admin)
CREATE POLICY "Enable update for authenticated users" ON public.music_groups
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Policy for delete (authenticated users only)
CREATE POLICY "Enable delete for authenticated users" ON public.music_groups
    FOR DELETE USING (auth.role() = 'authenticated');

-- Create app-assets bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('app-assets', 'app-assets', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policy: Public Read
CREATE POLICY "Public Access app-assets"
ON storage.objects FOR SELECT
USING ( bucket_id = 'app-assets' );

-- Storage Policy: Authenticated Upload
CREATE POLICY "Authenticated Upload app-assets"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'app-assets' AND auth.role() = 'authenticated' );
