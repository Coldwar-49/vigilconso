import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigiconso/models/rappel.dart';
import 'package:vigiconso/providers/favorites_provider.dart';
import 'package:vigiconso/screens/favorites_screen.dart';
import 'package:vigiconso/widgets/shimmer_loading.dart';

class _LoadingNotifier extends FavoritesNotifier {
  @override
  Future<List<Rappel>> build() => Completer<List<Rappel>>().future;
}

class _EmptyNotifier extends FavoritesNotifier {
  @override
  Future<List<Rappel>> build() async => [];
}

void main() {
  group('FavoritesScreen shimmer loading', () {
    testWidgets('shows RappelCardShimmer while favorites are loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesProvider.overrideWith(_LoadingNotifier.new),
          ],
          child: const MaterialApp(home: FavoritesScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(RappelCardShimmer), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows empty state when favorites list is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritesProvider.overrideWith(_EmptyNotifier.new),
          ],
          child: const MaterialApp(home: FavoritesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Aucun favori'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
