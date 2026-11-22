// Derived Provider - no API call. Pure in-memory filter of rappelServiceProvider.
// When subscriptions are empty, returns an empty list (never all rappels).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigiconso/models/rappel.dart';
import 'package:vigiconso/models/subscriptions.dart';
import 'package:vigiconso/providers/rappel_provider.dart';
import 'package:vigiconso/providers/subscription_provider.dart';
import 'package:vigiconso/utils/constants.dart';

/// Rappels filtered by user subscriptions (brand OR category match).
final mesAlertesProvider = Provider<AsyncValue<List<Rappel>>>((ref) {
  final rappelsAsync = ref.watch(rappelServiceProvider);
  final subsAsync = ref.watch(subscriptionProvider);

  if (rappelsAsync is AsyncLoading || subsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }
  if (rappelsAsync is AsyncError<List<Rappel>>) {
    return AsyncValue.error(rappelsAsync.error, rappelsAsync.stackTrace);
  }
  if (subsAsync is AsyncError<Subscriptions>) {
    return AsyncValue.error(subsAsync.error, subsAsync.stackTrace);
  }

  final rappels = rappelsAsync.value ?? const <Rappel>[];
  final subs =
      subsAsync.value ?? const Subscriptions(brands: [], categories: []);

  if (subs.isEmpty) {
    return const AsyncValue.data(<Rappel>[]);
  }

  final filtered = rappels.where((r) {
    final marque = r.marqueProduit.toLowerCase();
    final brandMatch =
        subs.brands.any((b) => marque.contains(b.toLowerCase()));

    final categorie = (r.categorieProduit ?? '').toLowerCase();
    final catMatch = subs.categories.any((c) {
      if (categorie.contains(c.toLowerCase())) return true;
      // Subscriptions store keys (e.g. 'bebe_enfant'); API uses labels.
      final label = AppConstants.categories[c]?.toLowerCase();
      return label != null && categorie.contains(label);
    });

    return brandMatch || catMatch;
  }).toList();

  return AsyncValue.data(filtered);
});
