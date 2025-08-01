-- ===============================================
-- COMPREHENSIVE SUPABASE TEMPLATE SCHEMA
-- ===============================================
-- This migration sets up a complete Supabase project with:
-- - User profiles with RLS security
-- - File storage (avatars + documents)
-- - Posts system with realtime
-- - Edge function support
-- - Production-ready security policies

-- ===============================================
-- USER PROFILES TABLE
-- ===============================================

-- Create user_profiles table with production-ready security
create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
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

-- User Profiles Security Policies
create policy "Users can view their own profile"
  on public.user_profiles for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.user_profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "Service can insert user profiles"
  on public.user_profiles for insert
  with check (true);

-- ===============================================
-- POSTS TABLE (REALTIME DEMO)
-- ===============================================

-- Create posts table for realtime demo
create table if not exists public.posts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  content text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  
  -- Constraints
  constraint title_length check (char_length(title) >= 1 and char_length(title) <= 200),
  constraint content_length check (char_length(content) <= 10000)
);

-- Create indexes for performance
create index posts_user_id_idx on public.posts(user_id);
create index posts_created_at_idx on public.posts(created_at desc);

-- Enable RLS on posts
alter table public.posts enable row level security;

-- Posts Security Policies
create policy "Users can view all posts"
  on public.posts for select
  using (true);

create policy "Users can create their own posts"
  on public.posts for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own posts"
  on public.posts for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own posts"
  on public.posts for delete
  using (auth.uid() = user_id);

-- ===============================================
-- STORAGE BUCKETS & POLICIES
-- ===============================================

-- Create storage bucket for avatars (public)
insert into storage.buckets (id, name, public) 
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Avatar storage policies
create policy "Avatar images are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "Users can upload their own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars' 
    and auth.uid()::text = (storage.foldername(name))[1] 
  );

create policy "Users can update their own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars' 
    and auth.uid()::text = (storage.foldername(name))[1] 
  )
  with check (
    bucket_id = 'avatars' 
    and auth.uid()::text = (storage.foldername(name))[1] 
  );

create policy "Users can delete their own avatar"
  on storage.objects for delete
  using (
    bucket_id = 'avatars' 
    and auth.uid()::text = (storage.foldername(name))[1] 
  );

-- Create storage bucket for documents (private)
insert into storage.buckets (id, name, public) 
values ('documents', 'documents', false)
on conflict (id) do nothing;

-- Document storage policies
create policy "Users can view their own documents"
  on storage.objects for select
  using (
    bucket_id = 'documents' 
    and auth.uid()::text = (storage.foldername(name))[1] 
  );

create policy "Users can upload their own documents"
  on storage.objects for insert
  with check (
    bucket_id = 'documents' 
    and auth.uid()::text = (storage.foldername(name))[1] 
  );

create policy "Users can update their own documents"
  on storage.objects for update
  using (
    bucket_id = 'documents' 
    and auth.uid()::text = (storage.foldername(name))[1] 
  );

create policy "Users can delete their own documents"
  on storage.objects for delete
  using (
    bucket_id = 'documents' 
    and auth.uid()::text = (storage.foldername(name))[1] 
  );

-- ===============================================
-- REALTIME SETUP
-- ===============================================

-- Enable realtime for user_profiles
alter publication supabase_realtime add table user_profiles;

-- Enable realtime for posts
alter publication supabase_realtime add table posts;

-- ===============================================
-- TRIGGER FUNCTIONS
-- ===============================================

-- Function to auto-create user profile when user signs up
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

-- Function to update updated_at timestamp
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$ language plpgsql;

-- ===============================================
-- TRIGGERS
-- ===============================================

-- Trigger to auto-create profile on user signup
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Trigger to update updated_at on user_profiles
create trigger handle_user_profiles_updated_at
  before update on public.user_profiles
  for each row execute procedure public.handle_updated_at();

-- Trigger to update updated_at on posts
create trigger handle_posts_updated_at
  before update on public.posts
  for each row execute procedure public.handle_updated_at();

-- ===============================================
-- HELPER FUNCTIONS (OPTIONAL)
-- ===============================================

-- Function for users to update their own profile
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

  if updated_profile is null then
    raise exception 'Profile not found';
  end if;

  return updated_profile;
end;
$$;

-- ===============================================
-- PERMISSIONS
-- ===============================================

-- Grant necessary permissions
grant usage on schema public to anon, authenticated;

-- User profiles permissions
grant select, update on table public.user_profiles to authenticated;
grant select on table public.user_profiles to anon;

-- Posts permissions
grant select, insert, update, delete on table public.posts to authenticated;
grant select on table public.posts to anon;

-- Function permissions
grant execute on function public.update_user_profile to authenticated;

-- ===============================================
-- TEMPLATE COMPLETE
-- ===============================================
-- This template provides:
-- ✅ Secure user authentication & profiles
-- ✅ File storage (public avatars, private documents)  
-- ✅ Realtime posts system
-- ✅ Row Level Security on all tables
-- ✅ Automatic profile creation on signup
-- ✅ Edge function compatible structure
-- ✅ Production-ready constraints & indexes
