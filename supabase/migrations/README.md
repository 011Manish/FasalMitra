# Database migrations

Apply these files by hand, one at a time, in file-name order (lowest number first),
in the Supabase dashboard: SQL Editor.

Rules
- Applied files are never edited. A change goes in a new file with the next number.
- Files from 20261121000010 onward were applied by hand, so the Supabase
  migration history table does not list them.
- Never run `supabase db push` on this project. If the CLI is ever used, first run
  `supabase migration repair --status applied <version>` for each applied file.
- A file starting with "Record only" is already in production, so it changes nothing
  there. It exists so the files can rebuild the database from empty.
- 20261121000040 (order guard) is obsolete: 20261121000110 removes what it creates.
- 20261122000010 removes out-of-scope tables and is already applied.

Known gaps (TO CONFIRM)
- A rebuild from empty has not been tested.
- catalog_enquiries_user_idx: production uses (user_id, created_at desc);
  20261121000020 creates (user_id) only.
- Grants and the 6 sample catalogue products are not recorded in any file.
## Admin dashboard: farm profiles
20261126000010_admin_farm_policies.sql lets admins read, edit and delete farm profiles
(used by the new "Farm profiles" tab). Run it once in the Supabase SQL Editor.
