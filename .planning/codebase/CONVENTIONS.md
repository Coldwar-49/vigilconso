# Coding Conventions

**Analysis Date:** 2026-06-16

## Naming Patterns

**Files:**
- Screens: `snake_case_screen.dart` — e.g., `home_screen.dart`, `rappel_details_page.dart`
- Services: `snake_case_service.dart` — e.g., `rappel_service.dart`, `favorites_service.dart`
- Widgets: `snake_case.dart` — e.g., `shimmer_loading.dart`, `app_menu.dart`
- Utils: `snake_case.dart` — e.g., `constants.dart`, `build_context_extensions.dart`
- Exception: detail pages use `_page` suffix (`rappel_details_page.dart`) while list screens use `_screen` suffix

**Classes:**
- Widgets: `PascalCase` matching the feature — `HomeScreen`, `RappelListScreen`, `RappelDetailsPage`
- State classes: `_WidgetNameState` private prefix — `_HomeScreenState`, `_RappelListScreenState`
- Private file-level shimmer widgets: leading underscore `_AlertCardShimmer`
- Service classes: `PascalCase` with `Service` suffix — `RappelService`, `FavoritesService`
- Constants class: `AppConstants` (static-only class, no instantiation)

**Variables and Fields:**
- Private instance fields: `_camelCase` with leading underscore — `_scrollController`, `_isLoading`, `_latestRappels`
- Local variables: `camelCase` — `final cs = Theme.of(context).colorScheme`
- Constants: `_camelCase` for private statics — `static const String _cacheKey`; `SCREAMING_SNAKE_CASE` is not used
- Boolean flags: `is*` / `has*` prefix — `_isLoading`, `_isNewestFirst`, `_isFavorite`

**Methods:**
- Private helper build methods: `_build*` prefix — `_buildHeader`, `_buildLatestAlertsSection`, `_buildRappelCard`
- Private action methods: `_verb*` — `_loadLatestRappels`, `_toggleFavorite`, `_submitSearch`
- Private state methods: `_applyYearFilter`, `_countNewAlerts`

**Types and Parameters:**
- Generic API data: `dynamic` type used extensively for JSON payloads — `final dynamic rappel`, `List<dynamic> _rappels`

## Code Style

**Formatting:**
- `flutter_lints: ^5.0.0` via `analysis_options.yaml` — includes `package:flutter_lints/flutter.yaml`
- No custom lint rules are added beyond the base `flutter_lints` ruleset
- No explicit formatter configuration (uses `dart format` defaults)
- Double quotes used for Dart strings (French text uses single quotes only when apostrophes are present)

**Linting:**
- `avoid_print` rule is not enforced (commented out in `analysis_options.yaml`)
- `debugPrint` is used in services for error logging — `debugPrint('RappelService error: $e')`
- `// ignore:` suppression is present in tests: `// ignore: depend_on_referenced_packages`

## Import Organization

**Order observed:**
1. Dart SDK imports — `import 'dart:convert';`, `import 'dart:async';`
2. Flutter framework — `import 'package:flutter/material.dart';`
3. Third-party packages — `import 'package:http/http.dart' as http;`, `import 'package:intl/intl.dart';`
4. Internal package imports — `import 'package:vigiconso/services/rappel_service.dart';`

**Import aliases:**
- `http` package aliased: `import 'package:http/http.dart' as http;`
- Selective imports used for platform stubs: `import '...' show NotificationService`

**Conditional exports (platform branching):**
- `lib/services/subscribe_to_newsletter.dart` uses `export ... if (dart.library.io)` to select mobile vs web service at compile time

**Path Aliases:**
- Package imports always use `package:vigiconso/` prefix — no relative imports

## Widget Structure Pattern

**StatefulWidget skeleton** — used by all screens:
```dart
class FooScreen extends StatefulWidget {
  const FooScreen({super.key});
  @override
  State<FooScreen> createState() => _FooScreenState();
}

class _FooScreenState extends State<FooScreen> {
  // fields with leading underscores
  @override
  void initState() { super.initState(); /* load data */ }
  @override
  void dispose() { /* cancel timers, dispose controllers */ super.dispose(); }
  @override
  Widget build(BuildContext context) { ... }
  // private _build* helpers
}
```

**StatelessWidget skeleton** — used for pure display widgets:
```dart
class AppMenu extends StatelessWidget {
  const AppMenu({super.key});
  @override
  Widget build(BuildContext context) { ... }
}
```

**Private internal widgets** — defined in same file at file level with leading underscore:
- `_AlertCardShimmer` in `lib/screens/home_screen.dart`
- `_OnboardingPage` in `lib/screens/onboarding_screen.dart`

## State Management

**Pattern:** `setState` exclusively — no external state management library (no Provider, Riverpod, Bloc, etc.)

**Global reactive state:** `ValueNotifier<int> newAlertsNotifier` in `lib/services/alerts_notifier.dart`
- Consumed via `ValueListenableBuilder` in `lib/screens/main_screen.dart`
- This is the only cross-widget reactive state in the app

**Data model:** API data flows as raw `dynamic` / `Map<String, dynamic>` — no typed model classes or DTOs

**Persistence:** `SharedPreferences` used directly in screens and services — no abstraction layer

## Error Handling

**Async methods in screens:**
```dart
Future<void> _loadData() async {
  setState(() { _isLoading = true; _errorMessage = null; });
  try {
    final result = await SomeService.fetch();
    if (mounted) setState(() { _data = result; _isLoading = false; });
  } catch (e) {
    if (mounted) setState(() { _isLoading = false; _errorMessage = 'Erreur: $e'; });
  }
}
```

**`mounted` guard:** Always checked before `setState` in async callbacks to prevent post-dispose calls.

**Service-level error handling:**
- `RappelService` returns `Map<String, dynamic>` with optional `'error'` key rather than throwing
- `FavoritesService` does not handle errors — assumes `SharedPreferences` never fails
- `debugPrint` used for service-level logging: `debugPrint('RappelService error: $e')`

**Empty/null fallback pattern:**
```dart
final title = rappel['libelle'] ?? rappel['libelle_produit'] ?? 'Produit sans nom';
```
Cascading null-coalescing operators used to handle missing API fields.

**Date parsing:** Silent catch-all pattern:
```dart
try {
  return DateTime.parse(dateStr);
} catch (_) {}
```
Errors swallowed silently, `null` returned on failure.

## Async Patterns

**Future-based throughout** — no Stream usage except `ValueNotifier`

**HTTP calls:**
- 15-second timeout applied to all HTTP calls: `.timeout(const Duration(seconds: 15))`
- Response decoding: `jsonDecode(response.body)` / `json.decode(response.body)` (both variants used)

**Async in initState:** Async work is triggered from `initState` via void async methods — `initState` itself is not marked `async`:
```dart
@override
void initState() {
  super.initState();
  _loadLatestRappels(); // fire-and-forget
}
```

## Logging

**Tool:** `debugPrint` from `package:flutter/foundation.dart` — only in service classes
- Used for HTTP/network errors in `RappelService` and `RappelDetailsPage`
- Screen-level errors stored in `_errorMessage` state and displayed to user, not logged

## Comments

**Doc comments (`///`):** Used on service classes and public methods:
```dart
/// Service centralisé pour récupérer les rappels depuis l'API gouvernementale.
/// CONTRAINTES API : ...
static Future<Map<String, dynamic>> fetchRappels({...}) async { ... }
```

**Inline comments:** French language, describe intent or API quirks:
```dart
// Tri local (API ignore sort=-date_publication)
// Filtre date pour obtenir des données récentes
```

**Section comments in build methods:** Used to label logical UI sections:
```dart
// Image en haut
// Description centrée
// Barre de recherche unifiée
```

## Theme and Styling

**Theming:** Material 3 (`useMaterial3: true`), light+dark themes defined in `lib/main.dart`
- Always obtain colors via `Theme.of(context).colorScheme` — no hardcoded colors except `Colors.red`, `Colors.white`, `Colors.grey`
- `ColorScheme` properties used: `primary`, `onPrimary`, `error`, `onErrorContainer`, `surfaceContainerHighest`, `onSurfaceVariant`
- Common shorthand: `final cs = Theme.of(context).colorScheme;`

**Card shape:** `BorderRadius.circular(12)` standard, `BorderRadius.circular(16)` for larger cards — set globally in `CardThemeData` in `lib/main.dart`

**Image proxy:** All network images routed through `wsrv.nl` proxy:
```dart
String _proxiedUrl(String url) {
  final encoded = Uri.encodeComponent(url);
  return 'https://wsrv.nl/?url=$encoded&output=jpg&q=85';
}
```
This pattern is duplicated across `home_screen.dart`, `rappel_screen.dart`, `favorites_screen.dart`, and `rappel_details_page.dart`.

## Navigation

**Pattern:** `Navigator.push` with `MaterialPageRoute` — no named routes
```dart
Navigator.push(context, MaterialPageRoute(builder: (_) => const TargetScreen()));
```
Anonymous `_` parameter used for builder context when context is unused.

**Bottom navigation:** `NavigationBar` (Material 3) with `IndexedStack` to preserve screen state — managed in `lib/screens/main_screen.dart`

## Module Design

**Exports:** Single class per file, no barrel files
**Static services:** All service classes are fully static — no instantiation, no dependency injection
**Const constructors:** Used on all `StatelessWidget` and data-only classes — `const AppMenu({super.key})`

---

*Convention analysis: 2026-06-16*
