# Third-party services

Every outside service the app or dashboard uses. Items marked **TO CONFIRM** were not verified when this was written.

Account owners: the three team members, Ayush Lamichhane, Manish Kafle and Narayan Pokhrel, jointly (the code repository is under Manish Kafle's GitHub account). After handover the client owns these accounts. See `docs/HANDOVER.md`.

| Service | Used for | Where in the code | Cost and limits | What is needed to change it |
|---|---|---|---|---|
| Supabase | Database, sign-in, file storage, Edge Functions, live notifications | `flutter_app/lib/services/`, `supabase/migrations/`, `flutter_app/supabase/functions/`, `web_dashboard/config.js` | The project is on the Free plan. Limits and price: **TO CONFIRM** | Transfer the project to the client's Supabase organization. Then put the new URL and publishable key in `assets/app.env` and `web_dashboard/config.js`. |
| Supabase built-in email | Sign-up confirmation and password reset emails | Supabase Authentication settings | The built-in sender is limited in volume. | Add your own email (SMTP) provider in Supabase, Authentication, Emails. |
| Google Gemini API | AI plant scan and scan follow-up questions | `flutter_app/supabase/functions/analyze-plant-photo`, `plant-scan-followup`, `lib/services/plant_scan_service.dart` | No working key is installed. Price and limits: **TO CONFIRM** | Set the secret `GEMINI_API_KEY` in Supabase. To use another AI provider, the two Edge Functions must be changed. |
| YouTube | Tutorial video playback and thumbnails | `lib/screens/video_player_screen.dart`, `lib/services/link_launcher.dart`, package `youtube_player_iframe` | No key needed. YouTube's terms apply to embedded videos. | Use only original, licensed or embeddable videos. Add links in the dashboard. |

No SMS provider is used. Phone-code login is switched off. Turning it on needs a paid SMS provider in Supabase.

No payment service is used. The app has no payments.

## AI disclosure

The AI plant scan sends the photo the user selected, and the crop name if a farm is chosen, to the Google Gemini API for analysis. The Edge Function sends it from the server, so the Google key is never inside the app. The result is shown as an AI estimate, with the notice "This is an AI estimate, not a confirmed diagnosis", and is saved in the user's scan history. No AI model was trained for this app.

The scan is switched off until a `GEMINI_API_KEY` is added. Until then the app shows "No API key added yet." and no photo is sent to Google.

The app asks Android for internet access only. It does not ask for location, camera or storage permission itself. The photo picker is handled by the `image_picker` package.
