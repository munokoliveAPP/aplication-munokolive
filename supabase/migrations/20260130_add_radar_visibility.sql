-- Migration pour le Radar : Ajout de la visibilité utilisateur
-- Date: 2026-01-30

-- 1. Ajout de la colonne is_visible_on_map
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS is_visible_on_map BOOLEAN DEFAULT FALSE;

-- 2. Index pour optimiser le filtrage (optionnel mais recommandé pour les performances)
CREATE INDEX IF NOT EXISTS users_visible_on_map_idx ON public.users (is_visible_on_map);

-- 3. Rafraîchir le cache du schéma PostgREST pour que l'API détecte le changement immédiatement
NOTIFY pgrst, 'reload schema';
