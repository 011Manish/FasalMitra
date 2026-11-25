# Architecture and API

The app talks to Supabase with the publishable (anon) key and the user's own sign-in session. Row Level Security (RLS) is enabled on every table, so the database decides what each user can read and write. Business rules that matter are enforced in database triggers, not only in the app.

Items marked **TO CONFIRM** were not verified when this document was written.

## Roles

`profiles.role` is `farmer`, `buyer` or `admin`.

- Sign-up can choose only `farmer` or `buyer`. A database trigger (`handle_new_auth_user`) creates the profile from the sign-up data.
- A trigger (`profiles_protect_role`) stops any signed-in user from making themselves admin. An admin is set only by SQL in the Supabase SQL Editor.
- `is_admin()` is a security-definer function used by every admin policy.
- Only `farmer` and `admin` can create marketplace listings (trigger `marketplace_listings_require_farmer`).

## Tables

| Table | Used for | Security rule (RLS summary) |
|---|---|---|
| `profiles` | One row per user: name, language, role, country, phone | Owner only. Admins can read all. |
| `farm_profiles` | A user's farms | Owner only |
| `crops` | Crop guide content (9 starter crops, placeholder, `is_verified = false`) | Read for signed-in users. Admin write. |
| `plant_health_scans` | AI scan results and history (`farm_id` is optional) | Owner only |
| `crop_price_history` | Market price rows (all sample data, `is_demo = true`) | Read for signed-in users. Admin write. |
| `learning_content` | Tutorials and learning items | Read for signed-in users. Admin write. |
| `catalog_products` | Shop products | Read for signed-in users. Admin write. |
| `catalog_enquiries` | Enquiries about a product | Owner or admin reads. A user inserts their own. Admin updates. |
| `marketplace_listings` | Produce listings | Active, not hidden listings are visible to signed-in users. A seller sees their own. Admin can hide or delete. A seller cannot unhide. |
| `listing_photos` | Photo records for listings | Linked to the listing owner |
| `listing_enquiries` | Buyer enquiries on a listing | Buyer, the listing's seller and admin can read. A buyer inserts. The seller updates status. |
| `notifications` | In-app messages | A user reads and marks read their own. Users cannot insert. |
| `saved_agri_places`, `agri_place_community_notes` | Old Nearby Agriculture feature. Removed from the app, no longer used. | Per-user rules. They can be dropped. |
| `diseases` | Leftover template table. Migration `20261122000030_diseases.sql` exists. | Current policy: **TO CONFIRM** |
| `farm_photos`, `schedule_items`, `crop_rules` | Old farm features. No longer used by the app. | Owner only (`crop_rules`: read for signed-in, admin write). They can be dropped later. |

To re-check security after any schema change, run the read-only queries in the "Checks" section of `docs/HANDOVER.md`.

## Functions and triggers

- `touch_updated_at()`: sets `updated_at`.
- `delete_current_user()`: lets a user delete their own account.
- `listing_enquiries_fill_buyer`: rejects an enquiry on your own or an inactive listing, and fills the buyer's name and phone from their profile.
- `notify(...)`: the single way notifications are created. App users cannot call it.
- Notification triggers: new listing enquiry (to the seller), listing sold, removed or available again (to buyers who enquired), admin hide, unhide or delete (to the seller), new shop enquiry (to all admins).

Realtime is enabled on `notifications`.

## Storage buckets (both private)

| Bucket | Content | Path |
|---|---|---|
| `farm-media` | Plant scan photos | `<user id>/plant-scans/<file>` or `<user id>/<farm id>/plant-scans/<file>` |
| `listing-media` | Listing photos | `<user id>/<listing id>/<file>` |

Uploads are limited to 5 MB. Photos are shown through short-lived signed URLs, never public URLs.

## Edge Functions

All four are in `flutter_app/supabase/functions/`. They call Supabase with the caller's own sign-in token, so RLS applies. They never use a service-role key.

### `analyze-plant-photo`

Analyses one photo with Google Gemini and saves the result.

Request: `POST`, header `Authorization: Bearer <user token>`, JSON body:

```json
{ "storage_path": "<user id>/plant-scans/<file>" }
```

or, with a farm: `{ "farm_id": "<uuid>", "storage_path": "<user id>/<farm id>/plant-scans/<file>" }`.

Success (`200`): the saved `plant_health_scans` row. Its `analysis` field holds: `disease_or_pest`, `nutrient_deficiency`, `health_score` (0 to 100), `growth_stage`, `treatment_plan`, `dosage_guidance`, `organic_alternatives`, `prevention_steps`, `estimated_recovery_time`, `confidence_level` (high, medium or low) and `summary`.

Secrets: `GEMINI_API_KEY` (required) and `GEMINI_MODEL` (optional, default `gemini-2.0-flash`). The key is sent to Google in the `x-goog-api-key` header.

Errors (JSON `{ "error": "<code>" }`):

| Code | HTTP | Meaning |
|---|---|---|
| `method_not_allowed` | 405 | Not a POST |
| `missing_authorization` | 401 | No sign-in token |
| `invalid_session` | 401 | Token not valid |
| `invalid_json`, `invalid_farm_id`, `invalid_storage_path` | 400 | Bad request |
| `no_api_key` | 503 | `GEMINI_API_KEY` is not set. The app shows "No API key added yet." |
| `farm_not_found` | 404 | The farm is missing or not the caller's |
| `storage_path_mismatch` | 403 | The photo path is not under the caller's own folder |
| `photo_not_found` | 404 | The photo could not be downloaded |
| `ai_unreachable` | 502 | Google could not be reached |
| `ai_key_rejected` | 502 | Google rejected the key |
| `ai_error` | 502 | Any other Google error |
| `analysis_parse_failed` | 502 | The AI answer was not valid JSON |
| `insert_failed` | 500 | The result could not be saved |

### `plant-scan-followup`

Answers a follow-up question about a scan. It uses the same `GEMINI_API_KEY` and the same key-related error codes (`no_api_key`, `ai_key_rejected`). Exact request and response shape: **TO CONFIRM** (the source was not available when this was written).

### `nearby-places` (not used)

Belonged to the Nearby Agriculture feature, which was removed from the app. It can be deleted.

### `generate-schedule` (not used)

Rebuilt watering, fertilizer and harvest items for a farm. The app no longer calls it. It can be removed together with the tables `schedule_items` and `crop_rules`.
