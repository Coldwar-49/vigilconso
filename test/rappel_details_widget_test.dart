import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigiconso/screens/rappel_details_page.dart';

void main() {
  group('RappelDetailsPage enriched sections', () {
    testWidgets('shows Lots concernés section when conditionnements is present', (tester) async {
      final rappel = {
        'id': 1,
        'libelle': 'Test Produit',
        'marque_produit': 'TestBrand',
        'conditionnements': 'Lot A, Lot B, Lot C',
        'lien_vers_la_fiche_rappel': 'https://rappel.conso.gouv.fr/fiche-rappel/123/interne',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: RappelDetailsPage(rappel: rappel),
        ),
      );
      await tester.pump();

      expect(find.text('Lots concernés'), findsOneWidget);
      expect(find.textContaining('Lot A'), findsOneWidget);
    });

    testWidgets('hides Lots concernés section when conditionnements is null', (tester) async {
      final rappel = {
        'id': 2,
        'libelle': 'Test Produit 2',
        'marque_produit': 'Brand',
        'conditionnements': null,
      };

      await tester.pumpWidget(
        MaterialApp(home: RappelDetailsPage(rappel: rappel)),
      );
      await tester.pump();

      expect(find.text('Lots concernés'), findsNothing);
    });

    testWidgets('shows Dates clés section', (tester) async {
      final rappel = {
        'id': 3,
        'libelle': 'Test',
        'marque_produit': 'Brand',
        'date_publication': '2026-01-15',
      };

      await tester.pumpWidget(
        MaterialApp(home: RappelDetailsPage(rappel: rappel)),
      );
      await tester.pump();

      expect(find.text('Dates clés'), findsOneWidget);
      expect(find.text('Publié'), findsOneWidget);
    });

    testWidgets('shows Fiche officielle button', (tester) async {
      final rappel = {
        'id': 4,
        'libelle': 'Test',
        'marque_produit': 'Brand',
        'lien_vers_la_fiche_rappel': 'https://rappel.conso.gouv.fr/fiche-rappel/456/interne',
      };

      await tester.pumpWidget(
        MaterialApp(home: RappelDetailsPage(rappel: rappel)),
      );
      await tester.pump();

      expect(find.textContaining('Fiche officielle'), findsOneWidget);
    });
  });
}
