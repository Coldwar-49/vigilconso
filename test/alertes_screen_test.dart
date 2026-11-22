// Widget tests for AlertesScreen CRUD (ALRT-04).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigiconso/models/subscriptions.dart';
import 'package:vigiconso/providers/mes_alertes_provider.dart';
import 'package:vigiconso/providers/subscription_provider.dart';
import 'package:vigiconso/screens/alertes_screen.dart';
import 'package:vigiconso/widgets/shimmer_loading.dart';

class _LoadingSubscriptionNotifier extends SubscriptionNotifier {
  @override
  Future<Subscriptions> build() => Completer<Subscriptions>().future;
}

class _FilledSubscriptionNotifier extends SubscriptionNotifier {
  @override
  Future<Subscriptions> build() async => const Subscriptions(
        brands: ['Nestlé', 'Samsung'],
        categories: ['alimentation'],
      );
}

Widget _app(SubscriptionNotifier Function() notifier, {bool loading = false}) {
  return ProviderScope(
    overrides: [
      subscriptionProvider.overrideWith(notifier),
      mesAlertesProvider.overrideWith((ref) => loading
          ? const AsyncValue.loading()
          : const AsyncValue.data([])),
    ],
    child: const MaterialApp(home: AlertesScreen()),
  );
}

void main() {
  group('AlertesScreen (ALRT-04)', () {
    testWidgets('shows shimmer while subscriptionProvider is loading',
        (tester) async {
      await tester
          .pumpWidget(_app(_LoadingSubscriptionNotifier.new, loading: true));
      await tester.pump();
      await tester.tap(find.text('Abonnements'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(RappelCardShimmer), findsWidgets);
    });

    testWidgets('shows brand ListTiles and delete icons', (tester) async {
      await tester.pumpWidget(_app(_FilledSubscriptionNotifier.new));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Abonnements'));
      await tester.pumpAndSettle();
      expect(find.text('Nestlé'), findsOneWidget);
      expect(find.text('Samsung'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('shows FilterChips for categories', (tester) async {
      await tester.pumpWidget(_app(_FilledSubscriptionNotifier.new));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Abonnements'));
      await tester.pumpAndSettle();
      expect(find.byType(FilterChip), findsWidgets);
    });
  });
}
