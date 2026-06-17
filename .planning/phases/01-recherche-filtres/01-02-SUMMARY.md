---
phase: 1
plan: 2
subsystem: search-filters
tags: [flutter, filters, material3, shared-preferences, tdd, stateful-widget]
dependency_graph:
  requires:
    - "01-01 (SearchScreen, RappelService.fetchRappels avec dateFrom/dateTo)"
  provides:
    - FilterState (lib/widgets/filter_panel.dart)
    - FilterPanel widget (lib/widgets/filter_panel.dart)
    - SearchScreen.applyRiskFilter() static (lib/screens/search_screen.dart)
    - SearchScreen.applyBrandFilter() static (lib/screens/search_screen.dart)
    - SearchScreen.applyReadFilter() static (lib/screens/search_screen.dart)
    - Persistance filtres SharedPreferences 'active_filters'
  affects:
    - lib/screens/search_screen.dart (augmenté avec FilterPanel + persistance)
    - test/filter_logic_test.dart (stubs → 19 vrais tests)
tech_stack:
  added: []
  patterns:
    - FilterState immuable value object (copyWith pattern)
    - toJson/fromJson pour persistance locale (SharedPreferences)
    - Méthodes statiques publiques sur StatefulWidget pour testabilité
    - DraggableScrollableSheet (bottom sheet scrollable)
    - showModalBottomSheet isScrollControlled transparent
    - OR logic pour filtres multi-valeurs (risque)
    - Chips actifs scrollables horizontalement avec × individuel
key_files:
  created:
    - lib/widgets/filter_panel.dart
  modified:
    - lib/screens/search_screen.dart
    - test/filter_logic_test.dart
decisions:
  - "Méthodes applyRiskFilter/applyBrandFilter/applyReadFilter déclarées static sur la classe publique SearchScreen (pas _SearchScreenState) pour être testables directement sans widget test"
  - "_readIds conservé comme Set vide dans Plan 2 — Plan 4 (ReadStatusService) le remplira via ReadStatusService.getReadIds()"
  - "locale: const Locale('fr', 'FR') retiré du showDateRangePicker — flutter_localizations non inclus per CONTEXT.md (aucune nouvelle dépendance pub). Le picker fonctionne en anglais pour l'instant."
  - "import flutter/material.dart ajouté dans filter_logic_test.dart pour accéder à DateTimeRange dans les tests"
metrics:
  duration: "15 minutes"
  completed: "2026-06-17T15:45:00Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 2
requirements:
  - SRCH-04
  - SRCH-05
  - SRCH-06
  - SRCH-08
---

# Phase 1 Plan 2: FilterPanel + Filtres Avancés + Persistance — Summary

FilterPanel widget réutilisable (DraggableScrollableSheet, 4 sections : Risque/Période/Marque/Statut) + FilterState value object immuable avec toJson/fromJson, intégré dans SearchScreen avec persistance SharedPreferences et 19 tests unitaires de la logique de filtrage.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Créer FilterPanel widget + FilterState avec Statut + persistance | d196c78 | lib/widgets/filter_panel.dart |
| 2 | Intégrer FilterPanel dans SearchScreen + persistance filtres + tests filter_logic | b73dd34 | lib/screens/search_screen.dart, test/filter_logic_test.dart |

## Deliverables

### FilterState (`lib/widgets/filter_panel.dart`)
- Value object immuable avec `riskLevels` (Set<String>), `dateDays`, `customDateRange`, `brandKeyword`, `readFilter`
- `hasActiveFilters` getter pour badge et affichage chips actifs
- `apiDateFrom` / `apiDateTo` calculés en format `YYYY-MM-DD` pour l'API
- `copyWith` avec flags `clearDateDays` / `clearCustomDateRange` pour mutation immuable
- `toJson` / `fromJson` pour persistance SharedPreferences (customDateRange non sérialisé — reset entre sessions)
- `FilterState.empty` constante

### FilterPanel (`lib/widgets/filter_panel.dart`)
- `DraggableScrollableSheet` (0.65 initial, 0.4 min, 0.9 max)
- Section **Niveau de risque** : FilterChip Grave / Modéré / Faible (multi-select)
- Section **Période** : FilterChip 7j / 30j / 90j / Personnalisé (exclusif, DateRangePicker)
- Section **Marque / mot-clé** : TextField outlined 14px
- Section **Statut** : FilterChip Tout / Non lus / Lus (locked decision CONTEXT.md)
- Bouton Réinitialiser + FilledButton "Appliquer les filtres"
- `onApply(FilterState)` callback + `onReset` callback

### SearchScreen (`lib/screens/search_screen.dart`)
- **3 méthodes statiques publiques** : `applyRiskFilter`, `applyBrandFilter`, `applyReadFilter`
- `applyRiskFilter` : OR logic sur `risques_encourus` (grave/sérieux/élevé + variantes sans accent)
- `applyBrandFilter` : `contains` case-insensitive sur `marque_produit` ou `nom_marque`
- `applyReadFilter` : filtre 'all'/'unread'/'read' via `readIds` Set passé en paramètre
- `_loadPersistedFilters()` dans `initState` : charge depuis SharedPreferences avec try/catch (T-1-13)
- `_applyFiltersAndSearch()` : sauvegarde filtres + appel API (dateFrom/dateTo) + filtres client-side
- `_openFilterPanel()` : `showModalBottomSheet` avec FilterPanel
- Badge point bleu sur `Icons.tune` quand `_activeFilters.hasActiveFilters`
- `_buildActiveFilterChips()` : chips scrollables avec × par filtre actif
- Chips actifs affichés sous la ligne sort chips dans `_buildResultsList`

### Tests (`test/filter_logic_test.dart`)
- 19 tests réels (0 stubs restants de Wave 0)
- 5 groupes : applyRiskFilter, applyBrandFilter, applyReadFilter, FilterState.apiDateFrom, FilterState.toJson/fromJson
- Couverture : OR logic, case-insensitive, accents, readIds vide, round-trip JSON, hasActiveFilters

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] prefer_final_fields sur `_readIds`**
- **Found during:** Tâche 2 — flutter analyze
- **Issue:** `Set<String> _readIds = {}` déclenchait un info `prefer_final_fields` car jamais modifié en Plan 2
- **Fix:** Changé en `final Set<String> _readIds = {}` — documenté comme placeholder Plan 4
- **Files modified:** lib/screens/search_screen.dart
- **Commit:** b73dd34

**2. [Rule 1 - Bug] `DateTimeRange` non disponible dans les tests sans import Flutter**
- **Found during:** Tâche 2 — `flutter test` — compilation error
- **Issue:** `filter_logic_test.dart` utilise `DateTimeRange` qui est une classe Flutter Material — pas automatiquement disponible dans les tests unitaires
- **Fix:** Ajout de `import 'package:flutter/material.dart';` dans filter_logic_test.dart
- **Files modified:** test/filter_logic_test.dart
- **Commit:** b73dd34

### Not deviating

- `locale: const Locale('fr', 'FR')` dans `showDateRangePicker` omis volontairement — `flutter_localizations` n'est pas dans les dépendances et CONTEXT.md interdit les nouvelles dépendances pub. Le DateRangePicker affiche en anglais pour l'instant.
- La chaîne `'active_filters'` n'apparaît qu'une fois (dans la constante `_activeFiltersKey`) : conforme aux bonnes pratiques Dart, utilisée via la constante à 4 endroits (définition, load, save, remove).

## Known Stubs

| Stub | Fichier | Ligne | Résolution |
|------|---------|-------|------------|
| `_readIds` toujours Set vide (filtre Statut sans données réelles) | search_screen.dart | ~96 | Plan 4 : ReadStatusService.getReadIds() remplira ce Set |
| `isRead` toujours false dans les cartes | search_screen.dart | ~521 | Plan 4 : connecter à ReadStatusService |

Ces stubs n'empêchent pas la fonctionnalité du plan : le filtre Statut fonctionne logiquement (applyReadFilter passe les tests), mais avec `_readIds` vide, le filtre "Lus" retourne toujours 0 résultats jusqu'à Plan 4.

## Threat Surface Scan

T-1-13 (Tampering — SharedPreferences → fromJson) : mitigé — `try/catch` autour de `jsonDecode` dans `_loadPersistedFilters()` (search_screen.dart:119-125). Filtre corrompu ignoré, état reset à `FilterState.empty`.

T-1-05 (Tampering — FilterState.apiDateFrom) : mitigé — dates calculées depuis `DateTime.now()` et `DateTimeRange` contrôlé Flutter, pas d'entrée libre utilisateur dans le calcul.

Aucune nouvelle surface de sécurité introduite au-delà du threat model du plan.

## Self-Check: PASSED

### Fichiers créés/modifiés — vérification

- lib/widgets/filter_panel.dart : FOUND
- lib/screens/search_screen.dart : FOUND (modifié)
- test/filter_logic_test.dart : FOUND (modifié — 9 stubs → 19 tests réels)

### Commits — vérification

- d196c78 (feat FilterPanel + FilterState) : FOUND
- b73dd34 (feat SearchScreen + tests) : FOUND

### Critères de succès

- [x] filter_panel.dart existe avec FilterState (readFilter, toJson/fromJson, apiDateFrom/apiDateTo/hasActiveFilters)
- [x] FilterPanel avec section Statut (Tout / Non lus / Lus) — locked decision CONTEXT.md
- [x] SearchScreen affiche bouton filtres avec badge point bleu quand filtres actifs
- [x] showModalBottomSheet ouvre FilterPanel avec 4 sections
- [x] Chips actifs scrollables sous la SearchBar avec × individuel
- [x] Filtres persistés via SharedPreferences 'active_filters' (load initState + save _applyFiltersAndSearch)
- [x] Méthodes statiques sur SearchScreen public : applyRiskFilter, applyBrandFilter, applyReadFilter
- [x] flutter test test/filter_logic_test.dart passe à 100% (19 tests, 0 stubs)
- [x] flutter analyze : 0 erreurs sur filter_panel.dart et search_screen.dart
