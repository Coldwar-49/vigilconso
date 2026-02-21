import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigiconso/utils/constants.dart';

/// Service centralisé pour récupérer les rappels depuis l'API gouvernementale.
/// Gère également un cache local pour affichage hors-ligne.
class RappelService {
  static const String _cacheKey = 'cached_rappels_';
  static const String _lastFetchKey = 'last_fetch_';

  /// Récupère les rappels pour une catégorie donnée.
  /// [forceRefresh] : force un appel API même si le cache est récent.
  static Future<Map<String, dynamic>> fetchRappels({
    required String categoryKey,
    String searchQuery = '',
    int limit = 100,
    bool newestFirst = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$_cacheKey$categoryKey';
    final lastFetchKey = '$_lastFetchKey$categoryKey';

    // Vérifier si le cache est encore valide (moins de 5 min)
    if (!forceRefresh) {
      final cached = await _getCached(cacheKey, lastFetchKey);
      if (cached != null && searchQuery.isEmpty) {
        return {'results': cached, 'fromCache': true};
      }
    }

    try {
      String apiUrl = '${AppConstants.apiBaseUrl}/records?limit=$limit';
      apiUrl += newestFirst ? '&sort=-date_publication' : '&sort=date_publication';

      List<String> filters = [];
      final categoryFilter = AppConstants.getCategoryFilter(categoryKey);
      if (categoryFilter.isNotEmpty) {
        filters.add('($categoryFilter)');
      }

      if (searchQuery.isNotEmpty) {
        final query = searchQuery.replaceAll('"', '');
        final searchFilter =
            '(libelle like "%$query%" or libelle_produit like "%$query%" or '
            'nom_marque like "%$query%" or modeles_ou_references like "%$query%")';
        filters.add(searchFilter);
      }

      if (filters.isNotEmpty) {
        apiUrl += '&where=${Uri.encodeQueryComponent(filters.join(" AND "))}';
      }

      final response =
          await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = List<dynamic>.from(data['results'] ?? []);

        // Mettre en cache uniquement si pas de recherche
        if (searchQuery.isEmpty) {
          await _saveCache(cacheKey, lastFetchKey, results);
        }

        return {'results': results, 'fromCache': false};
      } else {
        // Retourner le cache si l'API échoue
        final cached = await _getCachedAnyAge(cacheKey);
        if (cached != null) {
          return {'results': cached, 'fromCache': true, 'apiError': true};
        }
        return {'error': 'Erreur API: ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('RappelService error: $e');
      final cached = await _getCachedAnyAge(cacheKey);
      if (cached != null) {
        return {'results': cached, 'fromCache': true, 'apiError': true};
      }
      return {'error': 'Erreur réseau: $e'};
    }
  }

  static Future<List<dynamic>?> _getCached(
      String cacheKey, String lastFetchKey) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetch = prefs.getInt(lastFetchKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const fiveMinutes = 5 * 60 * 1000;
    if (now - lastFetch > fiveMinutes) return null;
    return _getCachedAnyAge(cacheKey);
  }

  static Future<List<dynamic>?> _getCachedAnyAge(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cacheKey);
    if (raw == null) return null;
    return jsonDecode(raw) as List<dynamic>;
  }

  static Future<void> _saveCache(
      String cacheKey, String lastFetchKey, List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, jsonEncode(data));
    await prefs.setInt(lastFetchKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Récupère les N derniers rappels toutes catégories confondues (pour l'accueil)
  static Future<List<dynamic>> fetchLatestRappels({int limit = 5}) async {
    final result = await fetchRappels(
      categoryKey: 'all',
      limit: limit,
      forceRefresh: true,
    );
    return List<dynamic>.from(result['results'] ?? []);
  }
}
