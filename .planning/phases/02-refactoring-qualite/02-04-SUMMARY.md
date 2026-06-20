---
phase: 02-refactoring-qualite
plan: "04"
subsystem: detail-page-ux
tags: [detail-page, shimmer, action-bar, url-fix, lots, dates, riverpod, widget-test]
dependency_graph:
  requires:
    - 02-01 (Rappel model, ImageUtils)
    - 02-02 (Riverpod providers, FavoritesScreen shimmer stub)
    - 02-03 (lien_vers_la_fiche_rappel field available in v2 API)
  provides:
    - lib/screens/rappel_details_page.dart (enriched — dates, lots, sticky action bar, correct URL)
    - test/rappel_details_widget_test.dart (4 widget tests)
    - test/favorites_shimmer_test.dart (2 widget tests, replaces Wave 0 stub)
  affects:
    - lib/screens/rappel_details_page.dart
tech_stack:
  added: []
  patterns:
    - Scaffold.bottomNavigationBar for sticky action bar
    - Conditional section (_buildLotsSection → null when empty)
    - Provider override in widget tests (_LoadingNotifier/_EmptyNotifier extends FavoritesNotifier)
key_files:
  created: []
  modified:
    - lib/screens/rappel_details_page.dart (dates section, lots section, sticky action bar, URL fix, ImageUtils migration)
    - test/rappel_details_widget_test.dart (4 real widget assertions — TDD RED then GREEN)
    - test/favorites_shimmer_test.dart (2 real widget assertions — replaces Wave 0 stub)
decisions:
  - "Provider override in test: test notifiers extend FavoritesNotifier (not AsyncNotifier directly) — required by Riverpod 2.x overrideWith type signature"
  - "Sticky action bar via Scaffold.bottomNavigationBar (persists above keyboard, standard Flutter pattern)"
  - "lien_vers_la_fiche_rappel used directly (full URL from v2 API) — reference_fiche was always null in v2"
  - "Lots section hidden when conditionnements is null or empty string (not shown for most recalls)"
  - "_proxiedImageUrl removed — replaced everywhere by ImageUtils.proxiedUrl (TECH-03 completion)"
requirements:
  - UX-02
  - UX-04
metrics:
  duration: "~2 sessions"
  completed: "2026-06-20"
  tasks_completed: 3
  tasks_total: 3
  tests_added: 6
  tests_passing: 6
  files_created: 0
  files_modified: 3
---

# Phase 02 Plan 04: Page de détail enrichie + shimmer homogène

**One-liner:** RappelDetailsPage enrichi avec section Dates clés (4 lignes), section Lots concernés (conditionnelle), action bar sticky avec lien officiel correct (`lien_vers_la_fiche_rappel`). `_proxiedImageUrl` supprimé, `ImageUtils.proxiedUrl` partout. `favorites_shimmer_test.dart` stub remplacé par 2 vrais tests widget Riverpod.

## What Was Built

### Task 1 — Enrichir RappelDetailsPage (TDD RED + GREEN)

**`lib/screens/rappel_details_page.dart`:**
- Import ajouté : `package:vigiconso/utils/image_utils.dart`
- `_proxiedImageUrl` supprimé, tous les appels remplacés par `ImageUtils.proxiedUrl`
- `_openOfficialPage()` corrigé : utilise `lien_vers_la_fiche_rappel` (URL complète v2) au lieu de construire une URL cassée via `reference_fiche` (toujours null en v2)
- `_buildDatesSection()` ajouté : section "Dates clés" avec 4 lignes (Publié, Début/Fin commercialisation, Fin de rappel) via `_buildInfoRow`
- `_buildLotsSection()` ajouté : section "Lots concernés" — retourne `null` si `conditionnements` est absent/vide
- `_buildStickyActionBar()` ajouté : `Scaffold.bottomNavigationBar` avec bouton "Fiche officielle" (`FilledButton.icon`), bouton PDF optionnel, bouton Partager

**`test/rappel_details_widget_test.dart`:** Stubs Wave 0 remplacés par 4 vrais tests :
1. Affiche "Lots concernés" quand `conditionnements` est non-vide
2. Cache "Lots concernés" quand `conditionnements` est null
3. Affiche "Dates clés" (toujours visible)
4. Affiche "Fiche officielle" dans l'action bar

### Task 2 — Checkpoint humain (device verification)

Vérification manuelle requise sur appareil :
- "Dates clés" section visible dans la page détail
- "Lots concernés" section visible si le rappel a des conditionnements
- Action bar sticky avec "Fiche officielle" → ouvre la bonne URL gouvernementale
- Favoris : shimmer visible au chargement (pas de spinner)

**Statut : en attente de confirmation utilisateur.** L'implémentation est complète et testée automatiquement.

### Task 3 — Mettre à jour favorites_shimmer_test.dart

**`test/favorites_shimmer_test.dart`:** Stub `expect(true, isTrue)` remplacé par 2 vrais tests widget :
1. `shows RappelCardShimmer while favorites are loading` — override provider avec `_LoadingNotifier` (Future jamais résolu), vérifie 4 shimmer et zéro `CircularProgressIndicator`
2. `shows empty state when favorites list is empty` — override avec `_EmptyNotifier` (liste vide), vérifie "Aucun favori"

## Commits

| Task | Commit | Message |
|------|--------|---------|
| Task 1 (RED) | `7c7dc82` | test(02-04): add failing widget tests for enriched RappelDetailsPage |
| Task 1 (GREEN) | `ffa2662` | feat(02-04): enrich RappelDetailsPage — dates, lots, sticky action bar, URL fix |
| Task 3 | `dde1169` | test(02-04): replace favorites_shimmer_test stub with real widget assertions |

## Tests

| Fichier | Tests | Statut |
|---------|-------|--------|
| test/rappel_details_widget_test.dart | 4 | PASS |
| test/favorites_shimmer_test.dart | 2 | PASS |

**Total plan 04: 6 tests, 6 PASS**

**Suite complète:** 74 passing · 3 stubs Wave 0 restants · 1 failing (`widget_test.dart` counter factice — TECH-13 Phase 6)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Type mismatch dans overrideWith Riverpod**
- **Found during:** Task 3, compilation
- **Issue:** `_LoadingNotifier extends AsyncNotifier<List<Rappel>>` → `overrideWith` attend `FavoritesNotifier Function()`, pas `AsyncNotifier Function()`
- **Fix:** `_LoadingNotifier extends FavoritesNotifier` (et idem `_EmptyNotifier`) — Riverpod 2.x exige que le type de notifier soit exact ou sous-type du notifier déclaré
- **Files modified:** test/favorites_shimmer_test.dart

## Known Stubs (Wave 0 restants)

Les stubs Wave 0 suivants existent encore dans `test/` — ils passent trivialement (`expect(true, isTrue)`). Ils seront transformés en tests réels en Phase 6 (TECH-11, TECH-12) :
- test/rappel_model_test.dart
- test/image_utils_test.dart
- test/date_utils_test.dart
- test/rappel_provider_test.dart
- test/favorites_provider_test.dart

## Threat Surface Scan

| Flag | File | Description |
|------|------|-------------|
| T-02-P4-01 mitigated | lib/screens/rappel_details_page.dart | `canLaunchUrl(uri)` check + empty URL guard avant launch |
| T-02-P4-02 accepted | lib/screens/rappel_details_page.dart | PDF URL publique — document gouvernemental, pas d'auth |
| T-02-P4-03 accepted | lib/screens/rappel_details_page.dart | `Share.share()` avec données publiques API — pas de PII |

## Self-Check: PASSED

- FOUND: `lien_vers_la_fiche_rappel` dans rappel_details_page.dart ✓
- NOT FOUND: `reference_fiche` dans rappel_details_page.dart ✓ (supprimé)
- FOUND: `_buildDatesSection` dans rappel_details_page.dart ✓
- FOUND: `conditionnements` dans rappel_details_page.dart ✓
- FOUND: `bottomNavigationBar` dans rappel_details_page.dart ✓
- NOT FOUND: `_proxiedImageUrl` dans rappel_details_page.dart ✓ (supprimé)
- FOUND: `ImageUtils.proxiedUrl` dans rappel_details_page.dart ✓
- FOUND: `RappelCardShimmer` dans favorites_screen.dart ✓
- 74 tests passing, 1 failing pré-existant (TECH-13) ✓

Commits vérifiés :
- FOUND: 7c7dc82 (Task 1 RED)
- FOUND: ffa2662 (Task 1 GREEN)
- FOUND: dde1169 (Task 3)
