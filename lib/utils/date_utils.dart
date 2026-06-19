// lib/utils/date_utils.dart
// Thin delegation wrapper — parseDate() is already public in RappelService.
// Screens should import from utils (not services) for cleaner dependency direction.
// Source: RappelService.parseDate() at lib/services/rappel_service.dart:204

import 'package:vigiconso/services/rappel_service.dart';

class DateUtils {
  DateUtils._(); // private constructor — pure static utility

  /// Parses a date string in ISO format ('2026-01-15') or French format ('15/01/2026').
  /// Returns null if the string is empty or unparseable.
  /// Delegates to RappelService.parseDate() — implementation is not duplicated.
  static DateTime? parseDate(String dateStr) => RappelService.parseDate(dateStr);
}
