---
phase: 03-alertes-personnalisees
plan: 04
subsystem: ui
tags: [riverpod, cache-indicator, follow-brand]
requires: [03-01, 03-02]
provides:
  - CacheIndicator widget and isFromCacheProvider
  - "Suivre cette marque" button on RappelDetailsPage
key-files:
  created:
    - lib/widgets/cache_indicator.dart
  modified:
    - lib/providers/rappel_provider.dart
    - lib/screens/rappel_screen.dart
    - lib/screens/rappel_details_page.dart
    - test/cache_indicator_test.dart
requirements-completed: [UX-05, ALRT-01]
completed: 2026-11-22
---

# Phase 3 Plan 04: Cache indicator and follow-brand button Summary

CacheIndicator banner fed by a separate `isFromCacheProvider` (set in RappelNotifier build/refresh), shown above the list in RappelListScreen; RappelDetailsPage gets a notifications AppBar button calling `SubscriptionService.addBrand` via dynamic map access.

## Commits
- 164da37: CacheIndicator + provider + screen integration + 3 widget tests
- 77895e3: _followBrand button in RappelDetailsPage

## Verification
- cache_indicator_test: 3/3 pass. Analyze of the 4 modified lib files: no issues.
- Full `flutter test`: 108 passed, 3 skipped, 1 failed (pre-existing template `test/widget_test.dart` counter test).
- Full `flutter analyze`: 8 info issues, all pre-existing (withOpacity deprecations, widget_test.dart), none in plan files.

## Deviations
- [Rule 3] Riverpod 3.x no longer exports `StateProvider` from the main library; imported it via `package:flutter_riverpod/legacy.dart show StateProvider`.
- Third test checks the banner width equals the view width instead of the plan's Container constraints check (more meaningful).

## Notes
- "Suivre" button not exercised in a widget test (no test specified); verified by analysis only.

## Self-Check: PASSED
