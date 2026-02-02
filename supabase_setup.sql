-- COPIEZ CE CODE ET EXÉCUTEZ-LE DANS L'ÉDITEUR SQL DE SUPABASE

-- 1. Créer le bucket 'events' s'il n'existe pas
INSERT INTO storage.buckets (id, name, public)
VALUES ('events', 'events', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Politique : Tout le monde peut voir les images (Lecture Publique)
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'events' );

-- 3. Politique : Les utilisateurs connectés peuvent uploader (Insertion Authentifiée)
CREATE POLICY "Authenticated Insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'events' );

-- 4. Politique : Les utilisateurs peuvent modifier leurs propres images (Update)
CREATE POLICY "Owner Update"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'events' AND owner = auth.uid() );

-- 5. Politique : Les utilisateurs peuvent supprimer leurs propres images (Delete)
CREATE POLICY "Owner Delete"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'events' AND owner = auth.uid() );
