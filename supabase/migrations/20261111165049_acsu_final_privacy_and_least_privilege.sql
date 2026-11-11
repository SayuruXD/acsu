-- Final ACSU privacy and least-privilege hardening.
-- This mirrors the final schema state applied to the hosted project.
alter table public.membership_applications
  drop column if exists home_address,
  drop column if exists medical_notes;

-- RLS does not apply to TRUNCATE, so remove broad default table privileges.
revoke all on table public.profiles from anon, authenticated;
revoke all on table public.membership_applications from anon, authenticated;
revoke all on table public.contact_messages from anon, authenticated;
revoke all on table public.user_roles from anon, authenticated;

-- Regrant only operations used by the site; row access remains controlled by RLS.
grant select, update on table public.profiles to authenticated;
grant select, insert, update on table public.membership_applications to authenticated;
grant select, update on table public.contact_messages to authenticated;
grant insert on table public.contact_messages to anon, authenticated;
grant select on table public.user_roles to authenticated;
