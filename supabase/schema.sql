-- Enable PostGIS extension for geolocation
create extension if not exists postgis;

-- Create User Category Enum
create type user_category as enum ('musicien', 'ministre');

-- Create Profiles Table
create table public.profiles (
  id uuid references auth.users not null primary key,
  full_name text,
  category user_category,
  sub_category text, -- instrument or function
  church_name text,
  city text,
  commune text,
  quartier text,
  phone text unique, -- Phone should be unique to be used as sponsor_number reference reliably
  sponsor_number text,
  stars integer default 0,
  is_validated boolean default false,
  is_available boolean default true,
  bio text,
  birthday date,
  role text default 'user', -- 'user' or 'admin'
  location geography(point), -- For PostGIS
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Set up Row Level Security (RLS)
alter table public.profiles enable row level security;

-- Policies

-- 1. Public read access
create policy "Public profiles are viewable by everyone"
  on public.profiles for select
  using ( true );

-- 2. Users can insert their own profile
create policy "Users can insert their own profile"
  on public.profiles for insert
  with check ( auth.uid() = id );

-- 3. Users can update their own profile
create policy "Users can update own profile"
  on public.profiles for update
  using ( auth.uid() = id );

-- 4. Admins can update everything
create policy "Admins can update everything"
  on public.profiles for all
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- Function to calculate sponsorship
-- Triggered when a new profile is created
create or replace function public.handle_sponsorship()
returns trigger as $$
declare
  sponsor_id uuid;
  referral_count integer;
begin
  -- Check if sponsor_number is provided
  if new.sponsor_number is not null and new.sponsor_number != '' then
    -- Find sponsor's ID based on phone number
    select id into sponsor_id from public.profiles where phone = new.sponsor_number limit 1;
    
    if sponsor_id is not null then
      -- Count total referrals by this sponsor (including the new one)
      select count(*) into referral_count from public.profiles where sponsor_number = new.sponsor_number;
      
      -- If count is a multiple of 10 (e.g., 10th, 20th referral...), increment stars
      if referral_count > 0 and (referral_count % 10) = 0 then
        update public.profiles
        set stars = stars + 1
        where id = sponsor_id;
      end if;
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer;

-- Trigger for sponsorship
create trigger on_profile_created
  after insert on public.profiles
  for each row execute procedure public.handle_sponsorship();

-- Function to prevent unauthorized updates to sensitive fields
create or replace function public.prevent_unauthorized_updates()
returns trigger as $$
begin
  -- If user is not postgres/service_role AND not an admin
  if (current_user not in ('postgres', 'service_role')) and
     (not exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')) then
     
     -- Check if sensitive fields are being modified
     if new.is_validated != old.is_validated or
        new.stars != old.stars or
        new.role != old.role then
        raise exception 'You are not authorized to update sensitive fields (is_validated, stars, role).';
     end if;
  end if;
  return new;
end;
$$ language plpgsql security definer;

-- Trigger to protect sensitive fields
create trigger check_profile_updates
  before update on public.profiles
  for each row execute procedure public.prevent_unauthorized_updates();
