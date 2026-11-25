# FasalMitra

FasalMitra is a mobile app (Android first) for farmers in Nepal and India, with an admin web dashboard.
The backend is Supabase. It was built as a six-day MVP to the client's "Developer Handoff" brief.

## What the app does

- **Account:** sign up and sign in with email and password, reset password, edit profile (name, phone, country Nepal or India, language, role farmer or buyer), sign out, delete account.
- **Farm profile:** create, view, edit and delete a farm (crop, land size and unit, plantation date, soil, irrigation, location).
- **Crop guide:** crop information pages and a rule-based suggestion form, always labelled "general guidance".
- **AI plant scan:** take or choose a leaf photo, get an AI estimate with a "not a confirmed diagnosis" notice, and see scan history. It needs an AI key (see `docs/HANDOVER.md`). Until a key is added the app shows "No API key added yet."
- **Market prices:** a list of crop, market, price, unit, source and price date, with filters, and a price trend chart. All rows are sample data and are labelled DEMO.
- **Marketplace:** a farmer publishes a produce listing, a buyer finds it and sends an enquiry, and the seller sees the enquiry and marks the listing sold or available. This is an enquiry workflow. There are no payments.
- **Shop:** a catalogue of seeds, fertilizer, tools and irrigation items, with a product page, an enquiry form and a call button.
- **Tutorials:** video tutorials by category. YouTube links play inside the app. Videos are links only.
- **Notifications:** in-app messages for enquiries and moderation. There are no push notifications.
- **Support page:** shows the owner's email, phone and WhatsApp, once they are set (they are empty now).

## Folder map

```
README.md
docs/                  Handover notes, architecture, third-party services, licences, tutorial guide
supabase/
  migrations/          All database SQL, in filename order
flutter_app/           The Flutter app. Run Flutter commands here.
  lib/                 config, models, screens, services
  supabase/functions/  Edge Functions (Deno, TypeScript)
  test/                Unit tests
web_dashboard/         Admin dashboard (plain HTML, CSS and JS)
```

`flutter_app/supabase/migrations/` is an old duplicate. Do not add files there.

## Prerequisites

- Flutter 3.19 or newer (Dart 3.3 or newer), and Android Studio or an Android phone
- A Supabase project
- Supabase CLI (optional, only if you deploy Edge Functions from the command line)
- Any static web server for the dashboard (the example below uses Python)

## Run the app

The app reads two values from `flutter_app/assets/app.env`. That file is git-ignored, so each developer creates it once after cloning. On Windows PowerShell:

```powershell
cd flutter_app
mkdir assets
copy .env.example assets\app.env
```

Open `assets\app.env` and fill in the two values below. Then:

```powershell
flutter pub get
flutter run
```

Without `assets/app.env` the app shows "Startup error". After changing `pubspec.yaml` or assets, stop the app and run it again.

### Environment variables

| Name | Where it is used | Where to get it |
|---|---|---|
| `SUPABASE_URL` | `flutter_app/assets/app.env`, `web_dashboard/config.js` | Supabase dashboard, Project Settings, API |
| `SUPABASE_ANON_KEY` | `flutter_app/assets/app.env`, `web_dashboard/config.js` | Same page. Use only the publishable (anon) key. |
| `GEMINI_API_KEY` | Edge Function secret (not in the app) | Google AI account. See `docs/HANDOVER.md`. |
| `GEMINI_MODEL` | Edge Function secret, optional | Defaults to `gemini-2.0-flash` |

The service-role key must never go into the app, the dashboard or the repository. The repository is public.

## Check the code

```powershell
cd flutter_app
flutter analyze lib
flutter test
```

`flutter analyze lib` shows two info hints about deprecated calls. There should be no errors.

## Build an APK

```powershell
cd flutter_app
flutter build apk
```

The file is created at `flutter_app\build\app\outputs\flutter-apk\app-release.apk`. The Android application id is still a placeholder (`com.example...`). Change it and set up release signing before any store release.

## Backend

- **Database:** all SQL is in `supabase/migrations/`, ordered by filename. The files from `20261121000010` onward were run by hand in the Supabase SQL Editor, so they are not in the live migration history. Do not run `supabase db push` against production before marking them as applied with `supabase migration repair --status applied <version>`. See `docs/HANDOVER.md`.
- **Edge Functions:** the app uses `analyze-plant-photo` and `plant-scan-followup`. `nearby-places` and `generate-schedule` are no longer used. All four are in `flutter_app/supabase/functions/`. Details are in `docs/ARCHITECTURE_AND_API.md`.
- **Storage:** two private buckets, `farm-media` (plant scan photos) and `listing-media` (listing photos).
- **Row Level Security** is enabled on every table. The app uses only the publishable key, so these rules are what protect user data.

## Admin dashboard

Static files with no build step:

```powershell
cd web_dashboard
python -m http.server 8080
```

Open `http://localhost:8080`. `config.js` holds the project URL and the publishable key. Sign in with an admin account. The dashboard manages tutorials, crop information, shop products and market price rows, moderates listings, and lists users and enquiries. To host it, upload the folder to any static host.

Admin accounts and how to create one are explained in `docs/HANDOVER.md`. No password is stored in the repository.

## Test accounts

Test the app with three accounts. Create them yourself and do not share the passwords in the repository.

| Role | How to create |
|---|---|
| Farmer | Sign up in the app and choose Farmer |
| Buyer | Sign up in the app and choose Buyer |
| Admin | Sign up, then run the SQL statement in `docs/HANDOVER.md` |

## Known limitations

- Market prices are sample data (`is_demo = true`), not a live market feed.
- Crop guidance and crop rules are placeholder content. An agronomist has not checked them.
- The AI scan is off until an API key is added. It gives an estimate, not a diagnosis.
- Phone-code login is built but switched off (`lib/config/auth_options.dart`) because it needs a paid SMS provider. The phone number is saved as an unverified contact detail.
- Support contact details are empty on purpose (`lib/config/support_contact.dart`).
- Tutorial videos are links. The client must supply licensed or embeddable starter videos.
- There are no payments, offline mode, push notifications or iOS release.
- Supabase's built-in email sender is limited. For real users, set up your own email provider in Supabase.

## More documents

- `docs/HANDOVER.md`: what is handed over, ownership checklist, how to add the AI key, support contacts and admins
- `docs/ARCHITECTURE_AND_API.md`: tables, security rules, buckets, Edge Functions
- `docs/THIRD_PARTY_SERVICES.md`: every outside service, including the AI disclosure
- `docs/ASSET_AND_LICENCE_LIST.md`: assets, sample content and package licences
- `docs/TUTORIAL_CONTENT_GUIDE.md`: how to add, edit and delete tutorial videos
- `docs/rls_checklist.md`: steps to check that the database security rules work
