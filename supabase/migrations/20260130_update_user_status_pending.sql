-- Update handle_new_user to set default status to 'pending'
-- This ensures users must complete their profile and wait for validation (or just complete profile if we allow auto-activation later)
-- But user requested "soumettre pour être validé", so 'pending' is appropriate.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  default_role text := 'user';
  default_status text := 'pending'; -- Changed from 'active' to 'pending'
  default_category text := 'Fidèle';
  default_sub_category text := 'Aucun';
  default_church text := 'Non renseigné';
BEGIN
  INSERT INTO public.users (
    id,
    email,
    role,
    status,
    first_name,
    last_name,
    church_name,
    category,
    sub_category,
    is_visible_on_map,
    referral_code,
    referral_count,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    default_role,
    default_status,
    '', -- Empty first_name signals incomplete profile
    '',
    default_church,
    default_category,
    default_sub_category,
    false,
    upper(substring(md5(random()::text) from 1 for 8)), -- Generate random referral code
    0,
    now(),
    now()
  );

  RETURN NEW;
END;
$$;
