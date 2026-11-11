-- ACSU authentication, member applications, contact enquiries and admin review.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.membership_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
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
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  submitted_at timestamptz not null default now()
);
create table if not exists public.contact_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  full_name text not null,
  email text not null,
  topic text not null default 'General question',
  message text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin')),
  created_at timestamptz not null default now()
);

create index if not exists membership_applications_user_id_idx on public.membership_applications(user_id);
create index if not exists membership_applications_submitted_at_idx on public.membership_applications(submitted_at desc);
create index if not exists membership_applications_status_idx on public.membership_applications(status);
create index if not exists membership_applications_reviewed_by_idx on public.membership_applications(reviewed_by);
create index if not exists contact_messages_created_at_idx on public.contact_messages(created_at desc);
create index if not exists contact_messages_user_id_idx on public.contact_messages(user_id);
create index if not exists contact_messages_is_read_idx on public.contact_messages(is_read);

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
revoke all on function public.handle_new_acsu_user() from public, anon, authenticated;
drop trigger if exists on_acsu_auth_user_created on auth.users;
create trigger on_acsu_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_acsu_user();

alter table public.profiles enable row level security;
alter table public.membership_applications enable row level security;
alter table public.contact_messages enable row level security;
alter table public.user_roles enable row level security;

create policy "Users can view their own ACSU profile" on public.profiles
for select to authenticated using ((select auth.uid()) = id);
create policy "Users can update their own ACSU profile" on public.profiles
for update to authenticated using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy "Users can view their own ACSU role" on public.user_roles
for select to authenticated using ((select auth.uid()) = user_id);

create policy "Signed-in users can submit their own membership application"
on public.membership_applications for insert to authenticated
with check (user_id = (select auth.uid()));
create policy "Users and admins can view membership applications"
on public.membership_applications for select to authenticated
using (
  user_id = (select auth.uid())
  or exists (select 1 from public.user_roles r
             where r.user_id = (select auth.uid()) and r.role = 'admin')
);
create policy "ACSU admins can review membership applications"
on public.membership_applications for update to authenticated
using (exists (select 1 from public.user_roles r
               where r.user_id = (select auth.uid()) and r.role = 'admin'))
with check (exists (select 1 from public.user_roles r
                    where r.user_id = (select auth.uid()) and r.role = 'admin'));

create policy "Anyone can send a contact message"
on public.contact_messages for insert to anon, authenticated
with check (user_id is null or user_id = (select auth.uid()));
create policy "ACSU admins can view contact messages"
on public.contact_messages for select to authenticated
using (exists (select 1 from public.user_roles r
               where r.user_id = (select auth.uid()) and r.role = 'admin'));
create policy "ACSU admins can mark contact messages read"
on public.contact_messages for update to authenticated
using (exists (select 1 from public.user_roles r
               where r.user_id = (select auth.uid()) and r.role = 'admin'))
with check (exists (select 1 from public.user_roles r
                    where r.user_id = (select auth.uid()) and r.role = 'admin'));

grant select, update on public.profiles to authenticated;
revoke all on public.user_roles from anon, authenticated;
grant select on public.user_roles to authenticated;
revoke all on public.membership_applications from anon;
grant select, insert, update on public.membership_applications to authenticated;
grant select, update on public.contact_messages to authenticated;
grant insert on public.contact_messages to anon, authenticated;