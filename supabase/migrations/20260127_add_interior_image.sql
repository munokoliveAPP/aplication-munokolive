-- Add interior image column to locations table
ALTER TABLE public.locations
ADD COLUMN IF NOT EXISTS interior_image_url text;

NOTIFY pgrst, 'reload schema';
