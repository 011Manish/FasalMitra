# FasalMitra: Figma UI merged into the app

The backend (supabase/, web_dashboard/, flutter_app/lib/services, models, config)
is unchanged. Only the screens and look of the Flutter app were updated.

## Run it
    cd flutter_app
    flutter pub get
    flutter run

assets/app.env already holds the project URL and key from your backup.

## What changed (all in flutter_app/lib)
- theme/app_theme.dart       Figma colors, rounded inputs, pill buttons
- l10n/app_lang.dart         EN / नेपाली switch (saved on the phone) + Nepali text
- widgets/design_kit.dart    shared design pieces (top bar, pills, role cards)
- screens/onboarding_screen.dart   3 intro slides (shown once, first launch)
- screens/login_screen.dart        Sign up / Log in / Reset password, same Supabase calls
- screens/verify_code_screen.dart  6-digit code screen (OFF by default, see below)
- screens/home_screen.dart         top bar + bottom bar: Home, My Farms, Market, Profile
- screens/home_grid_screen.dart    Home: overview card, 6 buttons, activity, info
- screens/profile_hub_screen.dart  Profile tab: edit profile, listings, notifications, support, log out
- small edits: marketplace_screen, farms_list_screen, profile_screen
- assets/images/ (illustrations and logo taken from your Figma file)
- pubspec.yaml: added shared_preferences

## Logo, splash and intro
- New logo (your 2.png) is used in the app and as the launcher icon on Android, iOS,
  macOS, Windows and web. After installing, uninstall the old app first so the phone
  refreshes the icon.
- Start-up order: green splash screen (2 seconds) -> intro slides ("Get started") ->
  Log in. If you are already logged in, the app goes splash -> Home.
- lib/config/app_options.dart: showIntroEveryLaunch = true shows the intro on every
  start while logged out, and again right after Log out. Set it to false before you
  publish, so the intro shows only the first time.

## Button map (Home)
My Farms -> My Farms tab | AI Crop Scan -> camera/scan | Market Prices -> price list
Sell Produce -> create listing (farmers) | Agricultural Shop -> shop | Tutorials -> videos
Bell -> notifications | person icon -> Profile tab

## Email 6-digit codes (design pages 5-8)
Off by default so sign up keeps working with your current Supabase email setup.
To turn on: in Supabase, Authentication > Email Templates (Confirm signup and Reset
Password) show the code with {{ .Token }}, then set emailCodes = true in
lib/config/auth_options.dart.

## Not built yet
Country/province/district pickers, Saved Farmers, Orders, Hindi, Admin screens in the app,
and Nepali text on screens other than sign up, onboarding, home, navigation and profile.

## Figma icons (added)
All icons in the app now come from the icon/* components in your Figma file
(home, sprout, scan, trend, pkg, bag, book, bell, user, chevrons, camera, etc.).
- lib/widgets/figma_icons.dart        FIcon widget (drop-in for Icon) + Material->Figma map
- lib/widgets/figma_icons_data.dart   the 36 Figma icon outlines (generated, no new package)
- design_icons/*.svg                  the same icons as SVG files, for reference
Every Icon(...) in lib/ is now FIcon(...). If an icon has no Figma version
(for example location pin, send, refresh) it keeps the normal Material icon.
To use a Figma icon directly: FIcon.named('sprout', size: 24, color: AppColors.primary).
No pubspec change is needed.

## Admin dashboard (new design)
web_dashboard/ now uses the new design: card layout, search box, EN / नेपाली switch,
and a new "Farm profiles" tab. Same Supabase login and admin checks as before.
Before using the Farm profiles tab, run supabase/migrations/20261126000010_admin_farm_policies.sql
once in the Supabase SQL Editor. Open web_dashboard/index.html through any static server,
e.g.  cd web_dashboard && python -m http.server 8080

## Tutorials screens (Figma: Tutorials, Tutorials Empty, Tutorial Player)
- screens/video_tutorials_screen.dart  Tutorials list: back + EN/नेपाली switch, title, English/हिन्दी/नेपाली tabs,
  video rows (thumbnail, title, category, arrow), empty state "No tutorials yet", error + Retry, pull to refresh.
  Opens from the Home "Tutorials" button and the featured video.
- screens/video_player_screen.dart     Tutorial Player: rounded video, big play button (tap to play/pause),
  progress bar (tap or drag to seek) with elapsed / total time, title, language tag, description.
  If a video cannot play inside the app, an "Open in YouTube" button is shown.
Same Supabase data as before (learning_content, content_type = video). The old
LearningAcademyScreen file is kept but is no longer opened from Home.

# AI Scan screens (from the Figma "Scan ..." frames)

Flow: Home > AI Crop Scan > Scan Camera > Photo Preview > Processing > Result
(Result / Demo / Uncertain) or Scan Error. History is the pill at the top right
of the Scan Camera page. All screens work in English and Nepali.

Files (flutter_app/lib):
- screens/camera_choice_screen.dart       Scan Camera page (dark). Take photo, Upload from gallery,
                                          History, camera help. Photos are resized to 1600 px and must be under 5 MB.
- screens/plant_scan_denied_screen.dart   Camera Denied (Open settings, Upload from gallery, Back to home)
- screens/plant_scan_preview_screen.dart  Photo Preview (Analyze photo, Retake)
- screens/plant_scan_result_screen.dart   Processing, Result, Demo, Uncertain, Error in one screen
- screens/plant_scan_history_screen.dart  Scan History and Scan History Empty (photo, issue, farm, date, confidence)
- widgets/scan_kit.dart                   shared pieces (buttons, cards, banners, confidence tag)
- models/scan_summary.dart                turns the AI report into the issue / confidence / summary / action shown
- pubspec.yaml: added app_settings (for "Open settings"). Run `flutter pub get`.
- ios/Runner/Info.plist: camera and photo library texts added.

How the states are chosen:
- Confidence "low" shows the "Result unclear" layout with Retake photo / Upload a different photo.
- If the server has no AI key yet ("server_misconfigured"), the DEMO layout shows with a sample result. It is never saved.
- Any other failure shows "Scan failed" with Try again (the photo is not uploaded twice).
- The server saves every finished scan itself, so "Save to history" confirms it.
- The "Simulate" chips in the Figma file are prototype controls and are not in the app.
- The extra report details (growth stage, treatment plan, dosage, organic options, prevention,
  recovery time) and the "More inquiry" chat are kept below the three Figma cards.
