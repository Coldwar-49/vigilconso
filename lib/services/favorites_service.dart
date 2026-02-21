import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'favorites';

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<void> addFavorite(Map<String, dynamic> rappel) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    final id = rappel['reference_fiche'] ?? rappel['libelle'] ?? '';
    if (favorites.any((f) => (f['reference_fiche'] ?? f['libelle'] ?? '') == id)) return;
    favorites.add(rappel);
    await prefs.setString(_key, jsonEncode(favorites));
  }

  static Future<void> removeFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.removeWhere((f) => (f['reference_fiche'] ?? f['libelle'] ?? '') == id);
    await prefs.setString(_key, jsonEncode(favorites));
  }

  static Future<bool> isFavorite(String id) async {
    final favorites = await getFavorites();
    return favorites.any((f) => (f['reference_fiche'] ?? f['libelle'] ?? '') == id);
  }

  static Future<void> toggleFavorite(Map<String, dynamic> rappel) async {
    final id = rappel['reference_fiche'] ?? rappel['libelle'] ?? '';
    final already = await isFavorite(id);
    if (already) {
      await removeFavorite(id);
    } else {
      await addFavorite(rappel);
    }
  }
}
