-- Migration pour définir un Super Admin (Compatible Firebase Auth)
-- Cette requête met à jour la table public.users directement

DO $$
DECLARE
    target_email TEXT := 'munokolive@gmail.com';
BEGIN
    -- Mettre à jour l'utilisateur s'il existe déjà dans public.users
    UPDATE public.users
    SET 
        role = 'admin',
        status = 'validated_admin',
        category = 'SuperAdmin',
        updated_at = NOW()
    WHERE email = target_email;

    IF FOUND THEN
        RAISE NOTICE 'Utilisateur % promu Super Admin avec succès.', target_email;
    ELSE
        RAISE NOTICE 'Utilisateur % non trouvé dans public.users. Veuillez vous INSCRIRE dans l''application d''abord.', target_email;
    END IF;
END $$;
