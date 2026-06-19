import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigiconso/providers/rappel_provider.dart';
import 'package:vigiconso/models/rappel.dart';

void main() {
  group('rappelServiceProvider', () {
    test('provider is defined with correct type', () {
      // Verify the provider declaration is correct type
      expect(rappelServiceProvider, isA<AsyncNotifierProvider<RappelNotifier, List<Rappel>>>());
    });

    test('RappelNotifier can be instantiated', () {
      final notifier = RappelNotifier();
      expect(notifier, isNotNull);
    });
  });
}
