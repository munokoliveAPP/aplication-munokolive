-- 1. Disable RLS momentarily to break any recursion loops
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- 2. Drop ALL existing policies to clean up any recursive logic
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.users;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;
DROP POLICY IF EXISTS "Enable update for users based on email" ON public.users;

-- 3. Re-enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 4. Create SIMPLE, NON-RECURSIVE policies
-- Allow public read access (no recursion possible here as it's just 'true')
CREATE POLICY "Public profiles are viewable by everyone"
ON public.users FOR SELECT
USING (true);

-- Allow users to insert their own profile (checks auth.uid(), no table lookup)
CREATE POLICY "Users can insert their own profile"
ON public.users FOR INSERT
WITH CHECK (auth.uid() = id);

-- Allow users to update their own profile (checks auth.uid(), no table lookup)
CREATE POLICY "Users can update their own profile"
ON public.users FOR UPDATE
USING (auth.uid() = id);

-- 5. Force Schema Cache Reload (Fixes PGRST205)
NOTIFY pgrst, 'reload schema';

-- 6. Ensure the Super Admin user exists and has correct role (Just in case)
INSERT INTO public.users (id, email, role, status, category, sub_category, first_name, last_name)
SELECT 
  id, 
  email, 
  'admin', 
  'active', 
  'Ministre', 
  'Pasteur', 
  'Munoko', 
  'Live'
FROM auth.users 
WHERE email = 'munokolive@gmail.com'
ON CONFLICT (id) DO UPDATE SET 
  role = 'admin',
  status = 'active',
  category = 'Ministre',
  sub_category = 'Pasteur';
