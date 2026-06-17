// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigiconso/screens/search_screen.dart';
import 'package:vigiconso/widgets/filter_panel.dart';

void main() {
  group('FilterLogic — applyRiskFilter', () {
    final rappels = [
      {'risques_encourus': 'risque grave pour la santé'},
      {'risques_encourus': 'risque modéré'},
      {'risques_encourus': 'risque faible'},
      {'risques_encourus': null},
    ];

    test('filtre vide retourne tous les rappels', () {
      final result = SearchScreen.applyRiskFilter({}, rappels);
      expect(result.length, equals(4));
    });

    test('filtre grave retourne uniquement les rappels graves', () {
      final result = SearchScreen.applyRiskFilter({'grave'}, rappels);
      expect(result.length, equals(1));
      expect(result.first['risques_encourus'], contains('grave'));
    });

    test('filtre multiple grave+faible retourne OR logic', () {
      final result = SearchScreen.applyRiskFilter({'grave', 'faible'}, rappels);
      expect(result.length, equals(2));
    });

    test('filtre modéré avec accent fonctionne', () {
      final result = SearchScreen.applyRiskFilter({'modéré'}, rappels);
      expect(result.length, equals(1));
    });
  });

  group('FilterLogic — applyBrandFilter', () {
    final rappels = [
      {'marque_produit': 'Danone SA'},
      {'marque_produit': 'DANONE BIO'},
      {'marque_produit': 'Nestlé'},
      {'marque_produit': null},
    ];

    test('filtre vide retourne tous les rappels', () {
      final result = SearchScreen.applyBrandFilter('', rappels);
      expect(result.length, equals(4));
    });

    test('filtre case-insensitive sur marque_produit', () {
      final result = SearchScreen.applyBrandFilter('danone', rappels);
      expect(result.length, equals(2));
    });

    test('filtre marque inexistante retourne liste vide', () {
      final result = SearchScreen.applyBrandFilter('Samsung', rappels);
      expect(result.length, equals(0));
    });
  });

  group('FilterLogic — applyReadFilter', () {
    final rappels = [
      {'reference_fiche': 'REF-001'},
      {'reference_fiche': 'REF-002'},
      {'reference_fiche': 'REF-003'},
    ];
    final readIds = {'REF-001'};

    test('readFilter all retourne tous les rappels', () {
      final result = SearchScreen.applyReadFilter('all', rappels, readIds);
      expect(result.length, equals(3));
    });

    test('readFilter unread retourne les non-lus', () {
      final result = SearchScreen.applyReadFilter('unread', rappels, readIds);
      expect(result.length, equals(2));
      expect(result.any((r) => r['reference_fiche'] == 'REF-001'), isFalse);
    });

    test('readFilter read retourne uniquement les lus', () {
      final result = SearchScreen.applyReadFilter('read', rappels, readIds);
      expect(result.length, equals(1));
      expect(result.first['reference_fiche'], equals('REF-001'));
    });

    test('readFilter unread avec readIds vide retourne tous', () {
      final result = SearchScreen.applyReadFilter('unread', rappels, {});
      expect(result.length, equals(3));
    });
  });

  group('FilterState — apiDateFrom', () {
    test('dateDays=7 retourne date il y a 7 jours au format YYYY-MM-DD', () {
      final fs = FilterState(dateDays: 7);
      final dateFrom = fs.apiDateFrom;
      expect(dateFrom, isNotNull);
      expect(dateFrom!.length, equals(10));
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateFrom), isTrue);
    });

    test('state vide retourne null', () {
      expect(FilterState.empty.apiDateFrom, isNull);
    });

    test('customDateRange retourne la date de début correcte', () {
      final range =
          DateTimeRange(start: DateTime(2024, 6, 1), end: DateTime(2024, 6, 30));
      final fs = FilterState(customDateRange: range);
      expect(fs.apiDateFrom, equals('2024-06-01'));
      expect(fs.apiDateTo, equals('2024-06-30'));
    });

    test('hasActiveFilters — false sur état vide', () {
      expect(FilterState.empty.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters — true si brandKeyword non vide', () {
      expect(FilterState(brandKeyword: 'Danone').hasActiveFilters, isTrue);
    });

    test('hasActiveFilters — true si readFilter != all', () {
      expect(FilterState(readFilter: 'unread').hasActiveFilters, isTrue);
    });
  });

  group('FilterState — toJson/fromJson (persistance)', () {
    test(
        'toJson/fromJson round-trip préserve riskLevels, dateDays, brandKeyword, readFilter',
        () {
      final original = FilterState(
        riskLevels: {'grave', 'faible'},
        dateDays: 30,
        brandKeyword: 'Danone',
        readFilter: 'unread',
      );
      final json = original.toJson();
      final restored = FilterState.fromJson(json);
      expect(restored.riskLevels, equals({'grave', 'faible'}));
      expect(restored.dateDays, equals(30));
      expect(restored.brandKeyword, equals('Danone'));
      expect(restored.readFilter, equals('unread'));
    });

    test('fromJson avec JSON vide retourne FilterState.empty', () {
      final restored = FilterState.fromJson({});
      expect(restored.hasActiveFilters, isFalse);
      expect(restored.readFilter, equals('all'));
    });
  });
}
