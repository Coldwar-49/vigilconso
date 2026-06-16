# VigilConso v2.0

## What This Is

VigilConso est une application Flutter mobile (Android/iOS) et web qui permet aux consommateurs français de suivre les rappels de produits publiés par la DGCCRF via l'API gouvernementale RappelConso (data.economie.gouv.fr). L'app n'est pas encore publiée sur les stores — cette milestone vise à atteindre une qualité publiable (v2.0).

L'app existe déjà avec des fonctionnalités de base opérationnelles. Ce projet est une **milestone d'amélioration complète** : nouvelles fonctionnalités, refonte UX, refactoring technique, et correction des dettes techniques critiques.

## Core Value

Permettre à n'importe quel consommateur français d'être alerté rapidement et sans friction quand un produit qu'il utilise fait l'objet d'un rappel.

## Requirements

### Validated

<!-- Fonctionnalités déjà livrées et opérationnelles dans le codebase actuel -->

- ✓ Parcourir les rappels par catégorie (10 catégories) — existant
- ✓ Page de détail d'un rappel (images, risques, lien officiel, partage) — existant
- ✓ Favoris locaux (sauvegarder / supprimer des rappels) — existant
- ✓ Scan de code-barres (caméra + lookup par GTIN) — existant
- ✓ Notifications push via OneSignal (mobile uniquement) — existant
- ✓ Flux d'onboarding (premier lancement) — existant
- ✓ Barre de recherche sur l'écran d'accueil — existant
- ✓ Mode sombre / clair (Material 3) — existant
- ✓ Backend newsletter Node.js (Express + nodemailer + cron) — existant

### Active

<!-- Scope de la milestone v2.0 — améliorations et nouvelles fonctionnalités -->

**Recherche & Filtres**
- [ ] Recherche globale toutes catégories simultanément (pas juste la catégorie courante)
- [ ] Suggestions / autocomplétion sur marques et produits
- [ ] Historique des recherches récentes
- [ ] Filtres avancés : niveau de risque (grave / sérieux / bénin)
- [ ] Filtres avancés : plage de dates (derniers 7j / 30j / 90j / personnalisé)
- [ ] Filtres avancés : marque ou mot-clé précis
- [ ] Statut lu / non-lu sur les rappels (marquer comme vu)
- [ ] Tri des listes (date décroissante / croissante / pertinence)

**Nouvelles Fonctionnalités**
- [ ] Alertes personnalisées : l'utilisateur peut suivre des marques et/ou catégories
- [ ] Notification OneSignal automatique quand un rappel matche une marque/catégorie suivie
- [ ] Mode offline : base de données locale (SQLite via `drift` ou Hive) pour accéder aux rappels sans connexion
- [ ] Synchronisation en arrière-plan des rappels récents
- [ ] Widget home screen (Android + iOS) affichant le dernier rappel en date

**UX & Design**
- [ ] Détails de rappel enrichis (meilleures infos sur le risque, dates clés, lot concerné)
- [ ] Navigation repensée (plus intuitive entre écrans)
- [ ] Design modernisé (cohérence visuelle, accessibilité améliorée)
- [ ] Shimmer loading homogène (utiliser le widget partagé existant partout)

**Qualité Technique**
- [ ] Modèle `Rappel` typé (`fromJson` factory) — supprimer les `dynamic` partout
- [ ] Refactoring architecture : introduire Riverpod pour séparer la logique UI des services
- [ ] Extraire `_proxiedUrl()` dans `lib/utils/image_utils.dart` (dupliqué en 4 endroits)
- [ ] Extraire `_parseDate()` dans `lib/utils/date_utils.dart` (dupliqué)
- [ ] Déléguer tous les appels HTTP de `RappelListScreen` à `RappelService` (bypass cache actuel)
- [ ] Migrer le barcode scanner vers l'API v2.1 (actuellement sur v1 dépréciée)
- [ ] Vrai formulaire de contact branché à l'API newsletter-api (actuellement simulé avec Future.delayed)
- [ ] Sécuriser OneSignal App ID via `--dart-define` (actuellement hardcodé)
- [ ] Corriger la race condition sur les écritures de favoris (debounce ou Mutex)
- [ ] Corriger le cycle de vie de la caméra dans `IndexedStack` (drain batterie)
- [ ] Tests unitaires pour `RappelService`, `FavoritesService`, modèles
- [ ] Tests widget pour les écrans principaux (HomeScreen, RappelListScreen, RappelDetailsPage)
- [ ] Remplacer le widget test dummy (counter app) par de vrais tests VigilConso

### Out of Scope

- Authentification / comptes utilisateurs — l'API gouvernementale est publique, aucun besoin de compte
- Monétisation (publicités, abonnement premium) — pas l'objectif de cette version
- Publication effective sur les stores (Play Store / App Store) — objectif = être publiable, pas publier
- Desktop (Linux, Windows, macOS) — stubs présents mais cibles secondaires, pas prioritaires
- Internationalisation multi-langue — app ciblée FR uniquement

## Context

**Codebase existante:** App Flutter fonctionnelle (`lib/`) + backend newsletter Node.js (`newsletter-api/`). Architecture actuelle : StatefulWidget + setState, services statiques, SharedPreferences pour la persistence locale. Pas de state management tiers.

**Codebase map disponible:** `.planning/codebase/` contient l'analyse complète de l'architecture, des patterns, des dettes techniques et des préoccupations sécurité.

**Anti-patterns connus à corriger:**
- `_proxiedUrl()` dupliqué dans 4 fichiers écrans
- Logique HTTP et tri directement dans `RappelListScreen` (bypass du cache `RappelService`)
- `_parseDate()` dupliqué dans 2 écrans
- `dynamic` partout (pas de modèle `Rappel` typé)
- Barcode scanner sur l'endpoint v1 (`rappelconso0`) — risque de coupure sans préavis
- Contact form simulé (Future.delayed toujours succès)

**Sécurité:** OneSignal App ID hardcodé en clair dans `lib/main.dart`. API newsletter sans rate limiting ni auth sur les endpoints write.

**Tests:** Quasi-inexistants — seul `AppConstants` a des tests. Le `widget_test.dart` par défaut teste une counter app factice.

## Constraints

- **Tech Stack:** Flutter (Dart 3.x) — pas de changement de framework
- **API:** Dépendance à l'API publique data.economie.gouv.fr v2.1 — pas de contrôle sur la disponibilité
- **State Management:** Migration vers Riverpod envisagée — décision à confirmer avant Phase 1 technique
- **Stores:** Signing release Android manquant (debug keystore actuellement) — à adresser avant publication
- **Locale:** Application en français, pour le marché français

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Riverpod pour la migration state management | Meilleure testabilité, séparation logique/UI, écosystème Flutter mature | — Pending |
| SQLite via `drift` pour la BDD locale offline | Type-safe, génération de code, performant vs Hive (pas typé) | — Pending |
| Widget home screen — Android uniquement d'abord | iOS HomeKit widget plus complexe, priorité à Android | — Pending |

## Evolution

Ce document évolue à chaque transition de phase et à chaque milestone.

**Après chaque transition de phase** (via `/gsd-transition`):
1. Requirements invalidés ? → Déplacer vers Out of Scope avec raison
2. Requirements validés ? → Déplacer vers Validated avec référence de phase
3. Nouveaux requirements émergés ? → Ajouter dans Active
4. Décisions à logger ? → Ajouter dans Key Decisions
5. "What This Is" toujours exact ? → Mettre à jour si dérivé

**Après chaque milestone** (via `/gsd-complete-milestone`):
1. Revue complète de toutes les sections
2. Core Value check — toujours la bonne priorité ?
3. Audit Out of Scope — raisons toujours valides ?
4. Mettre à jour Context avec l'état actuel

---
*Last updated: 2026-06-16 after initialization*
