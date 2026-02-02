-- ============================================================================
-- SCRIPT COMPLET DE RÉPARATION DE LA BASE DE DONNÉES (MASTER FIX)
-- Exécutez ce script dans l'éditeur SQL de Supabase pour corriger toutes les erreurs manquantes.
-- ============================================================================

-- 1. Table 'urgent_requests' (Manquante - Cause l'erreur SOS Live)
CREATE TABLE IF NOT EXISTS public.urgent_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    requester_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    role_needed TEXT NOT NULL,
    motive TEXT NOT NULL,
    location_address TEXT,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    hours_description TEXT,
    budget_range TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'broadcasted', 'accepted', 'completed', 'cancelled')),
    assigned_to_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sécurité pour urgent_requests
ALTER TABLE public.urgent_requests ENABLE ROW LEVEL SECURITY;

-- Politiques (Si elles n'existent pas, on les crée via DO block ou on ignore les erreurs de duplication)
-- NOTE: Supabase SQL Editor gère bien les "CREATE POLICY IF NOT EXISTS" si supporté, sinon on drop avant.
DROP POLICY IF EXISTS "Users can view their own urgent requests" ON public.urgent_requests;
CREATE POLICY "Users can view their own urgent requests" ON public.urgent_requests FOR SELECT USING (auth.uid() = requester_id);

DROP POLICY IF EXISTS "Admins can view all urgent requests" ON public.urgent_requests;
CREATE POLICY "Admins can view all urgent requests" ON public.urgent_requests FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

DROP POLICY IF EXISTS "Users can create urgent requests" ON public.urgent_requests;
CREATE POLICY "Users can create urgent requests" ON public.urgent_requests FOR INSERT WITH CHECK (auth.uid() = requester_id);

DROP POLICY IF EXISTS "Users can update their own urgent requests" ON public.urgent_requests;
CREATE POLICY "Users can update their own urgent requests" ON public.urgent_requests FOR UPDATE USING (auth.uid() = requester_id);

DROP POLICY IF EXISTS "Admins can update all urgent requests" ON public.urgent_requests;
CREATE POLICY "Admins can update all urgent requests" ON public.urgent_requests FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Activation Temps Réel
ALTER PUBLICATION supabase_realtime ADD TABLE public.urgent_requests;


-- 2. Colonne 'is_validated' et 'status' pour les Utilisateurs (Manquante - Cause l'erreur Validation)
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_validated BOOLEAN DEFAULT FALSE;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';


-- 3. Table 'notifications' (Pour les alertes Admin)
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can insert notifications" ON public.notifications;
CREATE POLICY "Admins can insert notifications" ON public.notifications FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- 4. Table 'locations' et 'events' (Colonnes de validation)
ALTER TABLE public.locations ADD COLUMN IF NOT EXISTS is_validated BOOLEAN DEFAULT FALSE;
ALTER TABLE public.locations ADD COLUMN IF NOT EXISTS submitted_by UUID REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE public.events ADD COLUMN IF NOT EXISTS is_validated BOOLEAN DEFAULT FALSE;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS submitted_by UUID REFERENCES public.users(id) ON DELETE SET NULL;

-- Fin du script
