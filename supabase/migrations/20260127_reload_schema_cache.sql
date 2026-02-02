-- Force PostgREST schema cache reload
NOTIFY pgrst, 'reload schema';

-- Ensure the Super Admin is set correctly
UPDATE public.users
SET 
  role = 'admin',
  status = 'active',
  category = 'Ministre',
  sub_category = 'Pasteur'
WHERE email = 'munokolive@gmail.com';
