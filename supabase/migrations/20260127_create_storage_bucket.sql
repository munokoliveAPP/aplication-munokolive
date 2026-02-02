-- Create a new storage bucket for profiles if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('profiles', 'profiles', true)
ON CONFLICT (id) DO NOTHING;

-- Policy to allow public access to profiles
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'profiles' );

-- Policy to allow authenticated users to upload their own avatar
CREATE POLICY "User Upload"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1] );

-- Policy to allow users to update their own avatar
CREATE POLICY "User Update"
ON storage.objects FOR UPDATE
USING ( bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1] );
