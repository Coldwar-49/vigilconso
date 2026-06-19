---
phase: 02-refactoring-qualite
plan: "01"
subsystem: foundation
tags: [model, utils, dependencies, test-stubs, riverpod, synchronized]
dependency_graph:
  requires: []
  provides:
    - lib/models/rappel.dart (Rappel typed model — all plans in phase 02 depend on this)
    - lib/utils/image_utils.dart (proxiedUrl utility)
    - lib/utils/date_utils.dart (parseDate delegation wrapper)
    - Wave 0 test stubs for plans 02, 03, 04
  affects:
    - pubspec.yaml (flutter_riverpod 3.3.2, synchronized 3.4.0 added)
tech_stack:
  added:
    - flutter_riverpod: 3.3.2 (AsyncNotifierProvider for Plan 02)
    - synchronized: 3.4.0 (Lock for FavoritesService race condition fix in Plan 03)
  patterns:
    - Static utility class with private constructor (ImageUtils, DateUtils)
    - Delegation pattern (DateUtils.parseDate → RappelService.parseDate)
    - fromJson factory with null-safe field mapping
    - Wave 0 test stubs (always-passing placeholders tracking future test work)
key_files:
  created:
    - lib/models/rappel.dart
    - lib/utils/image_utils.dart
    - lib/utils/date_utils.dart
    - test/rappel_model_test.dart
    - test/image_utils_test.dart
    - test/date_utils_test.dart
    - test/rappel_provider_test.dart
    - test/favorites_provider_test.dart
    - test/rappel_service_gtin_test.dart
    - test/contact_service_test.dart
    - test/favorites_race_test.dart
    - test/rappel_details_widget_test.dart
    - test/favorites_shimmer_test.dart
  modified:
    - pubspec.yaml (flutter_riverpod + synchronized added)
    - pubspec.lock
decisions:
  - "Used synchronized: ^3.4.0 instead of ^3.4.1 — SDK 3.11.4 constraint, 3.4.1 requires ^3.12.0"
  - "DateUtils uses delegation to RappelService.parseDate (not re-implementation) for clean import paths"
  - "Rappel model includes zoneGeographiqueDeVente (17th field) beyond the research skeleton for completeness"
metrics:
  duration: "~20 minutes"
  completed: "2026-06-19"
  tasks_completed: 2
  tasks_total: 2
  tests_added: 13
  tests_passing: 13
  files_created: 13
  files_modified: 2
---

# Phase 02 Plan 01: Fondation typée — modèle Rappel, utilitaires, stubs Wave 0

**One-liner:** Modèle `Rappel` typé avec `fromJson` factory v2.1, utils `ImageUtils`/`DateUtils` extraits, et 10 stubs Wave 0 installés pour garantir une suite de tests exécutable dès cette base.

## What Was Built

### Task 1: Dépendances + modèle Rappel
- `pubspec.yaml` mis à jour avec `flutter_riverpod: ^3.3.2` et `synchronized: ^3.4.0`
- `lib/models/rappel.dart` créé avec classe `Rappel` et factory `fromJson`
  - 17 champs typés correspondant exactement aux noms de champs de l'API v2.1
  - Null safety complète (champs requis: `id`, `libelle`, `marqueProduit`)
  - Fallback libelle: `modeles_ou_references` → `'Produit inconnu'` si les deux sont absents
  - `toJson()` backwards-compatible pour les écrans pas encore migrés
  - Champ `lien_vers_la_fiche_rappel` (URL complète v2) — `reference_fiche` absent intentionnellement

### Task 2: Utilitaires + stubs Wave 0
- `lib/utils/image_utils.dart`: `ImageUtils.proxiedUrl()` extraction des 4 écrans dupliqués
- `lib/utils/date_utils.dart`: `DateUtils.parseDate()` délégation vers `RappelService.parseDate()`
- 3 fichiers de test avec assertions réelles (13 tests, tous verts)
- 7 fichiers de stub Wave 0 (1 test always-pass chacun, marquent le travail futur plans 02-04)

## Commits

| Task | Commit | Message |
|------|--------|---------|
| Task 1 | `83d89b9` | feat(02-01): install flutter_riverpod 3.3.2 + synchronized 3.4.0, create Rappel model |
| Task 2 | `6308bef` | feat(02-01): extract ImageUtils + DateUtils + create 10 Wave 0 test stubs |

## Tests

| Fichier | Tests | Statut |
|---------|-------|--------|
| test/rappel_model_test.dart | 6 | PASS |
| test/image_utils_test.dart | 3 | PASS |
| test/date_utils_test.dart | 4 | PASS |
| test/rappel_provider_test.dart | 1 (stub) | PASS |
| test/favorites_provider_test.dart | 1 (stub) | PASS |
| test/rappel_service_gtin_test.dart | 1 (stub) | PASS |
| test/contact_service_test.dart | 1 (stub) | PASS |
| test/favorites_race_test.dart | 1 (stub) | PASS |
| test/rappel_details_widget_test.dart | 1 (stub) | PASS |
| test/favorites_shimmer_test.dart | 1 (stub) | PASS |

**Total: 20 tests, 20 PASS** (suite complète: 64 tests pass, 3 skipped, 1 échec pré-existant dans `widget_test.dart`)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] synchronized version incompatible avec le Dart SDK actuel**
- **Found during:** Task 1, flutter pub get
- **Issue:** `synchronized: ^3.4.1` exige Dart SDK `^3.12.0` mais le projet est sur Dart 3.11.4
- **Fix:** Remplacé par `synchronized: ^3.4.0` (version déjà transitive, identiquement fonctionnelle)
- **Files modified:** pubspec.yaml
- **Commit:** `83d89b9`

### Pre-existing Failures (out of scope)

- `test/widget_test.dart: Counter increments smoke test` — échec pré-existant, teste une counter app factice non liée à VigilConso. Confirmé par `git stash` + test avant mes changements. Sera remplacé en Phase 6.

## Known Stubs

Les stubs suivants sont intentionnels — ce sont des marqueurs Wave 0 pour garantir la présence de fichiers de test avant implémentation:

| Stub | Fichier | Plan cible |
|------|---------|------------|
| rappelServiceProvider | test/rappel_provider_test.dart | Plan 02 |
| favoritesProvider | test/favorites_provider_test.dart | Plan 02 |
| RappelService.fetchByGtin | test/rappel_service_gtin_test.dart | Plan 03 |
| ContactScreen._sendMessage | test/contact_service_test.dart | Plan 03 |
| FavoritesService race condition | test/favorites_race_test.dart | Plan 03 |
| RappelDetailsPage enriched | test/rappel_details_widget_test.dart | Plan 04 |
| FavoritesScreen shimmer | test/favorites_shimmer_test.dart | Plan 04 |

Ces stubs n'empêchent pas l'objectif du plan — ils sont le but du plan (Wave 0 setup).

## Threat Surface Scan

| Flag | File | Description |
|------|------|-------------|
| No new threats | — | Aucune nouvelle surface réseau, endpoint, ou accès fichier introduit. Le modèle Rappel.fromJson utilise des casts null-safe conformes à T-02-P1-01 (mitigate disposition satisfaite). |

## Self-Check: PASSED

Fichiers créés vérifiés:
- FOUND: lib/models/rappel.dart
- FOUND: lib/utils/image_utils.dart
- FOUND: lib/utils/date_utils.dart
- FOUND: test/rappel_model_test.dart
- FOUND: test/image_utils_test.dart
- FOUND: test/date_utils_test.dart
- FOUND: test/rappel_provider_test.dart
- FOUND: test/favorites_provider_test.dart
- FOUND: test/rappel_service_gtin_test.dart
- FOUND: test/contact_service_test.dart
- FOUND: test/favorites_race_test.dart
- FOUND: test/rappel_details_widget_test.dart
- FOUND: test/favorites_shimmer_test.dart

Commits vérifiés:
- FOUND: 83d89b9 (Task 1)
- FOUND: 6308bef (Task 2)
