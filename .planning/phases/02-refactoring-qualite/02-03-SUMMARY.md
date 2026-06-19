---
phase: 02-refactoring-qualite
plan: "03"
subsystem: bug-fixes
tags: [barcode, api-v2.1, camera-lifecycle, contact-form, favorites, race-condition, lock, newsletter-api]
dependency_graph:
  requires:
    - 02-01 (synchronized package installed, test stubs created)
  provides:
    - lib/screens/barcode_scanner.dart (v2.1 GTIN API + camera lifecycle fix)
    - lib/services/favorites_service.dart (Lock-serialized writes, private unlocked helpers)
    - newsletter-api/index.js (POST /contact endpoint)
  affects:
    - lib/screens/contact_screen.dart (real HTTP POST)
tech_stack:
  added: []
  patterns:
    - synchronized Lock (non-reentrant) with private unlocked helpers (Pitfall 6 avoidance)
    - WidgetsBindingObserver + autoStart: false for camera lifecycle
    - String.fromEnvironment('NEWSLETTER_API_URL') dart-define for API URL
    - Express.js POST route with ASVS V5 server-side input validation
key_files:
  created: []
  modified:
    - lib/screens/barcode_scanner.dart (v2.1 API + lifecycle)
    - lib/screens/contact_screen.dart (real HTTP POST)
    - lib/services/favorites_service.dart (Lock + private helpers)
    - newsletter-api/index.js (POST /contact route)
    - test/rappel_service_gtin_test.dart (real assertions)
    - test/contact_service_test.dart (behavior contracts)
    - test/favorites_race_test.dart (sequential + concurrent toggle tests)
decisions:
  - "Used id.toString() as canonical identity key in FavoritesService (reference_fiche absent in API v2)"
  - "Camera lifecycle fix: autoStart: false + WidgetsBindingObserver (not conditional IndexedStack rebuild)"
  - "NEWSLETTER_API_URL defaults to http://10.0.2.2:3000 (Android emulator localhost alias)"
  - "Private helpers do NOT acquire Lock (non-reentrant Lock — prevents deadlock)"
  - "newsletter-api /contact validates length limits (name 100, subject 200, message 5000) per ASVS V5"
requirements:
  - TECH-06
  - TECH-07
  - TECH-09
  - TECH-10
metrics:
  duration: "~8 minutes"
  completed: "2026-06-19"
  tasks_completed: 2
  tasks_total: 2
  tests_added: 7
  tests_passing: 7
  files_created: 0
  files_modified: 7
---

# Phase 02 Plan 03: Correction des 4 bugs critiques — API v2.1 barcode, contact HTTP, favoris Lock, caméra lifecycle

**One-liner:** Barcode scanner migré vers `rappelconso-v2-gtin-trie` (v2.1 API avec champs plats), contact form envoie un vrai HTTP POST au backend, `FavoritesService` sérialisé avec un `Lock` non-réentrant, caméra arrêtée quand l'app passe en arrière-plan.

## What Was Built

### Task 1: Fix barcode scanner (API v2.1 + camera lifecycle) + newsletter /contact endpoint

**`lib/screens/barcode_scanner.dart`:**
- Remplacement de l'appel HTTP cassé (`rappelconso0` dataset v1 — retourne 404) par le dataset correct `rappelconso-v2-gtin-trie`
- URL v2.1 : `https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/rappelconso-v2-gtin-trie/records?where=gtin="<barcode>"&limit=5`
- Migration de la forme de réponse v1 (`data['nhits']`, `data['records'][i]['fields']`) vers v2.1 (`data['results']`, objets plats)
- Migration des noms de champs v1 → v2.1 : `nom_de_la_marque_du_produit` → `marque_produit`, `motif_du_rappel` → `motif_rappel`, `date_de_publication` → `date_publication`, `reference_fiche` → `lien_vers_la_fiche_rappel` (URL complète)
- Ajout du mixin `WidgetsBindingObserver` : `initState` ajoute l'observateur, `dispose` le retire
- `MobileScannerController(autoStart: false)` — empêche la caméra de démarrer automatiquement
- `didChangeAppLifecycleState` : démarrage sur `resumed`, arrêt sur `paused`/`inactive`
- Correction des warnings `flutter analyze` : `super.key`, `withValues(alpha:)` au lieu de `withOpacity`, `mounted` check avant `Navigator.push`

**`newsletter-api/index.js`:**
- Ajout de la route `POST /contact` (n'existait pas — `/newsletter` et `/send-email` uniquement)
- Validation : 4 champs requis (`name`, `email`, `subject`, `message`) — retourne 400 si manquant
- Validation email via `isValidEmail` existant (ligne 16) — retourne 400 si format invalide
- Validation des longueurs : name ≤100, subject ≤200, message ≤5000 chars (ASVS V5 — T-02-01)
- Envoi via `transporter` existant avec `replyTo` = email expéditeur, `to` = admin (`FROM_EMAIL`)
- Réponse 200 `{"message": "Message envoyé avec succès."}` ou 500 en cas d'erreur SMTP

### Task 2: Fix contact form HTTP + favorites race condition

**`lib/screens/contact_screen.dart`:**
- Suppression de `Future.delayed(const Duration(seconds: 2))` (envoi simulé)
- Ajout des imports `dart:convert` et `package:http/http.dart as http`
- `_sendMessage()` effectue maintenant un vrai `http.post` vers `$newsletterApiUrl/contact`
- URL lue depuis `String.fromEnvironment('NEWSLETTER_API_URL', defaultValue: 'http://10.0.2.2:3000')`
- Gestion des cas : 200 (clear form + show success), non-200 (show error body), exception réseau

**`lib/services/favorites_service.dart`:**
- Import `package:synchronized/synchronized.dart`
- `static final _lock = Lock()` — singleton au niveau classe
- `toggleFavorite`, `addFavorite`, `removeFavorite` acquièrent le Lock une fois chacun
- Création de 3 helpers privés non verrouillés : `_isFavoriteUnlocked`, `_addFavoriteUnlocked`, `_removeFavoriteUnlocked`
- Les helpers privés **ne** appellent **pas** `_lock.synchronized()` (évite deadlock — Pitfall 6)
- Clé d'identité : `id.toString()` → fallback `lien_vers_la_fiche_rappel` → fallback `libelle` (compatible v1 et v2)
- `getFavorites()` et `isFavorite()` — méthodes lecture seule, pas de lock nécessaire

## Commits

| Task | Commit | Message |
|------|--------|---------|
| Task 1 | `dc3c931` | feat(02-03): fix barcode scanner API v2.1 + camera lifecycle + newsletter /contact endpoint |
| Task 2 | `67d7768` | feat(02-03): fix contact form real HTTP POST + favorites race condition with Lock |

## Tests

| Fichier | Tests | Statut |
|---------|-------|--------|
| test/rappel_service_gtin_test.dart | 2 | PASS |
| test/contact_service_test.dart | 2 | PASS |
| test/favorites_race_test.dart | 3 | PASS |

**Total: 7 tests, 7 PASS** (flutter analyze: 0 issues sur les 3 fichiers modifiés)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] flutter analyze warnings dans barcode_scanner.dart**
- **Found during:** Task 1, flutter analyze
- **Issue:** 7 infos dans le fichier réécrit : `use_super_parameters`, `library_private_types_in_public_api`, `use_build_context_synchronously`, `no_leading_underscores_for_local_identifiers`, 3x `withOpacity` deprecated
- **Fix:** Correction inline : `super.key`, ignore comment pour `_BarcodeScannerPageState`, `mounted` check avant `Navigator.push`, renommage `_gtinDataset` → `gtinDataset`, `withValues(alpha:)` au lieu de `withOpacity`
- **Files modified:** lib/screens/barcode_scanner.dart
- **Commit:** dc3c931

### Pre-existing Issues (hors scope)

- 12 warnings flutter analyze dans `lib/screens/` (rappel_details_page.dart, rappel_screen.dart, etc.) — préexistants avant ce plan, non modifiés par ce plan. Déférés à des plans ultérieurs.

## Known Stubs

Aucun stub dans les fichiers créés/modifiés par ce plan. Les tests documentaires dans `contact_service_test.dart` et `rappel_service_gtin_test.dart` sont intentionnellement basés sur des assertions statiques (grep verification) car les vrais tests HTTP nécessitent un mock HTTP framework (prévu Phase 6).

## Threat Surface Scan

| Flag | File | Description |
|------|------|-------------|
| T-02-01 mitigated | newsletter-api/index.js | POST /contact : validation serveur complète (4 champs, email regex, length limits) — conforme au modèle de menace du plan |

Aucune nouvelle surface réseau non prévue dans le modèle de menace.

## Self-Check: PASSED

Fichiers modifiés vérifiés :
- FOUND: lib/screens/barcode_scanner.dart (rappelconso-v2-gtin-trie ✓, autoStart: false ✓, WidgetsBindingObserver ✓)
- FOUND: lib/screens/contact_screen.dart (http.post ✓, NEWSLETTER_API_URL ✓, pas de Future.delayed ✓)
- FOUND: lib/services/favorites_service.dart (_lock = Lock() ✓, _lock.synchronized ✓, helpers privés ✓)
- FOUND: newsletter-api/index.js (app.post('/contact') ✓, isValidEmail ×4 ✓)
- FOUND: test/rappel_service_gtin_test.dart (2 tests ✓)
- FOUND: test/contact_service_test.dart (2 tests ✓)
- FOUND: test/favorites_race_test.dart (3 tests ✓)

Commits vérifiés :
- FOUND: dc3c931 (Task 1)
- FOUND: 67d7768 (Task 2)
