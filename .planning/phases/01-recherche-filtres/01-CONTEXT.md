# Phase 1: Recherche & Filtres - Context

**Gathered:** 2026-06-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 livre la fonctionnalité de recherche et filtrage complète : un écran de recherche dédié (`SearchScreen`) accessible depuis la barre de recherche de l'accueil, un panel de filtres (risque, dates, marque/mot-clé, statut lu/non-lu), l'autocomplétion avec historique, et le marquage lu/non-lu persistant. UX-01 (cartes Google News) est déjà livré — il sera réutilisé sans modification.

</domain>

<decisions>
## Implementation Decisions

### Écran de recherche — Navigation et layout
- Accès via appui sur la SearchBar existante (home_screen) → `Navigator.push` vers `SearchScreen` plein écran
- Layout : `SliverAppBar` avec `SearchBar` Material 3 en titre fixe en haut
- Retour : `Navigator.pop` (bouton back standard) + icône × pour vider la saisie
- Cartes de résultats : réutiliser `_buildRappelCard` de `rappel_screen.dart` sans modification (cohérence visuelle)

### Panel de filtres — UX et persistance
- Ouverture : bouton "Filtres" avec badge nombre de filtres actifs → `showModalBottomSheet`
- Filtres actifs : chips scrollables horizontaux sous la SearchBar, chaque chip a un × pour retirer
- Tri (date décroissante / croissante / pertinence) : `SegmentedButton` au-dessus des résultats, tri date décroissante par défaut
- Persistance : oui — filtres actifs sauvegardés via `SharedPreferences`

### Historique et autocomplétion
- Déclenchement suggestions : debounce 300 ms à partir de 2 caractères, overlay positionné sous le champ
- Source : API live `search(marque_produit,"<prefix>")` + cache en mémoire pour la session, 8 suggestions maximum
- Historique : 10 entrées max, LIFO, icône horloge, cliquable, bouton "tout supprimer"
- Affichage : champ vide → historique uniquement ; ≥ 2 chars → suggestions API (historique masqué)

### Statut lu / non-lu
- Indicateur visuel : point bleu en haut à gauche de la carte — disparaît automatiquement à la lecture
- Déclenchement marquage "lu" : automatique à l'ouverture de la page de détail (`RappelDetailsPage`)
- Filtre statut : dans le panel de filtres, section "Statut" (Tout / Non lus uniquement / Lus uniquement)
- Badge onglet home : badge numérique via `newAlertsNotifier` existant (`alerts_notifier.dart`)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `_buildRappelCard()` dans `lib/screens/rappel_screen.dart` — carte Google News complète (image droite + risque + date) — réutiliser telle quelle
- `RappelService.fetchRappels(categoryKey:'all', searchQuery:q)` — déjà capable de recherche globale toutes catégories
- `SharedPreferences` — déjà importé et utilisé dans `favorites_service.dart` et `rappel_service.dart`
- `newAlertsNotifier` (`lib/services/alerts_notifier.dart`) — `ValueNotifier<int>` global pour badge onglet
- `showDateRangePicker()` — Flutter intégré, déjà disponible sans dep externe
- `FilterChip`, `SearchBar`, `SegmentedButton` — Material 3 built-in, cohérents avec `useMaterial3: true`

### Established Patterns
- State management : `setState` + `StatefulWidget` — continuer ce pattern (Riverpod arrive en Phase 2)
- Persistence légère : `SharedPreferences` directement dans le service (pas d'abstraction)
- Async dans screens : `_loadData()` async, `mounted` guard avant `setState`, `_isLoading` / `_errorMessage` fields
- Navigation : `Navigator.push(context, MaterialPageRoute(builder: (_) => const Screen()))`
- Theming : `final cs = Theme.of(context).colorScheme;` — aucune couleur hardcodée

### Integration Points
- `lib/screens/home_screen.dart` : câbler le tap sur la `SearchBar` pour pousser `SearchScreen`
- `lib/screens/rappel_screen.dart` : extraire `_buildRappelCard` ou le rendre accessible à `SearchScreen`
- `lib/services/rappel_service.dart` : corriger le bypass de cache dans `_fetchRappels()` de `rappel_screen.dart` avant de câbler la recherche globale
- `lib/screens/rappel_details_page.dart` : ajouter le marquage auto "lu" à l'ouverture
- `lib/services/alerts_notifier.dart` : connecter le compteur non-lus au `newAlertsNotifier`
- Nouveaux services à créer : `SearchHistoryService` (SharedPreferences), `ReadStatusService` (SharedPreferences)

</code_context>

<specifics>
## Specific Ideas

- L'anti-pattern documenté (bypass cache dans `rappel_screen.dart`) est le prérequis bloquant — à corriger en tout premier dans le Plan 1
- Aucune nouvelle dépendance pub — tout le nécessaire est dans le stack existant
- `search_screen.dart` apparaît déjà dans la structure (commenté "if separate") — vérifier s'il existe et si du code est réutilisable

</specifics>

<deferred>
## Deferred Ideas

None — discussion restée dans le périmètre de la phase.

</deferred>
