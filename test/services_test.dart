import 'package:flutter_test/flutter_test.dart';
import 'package:vigiconso/utils/constants.dart';

void main() {
  group('AppConstants - getCategoryFilter', () {
    test('all retourne un filtre vide', () {
      final filter = AppConstants.getCategoryFilter('all');
      expect(filter, isEmpty);
    });

    test('alimentation retourne un filtre non vide', () {
      final filter = AppConstants.getCategoryFilter('alimentation');
      expect(filter, isNotEmpty);
      expect(filter.toLowerCase(), contains('alimentation'));
    });

    test('automobile retourne un filtre non vide', () {
      final filter = AppConstants.getCategoryFilter('automobile');
      expect(filter, isNotEmpty);
    });

    test('categorie inconnue retourne vide', () {
      final filter = AppConstants.getCategoryFilter('inexistant');
      expect(filter, isEmpty);
    });

    test('toutes les categories connues retournent un filtre', () {
      final knownCategories = ['alimentation', 'automobile', 'bebe_enfant', 'hygiene_beaute', 'vetement_mode', 'sport_loisirs', 'maison_habitat', 'appareils_outils', 'equipements_communication', 'autres'];
      for (final cat in knownCategories) {
        final filter = AppConstants.getCategoryFilter(cat);
        expect(filter, isNotEmpty, reason: 'Filtre vide pour $cat');
      }
    });
  });

  group('AppConstants - categories map', () {
    test('contient toutes les categories attendues', () {
      expect(AppConstants.categories.containsKey('all'), isTrue);
      expect(AppConstants.categories.containsKey('alimentation'), isTrue);
      expect(AppConstants.categories.containsKey('automobile'), isTrue);
    });

    test('les libelles ne sont pas vides', () {
      for (final entry in AppConstants.categories.entries) {
        expect(entry.value, isNotEmpty, reason: 'Libelle vide pour ${entry.key}');
      }
    });
  });

  group('AppConstants - apiBaseUrl', () {
    test('URL contient economie.gouv.fr', () {
      expect(AppConstants.apiBaseUrl, contains('economie.gouv.fr'));
    });

    test('URL commence par https', () {
      expect(AppConstants.apiBaseUrl, startsWith('https://'));
    });
  });
}