# Phase 2: Refactoring & Qualité Technique - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Codebase propre — modèle `Rappel` typé avec `fromJson`, architecture Riverpod pour `RappelService` et `FavoritesService`, utilitaires extraits (`image_utils`, `date_utils`), bugs critiques corrigés (barcode v2.1, contact form réel, OneSignal dart-define, race condition favoris, cycle caméra), page de détail enrichie, navigation clarifiée, shimmer homogène sur tous les écrans.

Ce que cette phase ne fait PAS : migration go_router (phase ultérieure si nécessaire), tests exhaustifs (Phase 6), mode offline (Phase 4), alertes personnalisées (Phase 3).

</domain>

<decisions>
## Implementation Decisions

### Riverpod Migration Scope
- Wrapper `RappelService` et `FavoritesService` uniquement dans cette phase — couvre les besoins des phases 3 et 4
- Style de provider : `AsyncNotifierProvider` — idiomatique Riverpod 2.x, adapté aux futures async
- `ProviderScope` enveloppe toute l'app dans `main.dart` dès cette phase
- Tests unitaires purs existants (AppConstants) restent inchangés ; `ProviderContainer` uniquement pour les nouveaux tests Riverpod

### Page de Détail Enrichie
- Lots concernés : texte brut formaté dans une section "Lots concernés" (masqué si absent)
- Dates clés (publication, début, fin rappel) : liste de lignes label + valeur (ex: "Publié: 12 jan 2025")
- Actions consommateur (lien officiel, PDF si dispo, partage) : boutons proéminents dans une action bar sticky au bas de la page
- Structure : colonne scrollable unique avec sections collapsibles

### Navigation Repensée
- Conserver les 4 tabs existants — améliorer labels/icônes pour la clarté sans restructurer
- Navigation impérative (`Navigator.push/pop`) conservée — pas de migration go_router dans cette phase
- Barre de recherche déjà dans un écran dédié (Phase 1) — aucun changement requis
- Transitions Cupertino/fade actuelles conservées pour cohérence

### Claude's Discretion
- Ordre d'extraction des utilitaires (image_utils vs date_utils en premier)
- Choix du Mutex vs debounce pour la race condition favoris (préférer Mutex si disponible dans les deps)
- Structure exacte des providers Riverpod (nommage, fichiers)
- Contenu exact de la section "Lots concernés" selon les champs disponibles dans l'API

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ShimmerLoading`, `ShimmerBox`, `RappelCardShimmer`, `HomeAlertShimmer` — widgets shimmer existants dans `lib/widgets/shimmer_loading.dart`
- `AppMenu` — widget overflow menu partagé dans `lib/widgets/app_menu.dart`
- `AppConstants.apiBaseUrl` — URL API v2.1 à réutiliser pour la migration barcode
- `RappelService.fetchRappels()` — déjà exposé avec paramètres `categoryKey`, `searchQuery`, `newestFirst`, `forceRefresh`

### Established Patterns
- StatefulWidget + setState (à migrer vers Riverpod pour RappelService/FavoritesService)
- Services statiques (`RappelService`, `FavoritesService`) — à wrapper en providers Riverpod
- SharedPreferences pour la persistence locale (favoris, cache)
- `Navigator.push` / `Navigator.pop` pour la navigation impérative
- Material 3 + light/dark theming déjà configuré dans `main.dart`
- `try/catch` dans chaque méthode async avec fallback cache

### Integration Points
- `lib/main.dart` — ajouter `ProviderScope` au bootstrap
- `lib/screens/rappel_screen.dart` — principal candidat pour déléguer appels HTTP à RappelService (anti-pattern documenté)
- `lib/screens/barcode_scanner.dart` — migrer endpoint `rappelconso0` → `AppConstants.apiBaseUrl` + GTIN filter
- `lib/screens/contact_screen.dart` — remplacer `Future.delayed` par vrai appel HTTP à `newsletter-api`
- `lib/screens/rappel_details_page.dart` — enrichir avec lots, dates, action bar sticky
- 4 fichiers avec `_proxiedUrl` dupliqué : `home_screen.dart`, `rappel_screen.dart`, `favorites_screen.dart`, `rappel_details_page.dart`

</code_context>

<specifics>
## Specific Ideas

- OneSignal App ID doit passer via `--dart-define=ONESIGNAL_APP_ID=xxx` (`.env.example` documente déjà la variable)
- `_proxiedUrl()` → extraire dans `lib/utils/image_utils.dart` (4 occurrences à corriger)
- `_parseDate()` → extraire dans `lib/utils/date_utils.dart` (2 occurrences)
- Page de détail : utiliser les champs existants de l'API v2.1 — `date_publication`, `date_debut_fin_de_commercialisation`, `informations_complementaires_sur_les_risques_pour_le_consommateur`, `zones_geographiques_de_vente`, `conditionnements`
- Shimmer homogène : vérifier que `RappelCardShimmer` et `HomeAlertShimmer` sont utilisés sur tous les écrans de liste (RappelListScreen, SearchScreen, FavoritesScreen)

</specifics>

<deferred>
## Deferred Ideas

- Migration go_router (navigation déclarative) — reportée, trop de scope pour cette phase, pertinente en Phase 3/4
- Tests unitaires complets pour les nouveaux providers Riverpod — Phase 6 est dédiée à ça
- Deep linking (widget home screen → détail) — Phase 5
- Ajout d'un tab "Mes Alertes" — Phase 3

</deferred>
