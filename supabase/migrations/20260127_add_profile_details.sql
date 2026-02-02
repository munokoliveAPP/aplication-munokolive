-- Add profile fields for modification
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS phone_number text,
ADD COLUMN IF NOT EXISTS country text,
ADD COLUMN IF NOT EXISTS city text,
ADD COLUMN IF NOT EXISTS commune text,
ADD COLUMN IF NOT EXISTS neighborhood text,
ADD COLUMN IF NOT EXISTS is_available boolean DEFAULT true;

NOTIFY pgrst, 'reload schema';
