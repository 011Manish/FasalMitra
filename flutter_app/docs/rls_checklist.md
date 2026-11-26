# RLS verification checklist

This is the single most important thing to run through before shipping this
phase. If any step here fails, stop and fix it â€” do not carry a broken RLS
policy into the next phase.

You'll need:

- Two throwaway phone numbers (or two email accounts if phone OTP isn't
  wired up yet) â€” call them **Farmer A** and **Farmer B**.
- A SQL editor connected as `postgres` / service role â€” Supabase dashboard
  -> SQL editor works. You'll use this only to _observe_, not to bypass RLS.
- `curl` (or Postman/Insomnia) for the raw REST checks.

## Setup

1. Sign up as **Farmer A** in the Flutter app. Create two farm profiles for
   them (any crop). Note down the `id` of one of A's farm profiles â€” call
   it `FARM_A_ID`.
2. Sign out. Sign up as **Farmer B**. Create one farm profile. Note down
   B's access token â€” you can `print(session.accessToken)` briefly in the
   app or grab it from the auth response in the browser tools.

## Checks

### 1. Farmer B cannot list Farmer A's farms

Signed in as B, in the app: the "My farms" screen should show only B's one
farm. It must not show A's two farms.

Via REST, with **B's** access token:

```bash
curl -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
     -H "apikey: ${SUPABASE_PUBLISHABLE_KEY}" \
     "https://YOUR-REF.supabase.co/rest/v1/farm_profiles?select=id,name"
```

Only B's farm should be in the response array. If any of A's farms come
back, RLS is broken.

### 2. Farmer B cannot read a specific farm of Farmer A by ID

```bash
curl -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
     -H "apikey: ${SUPABASE_PUBLISHABLE_KEY}" \
     "https://YOUR-REF.supabase.co/rest/v1/farm_profiles?id=eq.FARM_A_ID"
```

Expected: empty array `[]`. (Not 403 â€” RLS filters, it doesn't error.)

### 3. Farmer B cannot update Farmer A's farm

```bash
curl -X PATCH \
     -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
     -H "apikey: ${SUPABASE_PUBLISHABLE_KEY}" \
     -H "Content-Type: application/json" \
     -H "Prefer: return=representation" \
     -d '{"name":"pwned"}' \
     "https://YOUR-REF.supabase.co/rest/v1/farm_profiles?id=eq.FARM_A_ID"
```

Expected: empty array `[]` (no rows matched under B's RLS scope).
Verify in the SQL editor that A's farm name is unchanged.

### 4. Farmer B cannot delete Farmer A's farm

```bash
curl -X DELETE \
     -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
     -H "apikey: ${SUPABASE_PUBLISHABLE_KEY}" \
     "https://YOUR-REF.supabase.co/rest/v1/farm_profiles?id=eq.FARM_A_ID"
```

Expected: 204 with no rows affected. Confirm A's farm still exists.

### 5. Farmer B cannot insert a farm on Farmer A's behalf

```bash
curl -X POST \
     -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
     -H "apikey: ${SUPABASE_PUBLISHABLE_KEY}" \
     -H "Content-Type: application/json" \
     -d '{"user_id":"A_USER_ID","name":"stolen","crop_type":"rice",
          "land_size_hectares":1,"plantation_date":"2026-01-01",
          "soil_type":"loamy","irrigation_system":"drip"}' \
     "https://YOUR-REF.supabase.co/rest/v1/farm_profiles"
```

Expected: `403` / new row rejected by the WITH CHECK clause. If it succeeds,
the insert policy is wrong.

### 6. Farmer B cannot see Farmer A's schedule items

Sign in as A in the app, edit one of A's farms (trigger schedule
regeneration). Then, as B:

```bash
curl -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
     -H "apikey: ${SUPABASE_PUBLISHABLE_KEY}" \
     "https://YOUR-REF.supabase.co/rest/v1/schedule_items?select=id,farm_id"
```

Expected: only schedule items belonging to B's farms, none from A's.

### 7. Storage: Farmer B cannot download a file uploaded under A's folder

(Once media uploads exist â€” from Phase 2 onward.) Upload a file under
`A_USER_ID/anything.jpg` while signed in as A. Then try to download it
via a URL signed as B. Expected: 403 or "object not found."

### 8. `delete_current_user` only deletes the caller

Signed in as B, call `sb.rpc('delete_current_user')`. Confirm in the SQL
editor:

```sql
select id from auth.users where id = 'B_USER_ID';  -- 0 rows
select id from auth.users where id = 'A_USER_ID';  -- still 1 row
select count(*) from farm_profiles where user_id = 'A_USER_ID';  -- unchanged
select count(*) from schedule_items;                              -- A's still there
```

### 9. Every table has RLS on

```sql
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
order by tablename;
```

Every row must show `rowsecurity = true`. If any public table shows `false`,
that table is world-readable to anyone with the anon key. Fix before
shipping.

### 10. No policy uses `using (true)` unintentionally

```sql
select tablename, policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
order by tablename, policyname;
```

Only `crop_rules` should have a broad `true` select policy (it's a public
lookup table for signed-in users). Everything else must scope by
`auth.uid()`.

