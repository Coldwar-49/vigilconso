import 'package:flutter_test/flutter_test.dart';
import 'package:vigiconso/utils/date_utils.dart';

void main() {
  group('DateUtils.parseDate', () {
    test('parses ISO date string', () {
      final result = DateUtils.parseDate('2026-01-15');
      expect(result, DateTime(2026, 1, 15));
    });

    test('parses French DD/MM/YYYY format', () {
      final result = DateUtils.parseDate('15/01/2026');
      expect(result, DateTime(2026, 1, 15));
    });

    test('returns null for empty string', () {
      final result = DateUtils.parseDate('');
      expect(result, isNull);
    });

    test('returns null for unparseable string', () {
      final result = DateUtils.parseDate('not-a-date');
      expect(result, isNull);
    });
  });
}
