// Widget tests for MesAlertesScreen (ALRT-05).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigiconso/models/rappel.dart';
import 'package:vigiconso/providers/mes_alertes_provider.dart';
import 'package:vigiconso/screens/mes_alertes_screen.dart';
import 'package:vigiconso/widgets/shimmer_loading.dart';

Widget _wrap(AsyncValue<List<Rappel>> value) => ProviderScope(
      overrides: [mesAlertesProvider.overrideWith((ref) => value)],
      child: const MaterialApp(home: Scaffold(body: MesAlertesScreen())),
    );

void main() {
  group('MesAlertesScreen (ALRT-05)', () {
    testWidgets('shows RappelCardShimmer while loading', (tester) async {
      await tester.pumpWidget(_wrap(const AsyncValue.loading()));
      await tester.pump();
      expect(find.byType(RappelCardShimmer), findsWidgets);
    });

    testWidgets('shows empty state when provider returns empty list',
        (tester) async {
      await tester.pumpWidget(_wrap(const AsyncValue.data(<Rappel>[])));
      await tester.pump();
      expect(find.textContaining('Aucun rappel pour vos abonnements'),
          findsOneWidget);
    });

    testWidgets('shows list when provider returns rappels', (tester) async {
      await tester.pumpWidget(_wrap(const AsyncValue.data([
        Rappel(id: 1, libelle: 'Yaourt Nestlé', marqueProduit: 'Nestlé'),
      ])));
      await tester.pump();
      expect(find.text('Yaourt Nestlé'), findsOneWidget);
    });
  });
}
