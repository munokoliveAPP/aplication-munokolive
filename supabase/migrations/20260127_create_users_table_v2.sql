-- Create users table
create table public.users (
  id uuid references auth.users not null primary key,
  email text,
  first_name text,
  last_name text,
  full_name text,
  photo_url text,
  role text default 'user',
  status text default 'pending',
  category text,
  sub_category text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Set up Row Level Security (RLS)
alter table public.users enable row level security;

create policy "Users can view their own profile" on public.users
  for select using (auth.uid() = id);

create policy "Users can update their own profile" on public.users
  for update using (auth.uid() = id);

-- Allow admins to view all profiles (optional, adjust based on needs)
create policy "Admins can view all profiles" on public.users
  for select using (
    exists (
      select 1 from public.users where id = auth.uid() and role = 'admin'
    )
  );

-- Create a trigger to handle updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger on_auth_user_updated
  before update on public.users
  for each row execute procedure public.handle_updated_at();

-- IMPORTANT: Allow initial insert during sign up (handled by app logic or trigger)
-- Since the app inserts into public.users after auth.signUp, we need an insert policy
create policy "Users can insert their own profile" on public.users
  for insert with check (auth.uid() = id);

-- Grant access to authenticated users
grant all on public.users to authenticated;
grant all on public.users to service_role;
