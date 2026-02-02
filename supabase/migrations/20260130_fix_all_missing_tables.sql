-- ==============================================================================
-- MIGRATION COMPLETE : FIX ALL MISSING TABLES & COLUMNS
-- ==============================================================================

-- 1. Table: chat_messages (Chat du Salon)
-- ------------------------------------------------------------------------------
create table if not exists public.chat_messages (
  id uuid not null default gen_random_uuid(),
  salon_id text not null,
  user_id uuid not null references auth.users(id),
  content text not null,
  user_name text,
  user_avatar text,
  created_at timestamptz not null default now(),
  constraint chat_messages_pkey primary key (id)
);

create index if not exists idx_chat_messages_salon_created 
  on public.chat_messages (salon_id, created_at desc);

alter table public.chat_messages enable row level security;

create policy "Lecture publique chat" on public.chat_messages for select using (true);
create policy "Ecriture authentifiée chat" on public.chat_messages for insert with check (auth.role() = 'authenticated');
create policy "Nettoyage automatique chat" on public.chat_messages for delete using (created_at < (now() - interval '3 days'));
create policy "Suppression propre message" on public.chat_messages for delete using (auth.uid() = user_id);


-- 2. Table: users (Mise à jour des colonnes manquantes)
-- ------------------------------------------------------------------------------
do $$
begin
  -- Mode Radar
  if not exists (select 1 from information_schema.columns where table_name = 'users' and column_name = 'is_visible_on_map') then
    alter table public.users add column is_visible_on_map boolean default false;
  end if;
  
  -- Système de Parrainage
  if not exists (select 1 from information_schema.columns where table_name = 'users' and column_name = 'referral_code') then
    alter table public.users add column referral_code text unique;
  end if;

  if not exists (select 1 from information_schema.columns where table_name = 'users' and column_name = 'referred_by') then
    alter table public.users add column referred_by text; -- Stocke l'UUID du parrain (mais typé text pour flexibilité)
  end if;

  if not exists (select 1 from information_schema.columns where table_name = 'users' and column_name = 'referral_count') then
    alter table public.users add column referral_count int4 default 0;
  end if;
end $$;

-- Index géographique
create index if not exists idx_users_location on public.users (latitude, longitude) where is_visible_on_map = true;


-- 3. TRIGGER MAGIQUE : Correction automatique du code parrain en UUID
-- ------------------------------------------------------------------------------
-- Si l'application envoie un Code Parrain (ex: "CHR123") au lieu d'un UUID dans 'referred_by',
-- ce trigger va chercher l'UUID correspondant et corriger la valeur avant l'insertion.
create or replace function public.resolve_referral_code()
returns trigger as $$
declare
  referrer_uuid uuid;
begin
  -- Si referred_by est non nul et ne ressemble pas à un UUID (simple check de longueur/format)
  if NEW.referred_by is not null and length(NEW.referred_by) < 30 then
    -- On cherche l'ID de l'utilisateur qui a ce code
    select id into referrer_uuid from public.users where referral_code = NEW.referred_by limit 1;
    
    if referrer_uuid is not null then
      NEW.referred_by := referrer_uuid::text;
    end if;
  end if;
  return NEW;
end;
$$ language plpgsql;

drop trigger if exists trg_resolve_referral_code on public.users;
create trigger trg_resolve_referral_code
  before insert or update on public.users
  for each row execute function public.resolve_referral_code();


-- 4. RPC : Incrémenter le compteur de parrainage
-- ------------------------------------------------------------------------------
create or replace function public.increment_referral_count(referrer_code text)
returns void as $$
begin
  update public.users
  set referral_count = referral_count + 1
  where referral_code = referrer_code;
end;
$$ language plpgsql security definer;


-- 5. Table: app_config (Configuration Dynamique)
-- ------------------------------------------------------------------------------
create table if not exists public.app_config (
  id int8 not null default 1,
  constraint app_config_pkey primary key (id),
  constraint single_row_check check (id = 1)
);

-- Ajout sécurisé des colonnes si la table existait déjà sans elles
do $$
begin
  if not exists (select 1 from information_schema.columns where table_name = 'app_config' and column_name = 'maintenance_mode') then
    alter table public.app_config add column maintenance_mode boolean default false;
  end if;
  
  if not exists (select 1 from information_schema.columns where table_name = 'app_config' and column_name = 'radar_radius') then
    alter table public.app_config add column radar_radius int8 default 5000;
  end if;

  if not exists (select 1 from information_schema.columns where table_name = 'app_config' and column_name = 'ai_message') then
    alter table public.app_config add column ai_message text default 'Bienvenue sur MunokoLive !';
  end if;

  if not exists (select 1 from information_schema.columns where table_name = 'app_config' and column_name = 'updated_at') then
    alter table public.app_config add column updated_at timestamptz default now();
  end if;
end $$;

insert into public.app_config (id, maintenance_mode, radar_radius, ai_message)
values (1, false, 5000, 'Bienvenue sur MunokoLive !')
on conflict (id) do nothing;

alter table public.app_config enable row level security;
create policy "Lecture config publique" on public.app_config for select using (true);
create policy "Modification config admin" on public.app_config for update using (auth.role() = 'authenticated');


-- 6. Storage : Bucket 'files' (Si possible via SQL)
-- ------------------------------------------------------------------------------
-- Note: Ceci peut échouer selon les permissions, mais c'est la commande standard
insert into storage.buckets (id, name, public)
values ('files', 'files', true)
on conflict (id) do nothing;

-- Politique de stockage (si le bucket vient d'être créé)
-- Autoriser l'upload pour les authentifiés
create policy "Upload pour authentifiés"
  on storage.objects for insert
  with check (bucket_id = 'files' and auth.role() = 'authenticated');

-- Autoriser la lecture pour tous
create policy "Lecture publique fichiers"
  on storage.objects for select
  using (bucket_id = 'files');


-- 7. REALTIME : Activer la diffusion en direct
-- ------------------------------------------------------------------------------
-- Cela permet au chat et au message d'accueil de se mettre à jour instantanément
begin;
  -- Vérifier si la publication existe (par défaut 'supabase_realtime')
  -- On ajoute les tables à la publication
  alter publication supabase_realtime add table public.chat_messages;
  alter publication supabase_realtime add table public.app_config;
  alter publication supabase_realtime add table public.users;
commit;
