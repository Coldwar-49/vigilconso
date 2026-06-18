import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion du statut lu/non-lu des rappels.
/// Stocke les IDs des rappels lus dans SharedPreferences (clé 'read_rappels').
/// ID unique: reference_fiche ?? libelle ?? numero_fiche
class ReadStatusService {
  static const String _readKey = 'read_rappels';

  /// Returns the unique ID of a rappel (same priority as FavoritesService).
  static String getRappelId(dynamic rappel) {
    return rappel['reference_fiche']?.toString() ??
        rappel['libelle']?.toString() ??
        rappel['numero_fiche']?.toString() ??
        '';
  }

  /// Loads all read IDs from SharedPreferences.
  static Future<Set<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_readKey) ?? [];
    return Set<String>.from(raw);
  }

  /// Marks a rappel as read. Idempotent — avoids unnecessary writes.
  static Future<void> markAsRead(String id) async {
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_readKey) ?? [];
    final readSet = Set<String>.from(raw);
    if (readSet.contains(id)) return;
    readSet.add(id);
    await prefs.setStringList(_readKey, readSet.toList());
  }

  /// Returns true if the rappel with this ID has been read.
  static Future<bool> isRead(String id) async {
    if (id.isEmpty) return false;
    final readSet = await getReadIds();
    return readSet.contains(id);
  }

  /// Returns the count of unread rappels in a list.
  static Future<int> getUnreadCount(List<dynamic> rappels) async {
    if (rappels.isEmpty) return 0;
    final readSet = await getReadIds();
    int unread = 0;
    for (final r in rappels) {
      final id = getRappelId(r);
      if (id.isNotEmpty && !readSet.contains(id)) unread++;
    }
    return unread;
  }
}
