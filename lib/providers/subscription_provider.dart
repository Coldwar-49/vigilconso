// AsyncNotifierProvider wrapping SubscriptionService.
// Mirrors lib/providers/favorites_provider.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigiconso/models/subscriptions.dart';
import 'package:vigiconso/services/subscription_service.dart';

class SubscriptionNotifier extends AsyncNotifier<Subscriptions> {
  @override
  Future<Subscriptions> build() async {
    return Subscriptions(
      brands: await SubscriptionService.getBrands(),
      categories: await SubscriptionService.getCategories(),
    );
  }

  Future<void> addBrand(String brand) async {
    await SubscriptionService.addBrand(brand);
    ref.invalidateSelf();
  }

  Future<void> removeBrand(String brand) async {
    await SubscriptionService.removeBrand(brand);
    ref.invalidateSelf();
  }

  Future<void> addCategory(String categoryKey) async {
    await SubscriptionService.addCategory(categoryKey);
    ref.invalidateSelf();
  }

  Future<void> removeCategory(String categoryKey) async {
    await SubscriptionService.removeCategory(categoryKey);
    ref.invalidateSelf();
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, Subscriptions>(
  SubscriptionNotifier.new,
);
