// Unit tests for mesAlertesProvider derived filtering (ALRT-05).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigiconso/models/rappel.dart';
import 'package:vigiconso/models/subscriptions.dart';
import 'package:vigiconso/providers/mes_alertes_provider.dart';
import 'package:vigiconso/providers/rappel_provider.dart';
import 'package:vigiconso/providers/subscription_provider.dart';

class _EmptySubsNotifier extends SubscriptionNotifier {
  @override
  Future<Subscriptions> build() async =>
      const Subscriptions(brands: [], categories: []);
}

class _BrandSubsNotifier extends SubscriptionNotifier {
  @override
  Future<Subscriptions> build() async =>
      const Subscriptions(brands: ['nestlé'], categories: []);
}

class _CatSubsNotifier extends SubscriptionNotifier {
  @override
  Future<Subscriptions> build() async =>
      const Subscriptions(brands: [], categories: ['alimentation']);
}

class _RappelNotifierWithData extends RappelNotifier {
  @override
  Future<List<Rappel>> build() async => [
        const Rappel(
          id: 1,
          libelle: 'Yaourt Nestlé',
          marqueProduit: 'Nestlé',
          categorieProduit: 'Alimentation > Produits laitiers',
        ),
        const Rappel(
          id: 2,
          libelle: 'Câble Samsung',
          marqueProduit: 'Samsung',
          categorieProduit: 'Électroménager',
        ),
      ];
}

class _RappelNotifierEmpty extends RappelNotifier {
  @override
  Future<List<Rappel>> build() async => [];
}

void main() {
  Future<ProviderContainer> make(
    RappelNotifier Function() rappels,
    SubscriptionNotifier Function() subs,
  ) async {
    final container = ProviderContainer(
      overrides: [
        rappelServiceProvider.overrideWith(rappels),
        subscriptionProvider.overrideWith(subs),
      ],
    );
    addTearDown(container.dispose);
    await container.read(rappelServiceProvider.future);
    await container.read(subscriptionProvider.future);
    return container;
  }

  group('mesAlertesProvider (ALRT-05)', () {
    test('is defined as Provider<AsyncValue<List<Rappel>>>', () {
      expect(mesAlertesProvider, isA<Provider<AsyncValue<List<Rappel>>>>());
    });

    test('returns empty list when subscriptions are empty', () async {
      final c = await make(_RappelNotifierWithData.new, _EmptySubsNotifier.new);
      expect(c.read(mesAlertesProvider).value, isEmpty);
    });

    test('matches brand case-insensitively', () async {
      final c = await make(_RappelNotifierWithData.new, _BrandSubsNotifier.new);
      final result = c.read(mesAlertesProvider);
      expect(result.value, hasLength(1));
      expect(result.value?.first.marqueProduit, 'Nestlé');
    });

    test('matches category', () async {
      final c = await make(_RappelNotifierWithData.new, _CatSubsNotifier.new);
      final result = c.read(mesAlertesProvider);
      expect(result.value, hasLength(1));
      expect(result.value?.first.id, 1);
    });

    test('returns empty list when no rappels match', () async {
      final c = await make(_RappelNotifierEmpty.new, _BrandSubsNotifier.new);
      expect(c.read(mesAlertesProvider).value, isEmpty);
    });
  });
}
