# Phase 2: Refactoring & Qualité Technique - Research

**Researched:** 2026-06-18
**Domain:** Flutter refactoring — Riverpod 2.x/3.x migration, API v2.1 barcode, utils extraction, bug fixes
**Confidence:** HIGH (most findings verified via live API calls, Context7, or codebase inspection)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Wrapper `RappelService` et `FavoritesService` uniquement dans cette phase — couvre les besoins des phases 3 et 4
- Style de provider : `AsyncNotifierProvider` — idiomatique Riverpod 2.x, adapté aux futures async
- `ProviderScope` enveloppe toute l'app dans `main.dart` dès cette phase
- Tests unitaires purs existants (AppConstants) restent inchangés ; `ProviderContainer` uniquement pour les nouveaux tests Riverpod
- Lots concernés : texte brut formaté dans une section "Lots concernés" (masqué si absent)
- Dates clés (publication, début, fin rappel) : liste de lignes label + valeur
- Actions consommateur (lien officiel, PDF si dispo, partage) : boutons proéminents dans une action bar sticky au bas de la page
- Structure page de détail : colonne scrollable unique avec sections collapsibles
- Conserver les 4 tabs existants — améliorer labels/icônes pour la clarté sans restructurer
- Navigation impérative (`Navigator.push/pop`) conservée — pas de migration go_router dans cette phase
- Transitions Cupertino/fade actuelles conservées pour cohérence

### Claude's Discretion
- Ordre d'extraction des utilitaires (image_utils vs date_utils en premier)
- Choix du Mutex vs debounce pour la race condition favoris (préférer Mutex si disponible dans les deps)
- Structure exacte des providers Riverpod (nommage, fichiers)
- Contenu exact de la section "Lots concernés" selon les champs disponibles dans l'API

### Deferred Ideas (OUT OF SCOPE)
- Migration go_router (navigation déclarative) — reportée, trop de scope pour cette phase
- Tests unitaires complets pour les nouveaux providers Riverpod — Phase 6
- Deep linking (widget home screen → détail) — Phase 5
- Ajout d'un tab "Mes Alertes" — Phase 3
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TECH-01 | Modèle `Rappel` typé avec factory `fromJson` — supprimer les `dynamic` partout | API field names verified via live call (see Standard Stack section) |
| TECH-02 | `RappelService` refactorisé avec Riverpod (providers) — logique séparée des widgets | Riverpod 3.3.2 `AsyncNotifierProvider` pattern verified via Context7 |
| TECH-03 | `_proxiedUrl()` extrait dans `lib/utils/image_utils.dart` — 4 occurrences à corriger | Duplication confirmed by codebase grep |
| TECH-04 | `_parseDate()` extrait dans `lib/utils/date_utils.dart` — 2 occurrences | `RappelService.parseDate()` already public; `rappel_details_page` still has own copy |
| TECH-05 | `RappelListScreen` délègue tous ses appels HTTP à `RappelService` | Already partially done — `_loadRappels()` calls service; no rogue HTTP calls found |
| TECH-06 | Barcode scanner migré vers API v2.1 — suppression endpoint v1 déprécié | Live API confirmed: use `rappelconso-v2-gtin-trie` dataset with `gtin` field |
| TECH-07 | Contact form envoie réellement via newsletter-api | `/contact` endpoint does NOT exist — must add it; `/send-email` exists but sends to arbitrary `to` |
| TECH-08 | OneSignal App ID via `--dart-define` — suppression hardcoding `lib/main.dart` | `const String.fromEnvironment('ONESIGNAL_APP_ID')` pattern verified |
| TECH-09 | Race condition favoris corrigée | `synchronized` 3.4.1 Dart package confirmed; Lock pattern verified |
| TECH-10 | Cycle de vie caméra dans `IndexedStack` corrigé | `MobileScannerController(autoStart: false)` + tab visibility detection pattern confirmed |
| UX-02 | Page de détail enrichie (dates clés, lots concernés, description risque, actions) | API field names confirmed via live call on `rappelconso-v2-gtin-espaces` dataset |
| UX-03 | Navigation intuitive et cohérente | Labels/icons only — no structural change required |
| UX-04 | Shimmer loading homogène sur tous les écrans | `RappelCardShimmer` and `HomeAlertShimmer` confirmed existing in `lib/widgets/shimmer_loading.dart` |
</phase_requirements>

---

## Summary

Phase 2 is a codebase cleanup and bug-fix milestone, not a feature addition. The primary technical challenge is introducing Riverpod 3.x into an app that is entirely `setState`-based, without breaking existing screens. The strategy is an additive migration: wrap only `RappelService` and `FavoritesService` as `AsyncNotifierProvider` providers, add `ProviderScope` at the root, and convert the screens that use these services to `ConsumerStatefulWidget`. Screens not converted continue to work unchanged.

The second major challenge is the barcode scanner's use of the v1 API (`rappelconso0` dataset, which returns 404 — the dataset literally does not exist anymore). The v2.1 replacement uses a different dataset ID (`rappelconso-v2-gtin-trie`) with a dedicated `gtin` field that supports exact-match filtering. The main `rappelconso-v2-gtin-espaces` dataset used by the rest of the app does not have a `gtin` field — it has `identification_produits` (an array), so GTIN search requires switching to the `gtin-trie` dataset.

The contact form integration requires adding a new `/contact` endpoint to the newsletter-api Node.js backend — no such endpoint currently exists. The `synchronized` Dart package (3.4.1) provides a `Lock` class suitable for serializing SharedPreferences writes in `FavoritesService`.

**Primary recommendation:** Execute in this order: (1) extract utils first (zero risk, unblocks TECH-03/04), (2) introduce `Rappel` model (TECH-01), (3) add Riverpod providers without breaking existing screens (TECH-02), (4) fix barcode API (TECH-06), (5) fix contact form with backend endpoint (TECH-07), (6) fix OneSignal dart-define (TECH-08), (7) fix favorites race condition (TECH-09), (8) fix camera lifecycle (TECH-10), (9) enrich detail page (UX-02/03/04).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Riverpod provider state | Service layer | Presentation (read only) | Providers own state; widgets only watch/read |
| `Rappel` model typing | Service layer | Presentation | `fromJson` factory lives in model, screens use typed objects |
| Image proxy utility | Utils layer | — | Pure function, no state, shared across screens |
| Date parsing utility | Utils layer | — | Pure function, duplicated in service + screen, belongs in utils |
| Barcode GTIN lookup | Service layer (new) | Screen (call) | API call, should live in `RappelService` not in screen |
| Contact form submission | Service layer (new) | Screen (call) | HTTP call, not UI responsibility |
| OneSignal App ID config | Bootstrap (`main.dart`) | — | Read from environment at startup only |
| Camera lifecycle | Presentation (BarcodeScannerPage) | — | Widget-level state management for camera |
| Favorites race condition | Service layer | — | Lock lives in `FavoritesService` |
| Shimmer homogeneity | Widget layer | Presentation | Reuse existing `lib/widgets/shimmer_loading.dart` |

---

## Standard Stack

### Core (new additions for this phase)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_riverpod` | 3.3.2 | State management — `AsyncNotifierProvider` | Latest stable; `AsyncNotifier` idiom for async services |
| `synchronized` | 3.4.1 | Dart `Lock` for serializing async SharedPreferences writes | No external deps, supports Browser/VM/Flutter, well-maintained |

### Already Present (relevant to this phase)
| Library | Version | Purpose |
|---------|---------|---------|
| `shared_preferences` | 2.5.4 | Favorites persistence (race condition fix target) |
| `mobile_scanner` | 6.0.11 | Camera scan (lifecycle fix target) — **6.x is not latest (7.2.0 exists)** |
| `onesignal_flutter` | 5.4.1 | Push notifications (dart-define target) |
| `http` | 1.1.0 | HTTP client (contact form and barcode fix) |

> `mobile_scanner` 7.2.0 is available but the project is on 6.0.11 — do NOT upgrade during this phase; the lifecycle API is compatible in 6.x.

**Installation:**
```bash
flutter pub add flutter_riverpod synchronized
```

**Version verification:** [VERIFIED: `dart pub add --dry-run flutter_riverpod` → 3.3.2; `dart pub add --dry-run synchronized` → 3.4.1 (3.4.0+1 already transitive)]

---

## Architecture Patterns

### System Architecture Diagram (post-phase target)

```
main.dart
  └─ ProviderScope                    ← NEW: wraps entire app
       └─ RappelConsoApp (MaterialApp)
            └─ MainScreen (IndexedStack, 4 tabs)
                 ├─ HomeScreen (ConsumerStatefulWidget)
                 │    └─ ref.watch(rappelServiceProvider)
                 ├─ CategoriesScreen → RappelListScreen (ConsumerStatefulWidget)
                 │    └─ ref.watch(rappelServiceProvider)
                 ├─ FavoritesScreen (ConsumerStatefulWidget)
                 │    └─ ref.watch(favoritesProvider)
                 └─ BarcodeScannerPage (StatefulWidget, unchanged)
                      └─ RappelService.fetchByGtin() [static call, not yet a provider]

Service Layer (Riverpod providers — NEW):
  rappelServiceProvider: AsyncNotifierProvider<RappelNotifier, List<Rappel>>
  favoritesProvider:     AsyncNotifierProvider<FavoritesNotifier, List<Rappel>>

Utils Layer (NEW files):
  lib/utils/image_utils.dart   ← proxiedUrl() extracted from 4 screens
  lib/utils/date_utils.dart    ← parseDate() (delegates to RappelService.parseDate())

Model Layer (NEW):
  lib/models/rappel.dart       ← Rappel class with fromJson factory

Newsletter API (Node.js — NEW endpoint):
  POST /contact  { name, email, subject, message }
```

### Recommended Project Structure (delta — new files only)
```
lib/
├─ models/
│   └─ rappel.dart               # NEW — typed Rappel model
├─ providers/
│   ├─ rappel_provider.dart      # NEW — RappelNotifier : AsyncNotifier<List<Rappel>>
│   └─ favorites_provider.dart   # NEW — FavoritesNotifier : AsyncNotifier<List<Rappel>>
├─ utils/
│   ├─ image_utils.dart          # NEW — proxiedUrl(String url) → String
│   └─ date_utils.dart           # NEW — parseDate(String) → DateTime? (thin wrapper)
└─ services/
    └─ favorites_service.dart    # MODIFIED — add Lock for race condition fix

newsletter-api/
└─ index.js                      # MODIFIED — add POST /contact endpoint
```

### Pattern 1: AsyncNotifierProvider wrapping a static service (the core Riverpod migration pattern)

**What:** Convert a static service class call into a Riverpod `AsyncNotifier` that the UI watches.
**When to use:** When the data is async (HTTP + cache), and multiple screens need the same data reactively.
**Source:** [CITED: Context7 — github.com/rrousselgit/riverpod, from_state_notifier.mdx]

```dart
// lib/providers/rappel_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigiconso/models/rappel.dart';
import 'package:vigiconso/services/rappel_service.dart';

class RappelNotifier extends AsyncNotifier<List<Rappel>> {
  @override
  Future<List<Rappel>> build() async {
    // Default: fetch 'all' category; screens can override via .family
    final result = await RappelService.fetchRappels(categoryKey: 'all');
    if (result.containsKey('error')) throw Exception(result['error']);
    return (result['results'] as List).map(Rappel.fromJson).toList();
  }

  Future<void> refresh(String categoryKey) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await RappelService.fetchRappels(
        categoryKey: categoryKey,
        forceRefresh: true,
      );
      if (result.containsKey('error')) throw Exception(result['error']);
      return (result['results'] as List).map(Rappel.fromJson).toList();
    });
  }
}

final rappelServiceProvider =
    AsyncNotifierProvider<RappelNotifier, List<Rappel>>(RappelNotifier.new);
```

### Pattern 2: ProviderScope at app root

**Source:** [CITED: Context7 — github.com/rrousselgit/riverpod, getting_started.mdx]

```dart
// lib/main.dart — wrap runApp
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... existing init ...
  runApp(
    ProviderScope(                          // ← ADD this wrapper
      child: RappelConsoApp(showOnboarding: !onboardingShown),
    ),
  );
}
```

### Pattern 3: ConsumerStatefulWidget (replace StatefulWidget in screens)

**Source:** [CITED: Context7 — github.com/rrousselgit/riverpod, consumers.mdx]

```dart
// Replace: class HomeScreen extends StatefulWidget → State<HomeScreen>
// With:    class HomeScreen extends ConsumerStatefulWidget → ConsumerState<HomeScreen>

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final rappels = ref.watch(rappelServiceProvider);
    return rappels.when(
      loading: () => const HomeAlertShimmer(),
      error: (e, _) => _buildErrorState(e.toString()),
      data: (list) => _buildContent(list),
    );
  }
}
```

### Pattern 4: Lock-based race condition fix (FavoritesService)

**Source:** [CITED: pub.dev/packages/synchronized — synchronized 3.4.1]

```dart
import 'package:synchronized/synchronized.dart';

class FavoritesService {
  static final _lock = Lock();                    // ← class-level singleton Lock
  static const String _key = 'favorites';

  static Future<void> toggleFavorite(Map<String, dynamic> rappel) async {
    await _lock.synchronized(() async {           // ← serialize all writes
      final id = rappel['reference_fiche'] ?? rappel['libelle'] ?? '';
      final already = await _isFavoriteUnlocked(id);
      if (already) {
        await _removeFavoriteUnlocked(id);
      } else {
        await _addFavoriteUnlocked(rappel);
      }
    });
  }
  // Private unlocked variants that do NOT acquire the lock (called inside synchronized block)
}
```

### Pattern 5: `--dart-define` for OneSignal App ID

**Source:** [ASSUMED — standard Flutter dart-define pattern; Dart `String.fromEnvironment` is documented]

```dart
// lib/main.dart — replace hardcoded constant
const String _oneSignalAppId = String.fromEnvironment(
  'ONESIGNAL_APP_ID',
  defaultValue: '',   // empty string → OneSignal.initialize skipped gracefully
);
```

Run command:
```bash
flutter run --dart-define=ONESIGNAL_APP_ID=eb3fd80e-1a70-468f-ab2e-e1d2eb9592ab
```

Add to launch configs (`.vscode/launch.json` or Android Studio Run Config):
```json
"args": ["--dart-define=ONESIGNAL_APP_ID=eb3fd80e-1a70-468f-ab2e-e1d2eb9592ab"]
```

### Pattern 6: MobileScanner lifecycle in IndexedStack

**Source:** [CITED: pub.dev/packages/mobile_scanner — lifecycle docs] + [ASSUMED: IndexedStack-specific pattern based on official mobile_scanner WidgetsBindingObserver example]

The problem: `IndexedStack` keeps all children alive but does not trigger Flutter's route lifecycle when tabs switch. The camera in `BarcodeScannerPage` (tab index 3) runs even when tab index 0, 1, or 2 is active.

Fix: use `autoStart: false` + check tab visibility manually:

```dart
class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with WidgetsBindingObserver {
  late MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(autoStart: false); // ← key change
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.start();
    } else if (state == AppLifecycleState.inactive ||
               state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }
}
```

For IndexedStack tab switching, the parent `MainScreen` must call `_controller.start()` / `_controller.stop()` when the scanner tab becomes active/inactive. Implementation: expose a `ValueNotifier<bool>` or use a `Visibility` widget's `onChanged`. The simplest approach is to pass the current tab index down and let `BarcodeScannerPage` react in `didUpdateWidget`.

Alternatively (simpler): replace `IndexedStack` slot 3 with a conditional builder that builds `BarcodeScannerPage` only when active (loses state but acceptable for a transient camera screen).

### Pattern 7: Barcode lookup in API v2.1 (GTIN-trie dataset)

**Source:** [VERIFIED: live API call to data.economie.gouv.fr v2.1]

The v1 endpoint (`rappelconso0`) returns `{"error_code": "NotFoundResource"}` — it no longer exists. Use the `rappelconso-v2-gtin-trie` dataset with exact `gtin` field match:

```dart
// In RappelService — new static method
static Future<List<Map<String, dynamic>>> fetchByGtin(String barcode) async {
  const dataset = 'rappelconso-v2-gtin-trie';
  final base = 'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/$dataset';
  final where = Uri.encodeQueryComponent('gtin="$barcode"');
  final url = '$base/records?where=$where&limit=5';
  final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['results'] ?? []);
  }
  return [];
}
```

Field names in `rappelconso-v2-gtin-trie` response (verified):
- `gtin` — EAN-8/13 barcode string, exact match
- `marque_produit` — brand name
- `libelle` — product label
- `motif_rappel` — recall reason
- `date_publication` — ISO datetime
- `risques_encourus` — risk description
- `lien_vers_la_fiche_rappel` — official recall page URL
- `lien_vers_affichette_pdf` — PDF affichette URL

### Pattern 8: Contact form — newsletter-api `/contact` endpoint

**Source:** [VERIFIED: read `newsletter-api/index.js` — no `/contact` route exists]

The newsletter-api has `/newsletter` (subscribe), `/send-email` (generic), and `/health`. There is no `/contact` route. The fix requires:

1. **Backend**: Add a `POST /contact` endpoint to `newsletter-api/index.js`:
```javascript
app.post('/contact', async (req, res) => {
  const { name, email, subject, message } = req.body;
  if (!name || !email || !subject || !message) {
    return res.status(400).json({ message: 'Champs requis manquants.' });
  }
  if (!isValidEmail(email)) {
    return res.status(400).json({ message: 'Email invalide.' });
  }
  try {
    await transporter.sendMail({
      from: `VigilConso <${process.env.FROM_EMAIL}>`,
      to: process.env.FROM_EMAIL,   // send to admin
      replyTo: email,
      subject: `[Contact VigilConso] ${subject}`,
      text: `De: ${name} <${email}>\n\n${message}`,
    });
    return res.status(200).json({ message: 'Message envoyé avec succès.' });
  } catch (error) {
    console.error('Erreur contact:', error.message);
    return res.status(500).json({ message: "Erreur d'envoi. Réessayez." });
  }
});
```

2. **Flutter**: Replace `Future.delayed` in `_sendMessage()` with real HTTP call.
   - The newsletter-api URL is currently not in `AppConstants` — add `newsletterApiUrl` or read from `String.fromEnvironment('NEWSLETTER_API_URL')`.

### Anti-Patterns to Avoid

- **Do not use `StateNotifierProvider`** — deprecated in Riverpod 3.x. Use `AsyncNotifierProvider` for async data, `NotifierProvider` for sync.
- **Do not migrate all screens to ConsumerWidget in one pass** — screens not using the new providers can stay as `StatefulWidget`. Convert only screens that watch the new providers.
- **Do not add `riverpod_generator` / `riverpod_annotation`** — code generation is overkill for 2 providers; manual providers are simpler and faster.
- **Do not use `ref.read(provider)` inside `build()`** — use `ref.watch()` in build for reactive state, `ref.read()` only in callbacks.
- **Do not acquire a Lock inside another Lock** — `synchronized`'s `Lock()` is non-reentrant by default. Each private helper in `FavoritesService` must NOT call `synchronized()` itself.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Serialize concurrent async writes | Custom `Completer` queue | `synchronized` Lock | Edge cases in ordering, cancellation, disposal |
| AsyncValue loading/error states | Custom `_isLoading` + `_errorMessage` booleans | Riverpod `AsyncValue.when()` | AsyncValue handles all 3 states + error stack traces |
| Riverpod state management | BLoC, Provider, GetX alternatives | `flutter_riverpod` 3.x | Locked decision; already installed |

**Key insight:** The `synchronized` package handles all the subtle edge cases of a Dart mutex (zone-based, timeout support, proper cancellation) that a hand-rolled `Completer` queue would miss.

---

## API Field Reference (v2.1 — VERIFIED)

### Dataset: `rappelconso-v2-gtin-espaces` (main app dataset)
Base URL: `https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/rappelconso-v2-gtin-espaces`

Fields relevant to `Rappel.fromJson` model and detail page enrichment [VERIFIED: live API call 2026-06-18]:
| Field | Type | Purpose |
|-------|------|---------|
| `id` | int | Unique record ID |
| `rappel_guid` | String | Stable UUID for deduplication |
| `libelle` | String | Product label (primary title) |
| `marque_produit` | String | Brand |
| `modeles_ou_references` | String | Model/reference |
| `categorie_produit` | String | Category |
| `sous_categorie_produit` | String | Sub-category |
| `date_publication` | String (ISO) | Publication date |
| `date_debut_commercialisation` | String | Distribution start date |
| `date_date_fin_commercialisation` | String | Distribution end date |
| `date_de_fin_de_la_procedure_de_rappel` | String | Recall end date |
| `motif_rappel` | String | Recall reason |
| `risques_encourus` | String | Risk description |
| `description_complementaire_risque` | String? | Supplementary risk |
| `conduites_a_tenir_par_le_consommateur` | String | Consumer actions |
| `preconisations_sanitaires` | String? | Health recommendations |
| `conditionnements` | String? | Packaging / lots info |
| `identification_produits` | List? | GTIN array (not reliable for search) |
| `zone_geographique_de_vente` | String | Geographic zone |
| `distributeurs` | String? | Distributors |
| `liens_vers_les_images` | String | Image URL(s) |
| `lien_vers_la_fiche_rappel` | String | Official fiche URL |
| `lien_vers_affichette_pdf` | String? | PDF affichette URL |
| `lien_vers_la_liste_des_produits` | String? | Product list URL |

Note: `nom_marque` referenced in legacy code does NOT exist in this dataset — the correct field is `marque_produit`. `reference_fiche` referenced in some screens maps to `lien_vers_la_fiche_rappel` (contains the full URL, not just a numeric ID).

### Dataset: `rappelconso-v2-gtin-trie` (barcode scanner only)
Base URL: `https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/rappelconso-v2-gtin-trie`

Additional field: `gtin` (String, exact EAN-8/13 barcode). Use `where=gtin="<barcode>"` for exact match. [VERIFIED: live API call 2026-06-18 — exact match `gtin="3439496310268"` returns 2 records]

---

## Common Pitfalls

### Pitfall 1: `reference_fiche` field name confusion
**What goes wrong:** The existing code uses `widget.rappel['reference_fiche']` as a numeric ID to build `https://rappel.conso.gouv.fr/fiche-rappel/$ref`. But in `rappelconso-v2-gtin-espaces`, the field `lien_vers_la_fiche_rappel` contains the FULL URL (e.g., `https://rappel.conso.gouv.fr/fiche-rappel/22594/interne`). The field `reference_fiche` does not exist in the v2 dataset.
**Why it happens:** The v1 dataset had a `reference_fiche` field that was a numeric ID. The v2 dataset changed this to a full URL in `lien_vers_la_fiche_rappel`. The `id` field (int) is the numeric identifier.
**How to avoid:** In `Rappel.fromJson`, map `lien_vers_la_fiche_rappel` to a `officialUrl` field. For sharing/opening, use the URL directly instead of constructing it from an ID.
**Warning signs:** `reference_fiche` returning null everywhere when testing with real v2 data.

### Pitfall 2: Riverpod 3.x breaking changes from 2.x
**What goes wrong:** Documentation examples online may use Riverpod 2.x syntax (`ref.read(provider.notifier).state = x`). Riverpod 3.x removed `StateNotifierProvider` and changed some APIs.
**Why it happens:** The project installs 3.3.2 (latest stable). Many tutorials target 2.x.
**How to avoid:** Verify with Context7 `/rrousselgit/riverpod` (ID confirmed as Riverpod 3.x). Use `AsyncNotifier` (not `StateNotifier`). `ProviderContainer.test()` replaces custom `createContainer()` test helper.
**Warning signs:** Compile error about `StateNotifierProvider` not found.

### Pitfall 3: ProviderScope placement — don't wrap `MaterialApp`, wrap `runApp` child
**What goes wrong:** Placing `ProviderScope` inside `MaterialApp.builder` instead of wrapping the root widget.
**Why it happens:** Confusion about where Riverpod "hooks" into the widget tree.
**How to avoid:** `runApp(ProviderScope(child: RappelConsoApp(...)))` — `ProviderScope` is the root. [VERIFIED: Context7 — riverpod getting_started.mdx]
**Warning signs:** `ProviderNotFoundException` at runtime.

### Pitfall 4: `rappelconso0` v1 endpoint is gone
**What goes wrong:** Any call to `https://data.economie.gouv.fr/api/records/1.0/search/?dataset=rappelconso0` returns HTTP 404 (verified 2026-06-18). The v1 `/api/records/1.0/` path is gone.
**Why it happens:** The government migrated to ODS v2.1 (`/api/explore/v2.1/`).
**How to avoid:** Use `AppConstants.apiBaseUrl` for all calls. For barcode: use `rappelconso-v2-gtin-trie` dataset.
**Warning signs:** HTTP 404 or `NotFoundResource` error in barcode scanner.

### Pitfall 5: `identification_produits` is an array, not a searchable string
**What goes wrong:** Trying to search the main dataset (`rappelconso-v2-gtin-espaces`) with `where=identification_produits like "4006381333931"` returns 0 results.
**Why it happens:** In `gtin-espaces`, `identification_produits` is a JSON array (e.g., `["000000000", "1", "date de consommation recommandée", "2026-06-23"]`) that contains GTIN plus other identification data. The `like` operator on an array field works differently.
**How to avoid:** Switch to `rappelconso-v2-gtin-trie` dataset for barcode lookup — it has a proper `gtin` string field with one GTIN per row (one row per product per recall).
**Warning signs:** Zero results for any barcode search on the main dataset.

### Pitfall 6: Lock re-entrancy in FavoritesService
**What goes wrong:** If a `Lock.synchronized()` block calls another method that also calls `Lock.synchronized()` on the same lock instance, it deadlocks (non-reentrant by default).
**Why it happens:** Private methods inside `FavoritesService` being called from within the locked section.
**How to avoid:** Create `_addFavoriteUnlocked()` and `_removeFavoriteUnlocked()` private helpers that do NOT call `synchronized()`. The public API method acquires the lock once and calls the unlocked helpers.
**Warning signs:** App freezes on second rapid tap of favorite button.

### Pitfall 7: `dart-define` values are empty in tests
**What goes wrong:** `String.fromEnvironment('ONESIGNAL_APP_ID')` returns `''` in `flutter test` unless the test runner passes the define.
**Why it happens:** `dart-define` is a build-time configuration, not read from `.env` at runtime.
**How to avoid:** Add a null/empty check: if `_oneSignalAppId.isEmpty` then skip `NotificationService.initialize()`. This is correct behavior in test and web environments where OneSignal is not relevant.
**Warning signs:** Tests failing because `NotificationService.initialize('')` throws.

---

## Code Examples

### Rappel Model (fromJson skeleton)
```dart
// lib/models/rappel.dart
class Rappel {
  final int id;
  final String libelle;
  final String marqueProduct;
  final String? modeleOuReference;
  final String? categorieProduct;
  final String? datePublication;
  final String? dateDebutCommercialisation;
  final String? dateDateFinCommercialisation;
  final String? dateFinProcedureRappel;
  final String? motifRappel;
  final String? risquesEncourous;
  final String? conduitesATenirConsommateur;
  final String? conditionnements;
  final String? liensVersLesImages;
  final String? lienVersFicheRappel;
  final String? lienVersAffichettePdf;

  const Rappel({
    required this.id,
    required this.libelle,
    required this.marqueProduct,
    this.modeleOuReference,
    this.categorieProduct,
    this.datePublication,
    this.dateDebutCommercialisation,
    this.dateDateFinCommercialisation,
    this.dateFinProcedureRappel,
    this.motifRappel,
    this.risquesEncourous,
    this.conduitesATenirConsommateur,
    this.conditionnements,
    this.liensVersLesImages,
    this.lienVersFicheRappel,
    this.lienVersAffichettePdf,
  });

  factory Rappel.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return Rappel(
      id: map['id'] as int? ?? 0,
      libelle: map['libelle'] as String? ?? map['modeles_ou_references'] as String? ?? 'Produit inconnu',
      marqueProduct: map['marque_produit'] as String? ?? '',
      modeleOuReference: map['modeles_ou_references'] as String?,
      categorieProduct: map['categorie_produit'] as String?,
      datePublication: map['date_publication'] as String?,
      dateDebutCommercialisation: map['date_debut_commercialisation'] as String?,
      dateDateFinCommercialisation: map['date_date_fin_commercialisation'] as String?,
      dateFinProcedureRappel: map['date_de_fin_de_la_procedure_de_rappel'] as String?,
      motifRappel: map['motif_rappel'] as String?,
      risquesEncourous: map['risques_encourus'] as String?,
      conduitesATenirConsommateur: map['conduites_a_tenir_par_le_consommateur'] as String?,
      conditionnements: map['conditionnements'] as String?,
      liensVersLesImages: map['liens_vers_les_images'] as String?,
      lienVersFicheRappel: map['lien_vers_la_fiche_rappel'] as String?,
      lienVersAffichettePdf: map['lien_vers_affichette_pdf'] as String?,
    );
  }

  /// Backwards-compat: return dynamic map for screens not yet migrated
  Map<String, dynamic> toJson() => { /* ... */ };
}
```

### image_utils.dart
```dart
// lib/utils/image_utils.dart
class ImageUtils {
  static String proxiedUrl(String url) {
    final encoded = Uri.encodeComponent(url);
    return 'https://wsrv.nl/?url=$encoded&output=jpg&q=85';
  }
}
```

### date_utils.dart
```dart
// lib/utils/date_utils.dart
import 'package:vigiconso/services/rappel_service.dart';

/// Thin re-export so screens can import date_utils without knowing about rappel_service.
class DateUtils {
  static DateTime? parseDate(String dateStr) => RappelService.parseDate(dateStr);
}
```

Note: `RappelService.parseDate()` is already public and well-tested. `DateUtils.parseDate` is a delegation wrapper so screens import from utils, not services.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `rappelconso0` v1 API (`/api/records/1.0/`) | ODS v2.1 (`/api/explore/v2.1/`) | Before 2026 | v1 returns 404 — all callers MUST migrate |
| `StateNotifierProvider` (Riverpod 1.x/2.x) | `AsyncNotifierProvider` (Riverpod 3.x) | Riverpod 3.0 | New idiom, old pattern deprecated |
| `StatefulWidget` + boolean `_isLoading` | `ConsumerStatefulWidget` + `AsyncValue.when()` | Riverpod 2+ | Eliminates loading/error boilerplate |
| `ProviderContainer` (manual test setup) | `ProviderContainer.test()` | Riverpod 3.x | Auto-disposes after test |

**Deprecated/outdated:**
- `StateNotifier` / `StateNotifierProvider`: removed from Riverpod 3.x
- `rappelconso0` v1 dataset: returns 404, decommissioned
- `nhits` / `records[i]['fields']` v1 response shape: replaced by `total_count` / `results[i]` flat object in v2.1

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `String.fromEnvironment('ONESIGNAL_APP_ID')` with empty defaultValue will not crash OneSignal if the string is empty when `NotificationService.initialize('')` is called | Code Examples — dart-define | OneSignal might throw on empty string init; add explicit guard: `if (_oneSignalAppId.isNotEmpty)` |
| A2 | Replacing `StatefulWidget` with `ConsumerStatefulWidget` in `HomeScreen`, `RappelListScreen`, `FavoritesScreen` will not break the existing `IndexedStack` tab state preservation | Architecture Patterns | State is preserved by `ConsumerState` just like `State`; minor risk |
| A3 | The `date_utils.dart` thin wrapper pattern (delegating to `RappelService.parseDate`) is acceptable for TECH-04 — the goal is unified import path, not moving code | Code Examples | If reviewer interprets TECH-04 as "move the implementation" the delegation pattern would be rejected |
| A4 | `MobileScannerController.stop()` is a valid method call in `mobile_scanner` 6.0.11 | Pattern 6 — Camera lifecycle | API may differ in 6.x; verify with pub.dev docs before implementing |

**If this table is empty:** All claims were verified — not the case here (4 low-risk assumptions remain).

---

## Open Questions

1. **NEWSLETTER_API_URL configuration**
   - What we know: `newsletter-api` runs on `localhost:3000`; Flutter app needs to know the deployed URL
   - What's unclear: Is the newsletter API deployed anywhere, or only local? The `.env.example` has `NEWSLETTER_API_URL=` (empty)
   - Recommendation: Use `String.fromEnvironment('NEWSLETTER_API_URL', defaultValue: 'http://10.0.2.2:3000')` (Android emulator localhost alias) as fallback. Add to `AppConstants`.

2. **`reference_fiche` in existing favorites data**
   - What we know: Existing favorites in SharedPreferences were serialized from v2 API data using `widget.rappel['reference_fiche']` as the identity key, but `reference_fiche` is null in v2 data — meaning `libelle` was used as fallback
   - What's unclear: How many existing favorites have their identity stored as `libelle` vs a proper ID
   - Recommendation: In `Rappel.fromJson`, use `id.toString()` as the canonical identity key going forward. Existing favorites serialized with `libelle` as key will remain accessible since `FavoritesService` falls back to `libelle`.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `flutter_riverpod` | TECH-02 | ✗ (not in pubspec yet) | 3.3.2 (via dry-run) | — |
| `synchronized` | TECH-09 | ✗ (not in pubspec yet) | 3.4.1 (via dry-run) | debounce (weaker) |
| RappelConso v2.1 API | TECH-06, UX-02 | ✓ | `rappelconso-v2-gtin-trie` live | — |
| Newsletter API backend | TECH-07 | Local only (Node.js) | Express 5.x | — |
| Dart SDK | All | ✓ | `>=3.0.0 <4.0.0` | — |
| Flutter | All | ✓ | stable | — |

**Missing dependencies with no fallback:**
- `flutter_riverpod` must be added before TECH-02 can be implemented

**Missing dependencies with fallback:**
- `synchronized`: if not added, a debounce approach can partially mitigate TECH-09 (but does not fully serialize writes)

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) |
| Config file | none (uses default) |
| Quick run command | `flutter test test/services_test.dart -x` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TECH-01 | `Rappel.fromJson(map)` maps all 17+ fields correctly | unit | `flutter test test/rappel_model_test.dart -x` | ❌ Wave 0 |
| TECH-01 | `Rappel.fromJson` handles null fields gracefully | unit | `flutter test test/rappel_model_test.dart -x` | ❌ Wave 0 |
| TECH-02 | `rappelServiceProvider` returns `AsyncValue.data([...])` on success | unit (ProviderContainer) | `flutter test test/rappel_provider_test.dart -x` | ❌ Wave 0 |
| TECH-02 | `favoritesProvider` returns `AsyncValue.data([...])` on success | unit (ProviderContainer) | `flutter test test/favorites_provider_test.dart -x` | ❌ Wave 0 |
| TECH-03 | `ImageUtils.proxiedUrl('http://example.com/img.jpg')` returns correct wsrv.nl URL | unit | `flutter test test/image_utils_test.dart -x` | ❌ Wave 0 |
| TECH-04 | `DateUtils.parseDate('2026-01-15')` returns `DateTime(2026, 1, 15)` | unit | `flutter test test/date_utils_test.dart -x` | ❌ Wave 0 |
| TECH-05 | `RappelListScreen` does not contain `http.get` or `Uri.parse` calls | static (grep) | `grep -rn "http\.get\|Uri\.parse" lib/screens/rappel_screen.dart` | manual |
| TECH-06 | Barcode lookup uses `rappelconso-v2-gtin-trie` endpoint | unit (mock HTTP) | `flutter test test/rappel_service_gtin_test.dart -x` | ❌ Wave 0 |
| TECH-07 | Contact form POST returns success on 200 and shows snackbar | unit (mock HTTP) | `flutter test test/contact_service_test.dart -x` | ❌ Wave 0 |
| TECH-08 | `_oneSignalAppId` reads from `String.fromEnvironment` | static (grep) | `grep -n "fromEnvironment" lib/main.dart` | manual |
| TECH-09 | 10 rapid `toggleFavorite` calls result in exactly 1 final state | unit | `flutter test test/favorites_race_test.dart -x` | ❌ Wave 0 |
| TECH-10 | `MobileScannerController(autoStart: false)` in scanner init | static (grep) | `grep -n "autoStart" lib/screens/barcode_scanner.dart` | manual |
| UX-02 | `RappelDetailsPage` renders "Lots concernés" section when `conditionnements` non-null | widget | `flutter test test/rappel_details_widget_test.dart -x` | ❌ Wave 0 |
| UX-04 | `FavoritesScreen` shows `RappelCardShimmer` while loading | widget | `flutter test test/favorites_shimmer_test.dart -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/services_test.dart test/rappel_model_test.dart -x`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/rappel_model_test.dart` — covers TECH-01
- [ ] `test/rappel_provider_test.dart` — covers TECH-02 (RappelService provider)
- [ ] `test/favorites_provider_test.dart` — covers TECH-02 (FavoritesService provider)
- [ ] `test/image_utils_test.dart` — covers TECH-03
- [ ] `test/date_utils_test.dart` — covers TECH-04
- [ ] `test/rappel_service_gtin_test.dart` — covers TECH-06 (mock HTTP)
- [ ] `test/contact_service_test.dart` — covers TECH-07 (mock HTTP)
- [ ] `test/favorites_race_test.dart` — covers TECH-09

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | App is unauthenticated |
| V3 Session Management | no | No user sessions |
| V4 Access Control | no | No roles or permissions |
| V5 Input Validation | yes | Contact form: validate name/email/subject/message server-side in `/contact` endpoint |
| V6 Cryptography | no | No encryption introduced in this phase |

### Known Threat Patterns for this phase stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Contact form spam (no rate limiting) | Denial of Service | Out of scope for Phase 2; flagged in CONCERNS.md as v2 requirement |
| OneSignal App ID in compiled binary | Information Disclosure | Risk is LOW — App ID grants no admin access; `dart-define` removes it from source code |
| Newsletter `/contact` endpoint — no validation | Tampering | Server-side validation in the new endpoint (name, email regex, message length) |

---

## Sources

### Primary (HIGH confidence)
- Context7 `/rrousselgit/riverpod` — AsyncNotifierProvider migration, ProviderScope, ConsumerStatefulWidget, ProviderContainer.test()
- Live API call `https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/rappelconso-v2-gtin-espaces/records?limit=1` — field names verified 2026-06-18
- Live API call `https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/rappelconso-v2-gtin-trie/records?where=gtin%3D"3439496310268"&limit=1` — GTIN exact match confirmed 2026-06-18
- Live API call confirming `rappelconso0` returns 404 — v1 endpoint is gone
- Codebase grep — `_proxiedUrl()` in 4 files, `_parseDate()` duplication, `Future.delayed` in contact screen

### Secondary (MEDIUM confidence)
- pub.dev/packages/flutter_riverpod — version 3.3.2 confirmed latest stable
- pub.dev/packages/synchronized — version 3.4.1, `Lock` API description
- pub.dev/packages/mobile_scanner — `autoStart: false` and `WidgetsBindingObserver` lifecycle pattern

### Tertiary (LOW confidence)
- Web search results for `IndexedStack + MobileScanner` tab lifecycle — no authoritative source found; pattern is inferred from official mobile_scanner WidgetsBindingObserver example

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions confirmed via `dart pub add --dry-run`, live pub.dev
- Architecture: HIGH — based on direct codebase inspection and Context7-verified Riverpod patterns
- API field names: HIGH — verified via live API calls to production endpoint
- Pitfalls: HIGH — most derived from live API behavior (404 on v1, 0 results on `identification_produits` search)
- Camera lifecycle: MEDIUM — mobile_scanner docs confirm `autoStart: false` but IndexedStack-specific pattern is ASSUMED

**Research date:** 2026-06-18
**Valid until:** 2026-09-18 (API fields are stable; Riverpod 3.x is current stable)
