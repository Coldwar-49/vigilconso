// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigiconso/services/search_history_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SearchHistoryService', () {
    test('getHistory — retourne liste vide initialement', () async {
      final history = await SearchHistoryService.getHistory();
      expect(history, isEmpty);
    });

    test('addToHistory — insère en tête (LIFO)', () async {
      await SearchHistoryService.addToHistory('Nutella');
      await SearchHistoryService.addToHistory('Samsung');
      final history = await SearchHistoryService.getHistory();
      expect(history.first, equals('Samsung'));
      expect(history[1], equals('Nutella'));
    });

    test('addToHistory — déduplique : query existante remontée en tête', () async {
      await SearchHistoryService.addToHistory('Nutella');
      await SearchHistoryService.addToHistory('Samsung');
      await SearchHistoryService.addToHistory('Nutella');
      final history = await SearchHistoryService.getHistory();
      expect(history.first, equals('Nutella'));
      expect(history.length, equals(2));
    });

    test('addToHistory — respecte la limite de 10 entrées', () async {
      for (int i = 1; i <= 11; i++) {
        await SearchHistoryService.addToHistory('query$i');
      }
      final history = await SearchHistoryService.getHistory();
      expect(history.length, equals(10));
      expect(history.first, equals('query11'));
      expect(history.contains('query1'), isFalse);
    });

    test('addToHistory — ignore les queries vides ou whitespace', () async {
      await SearchHistoryService.addToHistory('');
      await SearchHistoryService.addToHistory('   ');
      final history = await SearchHistoryService.getHistory();
      expect(history, isEmpty);
    });

    test('clearHistory — vide la liste', () async {
      await SearchHistoryService.addToHistory('Nutella');
      await SearchHistoryService.addToHistory('Samsung');
      await SearchHistoryService.clearHistory();
      final history = await SearchHistoryService.getHistory();
      expect(history, isEmpty);
    });
  });
}
