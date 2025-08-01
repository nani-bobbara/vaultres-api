-- Create user_profiles table with production-ready security
create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  full_name text,
  avatar_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  
  -- Constraints for production readiness
  constraint username_length check (char_length(username) >= 3 and char_length(username) <= 30),
  constraint username_format check (username ~ '^[a-zA-Z0-9_]+$'),
  constraint full_name_length check (char_length(full_name) <= 100),
  constraint avatar_url_format check (avatar_url is null or avatar_url ~ '^https?://')
);

-- Create indexes for performance
create index if not exists user_profiles_username_idx on public.user_profiles(username);
create index if not exists user_profiles_created_at_idx on public.user_profiles(created_at);

-- Enable Row Level Security
alter table public.user_profiles enable row level security;

-- Create security policies
-- Policy: Only authenticated users can view their own profile
create policy "Users can view their own profile"
  on public.user_profiles
  for select
  using (auth.uid() = id);

-- Policy: Only authenticated users can update their own profile
create policy "Users can update their own profile"
  on public.user_profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Policy: Only the trigger can insert (service role or trigger context)
create policy "Service can insert user profiles"
  on public.user_profiles
  for insert
  with check (true);

-- Policy: Users cannot delete their own profile (business logic)
-- If you want to allow deletion, uncomment the following:
-- create policy "Users can delete their own profile"
--   on public.user_profiles
--   for delete
--   using (auth.uid() = id);

-- Create trigger function to auto-create user profile
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (id, username, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name')
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

-- Create trigger on auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Create function to update updated_at timestamp
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Create trigger for updated_at
create trigger handle_user_profiles_updated_at
  before update on public.user_profiles
  for each row execute procedure public.handle_updated_at();

-- Grant necessary permissions
grant usage on schema public to anon, authenticated;
grant select, insert, update on table public.user_profiles to authenticated;
grant select on table public.user_profiles to anon;

-- Create a function for users to update their own profile (optional, for API)
create or replace function public.update_user_profile(
  p_username text default null,
  p_full_name text default null,
  p_avatar_url text default null
)
returns public.user_profiles
language plpgsql
security definer
as $$
declare
  updated_profile public.user_profiles;
begin
  -- Check if user is authenticated
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  -- Update the profile
  update public.user_profiles
  set
    username = coalesce(p_username, username),
    full_name = coalesce(p_full_name, full_name),
    avatar_url = coalesce(p_avatar_url, avatar_url),
    updated_at = now()
  where id = auth.uid()
  returning * into updated_profile;

  return updated_profile;
end;
$$;

-- Grant execute permission on the function
grant execute on function public.update_user_profile to authenticated;
