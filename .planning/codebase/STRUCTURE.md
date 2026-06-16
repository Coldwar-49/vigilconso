# Directory Structure

**Analysis Date:** 2026-06-16

## Top-Level Layout

```
vigilconso/
├── lib/                    — Dart application source
│   ├── main.dart           — App entry point, theme, routing
│   ├── screens/            — Full-page screen widgets (11 screens)
│   ├── services/           — Data access and platform services (6 files)
│   ├── utils/              — Constants, extensions (2 files)
│   └── widgets/            — Reusable UI components (2 files)
├── test/                   — Unit and widget tests
│   ├── widget_test.dart    — Default Flutter smoke test (stub)
│   └── services_test.dart  — AppConstants unit tests
├── assets/
│   └── images/             — Local image assets
├── android/                — Android platform project
├── ios/                    — iOS platform project
├── web/                    — Flutter web target
├── linux/ macos/ windows/  — Desktop targets (not primary)
├── newsletter-api/         — Standalone Node.js Express backend
│   └── (Express + dotenv, handles newsletter subscriptions)
├── facturons/              — Separate untracked Flutter project (early stage)
├── scripts/                — Utility scripts directory
├── pubspec.yaml            — Flutter dependencies
├── pubspec.lock
└── analysis_options.yaml   — Linting rules (flutter_lints)
```

## `lib/` Detailed Layout

```
lib/
├── main.dart
│     RappelConsoApp — MaterialApp with light/dark Material 3 theme
│     main() — initialize, read prefs, route to onboarding or MainScreen
│
├── screens/
│   ├── main_screen.dart          — Tab shell (IndexedStack + NavigationBar)
│   ├── home_screen.dart          — Dashboard: alerts carousel, search, categories
│   ├── categories_screen.dart    — Category grid (10 categories)
│   ├── rappel_screen.dart        — Recall list with filters, pagination, search
│   ├── rappel_details_page.dart  — Full recall detail view
│   ├── favorites_screen.dart     — Saved recalls grid
│   ├── barcode_scanner.dart      — Camera barcode scan + API lookup
│   ├── onboarding_screen.dart    — First-launch 3-page intro
│   ├── about_screen.dart         — App info
│   ├── contact_screen.dart       — Contact form (simulated send)
│   └── search_screen.dart        — Dedicated search (if separate from rappel_screen)
│
├── services/
│   ├── rappel_service.dart             — HTTP + 5-min SharedPrefs cache for API v2.1
│   ├── favorites_service.dart          — Favorites CRUD via SharedPreferences JSON
│   ├── alerts_notifier.dart            — Global ValueNotifier<int> for new-alert badge
│   ├── subscribe_to_newsletter.dart    — Platform-conditional export (mobile/web)
│   ├── notification_service_mobile.dart — OneSignal integration (dart.library.io)
│   └── notification_service_web.dart   — Web stub for notification service
│
├── utils/
│   ├── constants.dart               — API URL, page size, category map, filter builder
│   └── build_context_extensions.dart — BuildContext extensions (image config polyfill)
│
└── widgets/
    ├── app_menu.dart         — Overflow menu (Contact, About) used in all AppBars
    └── shimmer_loading.dart  — ShimmerLoading, ShimmerBox, RappelCardShimmer, HomeAlertShimmer
```

## Key File Locations

| What to find | Where to look |
|---|---|
| App entry point | `lib/main.dart` |
| App theme (light/dark, Material 3) | `lib/main.dart` → `RappelConsoApp` |
| Tab navigation shell | `lib/screens/main_screen.dart` |
| API calls + cache | `lib/services/rappel_service.dart` |
| Category definitions | `lib/utils/constants.dart` → `AppConstants.categories` |
| API base URL + page size | `lib/utils/constants.dart` → `AppConstants.apiBaseUrl` |
| Favorites persistence | `lib/services/favorites_service.dart` |
| Alert badge logic | `lib/services/alerts_notifier.dart` |
| Push notifications | `lib/services/subscribe_to_newsletter.dart` (platform entry) |
| Reusable shimmer | `lib/widgets/shimmer_loading.dart` |
| Overflow menu | `lib/widgets/app_menu.dart` |
| Linting rules | `analysis_options.yaml` |
| Flutter dependencies | `pubspec.yaml` |

## Naming Conventions

**Files:** `snake_case.dart` throughout
- Screens: `*_screen.dart` or `*_page.dart`
- Services: `*_service.dart` or `*_notifier.dart`
- Widgets: descriptive `snake_case.dart`
- Utils: descriptive `snake_case.dart`

**Classes:** `PascalCase`
- Screens: `HomeScreen`, `RappelListScreen`, `RappelDetailsPage`
- State: `_HomeScreenState` (private, matches widget class)
- Services: `RappelService`, `FavoritesService`
- Constants: `AppConstants`

**One class per file** — no barrel files or re-exports (except platform-conditional service export).

## Where to Add New Code

| Adding | Location |
|---|---|
| New screen | `lib/screens/new_screen.dart` |
| New service / data access | `lib/services/new_service.dart` |
| New reusable widget | `lib/widgets/new_widget.dart` |
| New constant or config | `lib/utils/constants.dart` |
| New utility / extension | `lib/utils/new_util.dart` |
| New test | `test/feature_test.dart` |

## Platform Targets

**Primary targets:** Android, iOS
**Secondary targets:** Web (active, some stubs for web)
**Not actively developed:** Linux, macOS, Windows (scaffold exists, no customization)

## External Directories

**`newsletter-api/`** — Standalone Node.js Express server:
- Entry: `newsletter-api/index.js`
- Stack: Express, dotenv, cors
- Not part of Flutter build — deployed separately
- Has its own `node_modules/` and `package.json`

**`facturons/`** — Untracked Flutter project at very early stage (only `lib/main.dart`). Separate app concept, not integrated with vigilconso.

---

*Structure analysis: 2026-06-16*
