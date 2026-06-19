import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigiconso/providers/favorites_provider.dart';
import 'package:vigiconso/models/rappel.dart';

void main() {
  group('favoritesProvider', () {
    test('provider is defined with correct type', () {
      expect(favoritesProvider, isA<AsyncNotifierProvider<FavoritesNotifier, List<Rappel>>>());
    });

    test('FavoritesNotifier can be instantiated', () {
      final notifier = FavoritesNotifier();
      expect(notifier, isNotNull);
    });
  });
}
