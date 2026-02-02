-- Force PostgREST schema cache reload to fix "Could not find table" error
NOTIFY pgrst, 'reload schema';

-- Ensure permissions are correct
GRANT ALL ON public.users TO postgres, anon, authenticated, service_role;

-- Create a helper function to ensure the super admin is always set correctly
CREATE OR REPLACE FUNCTION public.ensure_super_admin()
RETURNS void AS $$
BEGIN
  -- This will update the user if they exist in public.users
  UPDATE public.users
  SET 
    role = 'admin',
    status = 'active',
    category = 'Ministre',
    sub_category = 'Pasteur'
  WHERE email = 'munokolive@gmail.com';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Run it immediately (it will do nothing if user doesn't exist yet, but harmless)
SELECT public.ensure_super_admin();
