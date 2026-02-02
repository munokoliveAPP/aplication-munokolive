ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS birth_date date;

NOTIFY pgrst, 'reload schema';
