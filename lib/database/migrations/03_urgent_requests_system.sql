-- Migration: 03_urgent_requests_system.sql
-- Description: Creates tables for handling SOS/Urgent requests ("Uber" style emergency missions)

-- 1. Create the table for urgent requests
CREATE TABLE IF NOT EXISTS public.urgent_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    requester_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role_needed TEXT NOT NULL, -- e.g., 'pianiste', 'batteur'
    motive TEXT NOT NULL, -- e.g., 'maladie', 'désistement'
    
    -- Location details
    location_address TEXT,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    
    -- Mission details
    hours_description TEXT, -- e.g., '20h - 23h'
    budget_range TEXT, -- e.g., '20.000 - 30.000 FCFA'
    
    -- Status workflow: pending -> broadcasted -> accepted -> completed (or cancelled)
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'broadcasted', 'accepted', 'completed', 'cancelled')),
    
    -- Assignment (if someone accepts)
    assigned_to_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable RLS
ALTER TABLE public.urgent_requests ENABLE ROW LEVEL SECURITY;

-- 3. Policies

-- Policy: Requesters can see their own requests
CREATE POLICY "Users can view their own urgent requests"
ON public.urgent_requests FOR SELECT
USING (auth.uid() = requester_id);

-- Policy: Admins can see ALL requests (for the SOS Live Dashboard)
CREATE POLICY "Admins can view all urgent requests"
ON public.urgent_requests FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role IN ('admin', 'super_admin')
    )
);

-- Policy: Users can create requests
CREATE POLICY "Users can create urgent requests"
ON public.urgent_requests FOR INSERT
WITH CHECK (auth.uid() = requester_id);

-- Policy: Requesters can update their own requests (e.g. cancel)
CREATE POLICY "Users can update their own urgent requests"
ON public.urgent_requests FOR UPDATE
USING (auth.uid() = requester_id);

-- Policy: Admins can update any request (to broadcast, assign, etc.)
CREATE POLICY "Admins can update all urgent requests"
ON public.urgent_requests FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role IN ('admin', 'super_admin')
    )
);

-- 4. Realtime
-- Enable realtime for this table so the Admin Dashboard updates instantly
ALTER PUBLICATION supabase_realtime ADD TABLE public.urgent_requests;

-- 5. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_urgent_requests_status ON public.urgent_requests(status);
CREATE INDEX IF NOT EXISTS idx_urgent_requests_created_at ON public.urgent_requests(created_at);
