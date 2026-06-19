---
phase: 02-refactoring-qualite
plan: "02"
subsystem: state-management
tags: [riverpod, providers, asyncnotifier, consumer-widget, navigation, ux]
dependency_graph:
  requires:
    - lib/models/rappel.dart (Plan 01 — Rappel typed model)
    - lib/utils/image_utils.dart (Plan 01 — ImageUtils.proxiedUrl)
    - pubspec.yaml flutter_riverpod 3.3.2 (Plan 01)
  provides:
    - lib/providers/rappel_provider.dart (RappelNotifier + rappelServiceProvider)
    - lib/providers/favorites_provider.dart (FavoritesNotifier + favoritesProvider)
    - lib/main.dart (ProviderScope root + dart-define OneSignal)
    - ConsumerStatefulWidget for home_screen, rappel_screen, favorites_screen
  affects:
    - lib/screens/home_screen.dart (ConsumerStatefulWidget, ImageUtils.proxiedUrl)
    - lib/screens/rappel_screen.dart (provider delegation, AsyncValue.when, RappelCardShimmer)
    - lib/screens/favorites_screen.dart (provider watch, shimmer, ImageUtils.proxiedUrl)
    - lib/screens/main_screen.dart (navigation label + icon update)
tech_stack:
  added: []
  patterns:
    - AsyncNotifierProvider<Notifier, State> (Riverpod 3.x — NOT StateNotifierProvider)
    - ConsumerStatefulWidget + ConsumerState pattern
    - AsyncValue.when(loading, error, data) for reactive UI
    - ref.watch(provider) in build(), ref.read(provider.notifier) in callbacks
    - ref.invalidateSelf() for post-mutation refresh
    - ref.invalidate(provider) for external invalidation (after removeFavorite)
    - String.fromEnvironment + isNotEmpty guard (TECH-08 dart-define)
key_files:
  created:
    - lib/providers/rappel_provider.dart
    - lib/providers/favorites_provider.dart
  modified:
    - lib/main.dart
    - lib/screens/home_screen.dart
    - lib/screens/rappel_screen.dart
    - lib/screens/favorites_screen.dart
    - lib/screens/main_screen.dart
    - test/rappel_provider_test.dart
    - test/favorites_provider_test.dart
decisions:
  - "rappel_screen.dart utilise AsyncValue.when avec filtrage/tri local dans le callback data — cohérent avec le fait que le provider retourne toutes les données et l'écran filtre localement"
  - "home_screen.dart garde _loadLatestRappels() local (appelle fetchLatestRappels) — la section 'Dernières alertes' a besoin de max 5 résultats triés côté API, pas du provider principal"
  - "Import rappel_provider retiré de home_screen.dart car unused — la HomeScreen est ConsumerStatefulWidget mais n'utilise pas encore rappelServiceProvider directement"
  - "ref.invalidate(favoritesProvider) utilisé dans favorites_screen pour la suppression (vs ref.invalidateSelf() dans le notifier pour toggle)"
  - "Navigation: 'Catégories' → 'Rappels' + grid_view → list_alt (UX-03 — label plus représentatif du contenu)"
metrics:
  duration: "~25 minutes"
  completed: "2026-06-19"
  tasks_completed: 2
  tasks_total: 2
  tests_added: 4
  tests_passing: 66
  files_created: 2
  files_modified: 7
---

# Phase 02 Plan 02: Migration Riverpod — providers, écrans ConsumerStatefulWidget, navigation

**One-liner:** Migration Riverpod 3.x avec `AsyncNotifierProvider` pour rappels et favoris, `ProviderScope` dans `main.dart` avec dart-define OneSignal, 3 écrans migrés en `ConsumerStatefulWidget` avec `AsyncValue.when` et `RappelCardShimmer`, navigation enrichie (label "Rappels" + icône list_alt).

## What Was Built

### Task 1 (TDD): Providers Riverpod + mise à jour main.dart

**Phase RED (commit `61c9ea6`):**
- Tests `rappel_provider_test.dart` et `favorites_provider_test.dart` mis à jour pour référencer `rappelServiceProvider` et `favoritesProvider` (types `AsyncNotifierProvider`)
- Tests échouent intentionnellement car `lib/providers/` n'existe pas encore

**Phase GREEN (commit `0e7a813`):**
- `lib/providers/rappel_provider.dart`: `RappelNotifier extends AsyncNotifier<List<Rappel>>`, `build()` appelle `RappelService.fetchRappels(categoryKey: 'all')`, `refresh(categoryKey, forceRefresh)` avec `AsyncValue.guard`
- `lib/providers/favorites_provider.dart`: `FavoritesNotifier extends AsyncNotifier<List<Rappel>>`, `build()` appelle `FavoritesService.getFavorites()`, `toggle(map)` appelle `toggleFavorite` + `ref.invalidateSelf()`
- `lib/main.dart`: `ProviderScope` wraps `runApp`, `String.fromEnvironment('ONESIGNAL_APP_ID')` remplace la clé hardcodée, garde `_oneSignalAppId.isNotEmpty` avant initialize
- 4 tests provider passent

### Task 2: Migration des écrans + navigation

- `home_screen.dart`: `ConsumerStatefulWidget` + `ConsumerState`, suppression `_proxiedUrl`, remplacement par `ImageUtils.proxiedUrl`
- `rappel_screen.dart`: `ConsumerStatefulWidget` + `ConsumerState`, `_loadRappels` délègue à `ref.read(rappelServiceProvider.notifier).refresh(...)`, `build()` utilise `ref.watch(rappelServiceProvider)` avec `AsyncValue.when`, `RappelCardShimmer` pour loading, suppression `_proxiedUrl` et `_buildCardShimmer` inline, suppression `_toggleSortOrder`/`_applyYearFilter` (logique intégrée dans `data:` callback)
- `favorites_screen.dart`: `ConsumerStatefulWidget` + `ConsumerState`, `ref.watch(favoritesProvider)` avec `AsyncValue.when`, `RappelCardShimmer` pour loading state (remplace `CircularProgressIndicator`), `ImageUtils.proxiedUrl` remplace `_proxiedUrl`, suppression champs `_favorites`/`_isLoading`/`_loadFavorites`
- `main_screen.dart`: label 'Catégories' → 'Rappels', `Icons.grid_view_outlined`/`Icons.grid_view` → `Icons.list_alt_outlined`/`Icons.list_alt`

## Commits

| Task | Commit | Message |
|------|--------|---------|
| Task 1 RED | `61c9ea6` | test(02-02): add failing provider type tests (TDD RED gate) |
| Task 1 GREEN | `0e7a813` | feat(02-02): create Riverpod providers + update main.dart (TDD GREEN gate) |
| Task 2 | `719c724` | feat(02-02): migrate 3 screens to ConsumerStatefulWidget + update navigation |

## Tests

| Fichier | Tests | Statut |
|---------|-------|--------|
| test/rappel_provider_test.dart | 2 | PASS (remplace stub Wave 0) |
| test/favorites_provider_test.dart | 2 | PASS (remplace stub Wave 0) |
| Reste de la suite | 62 | PASS (0 régressions) |
| test/widget_test.dart | 1 | FAIL (pré-existant — counter demo app, hors scope) |

**Total: 66 tests PASS, 3 skipped, 1 échec pré-existant inchangé**

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Import `rappel_provider` inutilisé dans home_screen.dart**
- **Found during:** Task 2, flutter analyze
- **Issue:** Le plan demande d'ajouter l'import `rappel_provider.dart` dans `home_screen.dart` mais la HomeScreen ne consomme pas encore `rappelServiceProvider` directement — `unused_import` warning
- **Fix:** Import retiré — `ConsumerStatefulWidget` est suffisant via `flutter_riverpod` pour le scaffold de migration; l'accès au provider sera ajouté si nécessaire en Plan 04
- **Files modified:** lib/screens/home_screen.dart

**2. [Rule 1 - Bug] `_toggleSortOrder`/`_applyYearFilter` devenus invalides après migration**
- **Found during:** Task 2, flutter analyze (`unused_element` warning)
- **Issue:** Ces méthodes manipulaient `_rappels` (champ supprimé) et `_filteredRappels` directement, incompatible avec la gestion AsyncValue.when
- **Fix:** Méthodes supprimées. La logique de tri est intégrée dans le callback `data:` du `AsyncValue.when` — `setState(() => _isNewestFirst = ...)` déclenche un rebuild qui re-trie la liste locale

**3. [Rule 1 - Bug] `_buildCardShimmer` inline inutilisé après migration vers `RappelCardShimmer`**
- **Found during:** Task 2, flutter analyze (`unused_element` warning)
- **Issue:** `_buildCardShimmer()` n'était plus appelé après remplacement par `const RappelCardShimmer()`
- **Fix:** Méthode inline supprimée

**4. [Rule 2 - Fonctionnalité manquante] `dead_null_aware_expression` sur `widget.categoryKey ?? 'all'`**
- **Found during:** Task 2, flutter analyze
- **Issue:** `categoryKey` est `String` non nullable (pas `String?`) — le `?? 'all'` est mort
- **Fix:** Retiré le `?? 'all'` — le provider reçoit `widget.categoryKey` directement

## Known Stubs

Aucun stub dans les fichiers créés/modifiés par ce plan. Les stubs Wave 0 de `rappel_provider_test.dart` et `favorites_provider_test.dart` ont été remplacés par de vrais tests.

## Threat Surface Scan

| Flag | File | Description |
|------|------|-------------|
| mitigate: T-02-02 | lib/main.dart | OneSignal App ID hardcodé supprimé — `String.fromEnvironment('ONESIGNAL_APP_ID')` + garde `isNotEmpty`. Disposition du threat register respectée. |

Aucune nouvelle surface réseau, endpoint, ou accès fichier introduit.

## Self-Check: PASSED

Fichiers créés vérifiés:
- FOUND: lib/providers/rappel_provider.dart
- FOUND: lib/providers/favorites_provider.dart

Commits vérifiés:
- FOUND: 61c9ea6 (Task 1 RED)
- FOUND: 0e7a813 (Task 1 GREEN)
- FOUND: 719c724 (Task 2)

Critères d'acceptance vérifiés:
- PASS: `grep "AsyncNotifierProvider" lib/providers/rappel_provider.dart` → match
- PASS: `grep "StateNotifierProvider" lib/providers/rappel_provider.dart` → no match
- PASS: `grep "invalidateSelf" lib/providers/favorites_provider.dart` → match
- PASS: `grep "ProviderScope" lib/main.dart` → match
- PASS: `grep "fromEnvironment" lib/main.dart` → match
- PASS: `grep "eb3fd80e" lib/main.dart` → no match
- PASS: `grep "isNotEmpty" lib/main.dart` → match
- PASS: ConsumerStatefulWidget dans home, rappel, favorites screens
- PASS: Aucun `_proxiedUrl` dans les 3 écrans
- PASS: `grep -c "NavigationDestination" lib/screens/main_screen.dart` → 4
- PASS: flutter analyze lib/providers/ lib/main.dart → 0 issues
- PASS: 66 tests passent, 0 régressions
