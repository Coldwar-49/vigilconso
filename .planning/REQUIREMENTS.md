# Requirements: VigilConso v2.0

**Defined:** 2026-06-16
**Core Value:** Permettre à n'importe quel consommateur français d'être alerté rapidement et sans friction quand un produit qu'il utilise fait l'objet d'un rappel.

## v1 Requirements

### Recherche & Filtres

- [x] **SRCH-01**: L'utilisateur peut rechercher des rappels dans toutes les catégories simultanément depuis un champ de recherche global *(partiellement existant — limité à la catégorie courante)*
- [ ] **SRCH-02**: L'utilisateur voit des suggestions d'autocomplétion (marques, produits) en tapant dans la barre de recherche
- [ ] **SRCH-03**: L'utilisateur peut retrouver ses dernières recherches dans l'historique
- [ ] **SRCH-04**: L'utilisateur peut filtrer les rappels par niveau de risque (grave / modéré / faible)
- [ ] **SRCH-05**: L'utilisateur peut filtrer les rappels par plage de dates (7j / 30j / 90j / personnalisé)
- [ ] **SRCH-06**: L'utilisateur peut filtrer les rappels par marque ou mot-clé précis
- [ ] **SRCH-07**: L'utilisateur peut marquer un rappel comme lu / non-lu
- [ ] **SRCH-08**: L'utilisateur peut trier les listes par date (récent → ancien ou inverse) et par pertinence

### Interface & UX

- [x] **UX-01**: L'utilisateur voit des cartes de rappels style Google News (liste verticale, image droite, texte gauche) *(livré dans ce commit)*
- [ ] **UX-02**: L'utilisateur voit les détails enrichis d'un rappel (dates clés, lots concernés, description du risque, actions à effectuer)
- [ ] **UX-03**: La navigation entre les écrans est intuitive et cohérente
- [ ] **UX-04**: L'interface utilise des shimmer loading homogènes sur tous les écrans
- [ ] **UX-05**: L'utilisateur comprend clairement si les données affichées viennent du cache ou du réseau en temps réel

### Alertes Personnalisées

- [x] **ALRT-01**: L'utilisateur peut suivre des marques spécifiques (ex: Nutella, Samsung)
- [x] **ALRT-02**: L'utilisateur peut suivre des catégories (ex: Alimentation, Électroménager)
- [ ] **ALRT-03**: L'utilisateur reçoit une notification push quand un nouveau rappel correspond à une marque ou catégorie suivie
- [ ] **ALRT-04**: L'utilisateur peut gérer sa liste d'abonnements (ajouter, supprimer)
- [ ] **ALRT-05**: L'utilisateur peut voir un fil dédié aux rappels de ses marques/catégories suivies

### Mode Offline

- [ ] **OFFL-01**: L'utilisateur peut consulter les rappels récents sans connexion internet
- [ ] **OFFL-02**: L'app synchronise automatiquement les données en arrière-plan quand la connexion est disponible
- [ ] **OFFL-03**: L'utilisateur voit clairement un indicateur quand il consulte des données en cache (date de dernière sync)
- [ ] **OFFL-04**: Les rappels récents (derniers 30 jours) sont stockés localement dans une base de données SQLite

### Widget Home Screen

- [ ] **WDGT-01**: L'utilisateur peut ajouter un widget Android sur son écran d'accueil affichant le dernier rappel en date
- [ ] **WDGT-02**: Le widget affiche le titre du rappel, la catégorie, et la date de publication
- [ ] **WDGT-03**: Appuyer sur le widget ouvre directement la page de détail du rappel dans l'app

### Qualité Technique

- [ ] **TECH-01**: Un modèle `Rappel` typé existe avec factory `fromJson` — toutes les occurrences de `dynamic` dans les services et écrans sont remplacées
- [ ] **TECH-02**: `RappelService` est refactorisé avec Riverpod (providers) — la logique est séparée des widgets
- [ ] **TECH-03**: `_proxiedUrl()` est extrait dans `lib/utils/image_utils.dart` (suppression des 4 duplications)
- [ ] **TECH-04**: `_parseDate()` est extrait dans `lib/utils/date_utils.dart` (suppression des 2 duplications)
- [ ] **TECH-05**: `RappelListScreen` délègue tous ses appels HTTP à `RappelService` (bypass du cache supprimé)
- [ ] **TECH-06**: Le barcode scanner est migré vers l'API v2.1 (suppression de l'endpoint v1 déprécié `rappelconso0`)
- [ ] **TECH-07**: Le formulaire de contact envoie réellement un message via l'API newsletter-api (suppression du `Future.delayed` simulé)
- [ ] **TECH-08**: L'OneSignal App ID est chargé via `--dart-define` (suppression du hardcoding dans `lib/main.dart`)
- [ ] **TECH-09**: La race condition sur les favoris est corrigée (debounce ou sérialisation des écritures)
- [ ] **TECH-10**: Le cycle de vie de la caméra dans `IndexedStack` est corrigé (plus de drain batterie)
- [ ] **TECH-11**: Les tests unitaires couvrent `RappelService`, `FavoritesService`, et le modèle `Rappel`
- [ ] **TECH-12**: Les tests widget couvrent `HomeScreen`, `RappelListScreen`, et `RappelDetailsPage`
- [ ] **TECH-13**: Le `widget_test.dart` factice est remplacé par de vrais tests VigilConso

## v2 Requirements

### Fonctionnalités futures (hors scope v2.0)

- **V2-01**: Widget iOS (WidgetKit) pour l'écran d'accueil
- **V2-02**: Notifications in-app (sans push) via un centre de notifications dans l'app
- **V2-03**: Partage de rappel enrichi (image + texte dans le share sheet)
- **V2-04**: Statistiques personnelles (nb rappels vus, catégories les plus suivies)
- **V2-05**: Export PDF/image d'un rappel
- **V2-06**: API newsletter sécurisée (rate limiting, auth sur endpoints write)
- **V2-07**: Base de données newsletter chiffrée (remplacer JSON plaintext)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Authentification / comptes utilisateurs | API gouvernementale publique — aucune notion d'identité nécessaire |
| Monétisation (pub, premium) | Pas l'objectif de cette version |
| Support multilingue | App ciblée marché français uniquement |
| Desktop (Linux, Windows, macOS) | Stubs présents mais cibles secondaires, non prioritaires |
| Publication sur les stores | Objectif = être publiable, pas publier dans cette milestone |
| Widget iOS (WidgetKit) | Complexité iOS élevée, reporté à v3 |

## Traceability

*Rempli par le roadmapper — voir ROADMAP.md*

| Requirement | Phase | Status |
|-------------|-------|--------|
| SRCH-01 | Phase 1 | In Progress |
| SRCH-02 | Phase 1 | Pending |
| SRCH-03 | Phase 1 | Pending |
| SRCH-04 | Phase 1 | Pending |
| SRCH-05 | Phase 1 | Pending |
| SRCH-06 | Phase 1 | Pending |
| SRCH-07 | Phase 1 | Pending |
| SRCH-08 | Phase 1 | Pending |
| UX-01 | Phase 1 | Complete |
| UX-02 | Phase 2 | Pending |
| UX-03 | Phase 2 | Pending |
| UX-04 | Phase 2 | Pending |
| UX-05 | Phase 3 | Pending |
| ALRT-01 | Phase 3 | Complete |
| ALRT-02 | Phase 3 | Complete |
| ALRT-03 | Phase 3 | Pending |
| ALRT-04 | Phase 3 | Pending |
| ALRT-05 | Phase 3 | Pending |
| OFFL-01 | Phase 4 | Pending |
| OFFL-02 | Phase 4 | Pending |
| OFFL-03 | Phase 4 | Pending |
| OFFL-04 | Phase 4 | Pending |
| WDGT-01 | Phase 5 | Pending |
| WDGT-02 | Phase 5 | Pending |
| WDGT-03 | Phase 5 | Pending |
| TECH-01 | Phase 2 | Pending |
| TECH-02 | Phase 2 | Pending |
| TECH-03 | Phase 2 | Pending |
| TECH-04 | Phase 2 | Pending |
| TECH-05 | Phase 2 | Pending |
| TECH-06 | Phase 2 | Pending |
| TECH-07 | Phase 2 | Pending |
| TECH-08 | Phase 2 | Pending |
| TECH-09 | Phase 2 | Pending |
| TECH-10 | Phase 2 | Pending |
| TECH-11 | Phase 6 | Pending |
| TECH-12 | Phase 6 | Pending |
| TECH-13 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 38 total
- Mapped to phases: 38
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-16*
*Last updated: 2026-06-16 after initial definition*
