---
phase: 1
plan: 1
subsystem: search
tags: [search, flutter, refactoring, material3, tdd]
dependency_graph:
  requires: []
  provides:
    - SearchScreen (lib/screens/search_screen.dart)
    - RappelService.dateFrom/dateTo params (lib/services/rappel_service.dart)
    - RappelService.parseDate() public method
  affects:
    - lib/screens/rappel_screen.dart (refactored — cache bypass removed)
    - lib/screens/home_screen.dart (navigation wired to SearchScreen)
tech_stack:
  added: []
  patterns:
    - RappelService delegation (single responsibility — no HTTP in screens)
    - StatefulWidget + setState (existing pattern)
    - Material 3 SearchBar in AppBar.title
    - Stagger animation (600ms AnimationController, 0.05 per card)
    - Semantics label on InkWell for accessibility
key_files:
  created:
    - lib/screens/search_screen.dart
    - test/filter_logic_test.dart
    - test/search_history_service_test.dart
    - test/read_status_service_test.dart
    - test/search_screen_test.dart
  modified:
    - lib/screens/rappel_screen.dart
    - lib/services/rappel_service.dart
    - lib/screens/home_screen.dart
decisions:
  - "RappelService._parseDate() renommée en parseDate() (public) pour partage avec SearchScreen — extraction vers date_utils.dart reportée en Phase 2 (TECH-04)"
  - "filter_panel.dart non importé dans SearchScreen Plan 1 — TODO(Plan2) commenté dans le code"
  - "_allResults / _filteredResults séparés dès Plan 1 pour faciliter le filtrage client-side en Plan 2"
  - "isRead hardcodé false en Plan 1 — variable supprimée pour éviter dead_code warning; sera relié à ReadStatusService en Plan 4"
metrics:
  duration: "9 minutes"
  completed: "2026-06-17T15:07:11Z"
  tasks_completed: 3
  tasks_total: 3
  files_created: 5
  files_modified: 3
requirements:
  - SRCH-01
  - UX-01
---

# Phase 1 Plan 1: Fondation Recherche Globale + SearchScreen — Summary

SearchScreen Material 3 câblé à RappelService(categoryKey:'all') avec bypass de cache supprimé, correction du champ risque API, et 21 stubs de tests Wave 0 pour les Plans 2-4.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Créer les 4 stubs de tests Wave 0 | eeb1336 | test/filter_logic_test.dart, test/search_history_service_test.dart, test/read_status_service_test.dart, test/search_screen_test.dart |
| 2 | Corriger rappel_screen.dart + étendre RappelService | 5186ba1 | lib/screens/rappel_screen.dart, lib/services/rappel_service.dart |
| 3 | Créer SearchScreen + câbler HomeScreen | f5bba50 | lib/screens/search_screen.dart, lib/screens/home_screen.dart |

## Deliverables

### SearchScreen (`lib/screens/search_screen.dart`)
- StatefulWidget complet avec `SingleTickerProviderStateMixin` pour l'animation stagger
- Machine d'états : idle / loading (6 shimmer cards) / résultats / empty / error
- `SearchBar` Material 3 en `AppBar.title` avec bouton clear
- `_performSearch()` : délègue à `RappelService.fetchRappels(categoryKey:'all')` avec sanitization de l'input (`replaceAll('"', '')` — mitigation T-1-01)
- Carte Google News identique à `rappel_screen.dart` : `Semantics` label + champ `risques_encourus` correct
- Compteur résultats + sort chips (Récent/Ancien) + tri en mémoire

### RappelService (`lib/services/rappel_service.dart`)
- Signature de `fetchRappels()` étendue avec `String? dateFrom, String? dateTo` optionnels
- `_parseDate()` renommée en `parseDate()` (publique) — utilisée par rappel_screen et search_screen

### rappel_screen.dart
- `_fetchRappels()` et `_searchRappels()` remplacées par `_loadRappels()` qui délègue au service
- Champ risque corrigé : `risques_encourus_par_le_consommateur` → `risques_encourus` (Pitfall 4)
- `_parseDate()` locale supprimée, remplacée par `RappelService.parseDate()`
- Import `http` supprimé

### HomeScreen
- `_submitSearch()` navigue vers `SearchScreen(initialQuery: q)` au lieu de `RappelListScreen`

### Tests Wave 0
- 21 tests skippés au total répartis dans 4 fichiers — exécutés sans erreur fatale

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Dead code warning sur `isRead` dans SearchScreen**
- **Found during:** Tâche 3 — flutter analyze
- **Issue:** `const bool isRead = false` + `isRead ? '' : ', non lu'` déclenchait un warning `dead_code` et `unused_local_variable`
- **Fix:** Supprimé la variable `isRead`, remplacé l'expression ternaire par `', non lu'` hardcodé — cohérent avec la spec Plan 1 (toujours non lu)
- **Files modified:** lib/screens/search_screen.dart
- **Commit:** f5bba50

**2. [Rule 2 - Missing] `_allResults` vs `_filteredResults` séparés dès Plan 1**
- **Found during:** Tâche 3 — conception de SearchScreen
- **Rationale:** Le plan 2 a besoin de deux listes séparées pour le filtrage client-side sans rappel API. Implémenter dès Plan 1 évite une refactorisation entre waves.
- **Fix:** `_allResults` stocke les résultats bruts API, `_filteredResults` les résultats filtrés. Compteur affiché comme `count / total` quand filtres actifs.
- **Files modified:** lib/screens/search_screen.dart
- **Commit:** f5bba50

### Not deviating

Les 4 `info` de dépreciation `withOpacity` dans `home_screen.dart` sont **préexistants** (code non modifié par ce plan). Hors scope — logué pour déferred-items.

## Known Stubs

Plan 1 livre intentionnellement ces stubs à compléter dans les Plans suivants :

| Stub | Fichier | Ligne | Résolution |
|------|---------|-------|------------|
| `TODO(Plan2): IconButton(Icons.tune) → FilterPanel` | search_screen.dart | ~130 | Plan 2 : création de filter_panel.dart |
| `isRead` toujours false dans les cartes SearchScreen | search_screen.dart | _buildRappelCard | Plan 4 : ReadStatusService.isRead() |
| 9 tests filter_logic_test.dart | test/filter_logic_test.dart | all | Plan 2 : FilterLogic client-side |
| 5 tests search_history_service_test.dart | test/search_history_service_test.dart | all | Plan 3 : SearchHistoryService |
| 4 tests read_status_service_test.dart | test/read_status_service_test.dart | all | Plan 4 : ReadStatusService |
| 3 tests search_screen_test.dart | test/search_screen_test.dart | all | Plan 3 : autocomplétion avec mock |

## Threat Flags

Aucune nouvelle surface de sécurité introduite au-delà du modèle de menace du plan :
- T-1-01 mitigé : `query.trim().replaceAll('"', '')` présent dans `_performSearch()`
- T-1-02 préservé : `searchQuery.replaceAll('"', '')` toujours présent dans `RappelService.fetchRappels()`
- T-1-03 accepté : aucune donnée sensible dans SharedPreferences

## Self-Check: PASSED

### Fichiers créés — vérification

- lib/screens/search_screen.dart : FOUND
- test/filter_logic_test.dart : FOUND
- test/search_history_service_test.dart : FOUND
- test/read_status_service_test.dart : FOUND
- test/search_screen_test.dart : FOUND

### Commits — vérification

- eeb1336 (test stubs) : FOUND
- 5186ba1 (fix rappel_screen + rappel_service) : FOUND
- f5bba50 (SearchScreen + HomeScreen) : FOUND

### Critères de succès

- [x] 4 fichiers stubs de tests existent dans test/ et passent sans erreur fatale (21 tests skippés)
- [x] `flutter analyze` retourne 0 erreurs sur les fichiers modifiés (hors `info` préexistants)
- [x] rappel_screen.dart ne contient plus d'appels `http.get` directs
- [x] rappel_screen.dart utilise `risques_encourus` (pas `risques_encourus_par_le_consommateur`)
- [x] RappelService.fetchRappels() accepte `dateFrom` et `dateTo` optionnels
- [x] SearchScreen existe et compile, affiche les résultats via RappelService(categoryKey:'all')
- [x] HomeScreen navigue vers SearchScreen (pas RappelListScreen) depuis la SearchBar
