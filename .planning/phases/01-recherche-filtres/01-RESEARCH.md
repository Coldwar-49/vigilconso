# Phase 1: Recherche & Filtres - Research

**Researched:** 2026-06-16
**Domain:** Flutter search UX, SharedPreferences persistence, RappelConso API v2.1
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SRCH-01 | Recherche globale toutes catégories (améliorer l'existant) | `RappelService.fetchRappels(categoryKey:'all', searchQuery:q)` couvre déjà cela — il suffit de câbler l'écran dédié et corriger le bypass de cache dans `rappel_screen.dart` |
| SRCH-02 | Suggestions / autocomplétion marques et produits | L'API supporte `search(marque_produit,"<prefix>")` + `group_by=marque_produit` — données live ou depuis cache local en mémoire |
| SRCH-03 | Historique des recherches récentes | SharedPreferences clé `search_history` — liste JSON de strings (max 10 entrées) |
| SRCH-04 | Filtre par niveau de risque | Champ API `risques_encourus` — filtre côté client sur les résultats déjà chargés; pas besoin d'appel API supplémentaire |
| SRCH-05 | Filtre par plage de dates | `date_publication >= "YYYY-MM-DD"` — déjà utilisé dans `RappelService`; ajouter des presets 7j/30j/90j |
| SRCH-06 | Filtre par marque / mot-clé | `marque_produit like "%<q>%"` — déjà dans la logique de `searchRappels` |
| SRCH-07 | Statut lu / non-lu | SharedPreferences clé `read_rappels` — Set de `reference_fiche` sérialisé en JSON; badge visuel sur la carte |
| SRCH-08 | Tri des listes (date + pertinence) | Tri local déjà implémenté dans `RappelService._parseDate` + sort; ajouter un troisième critère "pertinence" (résultats de recherche non-réordonnés) |
| UX-01 | Cartes style Google News | **Livré** — implémenté dans `rappel_screen.dart` `_buildRappelCard()` |
</phase_requirements>

---

## Summary

Phase 1 est principalement du travail de **câblage Flutter** plus que d'intégration de nouvelles dépendances. Le coeur API (`RappelService`), la persistance (`SharedPreferences`), et la carte Google News (`RappelListScreen._buildRappelCard`) existent déjà. Ce qui manque : un écran de recherche dédié, un panel de filtres, la persistance de l'historique et du statut lu/non-lu.

La recherche globale (SRCH-01) est bloquée par un anti-pattern documenté : `RappelListScreen._fetchRappels()` fait ses propres appels HTTP en bypass du cache de `RappelService`. Corriger ce bypass est le prérequis de toutes les autres tâches de recherche. Une fois ce correctif en place, l'écran dédié et les filtres s'ajoutent proprement dessus.

L'autocomplétion (SRCH-02) peut utiliser l'endpoint API `search(marque_produit,"<prefix>")` + `group_by=marque_produit` — confirmé en tests live sur l'API gouvernementale. La stratégie recommandée est un debounce de 300 ms + limite à 8 suggestions, sans package externe.

**Recommandation principale :** 4 tâches séquentielles — (1) corriger le bypass + global search, (2) panel filtres + tri, (3) historique + autocomplétion, (4) statut lu/non-lu.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Recherche globale (SRCH-01) | Service Layer (RappelService) | Presentation (SearchScreen) | La logique de construction de requête API appartient au service; l'écran gère le cycle setState |
| Autocomplétion (SRCH-02) | Service Layer (RappelService) | Presentation (SearchScreen) | Appel API dédié avec debounce géré dans l'écran |
| Historique recherches (SRCH-03) | Service Layer (nouveau SearchHistoryService) | Presentation (SearchScreen) | Isolation SharedPreferences dans un service dédié |
| Filtres risque/date/marque (SRCH-04/05/06) | Presentation Layer | Service Layer | Filtres date → paramètre API where; filtres risque → filtrage client des résultats en mémoire |
| Statut lu/non-lu (SRCH-07) | Service Layer (nouveau ReadStatusService) | Presentation (cartes) | Persistance SharedPreferences; badge visuel dans la carte |
| Tri (SRCH-08) | Service Layer (RappelService) | Presentation (chips de tri) | Le tri est déjà dans RappelService; l'écran expose les options |

---

## Standard Stack

### Core (déjà dans pubspec.yaml — aucune installation nécessaire)

| Library | Version résolue | Purpose | Why Standard |
|---------|-----------------|---------|--------------|
| `shared_preferences` | 2.x | Historique recherches, statut lu/non-lu | Déjà utilisé dans tout le projet pour la persistance légère |
| `flutter` SDK | 3.41.6 | `SearchBar` Material 3, `Chip`, `FilterChip`, `DateRangePicker` | Tous les widgets nécessaires sont dans Material 3 |
| `intl` | 0.20.2 | Format des dates de filtre (DateFormat français) | Déjà importé |
| `http` | 1.x | Appels API autocomplétion | Déjà utilisé dans RappelService |

[VERIFIED: pubspec.lock + `dart pub deps`]

### Aucune nouvelle dépendance requise

Tous les besoins de Phase 1 sont couverts par le stack existant. L'autocomplétion ne nécessite pas de package dédié (ex: `flutter_typeahead`) — un `ListView` positionné au-dessus du champ de recherche est suffisant et cohérent avec le style actuel. [ASSUMED — basé sur l'analyse des requirements + widgets Flutter disponibles]

### Alternatives considérées

| Besoin | Alternative externe | Pourquoi rejeter |
|--------|--------------------|--------------------|
| Autocomplétion | `flutter_typeahead` | Ajoute une dépendance pour un widget Material 3 natif (`SearchBar` + `Overlay`) suffit |
| Historique | SQLite/Drift | Overkill — max 10 strings, SharedPreferences largement suffisant |
| Filtres de date | `date_range_picker` externe | `showDateRangePicker()` Flutter intégré fait l'affaire |

---

## Architecture Patterns

### Diagramme de flux — Recherche globale (SRCH-01)

```
[HomeScreen search bar]
         │ onSubmit(query)
         ▼
[SearchScreen] (nouveau fichier: lib/screens/search_screen.dart)
         │
         ├─── initState → _saveToHistory(query) → SharedPrefs
         │
         ├─── _performSearch()
         │       │
         │       ▼
         │    RappelService.fetchRappels(
         │      categoryKey: 'all',
         │      searchQuery: query,
         │      [dateFrom: filter, dateTo: filter],
         │      [riskFilter: filter]
         │    )
         │       │
         │       ▼
         │    API v2.1: GET /records?where=...&limit=100
         │       │
         │       ▼
         │    results → setState → ListView (Google News cards)
         │
         └─── _applyClientFilters(results)
                 │ filtre risque (client-side)
                 ▼
             _filteredRappels → affichage
```

### Diagramme de flux — Autocomplétion (SRCH-02)

```
[SearchBar] onChanged(value.length >= 2)
         │ debounce 300ms
         ▼
[SearchScreen._fetchSuggestions(prefix)]
         │
         ▼
API: /records?where=search(marque_produit,"<prefix>")
            &select=marque_produit
            &group_by=marque_produit
            &limit=8
         │
         ▼
[Overlay / ListView suggestions] — tap → _submitSearch(suggestion)
```

### Diagramme de flux — Statut lu/non-lu (SRCH-07)

```
[Card rappel] onTap
         │
         ├─── ReadStatusService.markAsRead(reference_fiche)
         │         → SharedPrefs: 'read_rappels' (JSON Set<String>)
         │
         └─── [RappelDetailsPage] s'ouvre
                   │
                   ▼
              Navigator.pop → carte rebuild → badge "NON LU" disparaît
```

### Structure de fichiers Phase 1

```
lib/
├── screens/
│   └── search_screen.dart          (NOUVEAU — écran recherche dédié)
├── services/
│   ├── search_history_service.dart  (NOUVEAU — CRUD historique SharedPrefs)
│   ├── read_status_service.dart     (NOUVEAU — lu/non-lu SharedPrefs)
│   └── rappel_service.dart          (MODIFIÉ — paramètres dateFrom/dateTo)
└── widgets/
    └── filter_panel.dart            (NOUVEAU — panel filtres réutilisable)
```

### Patterns Flutter utilisés

**Pattern 1 : `SearchBar` Material 3 avec suggestions en Overlay**

```dart
// Source: [VERIFIED — flutter.dev/docs/cookbook, Material 3 SearchBar]
// SearchBar est disponible depuis Flutter 3.7+; notre version est 3.41.6
SearchBar(
  controller: _searchController,
  onChanged: (v) {
    if (v.length >= 2) _debouncedFetchSuggestions(v);
    else setState(() => _suggestions = []);
  },
  onSubmitted: _submitSearch,
  leading: const Icon(Icons.search),
  trailing: [
    if (_searchController.text.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch),
  ],
)
```

**Pattern 2 : Debounce sans package (Timer)**

```dart
// [ASSUMED — pattern standard Dart, pas de package requis]
Timer? _debounce;
void _onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () {
    if (value.length >= 2) _fetchSuggestions(value);
  });
}
// dispose() → _debounce?.cancel();
```

**Pattern 3 : Historique SharedPreferences (max 10 entrées, LIFO)**

```dart
// [ASSUMED — pattern standard SharedPreferences]
static const String _historyKey = 'search_history';
static const int _maxHistory = 10;

static Future<void> addToHistory(String query) async {
  final prefs = await SharedPreferences.getInstance();
  final history = prefs.getStringList(_historyKey) ?? [];
  history.remove(query); // évite les doublons
  history.insert(0, query);
  if (history.length > _maxHistory) history.removeLast();
  await prefs.setStringList(_historyKey, history);
}
```

**Pattern 4 : Statut lu/non-lu avec Set<String>**

```dart
// [ASSUMED — pattern standard SharedPreferences pour Set]
static const String _readKey = 'read_rappels';

static Future<void> markAsRead(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_readKey) ?? [];
  final readSet = Set<String>.from(raw);
  readSet.add(id);
  await prefs.setStringList(_readKey, readSet.toList());
}

static Future<bool> isRead(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_readKey) ?? [];
  return raw.contains(id);
}
```

**Pattern 5 : FilterChip Material 3 pour les filtres actifs**

```dart
// [VERIFIED — Material 3 FilterChip, flutter.dev]
FilterChip(
  label: Text('Grave'),
  selected: _selectedRiskLevels.contains('grave'),
  onSelected: (v) => setState(() {
    v ? _selectedRiskLevels.add('grave') : _selectedRiskLevels.remove('grave');
    _applyFilters();
  }),
)
```

**Pattern 6 : DateRangePicker Flutter intégré (SRCH-05)**

```dart
// [VERIFIED — showDateRangePicker, flutter.dev Material]
final range = await showDateRangePicker(
  context: context,
  firstDate: DateTime(2020),
  lastDate: DateTime.now(),
  locale: const Locale('fr', 'FR'),
);
if (range != null) {
  setState(() => _dateRange = range);
  _applyFilters();
}
```

### Anti-Patterns à éviter

- **Appels HTTP dans les widgets directement :** Toute logique de requête passe par `RappelService` — c'est précisément l'anti-pattern déjà présent dans `rappel_screen.dart` qu'il faut corriger (SRCH-01 prérequis).
- **Appel API à chaque caractère :** L'autocomplétion DOIT avoir un debounce de 300 ms minimum — l'API gouvernementale n'a pas de rate limiting documenté mais les appels excessifs dégradent l'UX.
- **setState après dispose :** Toujours vérifier `if (mounted)` avant tout setState dans un callback async (déjà respecté dans le code existant).
- **Filtrer en re-fetchant à chaque changement :** Les filtres risque (SRCH-04) et marque (SRCH-06) s'appliquent en mémoire sur `_allResults` — pas de nouvel appel API.

---

## Don't Hand-Roll

| Problème | Ne pas construire | Utiliser plutôt | Pourquoi |
|----------|------------------|-----------------|----------|
| Sélecteur de plage de dates | DateRangePicker custom | `showDateRangePicker()` Flutter | Intégré, localisé, accessible, Material 3 |
| Chip de filtre sélectionnable | Container avec GestureDetector | `FilterChip` Material 3 | États selected/disabled gérés, thème cohérent |
| Barre de recherche avec suggestions | TextField + Overlay custom | `SearchBar` Material 3 (Flutter 3.7+) | Animation et focus management inclus |
| Persistance Set de strings | SQLite/Drift | `SharedPreferences.getStringList` | Largement suffisant pour < 1000 IDs |

---

## Common Pitfalls

### Pitfall 1 : Bypass du cache dans `rappel_screen.dart`

**Ce qui dysfonctionne :** `_RappelListScreenState._fetchRappels()` et `_searchRappels()` construisent leurs propres URLs HTTP et ne passent pas par `RappelService.fetchRappels()`. La recherche globale (categoryKey='all') ne bénéficie pas du cache 5 minutes.

**Cause racine :** La fonction a été dupliquée au lieu d'être déléguée au service.

**Correction :** Supprimer `_fetchRappels()` et `_searchRappels()` de `_RappelListScreenState` et appeler directement `RappelService.fetchRappels(categoryKey: widget.categoryKey, searchQuery: _searchQuery)`.

**Signe d'alerte :** Si les tests de recherche globale montrent des appels HTTP dupliqués dans les DevTools réseau.

### Pitfall 2 : `_parseDate` dupliquée — bug subtil de parsing

**Ce qui dysfonctionne :** `rappel_screen.dart` a une version de `_parseDate` avec une boucle `for (int annee = 2020...)` absente de `rappel_service.dart`. Les deux peuvent retourner des valeurs différentes pour la même date.

**Correction Phase 1 :** Utiliser exclusivement `RappelService._parseDate` (exposer comme static public si nécessaire, ou faire passer toutes les dates par le service).

**Note :** L'extraction vers `date_utils.dart` est prévue en Phase 2 — en Phase 1, unifier suffit.

### Pitfall 3 : `search()` vs `like` dans l'API

**Ce qui dysfonctionne :** `like "%<q>%"` cherche une sous-chaîne exacte. `search(field, "<q>")` fait une recherche plein-texte qui trouve aussi des correspondances partielles au début de mots.

**Cas concret :** `search(marque_produit, "carr")` retourne "carrefour" (confirmé en test live). `like "%carr%"` échoue avec `group_by` (API retourne 0 résultats dans nos tests — voir ci-dessous).

**Correction :** Pour l'autocomplétion (SRCH-02), utiliser `search(marque_produit, "<prefix>")` + `group_by=marque_produit`. Pour la recherche principale (SRCH-01), conserver `like "%<q>%"` qui est plus précis pour les correspondances exactes.

**Pourquoi :** [VERIFIED — tests live sur l'API 2026-06-16 : `search()` fonctionne avec `group_by`, `like` avec `group_by` retourne 0 résultats dans nos tests]

### Pitfall 4 : Champs API — nomenclature incohérente entre datasets

**Ce qui dysfonctionne :** `rappel_screen.dart` utilise `risques_encourus_par_le_consommateur` comme champ de risque, mais ce champ n'existe PAS dans `rappelconso-v2-gtin-espaces`. Le vrai champ est `risques_encourus`.

**Vérification live :**
- `select=risques_encourus_par_le_consommateur` → erreur API : "Unknown field"
- `select=risques_encourus` → fonctionne, retourne des valeurs comme "listeria monocytogenes...", "blessures", "risque chimique"

**Impact SRCH-04 :** Le filtre par niveau de risque doit utiliser `risques_encourus`, pas `risques_encourus_par_le_consommateur`.

**Correction :** Dans `_buildRappelCard` de `rappel_screen.dart`, changer `rappel['risques_encourus_par_le_consommateur']` en `rappel['risques_encourus']`.

[VERIFIED — test live API 2026-06-16]

### Pitfall 5 : `categorie_produit` — valeurs API différentes des clés internes

**Ce qui dysfonctionne :** Les valeurs réelles de `categorie_produit` dans l'API sont en minuscules et avec des accents spécifiques ("alimentation", "automobiles et moyens de déplacement", "bébés-enfants (hors alimentaire)"). Les filtres dans `AppConstants.getCategoryFilter()` utilisent `like "%Alimentation%"` avec capitale — cela fonctionne car `like` est case-insensitive dans l'API ODS.

**Impact :** Pas un bug actuel, mais à documenter pour les futurs filtres.

[VERIFIED — test live API : `facets?facet=categorie_produit` retourne les vraies valeurs]

### Pitfall 6 : Total results limité à 100 — impact sur la pertinence

**Ce qui dysfonctionne :** Toutes les requêtes actuelles ont `limit=100`. Si une recherche "lait" retourne 545 résultats (confirmé en test), l'utilisateur ne voit que les 100 premiers (pas forcément les plus pertinents car l'API ne fait pas de ranking de pertinence).

**Impact SRCH-08 :** Le tri "par pertinence" ne peut pas être implémenté côté API — l'API ODS ne supporte pas le ranking. "Pertinence" en pratique signifie "ordre de retour de l'API" (léxicographique sur l'ID), qui n'est pas utile.

**Recommandation :** Proposer uniquement tri "date décroissante" (défaut) et "date croissante" comme dans l'existant. Qualifier "pertinence" comme "ordre de publication API". [ASSUMED]

---

## API RappelConso — Faits Clés Vérifiés

| Fait | Valeur | Source |
|------|--------|--------|
| Total records | 17 860 (au 2026-06-16) | [VERIFIED — live API] |
| Records 2025+ | 4 829 | [VERIFIED — live API] |
| Champ risque | `risques_encourus` (PAS `risques_encourus_par_le_consommateur`) | [VERIFIED — live API] |
| Champ marque | `marque_produit` | [VERIFIED — live API] |
| Champ titre | `libelle` | [VERIFIED — live API] |
| Champ date | `date_publication` (format ISO 8601) | [VERIFIED — live API] |
| Facets disponibles | `categorie_produit`, `risques_encourus` | [VERIFIED — live API `facets` endpoint] |
| `search()` avec `group_by` | Fonctionne pour l'autocomplétion | [VERIFIED — live API] |
| `like "%..."` avec `group_by` | Ne retourne pas de résultats dans nos tests | [VERIFIED — live API] |
| Valeurs réelles de risque | "listeria monocytogenes...", "blessures", "risque chimique", "autres contaminants chimiques" (free-text, pas un enum) | [VERIFIED — live API facets] |
| Tri par date | `order_by=date_publication desc` fonctionne sur `fetchLatestRappels` | [VERIFIED — code existant + test live] |
| Catégories réelles API | "alimentation", "automobiles et moyens de déplacement", "bébés-enfants (hors alimentaire)", etc. | [VERIFIED — live API facets] |

**Implication majeure pour SRCH-04 (filtre risque) :** `risques_encourus` est du free-text, pas un enum "grave/modéré/faible". Le filtre de risque DOIT être implémenté en client-side avec une classification par mots-clés (comme `_riskColor()` dans `rappel_screen.dart` le fait déjà). Pas possible de filtrer directement sur l'API avec des valeurs structurées.

---

## Clés SharedPreferences Phase 1

| Clé | Type | Contenu | Service propriétaire |
|-----|------|---------|---------------------|
| `search_history` | `List<String>` | Max 10 dernières recherches (LIFO) | `SearchHistoryService` (nouveau) |
| `read_rappels` | `List<String>` | Set de `reference_fiche` des rappels lus | `ReadStatusService` (nouveau) |

**Clés existantes à ne pas modifier :**

| Clé | Usage actuel | Risque si modifiée |
|-----|-------------|-------------------|
| `favorites` | Favoris JSON | Casser `FavoritesScreen` |
| `cached_rappels_v4_<category>` | Cache API 5 min | Casser le fallback offline |
| `last_fetch_v4_<category>` | Timestamp cache | Casser la logique de fraîcheur |
| `last_seen_alert_date` | Badge nouvelles alertes | Casser le compteur HomeScreen |
| `onboarding_shown` | Onboarding gate | Casser le flux first-launch |

---

## State of the Art

| Ancienne approche | Approche actuelle | Impact |
|------------------|-------------------|--------|
| Recherche limitée à une catégorie | Recherche globale `categoryKey='all'` sans filtre catégorie | Débloque SRCH-01 |
| `_fetchRappels()` HTTP direct dans l'écran | Délégation à `RappelService.fetchRappels()` | Élimine l'anti-pattern et active le cache |
| Pas de suggestions | `search()` API + debounce 300ms | SRCH-02 |
| Pas d'historique | `SharedPreferences.getStringList` LIFO | SRCH-03 |

---

## Assumptions Log

| # | Claim | Section | Risque si faux |
|---|-------|---------|----------------|
| A1 | `SearchBar` Material 3 (Flutter 3.7+) est disponible sans configuration supplémentaire dans Flutter 3.41.6 | Standard Stack | Faible — Flutter 3.41.6 est bien > 3.7 |
| A2 | Le filtre risque doit être client-side car `risques_encourus` est free-text | Common Pitfalls / SRCH-04 | Faible — confirmé par inspection des vraies valeurs API |
| A3 | "Pertinence" pour SRCH-08 est assimilable à "ordre de l'API" (pas de ranking serveur) | Common Pitfalls / SRCH-08 | Moyen — si l'utilisateur attend un vrai ranking de pertinence, il faudra implémenter un scoring local |
| A4 | Max 10 entrées dans l'historique de recherche est suffisant | Architecture Patterns | Faible — modifiable facilement |
| A5 | Un `Overlay` Flutter standard suffit pour les suggestions (pas de `flutter_typeahead`) | Don't Hand-Roll | Faible — pattern bien établi |
| A6 | `ReadStatusService` utilise `reference_fiche` comme identifiant unique | Architecture Patterns | Moyen — vérifier que `reference_fiche` est toujours présent dans les résultats API; fallback sur `libelle` si null |

---

## Open Questions (RESOLVED)

1. **Statut lu/non-lu : quel identifiant unique ?**
   - RESOLVED: Utiliser `reference_fiche ?? libelle ?? numero_fiche` pour cohérence avec `FavoritesService`. Implémenté dans `ReadStatusService.getRappelId()` (Plan 04).

2. **Persistance des filtres entre sessions ?**
   - RESOLVED: Persistance via SharedPreferences (`active_filters`) — décision utilisateur (CONTEXT.md) prime sur la recommandation de recherche session-only. La décision locked CONTEXT.md stipule explicitement "Persistance : oui — filtres actifs sauvegardés via SharedPreferences". Implémenté dans Plan 02 avec `FilterState.toJson/fromJson` et clé `active_filters`.

3. **Autocomplétion : API live ou cache local ?**
   - RESOLVED: Appel API live uniquement pour Phase 1 via `RappelService.fetchSuggestions()` — les suggestions dégradent gracieusement si hors ligne (retourne `[]` sans exception). Implémenté dans Plan 03.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Tous les écrans | oui | 3.41.6 (stable) | — |
| Dart SDK | Tous | oui | 3.11.4 | — |
| `shared_preferences` | SRCH-03, SRCH-07 | oui (pubspec.lock) | 2.x | — |
| `intl` | Formatage date filtres | oui (pubspec.lock) | 0.20.2 | — |
| API RappelConso v2.1 | SRCH-01, SRCH-02 | oui (live 2026-06-16) | v2.1 | Cache SharedPrefs (graceful degradation) |

Aucune dépendance bloquante — toutes les dépendances requises sont présentes.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK built-in, flutter_lints 5.0.0) |
| Config file | `analysis_options.yaml` (extends flutter_lints) |
| Quick run command | `flutter test test/services_test.dart` |
| Full suite command | `flutter test` |

Note : `test/widget_test.dart` a un test factice (counter app) qui échoue. La commande full suite retourne une erreur. Utiliser `flutter test test/services_test.dart` pour les tests Phase 1.

### Phase Requirements → Test Map

| Req ID | Comportement | Type de test | Commande automatisée | Fichier existe ? |
|--------|-------------|-------------|---------------------|-----------------|
| SRCH-01 | Recherche "Nutella" retourne résultats toutes catégories | integration (API live) | Manuel — nécessite réseau | Non |
| SRCH-02 | 2 caractères saisis → suggestions apparaissent | widget | `flutter test test/search_screen_test.dart` | Non — Wave 0 |
| SRCH-03 | Historique sauvegardé et cliquable | unit | `flutter test test/search_history_service_test.dart` | Non — Wave 0 |
| SRCH-04 | Filtre risque réduit la liste | unit | `flutter test test/filter_logic_test.dart` | Non — Wave 0 |
| SRCH-05 | Filtre 7j/30j/90j réduit la liste | unit | `flutter test test/filter_logic_test.dart` | Non — Wave 0 |
| SRCH-06 | Filtre marque réduit la liste | unit | `flutter test test/filter_logic_test.dart` | Non — Wave 0 |
| SRCH-07 | Rappel marqué lu persiste après redémarrage | unit | `flutter test test/read_status_service_test.dart` | Non — Wave 0 |
| SRCH-08 | Tri date bascule récent/ancien | unit | `flutter test test/filter_logic_test.dart` | Non — Wave 0 |

### Sampling Rate

- **Par commit de tâche :** `flutter test test/services_test.dart` (tests existants — s'assurer qu'on ne régresse pas)
- **Par wave merge :** `flutter test` (suite complète incluant les nouveaux tests)
- **Phase gate :** Suite complète verte avant `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/search_history_service_test.dart` — couvre SRCH-03 (addToHistory, getHistory, clearHistory)
- [ ] `test/read_status_service_test.dart` — couvre SRCH-07 (markAsRead, isRead, persistance)
- [ ] `test/filter_logic_test.dart` — couvre SRCH-04/05/06/08 (logique client-side de filtrage et tri)
- [ ] `test/search_screen_test.dart` — couvre SRCH-02 (apparition des suggestions avec mock)
- [ ] `test/widget_test.dart` — REMPLACER le test factice counter par un vrai smoke test VigilConso (cf. TECH-13, planifié en Phase 6 mais le test factice bloque `flutter test`)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Non | App publique, pas d'authentification |
| V3 Session Management | Non | Pas de sessions utilisateur |
| V4 Access Control | Non | Données publiques gouvernementales |
| V5 Input Validation | Oui | Sanitiser la query de recherche avant injection dans l'URL API |
| V6 Cryptography | Non | Données publiques non sensibles |

### Threat Patterns pour Phase 1

| Pattern | STRIDE | Mitigation Standard |
|---------|--------|---------------------|
| Injection via champ de recherche dans URL API | Tampering | `replaceAll('"', '')` déjà fait dans RappelService — maintenir et appliquer aussi dans SearchScreen |
| Stockage de données sensibles en SharedPrefs | Information Disclosure | Pas de données sensibles — l'historique de recherche et les IDs de rappels lus sont non-sensibles |
| Requête API excessive (autocomplétion) | Denial of Service (auto-infligé) | Debounce 300ms + limit=8 + annulation du timer à chaque keystroke |

---

## Sources

### Primary (HIGH confidence)

- API RappelConso v2.1 live — tests directs sur `data.economie.gouv.fr` (2026-06-16) : validation des champs, `search()`, `group_by`, facets, valeurs de risque
- Code source `lib/services/rappel_service.dart` — vérification directe de l'implémentation existante
- Code source `lib/screens/rappel_screen.dart` — vérification de l'anti-pattern bypass cache
- Code source `lib/services/favorites_service.dart` — pattern SharedPreferences à répliquer
- `pubspec.yaml` + `pubspec.lock` — versions résolues de toutes les dépendances
- `flutter --version` — Flutter 3.41.6, Dart 3.11.4 [VERIFIED — bash]
- `flutter test` — état des tests existants [VERIFIED — bash]

### Secondary (MEDIUM confidence)

- Flutter Material 3 `SearchBar`, `FilterChip`, `showDateRangePicker` — disponibles depuis Flutter 3.7, donc présents en 3.41.6 [VERIFIED par version SDK]

### Tertiary (LOW confidence)

- Performance debounce 300ms pour autocomplétion API gouvernementale — valeur standard de l'industrie [ASSUMED — non mesuré sur cette API spécifique]

---

## Metadata

**Confidence breakdown :**
- Standard Stack : HIGH — aucune nouvelle dépendance, tout vérifié dans pubspec.lock
- Architecture : HIGH — basé sur code existant lu et API testée en live
- Pitfalls : HIGH — pitfalls 3 et 4 vérifiés en tests live sur l'API; pitfalls 1 et 2 extraits du code source
- API Fields : HIGH — vérifiés en tests live

**Research date :** 2026-06-16
**Valid until :** 2026-07-16 (API gouvernementale stable; SDK Flutter peut évoluer mais pas les widgets Material 3 de base)
