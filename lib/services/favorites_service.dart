import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

class FavoritesService {
  static const String _key = 'favorites';
  static final _lock = Lock(); // Sérialise toutes les écritures — non-réentrant (Pitfall 6)

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<bool> isFavorite(String id) async {
    final favorites = await getFavorites();
    return favorites.any((f) {
      final fId = f['id']?.toString() ??
                  f['lien_vers_la_fiche_rappel']?.toString() ??
                  f['libelle']?.toString() ?? '';
      return fId == id;
    });
  }

  static Future<void> toggleFavorite(Map<String, dynamic> rappel) async {
    await _lock.synchronized(() async {
      // Utiliser id.toString() comme clé canonique (reference_fiche inexistant en v2)
      final id = rappel['id']?.toString() ??
                 rappel['lien_vers_la_fiche_rappel']?.toString() ??
                 rappel['libelle']?.toString() ?? '';
      final already = await _isFavoriteUnlocked(id);
      if (already) {
        await _removeFavoriteUnlocked(id);
      } else {
        await _addFavoriteUnlocked(rappel);
      }
    });
  }

  static Future<void> addFavorite(Map<String, dynamic> rappel) async {
    await _lock.synchronized(() async {
      await _addFavoriteUnlocked(rappel);
    });
  }

  static Future<void> removeFavorite(String id) async {
    await _lock.synchronized(() async {
      await _removeFavoriteUnlocked(id);
    });
  }

  // ── Helpers privés non verrouillés ────────────────────────────────────────
  // Appelés UNIQUEMENT depuis l'intérieur d'un bloc _lock.synchronized.
  // NE PAS appeler _lock.synchronized() ici (Lock non-réentrant — Pitfall 6).

  static Future<bool> _isFavoriteUnlocked(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '[]';
    final List<dynamic> favorites = jsonDecode(raw) as List<dynamic>;
    return favorites.any((f) {
      final fMap = f as Map<String, dynamic>;
      final fId = fMap['id']?.toString() ??
                  fMap['lien_vers_la_fiche_rappel']?.toString() ??
                  fMap['libelle']?.toString() ?? '';
      return fId == id;
    });
  }

  static Future<void> _addFavoriteUnlocked(Map<String, dynamic> rappel) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '[]';
    final List<dynamic> favorites = jsonDecode(raw) as List<dynamic>;
    final id = rappel['id']?.toString() ??
               rappel['lien_vers_la_fiche_rappel']?.toString() ??
               rappel['libelle']?.toString() ?? '';
    // Éviter les doublons
    final exists = favorites.any((f) {
      final fMap = f as Map<String, dynamic>;
      final fId = fMap['id']?.toString() ??
                  fMap['lien_vers_la_fiche_rappel']?.toString() ??
                  fMap['libelle']?.toString() ?? '';
      return fId == id;
    });
    if (!exists) {
      favorites.add(rappel);
      await prefs.setString(_key, jsonEncode(favorites));
    }
  }

  static Future<void> _removeFavoriteUnlocked(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '[]';
    final List<dynamic> favorites = jsonDecode(raw) as List<dynamic>;
    favorites.removeWhere((f) {
      final fMap = f as Map<String, dynamic>;
      final fId = fMap['id']?.toString() ??
                  fMap['lien_vers_la_fiche_rappel']?.toString() ??
                  fMap['libelle']?.toString() ?? '';
      return fId == id;
    });
    await prefs.setString(_key, jsonEncode(favorites));
  }
}
