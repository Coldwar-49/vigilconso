import 'package:flutter_test/flutter_test.dart';
import 'package:vigiconso/models/rappel.dart';

void main() {
  group('Rappel.fromJson', () {
    test('maps required fields correctly', () {
      final map = {
        'id': 42,
        'libelle': 'Test Produit',
        'marque_produit': 'TestBrand',
      };
      final rappel = Rappel.fromJson(map);
      expect(rappel.id, 42);
      expect(rappel.libelle, 'Test Produit');
      expect(rappel.marqueProduit, 'TestBrand');
    });

    test('handles null optional fields gracefully', () {
      final map = {
        'id': 1,
        'libelle': 'Minimal',
        'marque_produit': 'Brand',
      };
      final rappel = Rappel.fromJson(map);
      expect(rappel.conditionnements, isNull);
      expect(rappel.lienVersFicheRappel, isNull);
      expect(rappel.datePublication, isNull);
    });

    test('falls back to Produit inconnu when libelle is absent', () {
      final map = {'id': 0, 'marque_produit': ''};
      final rappel = Rappel.fromJson(map);
      expect(rappel.libelle, 'Produit inconnu');
    });

    test('uses modeles_ou_references as fallback for libelle', () {
      final map = {
        'id': 5,
        'modeles_ou_references': 'Ref-Model-X',
        'marque_produit': 'Brand',
      };
      final rappel = Rappel.fromJson(map);
      expect(rappel.libelle, 'Ref-Model-X');
    });

    test('maps lien_vers_la_fiche_rappel (not reference_fiche)', () {
      final map = {
        'id': 10,
        'libelle': 'Test',
        'marque_produit': 'B',
        'lien_vers_la_fiche_rappel': 'https://rappel.conso.gouv.fr/fiche-rappel/123/interne',
      };
      final rappel = Rappel.fromJson(map);
      expect(rappel.lienVersFicheRappel, 'https://rappel.conso.gouv.fr/fiche-rappel/123/interne');
    });

    test('toJson round-trip preserves fields', () {
      final map = {
        'id': 7,
        'libelle': 'Produit',
        'marque_produit': 'Marque',
        'conditionnements': 'Lot A, Lot B',
      };
      final rappel = Rappel.fromJson(map);
      final json = rappel.toJson();
      expect(json['libelle'], 'Produit');
      expect(json['marque_produit'], 'Marque');
      expect(json['conditionnements'], 'Lot A, Lot B');
    });
  });
}
