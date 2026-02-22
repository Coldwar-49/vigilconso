import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigiconso/utils/constants.dart';

/// Service centralisé pour récupérer les rappels depuis l'API gouvernementale.
/// Gère également un cache local pour affichage hors-ligne.
///
/// CONTRAINTES API :
/// - Le paramètre `sort` est IGNORÉ — les résultats arrivent toujours en ordre
///   croissant d'ID (du plus ancien au plus récent).
/// - `offset + limit` ne peut pas dépasser 10 000 → on ne peut pas aller chercher
///   les derniers enregistrements avec offset = total - limit (total > 10 000).
/// SOLUTION : filtre `where=date_publication >= "YYYY-01-01"` pour ne récupérer
/// que des données récentes, puis tri local.
class RappelService {
  static const String _cacheKey = 'cached_rappels_v4_';
  static const String _lastFetchKey = 'last_fetch_v4_';

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
      final year = DateTime.now().year - 1;
      final List<String> filters = [];

      // Filtre date pour obtenir des données récentes (API ignore sort)
      if (searchQuery.isEmpty) {
        filters.add('date_publication >= "$year-01-01"');
      }

      final categoryFilter = AppConstants.getCategoryFilter(categoryKey);
      if (categoryFilter.isNotEmpty) {
        filters.add('($categoryFilter)');
      }

      if (searchQuery.isNotEmpty) {
        final query = searchQuery.replaceAll('"', '');
        filters.add(
          '(libelle like "%$query%" or libelle_produit like "%$query%" or '
          'nom_marque like "%$query%" or modeles_ou_references like "%$query%")',
        );
      }

      String apiUrl = '${AppConstants.apiBaseUrl}/records?limit=$limit';
      if (filters.isNotEmpty) {
        apiUrl += '&where=${Uri.encodeQueryComponent(filters.join(" AND "))}';
      }

      final response =
          await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = List<dynamic>.from(data['results'] ?? []);

        // Tri local (API ignore sort=-date_publication)
        results.sort((a, b) {
          final dateA = _parseDate(a['date_publication'] ?? '');
          final dateB = _parseDate(b['date_publication'] ?? '');
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return newestFirst ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
        });

        // Mettre en cache uniquement si pas de recherche
        if (searchQuery.isEmpty) {
          await _saveCache(cacheKey, lastFetchKey, results);
        }

        return {'results': results, 'fromCache': false};
      } else {
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

  /// Récupère les N derniers rappels toutes catégories confondues (pour l'accueil).
  /// Utilise un filtre de date car l'API ignore sort ET interdit offset > 9900.
  static Future<List<dynamic>> fetchLatestRappels({int limit = 5}) async {
    try {
      final year = DateTime.now().year - 1;
      final dateFilter =
          Uri.encodeQueryComponent('date_publication >= "$year-01-01"');
      final apiUrl =
          '${AppConstants.apiBaseUrl}/records?limit=100&where=$dateFilter';

      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results =
            List<dynamic>.from(data['results'] ?? []);

        // Tri local du plus récent au plus ancien
        results.sort((a, b) {
          final dateA = _parseDate(a['date_publication'] ?? '');
          final dateB = _parseDate(b['date_publication'] ?? '');
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });

        return results.take(limit).toList();
      }
    } catch (e) {
      debugPrint('fetchLatestRappels error: $e');
    }
    return [];
  }

  /// Parse une date au format ISO (yyyy-MM-dd) ou dd/MM/yyyy
  static DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return null;
  }
}
