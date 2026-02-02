-- Migration to enhance locations table for validation and security

-- 1. Ensure submitted_by_id is a foreign key
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_locations_submitted_by'
  ) THEN
    ALTER TABLE public.locations 
    ADD CONSTRAINT fk_locations_submitted_by 
    FOREIGN KEY (submitted_by_id) 
    REFERENCES public.users(id) ON DELETE SET NULL;
  END IF;
END $$;

-- 2. Add policies if they don't exist (Idempotent check difficult in simple SQL, assuming they might need update)
-- Allow creators to update their own places
CREATE POLICY "Enable update for users based on submitted_by_id" 
ON public.locations FOR UPDATE 
USING (auth.uid() = submitted_by_id);

-- 3. Index for geospatial queries (if not exists)
CREATE INDEX IF NOT EXISTS locations_geo_idx ON public.locations USING GIST (
  ll_to_earth(latitude, longitude)
);

-- 4. Ensure is_validated default is false
ALTER TABLE public.locations ALTER COLUMN is_validated SET DEFAULT false;
