-- Migration pour définir un Super Admin
-- Remplacez l'email par celui de l'utilisateur à promouvoir
-- Cette requête doit être exécutée dans l'éditeur SQL de Supabase

DO $$
DECLARE
    target_email TEXT := 'munokolive@gmail.com';
    target_user_id UUID;
BEGIN
    -- 1. Récupérer l'ID de l'utilisateur depuis auth.users
    SELECT id INTO target_user_id FROM auth.users WHERE email = target_email;

    IF target_user_id IS NOT NULL THEN
        -- 2. Insérer ou mettre à jour dans public.users
        INSERT INTO public.users (id, email, role, status, category, updated_at)
        VALUES (
            target_user_id,
            target_email,
            'admin',           -- Rôle défini comme admin
            'validated_admin', -- Statut validé pour éviter le blocage
            'SuperAdmin',      -- Catégorie spéciale
            NOW()
        )
        ON CONFLICT (id) DO UPDATE
        SET 
            role = 'admin',
            status = 'validated_admin',
            category = 'SuperAdmin',
            updated_at = NOW();

        RAISE NOTICE 'Utilisateur % promu Super Admin avec succès.', target_email;
    ELSE
        RAISE NOTICE 'Utilisateur % non trouvé dans auth.users. Veuillez vous inscrire d''abord.', target_email;
    END IF;
END $$;
