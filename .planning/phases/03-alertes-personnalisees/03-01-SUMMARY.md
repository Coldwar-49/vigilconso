---
phase: 03-alertes-personnalisees
plan: 01
subsystem: subscriptions
tags: [riverpod, shared_preferences, onesignal, synchronized]
requires: []
provides:
  - Subscriptions model
  - SubscriptionService (brands/categories CRUD, Lock, OneSignal tag sync)
  - subscriptionProvider (AsyncNotifier)
affects: [03-02, 03-03, 03-04]
key-files:
  created:
    - lib/models/subscriptions.dart
    - lib/services/subscription_service.dart
    - lib/providers/subscription_provider.dart
    - test/subscription_service_test.dart
    - test/notification_filter_test.dart
    - test/mes_alertes_provider_test.dart
    - test/alertes_screen_test.dart
    - test/mes_alertes_screen_test.dart
    - test/cache_indicator_test.dart
key-decisions:
  - "Brand dedupe compares the sanitized (trimmed, truncated) lowercase value"
  - "OneSignal tag sync failures are swallowed; SharedPreferences is source of truth"
requirements-completed: [ALRT-01, ALRT-02]
completed: 2026-11-22
---

# Phase 3 Plan 01: Subscription foundation Summary

Lock-serialized SharedPreferences subscription service (brands + categories) with non-fatal OneSignal tag sync, an AsyncNotifier provider, and 6 test files (1 real, 5 stubs).

## Commits
- b23e372: feat - model, service, provider
- db186ee: test - 12 real service tests plus 5 Wave 0 stubs

## Verification
- `flutter analyze` on the 3 new lib files: no issues.
- `flutter test test/subscription_service_test.dart`: 12/12 pass.
- Full `flutter test`: 91 passed, 3 skipped, 1 failed. The failure is `test/widget_test.dart` "Counter increments smoke test", the default Flutter template test, which was not touched by this plan (pre-existing).
- Full `flutter analyze`: 22 pre-existing info/warning issues in other files (e.g. deprecated `withOpacity`); none in files from this plan.

## Deviations from Plan
- [Rule 1 - Bug] In `addBrand`, the plan computed the duplicate-check key from the untruncated brand while storing the truncated one, so a >100 char brand could be added twice. The key is now derived from the sanitized value. Added a truncation test (T-3-01).
- Added `TestWidgetsFlutterBinding.ensureInitialized()` to the service test so the OneSignal platform-channel call fails into the try/catch cleanly.

## Notes
- ALRT-04 is listed in the plan frontmatter, but only the service-level CRUD exists here. The UI arrives in plan 03-04, so I did not mark ALRT-04 complete.
- `flutter` tooling modified `pubspec.lock` and `analysis_options.yaml` in the working tree; not staged.
- `state advance-plan` failed with "Cannot parse Current Plan or Total Plans in Phase from STATE.md". Progress, roadmap and requirement updates ran.

## Self-Check: PASSED
