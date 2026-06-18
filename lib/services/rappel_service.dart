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
  /// [dateFrom] / [dateTo] : filtres optionnels au format 'YYYY-MM-DD'.
  static Future<Map<String, dynamic>> fetchRappels({
    required String categoryKey,
    String searchQuery = '',
    String? dateFrom,
    String? dateTo,
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

      // Filtres de date optionnels (s'ajoutent aux filtres existants)
      if (dateFrom != null) {
        filters.add('date_publication >= "$dateFrom"');
      }
      if (dateTo != null) {
        filters.add('date_publication <= "$dateTo"');
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
          final dateA = parseDate(a['date_publication'] ?? '');
          final dateB = parseDate(b['date_publication'] ?? '');
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
  /// Utilise order_by=date_publication desc pour obtenir directement les plus récents.
  static Future<List<dynamic>> fetchLatestRappels({int limit = 5}) async {
    try {
      final apiUrl =
          '${AppConstants.apiBaseUrl}/records?limit=$limit&order_by=date_publication%20desc';

      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results =
            List<dynamic>.from(data['results'] ?? []);

        // Tri local en secours si order_by est ignoré par l'API
        results.sort((a, b) {
          final dateA = parseDate(a['date_publication'] ?? '');
          final dateB = parseDate(b['date_publication'] ?? '');
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

  /// Fetch brand autocomplete suggestions from the RappelConso API.
  /// Uses search() instead of like to avoid the like+group_by bug (VERIFIED 2026-06-16).
  /// Returns [] on error or timeout (graceful degradation — suggestions are non-critical).
  static Future<List<String>> fetchSuggestions(String prefix) async {
    final sanitized = prefix.trim().replaceAll('"', '');
    if (sanitized.length < 2) return [];
    try {
      final where = Uri.encodeQueryComponent('search(marque_produit,"$sanitized")');
      final url = '${AppConstants.apiBaseUrl}/records'
          '?where=$where&select=marque_produit&group_by=marque_produit&limit=8';
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['results'] as List? ?? [])
            .map((r) => (r['marque_produit'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Parse une date au format ISO (yyyy-MM-dd) ou dd/MM/yyyy.
  /// Méthode publique — utilisée par SearchScreen et rappel_screen.dart.
  static DateTime? parseDate(String dateStr) {
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
