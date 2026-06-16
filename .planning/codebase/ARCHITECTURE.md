<!-- refreshed: 2026-06-16 -->
# Architecture

**Analysis Date:** 2026-06-16

## System Overview

```text
┌─────────────────────────────────────────────────────────────────────┐
│                         Entry Point                                  │
│              `lib/main.dart`  (RappelConsoApp)                       │
│  - Initializes OneSignal, SharedPreferences, routes to first screen  │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                ┌──────────────▼──────────────┐
                │    Onboarding Gate           │
                │  `lib/screens/              │
                │   onboarding_screen.dart`   │
                └──────────────┬──────────────┘
                               │ (first launch only)
┌──────────────────────────────▼──────────────────────────────────────┐
│                       Shell / Navigation                              │
│              `lib/screens/main_screen.dart`  (MainScreen)            │
│  IndexedStack + NavigationBar — 4 top-level tabs                     │
├──────────────┬──────────────┬──────────────┬────────────────────────┤
│  HomeScreen  │ Categories   │  Favorites   │  BarcodeScannerPage    │
│ `home_screen`│ `categories_ │ `favorites_  │ `barcode_scanner.dart` │
│  .dart`      │  screen.dart`│  screen.dart`│                        │
└──────┬───────┴──────┬───────┴──────┬───────┴──────────┬────────────┘
       │              │              │                   │
       ▼              ▼              │                   ▼
 RappelListScreen  RappelListScreen  │            (push route)
 `rappel_screen    `rappel_screen    │          MobileScanner overlay
  .dart`            .dart`           │
       │              │              │
       └──────────────┴──────────────┘
                      │
                      ▼
            RappelDetailsPage
          `rappel_details_page.dart`

┌─────────────────────────────────────────────────────────────────────┐
│                        Service Layer                                  │
├─────────────────┬──────────────────┬──────────────────┬────────────┤
│  RappelService  │ FavoritesService │NotificationSvc   │AlertsNotif │
│ `rappel_service │`favorites_service│`subscribe_to_    │`alerts_    │
│  .dart`         │ .dart`           │ newsletter.dart` │ notifier.  │
│  (HTTP + cache) │ (SharedPrefs)    │(platform condl.) │ dart`      │
└─────────────────┴──────────────────┴──────────────────┴────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│  External: data.economie.gouv.fr RappelConso API v2.1    │
│  + SharedPreferences (local cache & favorites)           │
│  + wsrv.nl image proxy                                   │
└──────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `RappelConsoApp` | App root, theming (Material 3, light+dark), initial route decision | `lib/main.dart` |
| `MainScreen` | Tab shell with `IndexedStack` + `NavigationBar`, alert badge | `lib/screens/main_screen.dart` |
| `OnboardingScreen` | First-launch 3-page intro; writes `onboarding_shown` to prefs | `lib/screens/onboarding_screen.dart` |
| `HomeScreen` | Dashboard: latest-alert carousel, search bar, category shortcuts, notification toggle | `lib/screens/home_screen.dart` |
| `CategoriesScreen` | Grid of all 10 category cards, navigates to `RappelListScreen` | `lib/screens/categories_screen.dart` |
| `RappelListScreen` | Filtered/searched recall list with 2-col grid, pagination, stagger animation | `lib/screens/rappel_screen.dart` |
| `RappelDetailsPage` | Full detail view: image carousel, risk chips, consumer actions, share, favorites | `lib/screens/rappel_details_page.dart` |
| `FavoritesScreen` | Local favorites grid, bulk-delete, navigation to details | `lib/screens/favorites_screen.dart` |
| `BarcodeScannerPage` | Camera scan (EAN-8/13/QR) + API lookup on legacy v1 endpoint | `lib/screens/barcode_scanner.dart` |
| `AboutScreen` | Static app info page | `lib/screens/about_screen.dart` |
| `ContactScreen` | Contact form (currently simulated send with `Future.delayed`) | `lib/screens/contact_screen.dart` |
| `RappelService` | HTTP calls to government API, 5-min SharedPrefs cache, local date sort | `lib/services/rappel_service.dart` |
| `FavoritesService` | CRUD favorites as JSON in SharedPreferences | `lib/services/favorites_service.dart` |
| `NotificationService` | Platform-conditional: OneSignal on mobile, stub on web | `lib/services/subscribe_to_newsletter.dart` |
| `newAlertsNotifier` | Global `ValueNotifier<int>` for new-alert badge count | `lib/services/alerts_notifier.dart` |
| `AppConstants` | API base URL, page size, category map, category API filter builder | `lib/utils/constants.dart` |
| `AppMenu` | Reusable overflow menu widget (Contact, About) used in all AppBars | `lib/widgets/app_menu.dart` |
| `ShimmerLoading` | Custom shimmer animation widget (no external package) | `lib/widgets/shimmer_loading.dart` |

## Pattern Overview

**Overall:** StatefulWidget + `setState` — plain Flutter state management with no third-party state library (no BLoC, Provider, Riverpod, or GetX). Cross-screen communication uses a single global `ValueNotifier`.

**Key Characteristics:**
- All API calls are made directly inside screen `State` classes via `RappelService` static methods
- Local persistence is handled exclusively through `SharedPreferences` (both cache and favorites)
- Navigation is imperative `Navigator.push` (no named routes, no `go_router`)
- The tab shell uses `IndexedStack` to keep tab state alive across switches
- Image loading uses a `wsrv.nl` proxy to work around CORS and format issues cross-platform

## Layers

**Presentation Layer:**
- Purpose: Screen widgets, local UI state, user interaction
- Location: `lib/screens/`
- Contains: `StatefulWidget` and `StatelessWidget` screens
- Depends on: Service layer, widgets, utils
- Used by: Navigation from `main.dart` and `main_screen.dart`

**Service Layer:**
- Purpose: Data access, persistence, external integrations
- Location: `lib/services/`
- Contains: Static-method classes for API, favorites, notifications; global `ValueNotifier`
- Depends on: `http`, `shared_preferences`, `onesignal_flutter`
- Used by: Screen widgets call service static methods directly

**Widget Layer:**
- Purpose: Reusable UI components shared across screens
- Location: `lib/widgets/`
- Contains: `AppMenu` (overflow menu), `ShimmerLoading` / `ShimmerBox` / `RappelCardShimmer` / `HomeAlertShimmer`
- Depends on: Flutter core only
- Used by: Screen widgets

**Utilities Layer:**
- Purpose: Constants, extensions
- Location: `lib/utils/`
- Contains: `AppConstants` (API URL, page size, category definitions, filter builder), `BuildContextExtensions` (image configuration polyfill)
- Depends on: Flutter core only
- Used by: Service layer and screen widgets

## Data Flow

### Primary Request Path — Browse Recalls by Category

1. User taps a category in `CategoriesScreen` or `HomeScreen` (`lib/screens/categories_screen.dart`, `lib/screens/home_screen.dart`)
2. `Navigator.push` creates `RappelListScreen(categoryKey, categoryTitle)` (`lib/screens/rappel_screen.dart`)
3. `initState` calls `_fetchRappels()`, which builds API URL using `AppConstants.getCategoryFilter()` (`lib/utils/constants.dart`)
4. HTTP GET to `https://data.economie.gouv.fr/api/explore/v2.1/...` via `dart:io` `http` package (15s timeout)
5. Results locally sorted by `date_publication` descending (API `sort` param is ignored by server)
6. `setState` updates `_rappels`, `_filteredRappels`, triggers grid re-render with stagger animation
7. User taps a card → `Navigator.push(RappelDetailsPage(rappel: rappel))` (`lib/screens/rappel_details_page.dart`)

### Home Screen — Latest Alerts

1. `HomeScreen.initState` calls `RappelService.fetchLatestRappels(limit: 5)` (`lib/services/rappel_service.dart`)
2. `RappelService` checks SharedPreferences cache (5-min TTL); fetches from API if stale
3. Results stored in cache under `cached_rappels_v4_<categoryKey>`
4. `_countNewAlerts` compares `date_publication` to `last_seen_alert_date` in SharedPreferences
5. `newAlertsNotifier.value = newCount` updates the global `ValueNotifier` (`lib/services/alerts_notifier.dart`)
6. `MainScreen`'s `ValueListenableBuilder` reacts and renders the badge on the Home nav icon

### Favorites Flow

1. `RappelDetailsPage` calls `FavoritesService.isFavorite()` on init to set heart icon state
2. Tap → `FavoritesService.toggleFavorite()` serializes full recall JSON to SharedPreferences under key `'favorites'`
3. `FavoritesScreen` reads from `FavoritesService.getFavorites()` on `initState` and on remove

### Barcode Scan Flow

1. `BarcodeScannerPage.initState` requests camera permission via `permission_handler`
2. `_scanBarcode` pushes an anonymous `Scaffold` containing `MobileScanner` widget
3. On barcode detected, `Navigator.pop(context, rawValue)` returns the barcode string
4. `_checkProductRecall(barcode)` calls the legacy v1 API (`rappelconso0` dataset) — note: different endpoint from the rest of the app
5. Result displayed as formatted text string in a colored container

**State Management:**
- Per-screen: local `setState` on `StatefulWidget`
- Cross-screen (alert badge count): `ValueNotifier<int> newAlertsNotifier` in `lib/services/alerts_notifier.dart`, read via `ValueListenableBuilder` in `MainScreen`

## Key Abstractions

**RappelService (static service):**
- Purpose: Centralized API access with offline-capable cache layer
- Examples: `lib/services/rappel_service.dart`
- Pattern: All-static class. `fetchRappels()` returns `Map<String, dynamic>` with keys `results`, `fromCache`, `apiError`, `error`. Falls back to stale cache on network failure.

**AppConstants (configuration registry):**
- Purpose: Single source of truth for API URL, page size, category metadata, and API filter SQL-like strings
- Examples: `lib/utils/constants.dart`
- Pattern: Pure static `const` class. `getCategoryFilter(categoryKey)` returns ODS `where` clause string.

**FavoritesService (static service):**
- Purpose: LocalStorage CRUD for saved recalls
- Examples: `lib/services/favorites_service.dart`
- Pattern: All-static, uses `reference_fiche ?? libelle` as identity key. Stores full recall JSON blob.

**NotificationService (platform conditional):**
- Purpose: Unified OneSignal interface with web stub
- Examples: `lib/services/subscribe_to_newsletter.dart`, `lib/services/notification_service_mobile.dart`, `lib/services/notification_service_web.dart`
- Pattern: Dart conditional export (`export ... if (dart.library.io) ...`). Callers import `subscribe_to_newsletter.dart` only.

**AppMenu (shared widget):**
- Purpose: Consistent overflow menu across all AppBars
- Examples: `lib/widgets/app_menu.dart`
- Pattern: `StatelessWidget` with `PopupMenuButton`. All screens include `actions: const [AppMenu()]`.

## Entry Points

**App Bootstrap:**
- Location: `lib/main.dart` → `main()` function
- Triggers: Flutter engine startup
- Responsibilities: `WidgetsFlutterBinding.ensureInitialized()`, `NotificationService.initialize()`, SharedPreferences read for notification-consent and onboarding flags, `runApp(RappelConsoApp(...))`

**Primary Shell:**
- Location: `lib/screens/main_screen.dart` → `MainScreen`
- Triggers: Navigation from `main.dart` (after onboarding or on subsequent launches)
- Responsibilities: `IndexedStack` tab management, badge notification via `ValueListenableBuilder`

**Onboarding Gate:**
- Location: `lib/screens/onboarding_screen.dart` → `OnboardingScreen`
- Triggers: First launch only (when `onboarding_shown` SharedPrefs key is absent/false)
- Responsibilities: 3-page intro, writes `onboarding_shown = true`, then `pushReplacement` to `MainScreen`

## Architectural Constraints

- **Threading:** Single-threaded Flutter event loop. All async is `Future`/`async-await`. No isolates used.
- **Global state:** One module-level mutable singleton: `newAlertsNotifier` in `lib/services/alerts_notifier.dart`. All other state is scoped to `State` objects.
- **Circular imports:** None detected. Services do not import screens. Screens import services and widgets.
- **Navigation:** Purely imperative `Navigator.push` / `Navigator.pop`. No named routes, no `go_router`, no `Navigator 2.0`. Deep linking is not supported.
- **API coupling:** Screens call service static methods directly — no repository abstraction layer between screens and services.

## Anti-Patterns

### Duplicated HTTP + parsing logic in `RappelListScreen`

**What happens:** `lib/screens/rappel_screen.dart` contains its own `_fetchRappels()` and `_searchRappels()` methods that build API URLs and sort results directly, duplicating logic already in `RappelService`.
**Why it's wrong:** Any change to API query logic, date parsing, or the wsrv.nl proxy URL must be made in multiple places. Cache is also bypassed in `RappelListScreen`.
**Do this instead:** Delegate all API calls to `RappelService.fetchRappels()`, which already accepts `categoryKey`, `searchQuery`, `newestFirst`, and `forceRefresh` parameters.

### Barcode scanner uses a different API version

**What happens:** `lib/screens/barcode_scanner.dart` calls `rappelconso0` (v1 API with `nhits` / `records` response shape), while all other screens use the v2.1 API with `results` shape via `AppConstants.apiBaseUrl`.
**Why it's wrong:** The v1 endpoint may be deprecated; field names differ (`nom_de_la_marque_du_produit` vs `marque_produit`), creating maintenance risk.
**Do this instead:** Migrate `_checkProductRecall` to use `AppConstants.apiBaseUrl` with a GTIN filter matching the scanned barcode.

### Contact form send is simulated

**What happens:** `lib/screens/contact_screen.dart` `_sendMessage()` uses `Future.delayed(Duration(seconds: 2))` and always shows success — no actual HTTP request is made.
**Why it's wrong:** Users believe their message was sent when it was not.
**Do this instead:** Implement a real API call (e.g., to the `newsletter-api/` Node.js backend in the repo root, or an email service).

### Image proxy URL duplicated across three files

**What happens:** The `_proxiedUrl` helper (`'https://wsrv.nl/?url=$encoded&output=jpg&q=85'`) is copy-pasted into `lib/screens/home_screen.dart`, `lib/screens/rappel_screen.dart`, `lib/screens/favorites_screen.dart`, and `lib/screens/rappel_details_page.dart`.
**Why it's wrong:** Changing proxy settings requires editing 4 files.
**Do this instead:** Extract to a shared utility in `lib/utils/image_utils.dart` or add a static method to `AppConstants`.

## Error Handling

**Strategy:** Try/catch in each async method. On API failure, fall back to stale SharedPreferences cache when available. Error state is stored in local `String? _errorMessage` and displayed via `_buildErrorState()` widget.

**Patterns:**
- `RappelService` returns `Map<String, dynamic>` with optional `error` key instead of throwing
- Screens catch exceptions from service calls and update `_errorMessage` state
- Image loading errors are handled per-widget via `errorBuilder` callback showing a placeholder
- No global error boundary or crash reporting integration

## Cross-Cutting Concerns

**Logging:** `debugPrint()` used for development-only service errors (e.g., `RappelService error: $e`). No structured logging or log levels.
**Validation:** Form validation only in `ContactScreen` via Flutter `Form` + `validator` callbacks. No input validation on search queries beyond whitespace trim.
**Authentication:** None. The app is entirely unauthenticated. OneSignal push subscription is the only user-identity mechanism.

---

*Architecture analysis: 2026-06-16*
