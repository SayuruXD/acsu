# ACSU administrator setup

The public website supports open email/password registration. Creating an account does **not** grant administrator access.

## Promote the first administrator

1. Open the Supabase project dashboard for `bwlrycirjpiekpbytdfd`.
2. Open **SQL Editor**.
3. Register an account through the ACSU website using the email address that should administer the unit. Complete email confirmation if it is enabled.
4. Run this SQL, replacing the email with the exact address used to register:

```sql
insert into public.user_roles (user_id, role)
select id, 'admin'
from auth.users
where lower(email) = lower('YOUR-ADMIN-EMAIL@example.com')
on conflict (user_id) do update set role = excluded.role;
```

5. Sign out and sign in again on the website, then open the **Admin** link.

If the query inserts zero rows, the account has not registered with that email yet. Do not share passwords or secret API keys.

## Admin dashboard

- Membership applications: view the latest 100 records, inspect applicant details, and mark an application pending, approved, or rejected.
- Contact messages: view the latest 100 enquiries and mark them as read.
- Only rows in `public.user_roles` with role `admin` grant admin UI access. RLS also checks this role in the database, so hiding the link is not the security boundary.

## Auth settings

In Supabase **Authentication → URL Configuration**, set the Site URL to the production website domain and add the exact production and preview URLs used by Vercel to the Redirect URLs allow-list. Email confirmation and password recovery depend on this allow-list.

## Data and privacy

- Membership applications require a signed-in account and are visible to the submitting user and authorised admins.
- Contact enquiries can be sent without signing in. Only admins can read them.
- Home address and medical-notes fields are not collected in the updated membership form or retained in the database schema.
- Never put a Supabase service-role or secret key in website code. The website uses the publishable key.
