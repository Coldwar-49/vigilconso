// lib/providers/favorites_provider.dart
// Wraps FavoritesService static methods in a Riverpod AsyncNotifierProvider.
// Lock-based race condition fix lives in FavoritesService (Plan 03).
// This provider calls toggleFavorite and invalidates self to trigger rebuild.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigiconso/models/rappel.dart';
import 'package:vigiconso/services/favorites_service.dart';

class FavoritesNotifier extends AsyncNotifier<List<Rappel>> {
  @override
  Future<List<Rappel>> build() async {
    final maps = await FavoritesService.getFavorites();
    return maps.map((m) => Rappel.fromJson(m)).toList();
  }

  /// Toggle a favorite and refresh the list.
  /// Lock-based serialization is handled inside FavoritesService.toggleFavorite.
  Future<void> toggle(Map<String, dynamic> rappelMap) async {
    await FavoritesService.toggleFavorite(rappelMap);
    ref.invalidateSelf(); // re-calls build() to reflect updated favorites
  }
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<Rappel>>(FavoritesNotifier.new);
