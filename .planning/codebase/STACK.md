# Technology Stack

**Analysis Date:** 2026-06-16

## Languages

**Primary:**
- Dart 3.x (SDK `>=3.0.0 <4.0.0`) — Flutter mobile/web application (`lib/`)
- JavaScript (Node.js) — Newsletter backend API (`newsletter-api/`)

**Secondary:**
- Kotlin — Android Gradle build config (`android/app/build.gradle.kts`)

## Runtime

**Mobile App:**
- Flutter SDK (version pinned at compile time via Gradle)
- Dart VM (Android/iOS native) + Dart2JS (web target)

**Newsletter API:**
- Node.js (version not pinned — no `.nvmrc` detected)

**Package Managers:**
- `pub` (Dart/Flutter) — lockfile: `pubspec.lock` (present and committed)
- `npm` (Node.js) — lockfile: `newsletter-api/package-lock.json` (present)

## Frameworks

**Core:**
- Flutter `stable` channel — cross-platform UI framework
  - Material 3 (`useMaterial3: true`) configured in `lib/main.dart`
  - System-aware theming: light + dark mode both implemented
  - Page transitions: Cupertino-style on Android/iOS/macOS, fade on Linux/Windows

**Newsletter Backend:**
- Express 5.x (`^5.1.0`) — HTTP API server (`newsletter-api/index.js`)

**Testing:**
- `flutter_test` (SDK built-in) — no custom test framework added beyond the default

**Build/Dev (Flutter):**
- `flutter_launcher_icons` `^0.14.3` — generates app icons from `assets/images/icon.png`
- `flutter_lints` `^5.0.0` — lint rules (extends `package:flutter_lints/flutter.yaml`)

## Key Dependencies

**Critical (Flutter):**
- `http` `^1.1.0` (resolved `1.x`) — all REST calls to the government API (`lib/services/rappel_service.dart`)
- `shared_preferences` `^2.2.1` — local persistence: favorites, onboarding flag, notification consent, API cache (`lib/services/favorites_service.dart`, `lib/services/rappel_service.dart`, `lib/main.dart`)
- `onesignal_flutter` `^5.2.6` — push notifications on Android/iOS (`lib/services/notification_service_mobile.dart`)
- `mobile_scanner` `^6.0.10` — barcode/QR camera scanning (`lib/screens/barcode_scanner.dart`)
- `cached_network_image` `^3.3.0` (resolved `3.4.1`) — product image loading with cache
- `url_launcher` `^6.1.14` — opens official recall links in browser
- `share_plus` `^10.0.0` — native share sheet for recall cards
- `permission_handler` `^12.0.0+1` — runtime camera and notification permissions
- `intl` `^0.20.2` — date/number formatting (French locale)
- `cupertino_icons` `^1.0.2` — iOS-style icon pack

**Critical (Newsletter API):**
- `nodemailer` `^6.10.2` — SMTP email sending (`newsletter-api/index.js`)
- `node-cron` `^3.0.3` — weekly digest cron job (every Monday 09:00 Europe/Paris)
- `dotenv` `^16.5.0` — environment variable loading
- `cors` `^2.8.5` — CORS middleware
- `body-parser` `^2.2.0` — JSON request parsing

## Configuration

**Environment (Flutter App):**
- OneSignal App ID is hard-coded as a constant in `lib/main.dart` (`const String _oneSignalAppId = 'eb3fd80e-1a70-468f-ab2e-e1d2eb9592ab'`)
- API base URL is hard-coded in `lib/utils/constants.dart` (`AppConstants.apiBaseUrl`)
- `.env.example` documents three variables: `ONESIGNAL_APP_ID`, `API_BASE_URL`, `NEWSLETTER_API_URL` — but these are NOT read at runtime by the Flutter app; the values are currently inlined in code

**Environment (Newsletter API):**
- Loaded via `dotenv` from `newsletter-api/.env` (not committed)
- Template: `newsletter-api/.env.example`
- Required vars: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `FROM_EMAIL`, `PORT`, `APP_URL`
- SMTP provider: Brevo (formerly Sendinblue) at `smtp-relay.brevo.com:587`

**Build (Android):**
- Config: `android/app/build.gradle.kts`
- Namespace: `com.example.vigilconso`
- `compileSdk`, `minSdk`, `targetSdk`, `versionCode`, `versionName` all delegated to Flutter Gradle plugin values
- NDK version: `27.0.12077973`
- Java/Kotlin target: `VERSION_11`
- Release signing: currently uses debug keystore (TODO comment present in build file)

**Static Analysis:**
- Config: `analysis_options.yaml`
- Extends `package:flutter_lints/flutter.yaml`
- No custom rules enabled

**Assets:**
- Images directory: `assets/images/` (declared in `pubspec.yaml`)
- App icon source: `assets/images/icon.png`

## Platform Requirements

**Development:**
- Flutter SDK (Dart SDK `>=3.0.0 <4.0.0`)
- Android NDK `27.0.12077973`
- Java 11+
- Node.js (any recent LTS) for the newsletter API

**Production:**
- Mobile targets: Android (via Google Play / APK), iOS (via App Store)
- Web target: supported (Dart2JS build, OneSignal disabled via platform stub)
- Desktop targets: Linux, macOS, Windows stubs present but not the primary target
- Newsletter API: any Node.js hosting (e.g., VPS, Railway, Render)

## App Version

- Current: `1.1.0+2` (`pubspec.yaml`)

---

*Stack analysis: 2026-06-16*
