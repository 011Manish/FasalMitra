# FasalMitra

FasalMitra is a mobile app (Android first) for farmers in Nepal and India, with an admin web dashboard.
The backend is Supabase. It was built as a six-day MVP to the client's "Developer Handoff" brief.

## What the app does

- **Account:** sign up and sign in with email and password, reset password, edit profile (name, phone, country Nepal or India, language, role farmer or buyer), sign out, delete account.
- **Farm profile:** create, view, edit and delete a farm (crop, land size and unit, plantation date, soil, irrigation, location).
- **Crop guide:** crop information pages and a rule-based suggestion form, always labelled "general guidance".
- **AI plant scan:** take or choose a leaf photo, check it, get an AI estimate with a "not a confirmed diagnosis" notice, and see scan history. See "AI Scan screens" below. It needs an AI key (see `docs/HANDOVER.md`). Until a key is added the app shows a clearly marked DEMO result.
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

## Install the APK on a phone

Use this if you were given `app-release.apk` and only want to try the app.

1. Copy `app-release.apk` to the phone (USB cable, WhatsApp, Google Drive or email).
2. Open the file on the phone and tap **Install**. If Android asks, allow **Install unknown apps** for the app you opened it from (Files, Chrome, WhatsApp).
3. Open **FASALMITRA**. Sign up as a Farmer or Buyer, or log in with an account you created.
4. Allow the camera permission when AI Crop Scan asks for it. If you refuse, the app shows a "Camera access is off" screen with **Open settings** and **Upload from gallery**.

Install from a computer instead (USB debugging on, phone connected):

```powershell
adb devices
adb install -r flutter_app\build\app\outputs\flutter-apk\app-release.apk
```

`Success` means the APK installed. To check that the APK is signed, run `apksigner verify --verbose app-release.apk` (it is in the Android SDK, folder `build-tools`).

If the app shows **Startup error**, the APK was built without `assets/app.env`. Create that file (see "Run the app") and build again.

## AI Scan screens

Open **Home, AI Crop Scan**. The screens follow the Figma design.

| Screen | What it does |
|---|---|
| Scan Camera | Photo tips, **Take photo**, **Upload from gallery**, **History** (top right), camera help |
| Camera Denied | Shown when the phone refuses camera access. **Open settings**, **Upload from gallery**, **Back to home** |
| Photo Preview | Shows the chosen photo. **Analyze photo** or **Retake** |
| Processing | "Analyzing your photo..." with **Cancel** |
| Scan Result | Detected issue, confidence, what we found, recommended action, **Save to history**, **Scan another crop**. Extra report details and "More inquiry" chat are listed below these |
| Result unclear | Shown when confidence is low. **Retake photo** or **Upload a different photo** |
| DEMO result | Shown while the server has no AI key. Sample content, marked as not a real diagnosis, never saved |
| Scan failed | **Try again** (the photo is not uploaded twice) or **Back to scan** |
| Scan History | Past scans with photo, issue, farm, date and confidence. Empty state included |

Every screen works in English and Nepali. Photos are resized to 1600 px and must be under 5 MB. The server saves every finished scan itself, so **Save to history** confirms it. Code is in `flutter_app/lib/screens/` (`camera_choice_screen.dart`, `plant_scan_*_screen.dart`), `lib/widgets/scan_kit.dart` and `lib/models/scan_summary.dart`. More detail is in `UI_UPDATE_NOTES.md`.

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
flutter doctor
flutter pub get
flutter clean
flutter build apk --release
```

The file is created at `flutter_app\build\app\outputs\flutter-apk\app-release.apk`. It is usually 20 to 60 MB.

- `flutter doctor` must show no errors for the Android toolchain. The project uses `compileSdk 36`, so use Flutter 3.27 or newer (`flutter upgrade` if needed).
- `assets/app.env` must exist before building, or the installed app shows "Startup error".
- For smaller files, run `flutter build apk --release --split-per-abi`. Most phones use `app-arm64-v8a-release.apk`.
- Before the final build, set `showIntroEveryLaunch = false` in `lib/config/app_options.dart`.
- The release build is signed with the debug key unless you set up your own keystore. That is fine for installing and review. The Android application id is still a placeholder (`com.example...`). Change it and set up release signing before any store release. A Play Store upload needs `flutter build appbundle --release`.

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
- The AI scan shows a DEMO result until an API key is added. It gives an estimate, not a diagnosis.
- Phone-code login is built but switched off (`lib/config/auth_options.dart`) because it needs a paid SMS provider. The phone number is saved as an unverified contact detail.
- Support contact details are empty on purpose (`lib/config/support_contact.dart`).
- Tutorial videos are links. The client must supply licensed or embeddable starter videos.
- There are no payments, offline mode, push notifications or iOS release.
- Supabase's built-in email sender is limited. For real users, set up your own email provider in Supabase.

## More documents

- `UI_UPDATE_NOTES.md`: what changed in the Figma UI merge and the AI Scan screens
- `docs/HANDOVER.md`: what is handed over, ownership checklist, how to add the AI key, support contacts and admins
- `docs/ARCHITECTURE_AND_API.md`: tables, security rules, buckets, Edge Functions
- `docs/THIRD_PARTY_SERVICES.md`: every outside service, including the AI disclosure
- `docs/ASSET_AND_LICENCE_LIST.md`: assets, sample content and package licences
- `docs/TUTORIAL_CONTENT_GUIDE.md`: how to add, edit and delete tutorial videos
- `docs/rls_checklist.md`: steps to check that the database security rules work
