---
phase: 03-alertes-personnalisees
verified: 2026-11-22T00:00:00Z
status: gaps_found
score: 2/4 roadmap success criteria verified
gaps:
  - truth: "SC1/SC2: user follows Nestle from a recall detail page, and an existing Nestle recall then appears in Mes alertes"
    status: failed
    reason: "RappelDetailsPage is a plain StatefulWidget and calls SubscriptionService.addBrand directly (rappel_details_page.dart:73), bypassing subscriptionProvider. The provider (built once, kept alive via IndexedStack) is never invalidated, so Mes alertes and the Abonnements tab do not show the new brand until app restart."
    artifacts:
      - path: "lib/screens/rappel_details_page.dart"
        issue: "No ref / provider call; follow action does not refresh subscriptionProvider"
    missing:
      - "Make RappelDetailsPage a ConsumerStatefulWidget and call ref.read(subscriptionProvider.notifier).addBrand(brand) (or invalidate subscriptionProvider)"
  - truth: "SC2 / ALRT-05: Mes alertes feed lists all recalls of followed brands/categories"
    status: failed
    reason: "CR-03 confirmed. mesAlertesProvider watches rappelServiceProvider; RappelNotifier.refresh(categoryKey: X) (called by rappel_screen.dart:67) replaces its state with category X only (and sets loading). After browsing a category, a followed brand in another category disappears from the feed."
    artifacts:
      - path: "lib/providers/mes_alertes_provider.dart"
        issue: "Derives from category-mutable rappelServiceProvider"
      - path: "lib/providers/rappel_provider.dart"
        issue: "refresh() overwrites shared state"
    missing:
      - "Dedicated feed provider that always fetches categoryKey 'all'"
  - truth: "ALRT-03: user receives a push notification when a new recall matches a followed brand/category"
    status: failed
    reason: "CR-01 confirmed: SubscriptionService.matchesSubscriptions (subscription_service.dart:122) compares the stored category KEY (e.g. bebe_enfant) against the payload's category label; unlike mesAlertesProvider it does not resolve AppConstants.categories[key]. Category-only subscribers get foreground notifications suppressed. CR-02 confirmed in code: main.dart:35-41 awaits SharedPreferences before preventDefault()/display(), so suppression is unreliable (not device-verified). Additionally, background delivery is not filtered or targeted client-side (only OneSignal tags are set); server-side segment filtering is outside the repo."
    artifacts:
      - path: "lib/services/subscription_service.dart"
        issue: "Category matcher ignores key-to-label mapping"
      - path: "lib/main.dart"
        issue: "preventDefault called after await"
    missing:
      - "Shared matcher resolving category label; call event.preventDefault() synchronously first, then display() on match inside try/catch"
human_verification:
  - test: "On a device with a real OneSignal app id, subscribe to a category only and send a matching and a non-matching push in foreground"
    expected: "Only the matching one displays"
    why_human: "Push delivery and listener timing cannot be verified statically"
---

# Phase 3: Alertes personnalisees - Verification Report

**Phase Goal:** L'utilisateur recoit automatiquement des notifications pour les rappels qui le concernent.
**Status:** gaps_found. Re-verification: No.

## Roadmap Success Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Add "Nestle" to followed brands from recall detail page | PARTIAL / FAILED | Button and `_followBrand` exist and persist to SharedPreferences, but the in-memory provider is not refreshed (details page has no ref). |
| 2 | Existing Nestle recall appears in "Mes alertes" | FAILED | Broken by the stale provider above and by CR-03 (feed depends on last category browsed). |
| 3 | Subscription screen lists followed brands and categories | VERIFIED (with caveat) | `alertes_screen.dart` watches `subscriptionProvider`; add/remove work from this screen. Brands followed from the details page show only after restart. |
| 4 | Cache freshness indicator visible on main list | VERIFIED | `CacheIndicator(fromCache: ref.watch(isFromCacheProvider))` at `rappel_screen.dart:433`; flag set in RappelNotifier build and refresh; `cache_indicator_test.dart` passes. |

## Requirements Coverage (all 6 IDs in PLAN frontmatter and REQUIREMENTS.md)

| ID | Status | Evidence |
|----|--------|----------|
| ALRT-01 follow brands | PARTIAL | Works via Abonnements screen; details-page path does not refresh state |
| ALRT-02 follow categories | SATISFIED | `addCategory` plus UI in `alertes_screen.dart` |
| ALRT-03 push on match | BLOCKED | CR-01 and CR-02 (see gaps). REQUIREMENTS.md also still marks it Pending |
| ALRT-04 manage subscriptions | SATISFIED | add/remove in `alertes_screen.dart` and service (WR-03/WR-04 are quality issues) |
| ALRT-05 dedicated feed | BLOCKED | CR-03 and stale provider |
| UX-05 cache indicator | SATISFIED | CacheIndicator wired and data-flowing (REQUIREMENTS.md checkbox still unchecked: bookkeeping) |

No orphaned requirement IDs.

## Spot-checks

- `flutter analyze`: 8 info-level issues (deprecated withOpacity, one test lint). No errors or warnings.
- `flutter test`: 108 passed, 3 skipped, 1 failed. The only failure is `test/widget_test.dart` "Counter increments smoke test" (known, TECH-13, phase 6, out of scope).
- Tests pass because they exercise the pure matcher and the derived provider in isolation. They do not cover category-key matching in the service, the details-page-to-provider path, or category refresh followed by feed read.

## Anti-patterns / review findings

- CR-01, CR-02, CR-03: confirmed in code and judged goal-blocking (above).
- WR-01 to WR-05: warnings (inconsistent no-data rule, substring over-matching, invalidateSelf flicker, unawaited add/remove with swallowed errors, raw error text). Not blocking individually.

## Gaps Summary

Artifacts exist and are mostly substantive and wired, and UX-05 plus the subscription screen work. But the core user journey (follow Nestle on a recall page, then see it in Mes alertes) fails because of the unrefreshed provider and CR-03. The push-notification requirement (ALRT-03) is undermined by CR-01 (category subscriptions never match foreground) and CR-02 (unreliable suppression). Fix these three review criticals plus the details-page provider wiring, then re-verify.

---
_Verified: 2026-11-22_
_Verifier: Claude (gsd-verifier)_
