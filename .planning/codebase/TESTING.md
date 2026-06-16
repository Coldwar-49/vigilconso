# Testing

**Analysis Date:** 2026-06-16

## Testing Framework

**Framework:** `flutter_test` (bundled with Flutter SDK)
**Test runner:** `flutter test`
**No mocking library installed** — `mockito` and `mocktail` are absent from `pubspec.yaml`

## Test Structure

```
test/
├── widget_test.dart       — Widget smoke test (default Flutter template)
└── services_test.dart     — Unit tests for AppConstants utilities
```

**Total test files:** 2
**Total test groups:** 3 (in `services_test.dart`)
**Total test cases:** ~8

## Existing Tests

### `test/widget_test.dart`
Default Flutter counter widget smoke test — tests a `MyApp` stub widget, not the actual app. **Not testing real application code.**

```dart
testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.text('0'), findsOneWidget);
  // ...
});
```

### `test/services_test.dart`
Unit tests for `AppConstants` utilities in `lib/utils/constants.dart`:

```dart
group('AppConstants - getCategoryFilter', () { ... }); // 5 tests
group('AppConstants - categories map', () { ... });    // 2 tests
group('AppConstants - apiBaseUrl', () { ... });        // 2 tests
```

Tests cover:
- `getCategoryFilter()` returns correct OData filter strings per category
- `AppConstants.categories` map contains expected keys and non-empty labels
- `apiBaseUrl` starts with `https://` and contains `economie.gouv.fr`

## Coverage Gaps

### Untested Services
- `lib/services/rappel_service.dart` — Core HTTP fetch logic, pagination, filtering, caching (`SharedPreferences`)
- `lib/services/favorites_service.dart` — Add/remove/list favorites via `SharedPreferences`
- `lib/services/notification_service.dart` — Push notification setup
- `lib/services/alerts_notifier.dart` — `ValueNotifier<int>` update logic
- `lib/services/subscribe_to_newsletter.dart` — Newsletter subscription HTTP call

### Untested Screens
All screens are untested widget-level:
- `lib/screens/home_screen.dart`
- `lib/screens/rappel_screen.dart`
- `lib/screens/rappel_details_page.dart`
- `lib/screens/favorites_screen.dart`
- `lib/screens/search_screen.dart`
- `lib/screens/onboarding_screen.dart`
- `lib/screens/main_screen.dart`

### Untested Utils
- `lib/utils/build_context_extensions.dart`

## Testing Patterns

**Unit test pattern** (services_test.dart):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vigiconso/utils/constants.dart';

void main() {
  group('GroupName', () {
    test('description', () {
      final result = Subject.method(args);
      expect(result, matcher);
    });
  });
}
```

**Widget test pattern** (widget_test.dart):
```dart
testWidgets('description', (WidgetTester tester) async {
  await tester.pumpWidget(const MyWidget());
  expect(find.text('expected'), findsOneWidget);
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
});
```

## Mocking

**No mocking library installed.** The static service pattern makes mocking difficult without dependency injection.

To add mocking:
```yaml
# pubspec.yaml dev_dependencies
mockito: ^5.4.0
build_runner: ^2.4.0
```

Services must be refactored from static methods to injected instances to be mockable.

## Known Issues

- `// ignore: depend_on_referenced_packages` present in `test/widget_test.dart` — suppress linting for test-only dependency
- `widget_test.dart` tests a stub counter app, not the real `vigiconso` app — misleading test file
- No integration tests (`integration_test/` directory absent)
- No CI configuration found that runs tests automatically

---

*Testing analysis: 2026-06-16*
