// lib/providers/rappel_provider.dart
// Wraps RappelService static methods in a Riverpod AsyncNotifierProvider.
// Pattern: AsyncNotifierProvider (NOT StateNotifierProvider — removed in Riverpod 3.x)
// Source: RESEARCH.md Pattern 1, verified via Context7 riverpod AsyncNotifier docs.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:vigiconso/models/rappel.dart';
import 'package:vigiconso/services/rappel_service.dart';

/// Tracks whether the last fetch returned cached data (UX-05).
final isFromCacheProvider = StateProvider<bool>((ref) => false);

class RappelNotifier extends AsyncNotifier<List<Rappel>> {
  @override
  Future<List<Rappel>> build() async {
    final result = await RappelService.fetchRappels(categoryKey: 'all');
    ref.read(isFromCacheProvider.notifier).state =
        result['fromCache'] as bool? ?? false;
    if (result.containsKey('error')) {
      throw Exception(result['error']);
    }
    return (result['results'] as List<dynamic>)
        .map((item) => Rappel.fromJson(item))
        .toList();
  }

  /// Refreshes the list for a given category.
  /// Screens call: ref.read(rappelServiceProvider.notifier).refresh(categoryKey: key)
  Future<void> refresh({String categoryKey = 'all', bool forceRefresh = false}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await RappelService.fetchRappels(
        categoryKey: categoryKey,
        forceRefresh: forceRefresh,
      );
      // Side-effect: cache flag for CacheIndicator (UX-05)
      ref.read(isFromCacheProvider.notifier).state =
          result['fromCache'] as bool? ?? false;
      if (result.containsKey('error')) throw Exception(result['error']);
      return (result['results'] as List<dynamic>)
          .map((item) => Rappel.fromJson(item))
          .toList();
    });
  }
}

final rappelServiceProvider =
    AsyncNotifierProvider<RappelNotifier, List<Rappel>>(RappelNotifier.new);
