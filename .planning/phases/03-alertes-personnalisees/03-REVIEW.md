---
phase: 03-alertes-personnalisees
depth: standard
status: issues_found
files_reviewed: 8
files_in_scope: 18
findings:
  critical: 3
  warning: 5
  info: 0
  total: 8
---

# Phase 3 Code Review

**Coverage caveat:** the reviewer read 8 of 18 in-scope files. NOT reviewed: `lib/screens/rappel_screen.dart`, `lib/screens/main_screen.dart`, `lib/screens/rappel_details_page.dart`, `lib/widgets/cache_indicator.dart` (partially), and all 6 test files.
CR-01, CR-02 and CR-03 were re-checked against the code by the orchestrator (CR-02's runtime effect on OneSignal is plausible but not verified on a device).

## Critical

### CR-01: Foreground filter compares category keys against labels
`lib/services/subscription_service.dart:122-124` (called from `lib/main.dart:37`).
`matchesSubscriptions` does `categorie.contains(c)` with `c` a stored key (e.g. `bebe_enfant`), while the payload carries the API label. `mesAlertesProvider` also matches `AppConstants.categories[c]`; the service does not. Category-only subscribers get matching foreground notifications suppressed.
Fix: share one matcher, resolving the label the way `mesAlertesProvider` does.

### CR-02: `preventDefault()` called after an `await`
`lib/main.dart:26-43`.
The handler awaits SharedPreferences reads before `preventDefault()`/`display()`. OneSignal likely reads the decision when the listener returns, so non-matching notifications may still show; a throwing read loses the notification.
Fix: call `event.preventDefault()` synchronously first, then read subscriptions in try/catch and call `display()` only on a match.

### CR-03: "Mes alertes" is filtered by the last category browsed
`lib/providers/mes_alertes_provider.dart:13` with `lib/providers/rappel_provider.dart:30-44`.
`mesAlertesProvider` derives from `rappelServiceProvider`; `refresh(categoryKey: X)` replaces that state with category X only (and flips it to loading). Subscribed brands in other categories disappear from the feed after browsing one category.
Fix: give the feed its own provider that always fetches `categoryKey: 'all'`.

## Warning

- **WR-01** `lib/main.dart:29-43` — inconsistent rule: no `additionalData` → shown; data but no subscriptions → suppressed. Pick and document one rule.
- **WR-02** `subscription_service.dart:119-121`, `mes_alertes_provider.dart:36-37` — substring `contains` over-matches short brands ("a", "LG"). Add a minimum length or word-boundary match.
- **WR-03** `lib/providers/subscription_provider.dart:19,24,29,34` — `invalidateSelf()` puts the provider in loading, so the feed shows shimmer and the Abonnements tab flickers on every change. Set `state = AsyncData(...)` instead.
- **WR-04** `alertes_screen.dart:51,104-112`, `subscription_service.dart:105-107` — add/remove not awaited or guarded; "Marque retirée" shows regardless of outcome; `catch (_) {}` in `_syncTagsUnlocked` hides OneSignal errors.
- **WR-05** raw `Text('Erreur : $e')` in `mes_alertes_screen.dart:73` and `alertes_screen.dart:69`; `getBrands`/`getCategories` throw on corrupt stored JSON.
