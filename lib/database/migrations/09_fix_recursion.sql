-- ============================================================================
-- CORRECTIF "BOUCLE INFINIE" (RECURSION)
-- ============================================================================
-- Problème : Quand on vérifie si un user est admin en lisant la table 'users',
-- la politique de sécurité se déclenche... et revérifie si on est admin... à l'infini.
--
-- Solution : On crée une fonction "Privilégiée" (SECURITY DEFINER) qui a le droit
-- de lire la table sans déclencher les vérifications de sécurité habituelles.

-- 1. Création de la fonction de vérification Admin (Mode "Super-User")
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  -- Cette requête s'exécute avec les droits du créateur (Admin), donc pas de RLS
  RETURN EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
    AND (role = 'admin' OR role = 'super_admin')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; -- SECURITY DEFINER est la clé magique !

-- 2. Mise à jour des Politiques de Sécurité (RLS)

-- A. LECTURE (SELECT)
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.users;
CREATE POLICY "Admins can view all profiles" ON public.users
FOR SELECT USING (
  public.is_admin() -- Utilise la fonction sécurisée au lieu de lire la table directement
);

-- B. MODIFICATION (UPDATE)
DROP POLICY IF EXISTS "Admins can update profiles" ON public.users;
CREATE POLICY "Admins can update profiles" ON public.users
FOR UPDATE USING (
  public.is_admin()
);

-- C. SUPPRESSION (DELETE)
DROP POLICY IF EXISTS "Admins can delete profiles" ON public.users;
CREATE POLICY "Admins can delete profiles" ON public.users
FOR DELETE USING (
  public.is_admin()
);

-- D. Note : La politique "Users can view own profile" reste inchangée car elle ne crée pas de boucle
-- (auth.uid() = id est une comparaison simple, pas une requête sur la table)
