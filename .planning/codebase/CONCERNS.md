# Technical Concerns

**Analysis Date:** 2026-06-16

## Security

### Hardcoded OneSignal App ID
- **File:** `lib/main.dart`
- **Issue:** OneSignal App ID hardcoded in source — exposed in public repo
- **Risk:** Medium — App ID alone doesn't grant write access, but exposes push infrastructure
- **Fix:** Move to `--dart-define` build args or environment config

### Newsletter API — No Auth on Write Endpoints
- **File:** `newsletter-api/index.js`
- **Issue:** POST endpoints (subscribe/unsubscribe) have no authentication or rate limiting
- **Risk:** Medium — subscriber list can be spammed or harvested
- **Fix:** Add rate limiting (`express-rate-limit`) and optionally a CAPTCHA or signed token

### Subscriber List Stored as Plaintext JSON
- **File:** `newsletter-api/` storage
- **Issue:** Email addresses stored in plain JSON without encryption
- **Risk:** Medium — data breach exposure
- **Fix:** Use a proper database with encryption at rest

### Barcode Scanner Uses Deprecated v1 API
- **File:** `lib/screens/barcode_scanner.dart`
- **Issue:** Calls `rappelconso0` (v1 endpoint) — different field names, may be deprecated
- **Risk:** High — could break without notice when v1 is shut down
- **Fix:** Migrate to v2.1 API using `AppConstants.apiBaseUrl` with GTIN filter

### Contact Form Sends Nothing
- **File:** `lib/screens/contact_screen.dart`
- **Issue:** `_sendMessage()` uses `Future.delayed(Duration(seconds: 2))` and always shows success
- **Risk:** High user trust issue — users believe their message was sent when it was not
- **Fix:** Implement real API call to backend or email service

### Typo in Support Email
- **File:** `lib/screens/about_screen.dart`
- **Issue:** Support email address may contain a typo
- **Risk:** Low — user messages silently bounced

## Technical Debt

### Image Proxy URL Duplicated in 4 Files
- **Files:** `lib/screens/home_screen.dart`, `lib/screens/rappel_screen.dart`, `lib/screens/favorites_screen.dart`, `lib/screens/rappel_details_page.dart`
- **Issue:** `_proxiedUrl()` helper copy-pasted:
  ```dart
  'https://wsrv.nl/?url=$encoded&output=jpg&q=85'
  ```
- **Fix:** Extract to `lib/utils/image_utils.dart` or add `AppConstants.proxiedImageUrl(url)`

### Direct HTTP Calls in Screen Files Bypass Cache
- **Files:** `lib/screens/rappel_screen.dart`
- **Issue:** `_fetchRappels()` and `_searchRappels()` build API URLs directly, bypassing `RappelService` and its 5-min SharedPreferences cache
- **Fix:** Delegate all API calls to `RappelService.fetchRappels()` (already accepts category, query, sort, forceRefresh params)

### `_parseDate` Duplicated
- **Files:** `lib/screens/rappel_screen.dart`, `lib/screens/rappel_details_page.dart`
- **Issue:** Date parsing helper duplicated
- **Fix:** Move to `lib/utils/date_utils.dart`

### Untyped `dynamic` API Data — No Model Classes
- **Scope:** All screens and services
- **Issue:** `List<dynamic>` and `Map<String, dynamic>` used everywhere — no typed models for `Rappel`, category, etc.
- **Risk:** Silent null access errors at runtime
- **Fix:** Introduce typed `Rappel` model class with `fromJson` factory

### Shimmer Loading Re-implemented in `home_screen.dart`
- **File:** `lib/screens/home_screen.dart` → `_AlertCardShimmer`
- **Issue:** Custom shimmer defined inline instead of reusing `lib/widgets/shimmer_loading.dart`
- **Fix:** Replace with `RappelCardShimmer` or `HomeAlertShimmer` from shared widget

## Performance

### FavoritesService Reads SharedPreferences Multiple Times Per Toggle
- **File:** `lib/services/favorites_service.dart`
- **Issue:** `toggleFavorite()` reads → decodes → modifies → encodes → writes on every tap
- **Risk:** Low — but adds latency on large favorites lists
- **Fix:** Cache favorites list in memory, persist async

### `IndexedStack` Keeps All Tabs Alive (Including Camera)
- **File:** `lib/screens/main_screen.dart`
- **Issue:** `IndexedStack` prevents widget disposal. `BarcodeScannerPage`'s camera controller stays initialized even when not visible
- **Risk:** Battery drain, memory usage
- **Fix:** Lazy-initialize camera only when tab is active using `AutomaticKeepAliveClientMixin` selectively or `IndexedStack` with null placeholders

### Newsletter Digest Sends Emails Serially
- **File:** `newsletter-api/`
- **Issue:** If emails sent in a loop without `Promise.all`, large lists block the event loop
- **Fix:** Batch with `Promise.all` + chunking

## Fragile Areas

### Barcode Scanner Controller Reuse After `Navigator.pop`
- **File:** `lib/screens/barcode_scanner.dart`
- **Issue:** `MobileScanner` widget is pushed as a temporary route; controller lifecycle depends on correct pop timing. Race conditions possible on rapid scan + pop.
- **Risk:** Medium — potential crash on fast scan sequences

### Race Condition on Concurrent Favorites Writes
- **File:** `lib/services/favorites_service.dart`
- **Issue:** Multiple rapid taps call `toggleFavorite()` simultaneously — two reads can occur before either write, causing one write to overwrite the other
- **Fix:** Serialize writes with a Mutex/lock or debounce the toggle

### `newAlertsNotifier` Module-Level Singleton — No Ownership Boundary
- **File:** `lib/services/alerts_notifier.dart`
- **Issue:** `ValueNotifier<int> newAlertsNotifier` is module-level mutable state accessible from anywhere. Value can be mutated from multiple places with no clear owner.
- **Risk:** Low now (only `HomeScreen` writes it), but dangerous as codebase grows

### Notification Permission Not Re-checked After OS Settings Change
- **File:** `lib/screens/home_screen.dart`
- **Issue:** Notification toggle reflects local SharedPrefs state, not actual OS permission status. User can revoke in Settings; app won't reflect this until reinstall or next explicit permission check.

## Dependency Risks

| Package | Version | Risk |
|---|---|---|
| `mobile_scanner` | ^6.x | Major version — API may break with `^6` |
| `permission_handler` | ^12.x | iOS Privacy Manifest required (App Store review risk) |
| `onesignal_flutter` | latest | OneSignal SDK migration history — watch for breaking changes |
| Express (newsletter-api) | v5 | Relatively new — some middleware not yet compatible |

## Test Gaps

- `test/widget_test.dart` tests a dummy counter app unrelated to VigilConso — misleading
- Only `AppConstants` has service-level tests
- Zero widget tests for any real screen
- Barcode scan flow completely untested
- `FavoritesService` toggle race condition has no test coverage
- No integration tests (`integration_test/` absent)

---

*Concerns analysis: 2026-06-16*
