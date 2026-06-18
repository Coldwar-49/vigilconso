---
phase: 01-recherche-filtres
verified: 2026-06-18T00:00:00Z
status: human_needed
score: 5/5
must_haves_verified: 5
must_haves_total: 5
human_verification:
  - test: "Taper 'Nutella' dans la SearchBar de HomeScreen et observer le résultat"
    expected: "SearchScreen s'ouvre, les résultats de toutes les catégories apparaissent en moins de 3 secondes"
    why_human: "Latence réseau réelle vers l'API RappelConso gouvernementale non testable sans appareil"
  - test: "Taper 'Nu' dans la SearchBar de SearchScreen et attendre 300ms"
    expected: "Un overlay de suggestions de marques apparaît (ex: 'Nutella', 'Nutrexpa'...)"
    why_human: "Appel HTTP live vers l'API gouvernementale requis — non testable par grep"
  - test: "Soumettre 'Nutella', revenir en arrière, rouvrir SearchScreen"
    expected: "'Nutella' apparaît dans la section 'Recherches récentes'"
    why_human: "Comportement SharedPreferences persistant nécessite un appareil réel ou émulateur"
  - test: "Activer le filtre 'Grave' dans FilterPanel et appuyer 'Appliquer les filtres'"
    expected: "La liste se réduit aux rappels avec niveau de risque grave ; un chip 'Grave' apparaît sous la SearchBar"
    why_human: "Rendu visuel et filtrage client-side sur données réelles API nécessite un appareil"
  - test: "Tapper sur une carte rappel depuis SearchScreen, puis revenir"
    expected: "Le badge 'NON LU' a disparu sur cette carte ; à la prochaine session le badge reste absent"
    why_human: "Optimistic update + persistance SharedPreferences 'read_rappels' nécessitent appareil réel"
---

# Phase 1 Verification: Recherche & Filtres

**Phase Goal:** L'utilisateur peut trouver n'importe quel rappel en quelques secondes — recherche globale, filtres, historique, tri.
**Verified:** 2026-06-18
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

All 5 roadmap success criteria have substantive code implementations verified in the actual source files. The automated test suite (35/35 passing) confirms correctness of the pure-logic layers. Human verification is required only for on-device behavior (network latency, visual rendering, SharedPreferences persistence across sessions).

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | L'utilisateur peut chercher "Nutella" et voir les résultats de toutes les catégories en moins de 3 secondes | ? UNCERTAIN | `search_screen.dart:284` calls `RappelService.fetchRappels(categoryKey: 'all', searchQuery: q)`. HomeScreen wired at `home_screen.dart:131`. Speed depends on live API — needs device test |
| 2 | En tapant dans la barre de recherche, des suggestions apparaissent après 2 caractères | ? UNCERTAIN | `search_screen.dart:165-188` implements `_onSearchChanged` with `Timer(Duration(milliseconds:300))` debounce calling `RappelService.fetchSuggestions`. Logic is correct; live API response needs device test |
| 3 | Les recherches récentes sont visibles et cliquables dans l'historique | ? UNCERTAIN | `SearchHistoryService` (LIFO, max 10, dedup) verified in 6/6 tests. `_buildIdleState` at `search_screen.dart:994-1090` renders history list with onTap. Persistence needs device test |
| 4 | Les filtres (risque, date, marque) réduisent visiblement les résultats de la liste | ? UNCERTAIN | `applyRiskFilter/applyBrandFilter/applyReadFilter` verified in 19/19 tests. `FilterPanel` at `filter_panel.dart` has all 4 sections. `_applyFiltersAndSearch` wires results. Visual reduction needs device test |
| 5 | Un rappel peut être marqué lu/non-lu avec persistance entre sessions | ? UNCERTAIN | `ReadStatusService` verified in 10/10 tests. `rappel_details_page.dart:29-35` calls `_markAsRead()` in initState. `search_screen.dart:580,640-642` shows badge and optimistic update. Persistence needs device test |

**Score:** 5/5 truths have complete code implementations. All are UNCERTAIN only due to network/device requirements, not missing code.

## Requirement Traceability

| Requirement | Description | Plan | Status | Evidence |
|-------------|-------------|------|--------|----------|
| SRCH-01 | Recherche globale toutes catégories | Plan 1 | VERIFIED | `search_screen.dart:284` — `fetchRappels(categoryKey:'all')` |
| SRCH-02 | Suggestions d'autocomplétion | Plan 3 | VERIFIED | `search_screen.dart:175-188` — debounce 300ms + `RappelService.fetchSuggestions` |
| SRCH-03 | Historique de recherche | Plan 3 | VERIFIED | `SearchHistoryService` — LIFO/max10/dedup; idle state renders history list |
| SRCH-04 | Filtre par niveau de risque | Plan 2 | VERIFIED | `SearchScreen.applyRiskFilter` static — OR logic on `risques_encourus`; FilterPanel Grave/Modéré/Faible chips |
| SRCH-05 | Filtre par plage de dates | Plan 2 | VERIFIED | `FilterPanel` période chips (7j/30j/90j/Personnalisé); `FilterState.apiDateFrom/apiDateTo` passed to API |
| SRCH-06 | Filtre par marque / mot-clé | Plan 2 | VERIFIED | `SearchScreen.applyBrandFilter` — case-insensitive contains on `marque_produit` |
| SRCH-07 | Statut lu/non-lu | Plan 4 | VERIFIED | `ReadStatusService` — markAsRead/isRead/getUnreadCount; badge NON LU in SearchScreen + RappelScreen |
| SRCH-08 | Tri par date (récent/ancien) | Plan 2 | VERIFIED | `_toggleSort` at `search_screen.dart:322-333` — in-memory sort using `RappelService.parseDate` |
| UX-01 | Cartes style Google News | Plan 1 | VERIFIED | `_buildRappelCard` in `search_screen.dart:568-812` — image droite, texte gauche, badges |

All 9 requirements claimed by Phase 1 plans have implementation evidence in the source files.

## Must-Haves Check

### Plan 1 Must-Haves

| Must-Have | Status | Evidence |
|-----------|--------|----------|
| HomeScreen SearchBar navigue vers SearchScreen | VERIFIED | `home_screen.dart:131` — `SearchScreen(initialQuery: q)` |
| SearchScreen appelle RappelService.fetchRappels(categoryKey:'all') | VERIFIED | `search_screen.dart:284` |
| Carte identique visuellement à rappel_screen.dart | VERIFIED | `_buildRappelCard` copied with same Google News layout |
| Champ risque utilise 'risques_encourus' (pas '..._par_le_consommateur') | VERIFIED | `search_screen.dart:576-577`; `rappel_screen.dart:258`; no occurrence of `risques_encourus_par_le_consommateur` found |
| 6 shimmer cards en état de chargement | VERIFIED | `search_screen.dart:986-992` — `itemCount: 6` |
| Stubs de tests Wave 0 exécutent sans erreur fatale | VERIFIED | Upgraded to real tests — 35/35 passing |

### Plan 2 Must-Haves

| Must-Have | Status | Evidence |
|-----------|--------|----------|
| Panel filtres depuis icône tune | VERIFIED | `search_screen.dart:908-927` — `Icons.tune` with `_openFilterPanel` |
| FilterChip Grave/Modéré/Faible OR logic | VERIFIED | 4 tests passing in `test/filter_logic_test.dart` |
| Chips période 7j/30j/90j/Personnalisé → DateRangePicker | VERIFIED | `filter_panel.dart:199-325` |
| Filtre marque case-insensitive sur marque_produit | VERIFIED | 3 tests passing for `applyBrandFilter` |
| Section Statut (Tout/Non lus/Lus) | VERIFIED | `filter_panel.dart:223-234` — `_readFilterChip` chips |
| Tri Récent/Ancien en mémoire sans appel API | VERIFIED | `_toggleSort` at `search_screen.dart:322-333` |
| Chips actifs scrollables avec × | VERIFIED | `search_screen.dart:344-416` — `_buildActiveFilterChips` with `_activeChip` |
| Filtres persistés SharedPreferences 'active_filters' | VERIFIED | `search_screen.dart:142-153` (load) and `194-196` (save) |
| Tests filter_logic_test.dart passent | VERIFIED | 19/19 tests passing |

### Plan 3 Must-Haves

| Must-Have | Status | Evidence |
|-----------|--------|----------|
| Suggestions après 2+ chars en 300ms | VERIFIED (logic) | `search_screen.dart:165-188` — debounce Timer 300ms |
| Suggestions via RappelService.fetchSuggestions | VERIFIED | `search_screen.dart:182` — no raw http.get in screen |
| Tap suggestion soumet immédiatement | VERIFIED | `search_screen.dart:965-969` — onTap calls `_performSearch` |
| Historique 10 recherches dans idle state | VERIFIED | `SearchHistoryService._maxHistory=10`; `_buildIdleState` renders list |
| Historique persisté SharedPreferences 'search_history' | VERIFIED | `search_history_service.dart:4` — `_historyKey = 'search_history'` |
| Entrées historique cliquables → recherche | VERIFIED | `search_screen.dart:1083` — `onTap: () => _performSearch(query)` |
| Bouton 'Effacer l'historique' avec confirmation inline 3s | VERIFIED | `search_screen.dart:1028-1062` — `_confirmingClearHistory` state + `Timer(Duration(seconds:3))` |
| Tests search_history_service_test.dart passent | VERIFIED | 6/6 tests passing |

### Plan 4 Must-Haves

| Must-Have | Status | Evidence |
|-----------|--------|----------|
| Badge 'NON LU' sur carte (9px, w800, cs.primary) | VERIFIED | `search_screen.dart:658-676` — fontSize:9, FontWeight.w800, color:cs.primary |
| Ouverture RappelDetailsPage marque automatiquement comme lu | VERIFIED | `rappel_details_page.dart:29,32-35` — `_markAsRead()` in initState |
| Badge disparaît au retour (optimistic update) | VERIFIED | `search_screen.dart:639-643` — `setState(() => _readIds = {..._readIds, id})` on tap |
| Persistance lu/non-lu entre sessions | VERIFIED (logic) | `ReadStatusService` with `'read_rappels'` SharedPreferences key |
| ID unique: reference_fiche ?? libelle ?? numero_fiche | VERIFIED | `read_status_service.dart:10-14` — `getRappelId` priority chain |
| Semantics label inclut 'non lu' si non lu | VERIFIED | `search_screen.dart:637` — `${isRead ? '' : ', non lu'}` |
| Tests read_status_service_test.dart passent | VERIFIED | 10/10 tests passing |

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/screens/search_screen.dart` | SearchScreen StatefulWidget | VERIFIED | 1219 lines — substantive, fully wired |
| `lib/widgets/filter_panel.dart` | FilterPanel + FilterState | VERIFIED | 353 lines — DraggableScrollableSheet, 4 sections, toJson/fromJson |
| `lib/services/search_history_service.dart` | SearchHistoryService LIFO max 10 | VERIFIED | 28 lines — getHistory/addToHistory/clearHistory |
| `lib/services/read_status_service.dart` | ReadStatusService markAsRead/isRead | VERIFIED | 53 lines — markAsRead/isRead/getUnreadCount/getRappelId |
| `lib/services/rappel_service.dart` | fetchRappels dateFrom/dateTo + fetchSuggestions | VERIFIED | dateFrom/dateTo at line 27-28; fetchSuggestions at line 180 |
| `lib/screens/home_screen.dart` | Navigation vers SearchScreen | VERIFIED | Line 131: `SearchScreen(initialQuery: q)` |
| `lib/screens/rappel_details_page.dart` | ReadStatusService.markAsRead in initState | VERIFIED | Lines 29,32-35 |
| `lib/screens/rappel_screen.dart` | Badge NON LU + RappelService delegation | VERIFIED | Line 258: `risques_encourus`; line 83: `RappelService.fetchRappels`; line 336: 'NON LU' |
| `test/filter_logic_test.dart` | 19 real tests | VERIFIED | 19/19 passing |
| `test/search_history_service_test.dart` | 6 real tests | VERIFIED | 6/6 passing |
| `test/read_status_service_test.dart` | 10 real tests | VERIFIED | 10/10 passing |

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `home_screen.dart` | `search_screen.dart` | `Navigator.push` in `_submitSearch` | WIRED | `home_screen.dart:131` — `SearchScreen(initialQuery: q)` |
| `search_screen.dart` | `rappel_service.dart` | `RappelService.fetchRappels(categoryKey:'all')` | WIRED | `search_screen.dart:284` |
| `search_screen.dart` | `filter_panel.dart` | `showModalBottomSheet` returning `FilterState` | WIRED | `search_screen.dart:246-265` — `FilterPanel(initialState:, onApply:, onReset:)` |
| `search_screen.dart` | `rappel_service.dart` | `RappelService.fetchSuggestions(prefix)` with debounce | WIRED | `search_screen.dart:175,182` — Timer 300ms |
| `search_screen.dart` | `search_history_service.dart` | `SearchHistoryService.addToHistory()` after submit | WIRED | `search_screen.dart:274` |
| `rappel_details_page.dart` | `read_status_service.dart` | `ReadStatusService.markAsRead(id)` in initState | WIRED | `rappel_details_page.dart:29,35` |
| `search_screen.dart` | `read_status_service.dart` | `_readIds` cache populated by `_loadReadStatus()` | WIRED | `search_screen.dart:155-158`, `311`, `232` |
| `home_screen.dart` | `read_status_service.dart` | `ReadStatusService.getUnreadCount` → `newAlertsNotifier` | WIRED | `home_screen.dart:72` |
| `SharedPreferences 'active_filters'` | `_activeFilters` state | `FilterState.fromJson/toJson` in initState / _applyFiltersAndSearch | WIRED | `search_screen.dart:142-153`, `194-196` |
| `SharedPreferences 'read_rappels'` | `_readIds` Set | `ReadStatusService.getReadIds()` in `_loadReadStatus` | WIRED | `search_screen.dart:155-158` |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `search_screen.dart` `_buildResultsList` | `_filteredResults` | `RappelService.fetchRappels` → `_performSearch` | YES — API call with `searchQuery` | FLOWING |
| `search_screen.dart` `_buildIdleState` | `_searchHistory` | `SearchHistoryService.getHistory()` → `_loadHistory()` | YES — reads SharedPreferences `search_history` | FLOWING |
| `search_screen.dart` `_buildBody` suggestions | `_suggestions` | `RappelService.fetchSuggestions(prefix)` | YES — live API call with prefix | FLOWING |
| `filter_panel.dart` `_readFilterChip` | `_readFilter` | `FilterState.readFilter` from `widget.initialState` | YES — initialized from `_activeFilters` in SearchScreen | FLOWING |
| `search_screen.dart` `_buildRappelCard` | `isRead` / badge | `_readIds` ← `ReadStatusService.getReadIds()` | YES — reads SharedPreferences `read_rappels` | FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| 35 unit tests pass | `flutter test test/filter_logic_test.dart test/search_history_service_test.dart test/read_status_service_test.dart` | 35/35 passed | PASS |
| No `risques_encourus_par_le_consommateur` in rappel_screen.dart | grep | 0 occurrences | PASS |
| No `http.get` in rappel_screen.dart | grep | 0 occurrences | PASS |
| `RappelService.fetchRappels` called in rappel_screen.dart | grep | line 83 | PASS |
| `SearchScreen` wired in home_screen.dart | grep | line 131 | PASS |
| `ReadStatusService.markAsRead` called in rappel_details_page.dart | grep | lines 29,35 | PASS |
| `ReadStatusService.getUnreadCount` called in home_screen.dart | grep | line 72 | PASS |
| Badge 'NON LU' present in search_screen.dart | grep | lines 658-676 | PASS |
| Badge 'NON LU' present in rappel_screen.dart | grep | line 336 | PASS |
| Debounce 300ms in search_screen.dart | grep | line 175 | PASS |

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SRCH-01 | Plan 1 | Recherche globale toutes catégories | SATISFIED | `fetchRappels(categoryKey:'all')` in search_screen.dart:284 |
| SRCH-02 | Plan 3 | Suggestions d'autocomplétion | SATISFIED | `fetchSuggestions` + debounce 300ms |
| SRCH-03 | Plan 3 | Historique de recherche | SATISFIED | `SearchHistoryService` + `_buildIdleState` |
| SRCH-04 | Plan 2 | Filtre par niveau de risque | SATISFIED | `applyRiskFilter` + FilterPanel chips |
| SRCH-05 | Plan 2 | Filtre par plage de dates | SATISFIED | `apiDateFrom/apiDateTo` + période chips |
| SRCH-06 | Plan 2 | Filtre par marque/mot-clé | SATISFIED | `applyBrandFilter` + brandKeyword TextField |
| SRCH-07 | Plan 4 | Statut lu/non-lu | SATISFIED | `ReadStatusService` + badge NON LU + auto-mark |
| SRCH-08 | Plan 2 | Tri par date | SATISFIED | `_toggleSort` in-memory sort |
| UX-01 | Plan 1 | Cartes style Google News | SATISFIED | `_buildRappelCard` — image right, text left |

No orphaned requirements found for Phase 1.

## Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `search_screen.dart` | `// ignore: prefer_final_fields` comment on `_readIds` | INFO | Intentional — documented as needed for Plan 4 `setState(() => _readIds = ids)`. Plan 4 implemented; the ignore comment is now harmless but could be cleaned up |
| `filter_panel.dart` | `locale:` param omitted from `showDateRangePicker` | INFO | DateRangePicker displays in English instead of French. `flutter_localizations` not added per CONTEXT.md constraint (no new pub deps). Acceptable for Phase 1 |

No BLOCKER anti-patterns found. No TODO/FIXME/placeholder patterns indicating incomplete behavior. No `return null` / `return []` stubs in rendering paths.

## Human Verification Required

### 1. Recherche globale "Nutella" en moins de 3 secondes

**Test:** Taper "Nutella" dans la SearchBar de HomeScreen et soumettre
**Expected:** SearchScreen s'ouvre, les résultats apparaissent depuis toutes catégories en moins de 3 secondes
**Why human:** Latence API RappelConso gouvernementale varie selon le réseau — non testable par grep

### 2. Autocomplétion après 2 caractères

**Test:** Dans SearchScreen, taper "Nu" dans la barre et attendre 300ms
**Expected:** Un overlay de suggestions de marques apparaît (ex: "Nutella", "Nutrexpa"...)
**Why human:** `RappelService.fetchSuggestions` fait un appel HTTP live — la présence de données retournées dépend de l'API

### 3. Historique persistant entre sessions

**Test:** Chercher "Nutella", fermer l'app, rouvrir, ouvrir SearchScreen
**Expected:** "Nutella" apparaît dans la liste des recherches récentes
**Why human:** Persistance SharedPreferences entre sessions nécessite arrêt/relance réelle de l'app

### 4. Filtres réduisent visiblement les résultats

**Test:** Chercher "rappel", ouvrir FilterPanel, sélectionner "Grave", appuyer "Appliquer les filtres"
**Expected:** La liste se réduit aux rappels graves ; un chip "Grave" apparaît sous la SearchBar
**Why human:** Filtrage sur données API réelles — le nombre de résultats dépend de l'état actuel de l'API

### 5. Badge NON LU disparaît et persiste

**Test:** Chercher des rappels, ouvrir une fiche (RappelDetailsPage), revenir à SearchScreen
**Expected:** Le badge "NON LU" a disparu sur cette fiche ; relancer l'app confirme la persistance
**Why human:** Optimistic update visuel + persistance SharedPreferences 'read_rappels' nécessitent un appareil

## Gaps Summary

No code gaps found. All 5 roadmap success criteria are implemented substantively and wired end-to-end. The 35 automated tests covering FilterState, applyRiskFilter/applyBrandFilter/applyReadFilter, SearchHistoryService, and ReadStatusService all pass. The `human_needed` status reflects that 5 behaviors require on-device/emulator validation with live API calls or session-crossing persistence — not that code is missing.

---

_Verified: 2026-06-18_
_Verifier: Claude (gsd-verifier)_
