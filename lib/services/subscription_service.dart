// Mirrors FavoritesService (lib/services/favorites_service.dart) pattern.
// All public mutations go through _lock.synchronized().
// _syncTagsUnlocked is called inside the lock but must NOT call _lock.synchronized() again.
// [SECURITY T-3-01]: Brand names trimmed + truncated to 100 chars before OneSignal Tag sync.

import 'dart:convert';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

class SubscriptionService {
  static const String _brandsKey = 'subscription_brands';
  static const String _categoriesKey = 'subscription_categories';
  static final _lock = Lock();

  static Future<List<String>> getBrands() async {
    final prefs = await SharedPreferences.getInstance();
    return List<String>.from(
      jsonDecode(prefs.getString(_brandsKey) ?? '[]') as List,
    );
  }

  static Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return List<String>.from(
      jsonDecode(prefs.getString(_categoriesKey) ?? '[]') as List,
    );
  }

  static Future<void> addBrand(String brand) async {
    await _lock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final brands = List<String>.from(
        jsonDecode(prefs.getString(_brandsKey) ?? '[]') as List,
      );
      // T-3-01: trim whitespace + truncate to 100 chars before storage/tag sync
      final trimmed = brand.trim();
      final sanitized =
          trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;
      if (sanitized.isEmpty) return;
      final normalized = sanitized.toLowerCase();
      if (!brands.map((b) => b.toLowerCase()).contains(normalized)) {
        brands.add(sanitized);
        await prefs.setString(_brandsKey, jsonEncode(brands));
        await _syncTagsUnlocked(brands, null);
      }
    });
  }

  static Future<void> removeBrand(String brand) async {
    await _lock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final brands = List<String>.from(
        jsonDecode(prefs.getString(_brandsKey) ?? '[]') as List,
      );
      brands.removeWhere((b) => b.toLowerCase() == brand.trim().toLowerCase());
      await prefs.setString(_brandsKey, jsonEncode(brands));
      await _syncTagsUnlocked(brands, null);
    });
  }

  static Future<void> addCategory(String categoryKey) async {
    await _lock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final cats = List<String>.from(
        jsonDecode(prefs.getString(_categoriesKey) ?? '[]') as List,
      );
      if (!cats.contains(categoryKey)) {
        cats.add(categoryKey);
        await prefs.setString(_categoriesKey, jsonEncode(cats));
        await _syncTagsUnlocked(null, cats);
      }
    });
  }

  static Future<void> removeCategory(String categoryKey) async {
    await _lock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final cats = List<String>.from(
        jsonDecode(prefs.getString(_categoriesKey) ?? '[]') as List,
      );
      cats.remove(categoryKey);
      await prefs.setString(_categoriesKey, jsonEncode(cats));
      await _syncTagsUnlocked(null, cats);
    });
  }

  // Called ONLY from inside a _lock.synchronized block (Lock is non-reentrant).
  // Tag sync failure is non-fatal — local SharedPreferences is source of truth.
  static Future<void> _syncTagsUnlocked(
      List<String>? brands, List<String>? categories) async {
    try {
      if (brands != null) {
        await OneSignal.User.addTagWithKey(
          'subscribed_brands',
          brands.join(','),
        );
      }
      if (categories != null) {
        await OneSignal.User.addTagWithKey(
          'subscribed_categories',
          categories.join(','),
        );
      }
    } catch (_) {
      // non-fatal
    }
  }

  // -- Pure filter function (ALRT-03) ---------------------------------------
  // Extracted for unit testing without OneSignal SDK mocks.
  // Called from the main.dart foreground listener. Never reads a URL from payload (T-3-03).
  static bool matchesSubscriptions(
    String marque,
    String categorie,
    List<String> brands,
    List<String> categories,
  ) {
    final brandMatch = brands.any(
      (b) => marque.toLowerCase().contains(b.toLowerCase()),
    );
    final catMatch = categories.any(
      (c) => categorie.toLowerCase().contains(c.toLowerCase()),
    );
    return brandMatch || catMatch;
  }
}
