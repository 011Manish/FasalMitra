# Handover

This file lists what the client receives and what to do on day one. Items marked **TO CONFIRM** were not verified when this was written.

## What the client receives

- **Source code:** the GitHub repository (branch `main` after the final merge). Setup is in the root `README.md`.
- **Android app file (APK):** built with `flutter build apk` (see the root `README.md`).
- **Backend access:** the Supabase project (database, sign-in, storage, Edge Functions).
- **Admin access:** the admin dashboard in `web_dashboard/` and admin accounts.
- **Documents:** `README.md` and the files in `docs/`.

Passwords, keys and tokens are handed over privately, never in the repository.

## Ownership transfer checklist

| Item | Action | Done |
|---|---|---|
| GitHub repository | Transfer ownership to the client, or add the client as owner | |
| Supabase project | Transfer to the client's Supabase organization (Project Settings, General) | |
| Hosting for the dashboard | None exists yet. The client chooses a static host. | |
| Domain | None exists. | |
| Store accounts (Google Play) | None exist. Needed before a store release. | |
| Secret names to hand over | `GEMINI_API_KEY`. Also `ADMIN_EMAILS`: purpose **TO CONFIRM** | |
| Team admin accounts | Review the admin list (query below). Demote any account that should not keep access. | |

## Add the AI key

1. Get a Gemini API key from your Google AI account.
2. In the Supabase dashboard, open Edge Functions, then Secrets, and add a secret named `GEMINI_API_KEY`.
3. Optional: add `GEMINI_MODEL` to choose another Gemini model. The default is `gemini-2.0-flash`.
4. Open the app, go to AI Scan and scan a leaf photo. The message "No API key added yet." should be gone.

If the app says "The API key is not valid. Add a working key.", the key was rejected. Check it.

## Set the support contacts

Open `flutter_app/lib/config/support_contact.dart`. It has three empty values: email, phone and WhatsApp. Fill in what the owner wants to publish, build a new APK and release it. The repository is public, so the owner decides what to publish. If all three stay empty the Support page says "Support contact details are not available yet."

## Create an admin

1. Sign up in the app with the person's email.
2. In the Supabase SQL Editor run, with the real email in place of `ADMIN_EMAIL_HERE`:

```sql
update public.profiles set role = 'admin'
where id in (select id from auth.users where email = 'ADMIN_EMAIL_HERE');
```

3. Sign in to the dashboard with that account.

The app cannot make anyone admin. Only this SQL can.

To remove admin access, set `role` back to `'farmer'` the same way.

## Checks (read-only SQL, run one at a time)

List all admins:

```sql
select u.email, p.role from public.profiles p join auth.users u on u.id = p.id where p.role = 'admin';
```

Find tables without RLS (should return no rows):

```sql
select tablename from pg_tables where schemaname = 'public' and not rowsecurity;
```

Check that both storage buckets are private (`public` must be false):

```sql
select id, public from storage.buckets;
```

Find leftover test tutorials (delete them only after checking the list):

```sql
select id, title from public.learning_content where title like 'Test %';
```

## How database migrations are applied

- All SQL is in `supabase/migrations/`. Never edit a file after it has been run.
- The files from `20261121000010` onward were run by hand in the SQL Editor, so they are not recorded in Supabase's migration history. Whether `20261122000030`, `20261122000040` and `20261122000050` were run in production: **TO CONFIRM**.
- Do not run `supabase db push` against production before marking those files as applied: `supabase migration repair --status applied <version>`. Otherwise Supabase tries to run them a second time.
- To change the database, write a new numbered file, read it, run it in the SQL Editor, and commit the file as a record.
- `20261122000010_remove_out_of_scope_tables.sql` deletes tables. Read it before anyone runs it on any database. Whether it was run in production: **TO CONFIRM**.

## Open items

- **Nepali and English interface:** status **TO CONFIRM**. The brief asks for both.
- **AI key:** not installed. The scan is off until it is added.
- **Support contacts:** empty.
- **Starter videos:** the client must supply original, licensed or embeddable Nepali videos and add them in the dashboard. Remove any test tutorial rows.
- **Market prices:** sample data only. Real prices need a data source from the client.
- **Crop guidance:** placeholder content. Needs an agronomist's check before `is_verified` is set to true.
- **Phone-code login:** built but off. To turn it on, set `AuthOptions.phoneLogin = true` in `flutter_app/lib/config/auth_options.dart` and set up a paid SMS provider in Supabase.
- **Email:** set up your own email provider in Supabase for real users.
- **Android application id and release signing:** change before any store release.
- **Old database tables:** `farm_photos`, `schedule_items` and `crop_rules`, and the function `generate-schedule`, are unused and can be removed.
- **Nearby Agriculture** was removed from the app because it is not in the brief. Its two tables (`saved_agri_places`, `agri_place_community_notes`) and the `nearby-places` Edge Function are still in Supabase and are unused. Remove them after checking they hold no data you need.
- **Learning Academy** (courses, e-books, stories) is not part of the brief. Tutorials are.
- **AI prompt text:** the instruction text in `analyze-plant-photo` contains a garbled dash. It should be corrected when the function is next deployed.
