// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigiconso/services/read_status_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReadStatusService', () {
    test('isRead — retourne false initialement pour tout rappel', () async {
      final result = await ReadStatusService.isRead('REF-001');
      expect(result, isFalse);
    });

    test('markAsRead — persiste dans SharedPreferences', () async {
      await ReadStatusService.markAsRead('REF-001');
      final result = await ReadStatusService.isRead('REF-001');
      expect(result, isTrue);
    });

    test('markAsRead — idempotent (appels multiples sans doublon)', () async {
      await ReadStatusService.markAsRead('REF-001');
      await ReadStatusService.markAsRead('REF-001');
      final readSet = await ReadStatusService.getReadIds();
      expect(readSet.where((id) => id == 'REF-001').length, equals(1));
    });

    test('markAsRead — ignore les IDs vides', () async {
      await ReadStatusService.markAsRead('');
      final readSet = await ReadStatusService.getReadIds();
      expect(readSet, isEmpty);
    });

    test('getReadIds — retourne tous les IDs marqués lus', () async {
      await ReadStatusService.markAsRead('REF-001');
      await ReadStatusService.markAsRead('REF-002');
      final readSet = await ReadStatusService.getReadIds();
      expect(readSet.contains('REF-001'), isTrue);
      expect(readSet.contains('REF-002'), isTrue);
      expect(readSet.length, equals(2));
    });

    test('getUnreadCount — compte les non-lus dans une liste', () async {
      await ReadStatusService.markAsRead('REF-001');
      final rappels = [
        {'reference_fiche': 'REF-001'},
        {'reference_fiche': 'REF-002'},
        {'reference_fiche': 'REF-003'},
      ];
      final count = await ReadStatusService.getUnreadCount(rappels);
      expect(count, equals(2));
    });

    test('getUnreadCount — liste vide retourne 0', () async {
      final count = await ReadStatusService.getUnreadCount([]);
      expect(count, equals(0));
    });

    test('getRappelId — utilise reference_fiche en priorité', () {
      final rappel = {
        'reference_fiche': 'REF-001',
        'libelle': 'Nutella',
        'numero_fiche': 'NUM-001'
      };
      expect(ReadStatusService.getRappelId(rappel), equals('REF-001'));
    });

    test('getRappelId — fallback sur libelle si reference_fiche null', () {
      final rappel = {
        'reference_fiche': null,
        'libelle': 'Nutella',
        'numero_fiche': 'NUM-001'
      };
      expect(ReadStatusService.getRappelId(rappel), equals('Nutella'));
    });

    test('getRappelId — fallback sur numero_fiche si les deux sont null', () {
      final rappel = {
        'reference_fiche': null,
        'libelle': null,
        'numero_fiche': 'NUM-001'
      };
      expect(ReadStatusService.getRappelId(rappel), equals('NUM-001'));
    });
  });
}
