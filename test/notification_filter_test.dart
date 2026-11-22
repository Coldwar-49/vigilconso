// Unit tests for matchesSubscriptions pure function (ALRT-03).
import 'package:flutter_test/flutter_test.dart';
import 'package:vigiconso/services/subscription_service.dart';

bool _m(String m, String c, List<String> b, List<String> cs) =>
    SubscriptionService.matchesSubscriptions(m, c, b, cs);

void main() {
  group('matchesSubscriptions (ALRT-03)', () {
    test('brand exact match', () {
      expect(_m('Nestlé', '', ['Nestlé'], []), isTrue);
    });
    test('brand contains, case-insensitive', () {
      expect(_m('nestlé extra bio', '', ['Nestlé'], []), isTrue);
    });
    test('category contains match', () {
      expect(_m('', 'Alimentation > Fruits et légumes', [], ['alimentation']),
          isTrue);
    });
    test('category matches even if brand does not', () {
      expect(_m('Samsung', 'Alimentation > Fruits', ['Nestlé'], ['alimentation']),
          isTrue);
    });
    test('neither matches', () {
      expect(_m('Other Brand', 'Electroménager', ['Nestlé'], ['alimentation']),
          isFalse);
    });
    test('empty subscription lists', () {
      expect(_m('Nestlé', 'alimentation', [], []), isFalse);
    });
    test('empty marque and categorie', () {
      expect(_m('', '', ['Nestlé'], ['alimentation']), isFalse);
    });
    test('case-insensitive both ways', () {
      expect(_m('samsung galaxy', '', ['Samsung'], []), isTrue);
      expect(_m('NESTLÉ', '', ['nestlé'], []), isTrue);
    });
  });
}
