# Asset and licence list

This lists every asset, sample content item and package used by the app. Licence types for packages were read from the `LICENSE` file of each package on 25 Nov 2026. Items marked **TO CONFIRM** were not verified.

## Images, fonts and icons

| Item | Source | Licence |
|---|---|---|
| Image files | None. `flutter_app/assets/` holds no image files. | Not applicable |
| Custom fonts | None declared in `pubspec.yaml`. The app uses Flutter's default Material fonts. | Not applicable |
| Icons inside the app | Material Icons, bundled with Flutter (`uses-material-design: true`) | Apache License 2.0 |
| Android launcher icon (`@mipmap/ic_launcher`) | **TO CONFIRM**: is it the default Flutter icon or the team's own artwork? | **TO CONFIRM** |
| Video thumbnails | Come from YouTube (`img.youtube.com`) or a link the admin adds. Nothing is stored in the repository. | YouTube's terms. The client must own or be allowed to use each video. |

`flutter_app/assets/app.env` is a settings file, not an asset. It is git-ignored and holds no artwork.

## Sample content

| Content | Where | Status |
|---|---|---|
| Market prices (32 rows) | `crop_price_history` | Invented sample data, `is_demo = true`, shown with a DEMO label. Not real prices. |
| Crop information (9 starter crops) | `crops` | Placeholder text, `is_verified = false`. An agronomist has not checked it. |
| Shop products | `catalog_products` | Sample products with placeholder sellers, `is_demo = true`, shown as "Sample product". |
| Tutorial videos | `learning_content` | Links only. No video is stored or re-uploaded. Any row whose title starts with `Test ` is a test row and must be deleted before handover. |

The client has not supplied starter videos, prices or crop data. Nothing in the app presents invented values as real.

## Packages (from `flutter_app/pubspec.yaml`)

| Package | Version in `pubspec.yaml` | Used for | Licence (from its LICENSE file) |
|---|---|---|---|
| `supabase_flutter` | ^2.5.6 | Sign-in, database, storage, functions | MIT |
| `intl` | ^0.19.0 | Dates and number formats | BSD-style (Dart project authors) |
| `flutter_dotenv` | ^5.1.0 | Reads `assets/app.env` | MIT |
| `image_picker` | ^1.1.2 | Camera and gallery photos | Flutter Authors licence file. Exact type **TO CONFIRM** |
| `url_launcher` | ^6.3.2 | Open links, phone and email | BSD-style (Flutter Authors) |
| `fl_chart` | ^0.69.0 | Price trend chart | MIT |
| `youtube_player_iframe` | ^6.0.2 | In-app YouTube player | BSD-style (Sarbagya Dhaubanjar) |
| `flutter_lints` (development only) | ^3.0.2 | Code checks. Not in the app. | BSD-style (Flutter Authors) |
| `flutter`, `flutter_test` | Flutter SDK | The framework and its tests | Part of the Flutter SDK. Licence: **TO CONFIRM** |

These packages pull in other packages. Their licences are **TO CONFIRM**. To list them, run `flutter pub deps` in `flutter_app`.

"BSD-style" means the licence file begins with the standard "Redistribution and use in source and binary forms, with or without modification, are permitted" text. The exact BSD variant was not checked.
