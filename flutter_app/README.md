<<<<<<< HEAD
# FASALMITRA

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
=======
# Krishi

Farmer-facing mobile app + admin web dashboard, backed by Supabase.

This phase covers: phone-OTP auth, farm profiles, rule-based schedule generation,
and a "reminders" view. Not in this phase: chatbot, weather/satellite, marketplace,
price prediction.

```
supabase/         SQL migrations + Edge Function(s)
flutter_app/      Farmer-facing mobile app (Flutter)
web_dashboard/    Admin/seller dashboard (plain HTML/CSS/JS + supabase-js)
docs/             RLS verification checklist, notes
```

## Prerequisites

- A Supabase project (create one at https://supabase.com)
- Supabase CLI: https://supabase.com/docs/guides/cli
- Flutter 3.19+ and Dart 3.3+
- Deno 1.40+ (for Edge Functions, installed via the Supabase CLI)

## Link the local project to your Supabase project

```bash
cd supabase
supabase login
supabase link --project-ref <your-project-ref>
```

The `project-ref` is the alphanumeric string in your Supabase project URL.

## Run migrations

Migrations live in `supabase/migrations/` and are pure SQL, ordered by filename.

```bash
# Apply everything to the linked remote project:
supabase db push

# Or, if you're running Supabase locally with `supabase start`:
supabase db reset
```

## Deploy the Edge Function

```bash
supabase functions deploy generate-schedule --no-verify-jwt=false
```

The function is called from Flutter right after a farm profile is created or
updated. We chose the client-side call over a Postgres trigger because:

- The trigger route requires embedding a service-role key or an HTTP extension
  inside the DB, which crosses a security boundary we don't want to cross for
  a simple derived-data job.
- The Flutter client already has a valid session and RLS already restricts
  what it can affect, so calling the function directly is the smaller
  attack surface and much easier to debug.

## Enable phone OTP in Supabase

Dashboard -> Authentication -> Providers -> Phone: enable, pick an SMS provider
(Twilio, MessageBird, Vonage, Textlocal), and paste in the credentials. Also
set: Auth -> Rate Limits -> "SMS OTP" to something conservative
(e.g. 5 per hour per phone) so this can't be abused.

## Run the Flutter app

```bash
cd flutter_app
cp .env.example .env
# fill in SUPABASE_URL and SUPABASE_ANON_KEY
flutter pub get
flutter run
```

Only the anon key ever goes into the app. The service-role key must never
leave server-side environments (Edge Functions, your own CI). If a client
build ends up shipping the service-role key, every RLS policy in this repo
becomes decorative.

## Run the web dashboard

Static files, no build step. Serve `web_dashboard/` with anything:

```bash
cd web_dashboard
cp .env.example .env    # then paste values into config.js manually
python3 -m http.server 5173
```

For production, drop the `web_dashboard/` folder into Netlify or Vercel as a
static site.

## Verifying RLS actually works

Before shipping this phase, walk through `docs/rls_checklist.md`. It is the
single most important thing to confirm before moving on.
>>>>>>> f5eddb987be16f4515c575dc3abb97139633d92a
