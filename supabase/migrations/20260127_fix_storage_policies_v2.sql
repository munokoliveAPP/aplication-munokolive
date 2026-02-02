-- Fix Storage Policies to be more robust
BEGIN;

-- Drop existing policies for profiles bucket to avoid conflicts
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "User Upload" ON storage.objects;
DROP POLICY IF EXISTS "User Update" ON storage.objects;
DROP POLICY IF EXISTS "User Delete" ON storage.objects;

-- Policy to allow public access to profiles
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'profiles' );

-- Policy to allow authenticated users to upload their own avatar (using path prefix matching)
CREATE POLICY "User Upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profiles' AND
  (name LIKE (auth.uid() || '/%'))
);

-- Policy to allow users to update their own avatar
CREATE POLICY "User Update"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profiles' AND
  (name LIKE (auth.uid() || '/%'))
);

-- Policy to allow users to delete their own avatar
CREATE POLICY "User Delete"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profiles' AND
  (name LIKE (auth.uid() || '/%'))
);

COMMIT;
