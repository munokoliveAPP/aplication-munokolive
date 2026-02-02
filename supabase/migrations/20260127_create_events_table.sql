-- Create events table
CREATE TABLE IF NOT EXISTS public.events (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at timestamptz DEFAULT now(),
    name text NOT NULL,
    description text,
    event_date timestamptz NOT NULL,
    image_url text,
    location_name text,
    latitude double precision,
    longitude double precision,
    submitted_by_name text,
    submitted_by_id uuid REFERENCES public.users(id),
    is_validated boolean DEFAULT false
);

-- Enable RLS
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- Policies
-- Everyone can read validated events
CREATE POLICY "Public events are viewable by everyone" 
ON public.events FOR SELECT 
USING (is_validated = true);

-- Users can read their own submissions
CREATE POLICY "Users can see their own events" 
ON public.events FOR SELECT 
USING (auth.uid() = submitted_by_id);

-- Authenticated users can insert new events
CREATE POLICY "Users can insert events" 
ON public.events FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

NOTIFY pgrst, 'reload schema';
