-- 1. Add missing columns to match UserProfile model
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS points bigint DEFAULT 0,
ADD COLUMN IF NOT EXISTS church_name text,
ADD COLUMN IF NOT EXISTS is_validated boolean DEFAULT false;

-- 2. Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 3. Re-create policies to ensure permissions are correct
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;

CREATE POLICY "Public profiles are viewable by everyone"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "Users can insert their own profile"
ON public.users FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON public.users FOR UPDATE
USING (auth.uid() = id);

-- 4. Force PostgREST schema cache reload to fix PGRST205
NOTIFY pgrst, 'reload schema';
