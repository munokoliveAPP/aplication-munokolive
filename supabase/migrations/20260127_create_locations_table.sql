-- Create locations table
CREATE TABLE IF NOT EXISTS public.locations (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at timestamptz DEFAULT now(),
    name text NOT NULL,
    category text NOT NULL,
    image_url text,
    responsible_name text,
    contact_phone text,
    address text,
    submitted_by_name text,
    submitted_by_id uuid REFERENCES public.users(id),
    is_validated boolean DEFAULT false,
    latitude double precision,
    longitude double precision
);

-- Enable RLS
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

-- Policies
-- Everyone can read validated locations
CREATE POLICY "Public locations are viewable by everyone" 
ON public.locations FOR SELECT 
USING (is_validated = true);

-- Users can read their own submissions even if not validated
CREATE POLICY "Users can see their own submissions" 
ON public.locations FOR SELECT 
USING (auth.uid() = submitted_by_id);

-- Authenticated users can insert new locations
CREATE POLICY "Users can insert locations" 
ON public.locations FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

-- Only admins can update (validation) - For simplicity, let's allow users to update their own for now, or just admins.
-- Let's stick to insert only for users as per prompt "Les lieux ajoutés arrivent... Ils ne s'affichent pour tous QUE lorsque l'Admin les valide".

NOTIFY pgrst, 'reload schema';
