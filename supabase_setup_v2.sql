-- VERSION CORRIGÉE : Utilise des noms de règles uniques pour éviter les conflits

-- 1. Créer le bucket 'events' s'il n'existe pas (inchangé)
INSERT INTO storage.buckets (id, name, public)
VALUES ('events', 'events', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Politique : Lecture Publique (Renommée pour éviter l'erreur)
-- On supprime l'ancienne si elle existe avec ce nom spécifique, puis on la recrée
DROP POLICY IF EXISTS "Events Public Access" ON storage.objects;
CREATE POLICY "Events Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'events' );

-- 3. Politique : Insertion pour les utilisateurs connectés
DROP POLICY IF EXISTS "Events Authenticated Insert" ON storage.objects;
CREATE POLICY "Events Authenticated Insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'events' );

-- 4. Politique : Modification par le propriétaire
DROP POLICY IF EXISTS "Events Owner Update" ON storage.objects;
CREATE POLICY "Events Owner Update"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'events' AND owner = auth.uid() );

-- 5. Politique : Suppression par le propriétaire
DROP POLICY IF EXISTS "Events Owner Delete" ON storage.objects;
CREATE POLICY "Events Owner Delete"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'events' AND owner = auth.uid() );
