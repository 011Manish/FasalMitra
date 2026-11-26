# FasalMitra (Flutter app)

This folder holds the FasalMitra mobile app. Setup, environment variables, build steps and backend notes are in the root [README.md](../README.md).

Quick start, from this folder:

```powershell
mkdir assets
copy .env.example assets\app.env
flutter pub get
flutter run
```

Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `assets\app.env` first.
