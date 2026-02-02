-- Add location columns to users table
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS latitude double precision,
ADD COLUMN IF NOT EXISTS longitude double precision,
ADD COLUMN IF NOT EXISTS last_location_update timestamptz;

-- Index for geospatial queries (optional but good practice)
-- CREATE INDEX idx_users_location ON public.users USING gist (ll_to_earth(latitude, longitude));

NOTIFY pgrst, 'reload schema';
