-- ACSU authentication and public form submissions
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.membership_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  reference text not null unique,
  student_full_name text not null,
  date_of_birth date not null,
  admission_number text not null,
  grade_class text not null,
  student_phone text not null default '',
  student_email text not null,
  home_address text not null default '',
  guardian_name text not null,
  guardian_phone text not null,
  area_of_interest text not null default '',
  medical_notes text not null default '',
  reason_for_joining text not null default '',
  consent boolean not null default false check (consent = true),
  submitted_at timestamptz not null default now()
);
create table if not exists public.contact_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  full_name text not null,
  email text not null,
  topic text not null default 'General question',
  message text not null,
  created_at timestamptz not null default now()
);
create index if not exists membership_applications_user_id_idx on public.membership_applications(user_id);
create index if not exists membership_applications_submitted_at_idx on public.membership_applications(submitted_at desc);
create index if not exists contact_messages_created_at_idx on public.contact_messages(created_at desc);
create or replace function public.handle_new_acsu_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_acsu_auth_user_created on auth.users;
create trigger on_acsu_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_acsu_user();
alter table public.profiles enable row level security;
alter table public.membership_applications enable row level security;
alter table public.contact_messages enable row level security;
drop policy if exists "Users can view their own ACSU profile" on public.profiles;
create policy "Users can view their own ACSU profile" on public.profiles
for select to authenticated using (auth.uid() = id);
drop policy if exists "Users can update their own ACSU profile" on public.profiles;
create policy "Users can update their own ACSU profile" on public.profiles
for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
drop policy if exists "Anyone can submit a membership application" on public.membership_applications;
create policy "Anyone can submit a membership application" on public.membership_applications
for insert to anon, authenticated with check (user_id is null or user_id = auth.uid());
drop policy if exists "Users can view their own membership applications" on public.membership_applications;
create policy "Users can view their own membership applications" on public.membership_applications
for select to authenticated using (auth.uid() = user_id);
drop policy if exists "Anyone can send a contact message" on public.contact_messages;
create policy "Anyone can send a contact message" on public.contact_messages
for insert to anon, authenticated with check (user_id is null or user_id = auth.uid());
grant select, update on public.profiles to authenticated;
grant insert, select on public.membership_applications to anon, authenticated;
grant insert on public.contact_messages to anon, authenticated;