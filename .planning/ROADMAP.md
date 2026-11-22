# Roadmap: VigilConso v2.0

**Created:** 2026-06-16
**Phases:** 6 | **Requirements:** 38 | **Coverage:** 100% ✓

---

## Phase Overview

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|-----------------|
| 1 | ~~Recherche & Filtres~~ ✅ | L'utilisateur peut trouver n'importe quel rappel en quelques secondes | SRCH-01 à SRCH-08, UX-01 | 5/5 ✅ |
| 2 | Refactoring & Qualité Technique | Code propre, typé, sans duplications, architecture Riverpod | TECH-01 à TECH-10, UX-02 à UX-04 | 4 |
| 3 | Alertes Personnalisées | L'utilisateur est notifié automatiquement pour ses marques/catégories suivies | ALRT-01 à ALRT-05, UX-05 | 4 |
| 4 | Mode Offline | L'app fonctionne sans connexion avec données récentes synchronisées | OFFL-01 à OFFL-04 | 4 |
| 5 | Widget Home Screen | L'utilisateur voit le dernier rappel directement sur son écran d'accueil Android | WDGT-01 à WDGT-03 | 3 |
| 6 | Tests & Qualité Finale | L'app est testée et prête pour publication v2.0 | TECH-11 à TECH-13 | 3 |

---

## Phase Details

### Phase 1: Recherche & Filtres

**Goal:** L'utilisateur peut trouver n'importe quel rappel en quelques secondes — recherche globale, filtres, historique, tri.

**UI hint:** yes

**Requirements:**
- SRCH-01: Recherche globale toutes catégories (améliorer l'existant)
- SRCH-02: Suggestions / autocomplétion marques et produits
- SRCH-03: Historique des recherches récentes
- SRCH-04: Filtre par niveau de risque
- SRCH-05: Filtre par plage de dates
- SRCH-06: Filtre par marque / mot-clé
- SRCH-07: Statut lu / non-lu
- SRCH-08: Tri des listes (date + pertinence)
- UX-01: Cartes style Google News *(livré — déjà intégré)*

**Success criteria:**
1. L'utilisateur peut chercher "Nutella" et voir les résultats de toutes les catégories en moins de 3 secondes
2. En tapant dans la barre de recherche, des suggestions apparaissent après 2 caractères
3. Les recherches récentes sont visibles et cliquables dans l'historique
4. Les filtres (risque, date, marque) réduisent visiblement les résultats de la liste
5. Un rappel peut être marqué lu/non-lu avec persistance entre sessions

**Plans:** 4 plans

**Status:** ✅ Complete (2026-06-18) | Verification: human_needed (5/5 implemented, device testing pending)

Plans:
- [x] 01-01-PLAN.md — Recherche globale + SearchScreen (correction bypass cache, wave 1)
- [x] 01-02-PLAN.md — FilterPanel (filtres avancés + tri, wave 2)
- [x] 01-03-PLAN.md — Historique + autocomplétion (wave 2, parallèle avec Plan 2)
- [x] 01-04-PLAN.md — Statut lu/non-lu (badge NON LU + persistance, wave 2, parallèle)

---

### Phase 2: Refactoring & Qualité Technique

**Goal:** Codebase propre — modèle typé, architecture Riverpod, zéro duplication, bugs critiques corrigés.

**UI hint:** no

**Requirements:**
- TECH-01: Modèle `Rappel` typé avec `fromJson`
- TECH-02: Migration Riverpod (providers pour services)
- TECH-03: Extraction `_proxiedUrl()` → `image_utils.dart`
- TECH-04: Extraction `_parseDate()` → `date_utils.dart`
- TECH-05: `RappelListScreen` délègue à `RappelService`
- TECH-06: Barcode scanner → API v2.1
- TECH-07: Formulaire de contact → API réelle
- TECH-08: OneSignal App ID → `--dart-define`
- TECH-09: Race condition favoris corrigée
- TECH-10: Cycle de vie caméra `IndexedStack` corrigé
- UX-02: Page de détail enrichie (lots, dates clés, actions)
- UX-03: Navigation repensée
- UX-04: Shimmer homogène sur tous les écrans

**Success criteria:**
1. `flutter analyze` retourne 0 issues sur tout le projet
2. Plus aucune utilisation de `dynamic` pour les données de rappel — tout est typé `Rappel`
3. Le barcode scanner retourne des résultats via l'API v2.1 (test avec un EAN existant)
4. Le formulaire de contact envoie réellement un email (vérifiable dans le backend)

**Plans:** 4 plans

Plans:
- [ ] 02-01-PLAN.md — Rappel model (fromJson) + image_utils + date_utils + Wave 0 test stubs (wave 1)
- [ ] 02-02-PLAN.md — Riverpod providers + ProviderScope + screen migration + navigation (wave 2)
- [ ] 02-03-PLAN.md — Bug fixes: barcode v2.1, contact form /contact, Lock race condition, camera lifecycle (wave 2, parallèle avec Plan 02)
- [ ] 02-04-PLAN.md — Page de détail enrichie (dates, lots, action bar sticky) + shimmer homogène (wave 3)

---

### Phase 3: Alertes Personnalisées

**Goal:** L'utilisateur reçoit automatiquement des notifications pour les rappels qui le concernent.

**UI hint:** yes

**Requirements:**
- ALRT-01: Suivre des marques
- ALRT-02: Suivre des catégories
- ALRT-03: Notification push lors d'un match
- ALRT-04: Gestion des abonnements (CRUD)
- ALRT-05: Fil dédié aux rappels suivis
- UX-05: Indicateur cache vs. temps réel

**Success criteria:**
1. L'utilisateur peut ajouter "Nestlé" à ses marques suivies depuis la page de détail d'un rappel
2. Un rappel Nestlé existant apparaît dans le fil "Mes alertes"
3. L'écran de gestion des abonnements liste marques et catégories suivies
4. L'indicateur de fraîcheur des données est visible sur la liste principale

**Plans:** 4 plans

Plans:
- [x] 03-01-PLAN.md — Subscriptions model + SubscriptionService + subscriptionProvider + Wave 0 test stubs (wave 1)
- [x] 03-02-PLAN.md — mesAlertesProvider (derived filter) + AlertesScreen CRUD + MesAlertesScreen + 5th nav tab (wave 2)
- [ ] 03-03-PLAN.md — OneSignal foreground listener + matchesSubscriptions pure function (wave 2, parallel)
- [ ] 03-04-PLAN.md — CacheIndicator (UX-05) + isFromCacheProvider + "Suivre cette marque" button (wave 3)

---

### Phase 4: Mode Offline

**Goal:** L'app reste utilisable sans connexion — les rappels récents sont disponibles localement.

**UI hint:** no

**Requirements:**
- OFFL-01: Consultation offline des rappels récents
- OFFL-02: Sync en arrière-plan
- OFFL-03: Indicateur date de dernière sync
- OFFL-04: BDD locale SQLite (drift) — 30 jours d'historique

**Success criteria:**
1. En mode avion, les rappels chargés lors de la session précédente sont accessibles
2. La date de dernière synchronisation est visible sur l'écran d'accueil
3. L'app se synchronise automatiquement au retour de la connexion (sans action utilisateur)
4. La BDD locale contient les rappels des 30 derniers jours après la première sync complète

**Plans:**
1. Intégration `drift` — schéma de BDD, migration, DAO
2. `RappelService` — couche offline-first (cache BDD prioritaire, API en background)
3. Sync en arrière-plan (workmanager ou flutter_background_fetch)
4. Indicateurs visuels offline / sync en cours

---

### Phase 5: Widget Home Screen Android

**Goal:** L'utilisateur voit le dernier rappel depuis son écran d'accueil Android sans ouvrir l'app.

**UI hint:** yes

**Requirements:**
- WDGT-01: Widget Android affichant le dernier rappel
- WDGT-02: Widget affiche titre, catégorie, date
- WDGT-03: Appui widget → page de détail dans l'app

**Success criteria:**
1. Le widget est disponible dans le sélecteur de widgets Android
2. Le widget affiche le titre et la date du rappel le plus récent
3. Appuyer sur le widget ouvre la page de détail du rappel correspondant dans l'app
4. Le widget se met à jour automatiquement (toutes les heures)

**Plans:**
1. Intégration `home_widget` — configuration Android AppWidget
2. Layout XML du widget (titre, catégorie, date, icône)
3. Service de mise à jour du widget (déclenché par la sync offline)
4. Deep link widget → `RappelDetailsPage`

---

### Phase 6: Tests & Qualité Finale

**Goal:** L'app est correctement testée et prête pour soumission sur les stores.

**UI hint:** no

**Requirements:**
- TECH-11: Tests unitaires (`RappelService`, `FavoritesService`, modèle `Rappel`)
- TECH-12: Tests widget (`HomeScreen`, `RappelListScreen`, `RappelDetailsPage`)
- TECH-13: Suppression du widget_test.dart factice

**Success criteria:**
1. `flutter test` passe à 100% avec couverture des services principaux
2. Les tests widget couvrent les états loading, error, et data pour les 3 écrans principaux
3. Aucun test factice (counter app) dans la suite de tests
4. `flutter analyze` retourne 0 issues sur l'ensemble du projet

**Plans:**
1. Tests unitaires — modèle `Rappel`, `RappelService`, `FavoritesService`
2. Tests widget — `HomeScreen`, `RappelListScreen`, `RappelDetailsPage`
3. Revue finale qualité — analyze, lints, release build Android

---

## Dependency Graph

```
Phase 1 (Recherche) ──→ Phase 2 (Refactoring) ──→ Phase 3 (Alertes)
                                    │                      │
                                    └──────────────────────┤
                                                           ↓
                                                    Phase 4 (Offline)
                                                           │
                                                           ↓
                                                    Phase 5 (Widget)
                                                           │
                                                           ↓
                                                    Phase 6 (Tests)
```

Phase 1 et Phase 2 peuvent être lancées en parallèle si nécessaire (elles touchent des fichiers distincts en majorité). Phase 3, 4, 5, 6 sont séquentielles.

---

*Roadmap created: 2026-06-16*
*Plans Phase 1 created: 2026-06-17*
*Plans Phase 2 created: 2026-06-18*
