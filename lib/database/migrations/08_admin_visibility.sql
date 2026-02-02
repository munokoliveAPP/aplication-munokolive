-- ============================================================================
-- SCRIPT DE VISIBILITÉ UTILISATEURS (ADMIN VIEW ALL)
-- ============================================================================

-- 1. Activer RLS sur la table users (sécurité de base)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 2. Politique de LECTURE (SELECT)
-- Permet aux admins et super_admins de voir TOUS les profils
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.users;

CREATE POLICY "Admins can view all profiles" ON public.users
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.users AS u
    WHERE u.id = auth.uid() 
    AND (u.role = 'admin' OR u.role = 'super_admin')
  )
);

-- Permet aussi à chaque utilisateur de voir son PROPRE profil (indispensable)
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users
FOR SELECT USING (
  auth.uid() = id
);

-- 3. Politique de MODIFICATION (UPDATE)
-- Permet aux admins de modifier les profils (ex: changer le rôle, bannir)
DROP POLICY IF EXISTS "Admins can update profiles" ON public.users;

CREATE POLICY "Admins can update profiles" ON public.users
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.users AS u
    WHERE u.id = auth.uid() 
    AND (u.role = 'admin' OR u.role = 'super_admin')
  )
);

-- Permet à l'utilisateur de modifier son propre profil
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users
FOR UPDATE USING (
  auth.uid() = id
);

-- 4. Politique de SUPPRESSION (DELETE)
-- Seuls les admins peuvent supprimer des utilisateurs
DROP POLICY IF EXISTS "Admins can delete profiles" ON public.users;

CREATE POLICY "Admins can delete profiles" ON public.users
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM public.users AS u
    WHERE u.id = auth.uid() 
    AND (u.role = 'admin' OR u.role = 'super_admin')
  )
);
