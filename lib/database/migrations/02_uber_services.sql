-- 1. Table des Services (Ce que les utilisateurs proposent)
-- Un utilisateur peut proposer plusieurs services (ex: Pianiste ET Professeur de chant)
CREATE TABLE public.services (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    provider_id uuid REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    title text NOT NULL, -- ex: "Pianiste Jazz", "Sonorisation Complète"
    description text,
    rate_amount numeric NOT NULL, -- Montant
    rate_type text NOT NULL CHECK (rate_type IN ('hourly', 'fixed')), -- 'hourly' ou 'fixed'
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Index pour la recherche rapide par prestataire
CREATE INDEX idx_services_provider ON public.services(provider_id);

-- 2. Table des Réservations (Bookings)
CREATE TABLE public.bookings (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id uuid REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    service_id uuid REFERENCES public.services(id) ON DELETE SET NULL, -- Si le service est supprimé, on garde l'historique
    provider_id uuid REFERENCES public.users(id) ON DELETE CASCADE NOT NULL, -- Dénormalisation utile pour les requêtes rapides
    
    status text NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'accepted', 'declined', 'en_route', 'in_progress', 'completed', 'cancelled')),
    
    booking_date timestamptz NOT NULL, -- Date prévue de la prestation
    location_name text, -- Lieu du RDV
    latitude double precision, -- Pour le GPS
    longitude double precision, -- Pour le GPS
    
    total_price numeric, -- Prix convenu (peut différer du rate si négocié)
    
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Index pour les listes "Mes Réservations"
CREATE INDEX idx_bookings_client ON public.bookings(client_id);
CREATE INDEX idx_bookings_provider ON public.bookings(provider_id);
CREATE INDEX idx_bookings_status ON public.bookings(status);

-- 3. Sécurité (RLS - Row Level Security)
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Policies Services
-- Tout le monde peut voir les services actifs
CREATE POLICY "Services are viewable by everyone" 
ON public.services FOR SELECT 
USING (is_active = true);

-- Seul le propriétaire peut créer/modifier ses services
CREATE POLICY "Users can insert their own services" 
ON public.services FOR INSERT 
WITH CHECK (auth.uid() = provider_id);

CREATE POLICY "Users can update their own services" 
ON public.services FOR UPDATE 
USING (auth.uid() = provider_id);

CREATE POLICY "Users can delete their own services" 
ON public.services FOR DELETE 
USING (auth.uid() = provider_id);

-- Policies Bookings
-- Le client et le prestataire peuvent voir leurs réservations
CREATE POLICY "Users can see their own bookings" 
ON public.bookings FOR SELECT 
USING (auth.uid() = client_id OR auth.uid() = provider_id);

-- Seul un utilisateur authentifié peut créer une réservation
CREATE POLICY "Authenticated users can create bookings" 
ON public.bookings FOR INSERT 
WITH CHECK (auth.uid() = client_id);

-- Mise à jour (Acceptation/Annulation/Statut) par les concernés
CREATE POLICY "Participants can update bookings" 
ON public.bookings FOR UPDATE 
USING (auth.uid() = client_id OR auth.uid() = provider_id);
