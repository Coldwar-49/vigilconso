// Unit tests for ALRT-01 (brands) and ALRT-02 (categories).
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigiconso/services/subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SubscriptionService — brands (ALRT-01)', () {
    test('addBrand persists brand to SharedPreferences', () async {
      await SubscriptionService.addBrand('Nestlé');
      final brands = await SubscriptionService.getBrands();
      expect(brands, contains('Nestlé'));
    });

    test('addBrand is idempotent — no duplicate entries', () async {
      await SubscriptionService.addBrand('Nestlé');
      await SubscriptionService.addBrand('Nestlé');
      final brands = await SubscriptionService.getBrands();
      expect(brands.where((b) => b.toLowerCase() == 'nestlé').length, equals(1));
    });

    test('removeBrand removes the brand', () async {
      await SubscriptionService.addBrand('Nestlé');
      await SubscriptionService.removeBrand('Nestlé');
      final brands = await SubscriptionService.getBrands();
      expect(brands, isNot(contains('Nestlé')));
    });

    test('getBrands returns empty list when no brands stored', () async {
      expect(await SubscriptionService.getBrands(), isEmpty);
    });

    test('addBrand trims whitespace', () async {
      await SubscriptionService.addBrand('  Samsung  ');
      final brands = await SubscriptionService.getBrands();
      expect(brands, contains('Samsung'));
      expect(brands, isNot(contains('  Samsung  ')));
    });

    test('addBrand ignores empty brand after trim', () async {
      await SubscriptionService.addBrand('   ');
      expect(await SubscriptionService.getBrands(), isEmpty);
    });

    test('addBrand truncates to 100 chars (T-3-01)', () async {
      await SubscriptionService.addBrand('a' * 150);
      final brands = await SubscriptionService.getBrands();
      expect(brands.single.length, equals(100));
    });
  });

  group('SubscriptionService — categories (ALRT-02)', () {
    test('addCategory persists category key', () async {
      await SubscriptionService.addCategory('alimentation');
      expect(await SubscriptionService.getCategories(), contains('alimentation'));
    });

    test('addCategory is idempotent', () async {
      await SubscriptionService.addCategory('alimentation');
      await SubscriptionService.addCategory('alimentation');
      final cats = await SubscriptionService.getCategories();
      expect(cats.where((c) => c == 'alimentation').length, equals(1));
    });

    test('removeCategory removes the category', () async {
      await SubscriptionService.addCategory('alimentation');
      await SubscriptionService.removeCategory('alimentation');
      expect(await SubscriptionService.getCategories(),
          isNot(contains('alimentation')));
    });

    test('getCategories returns empty list when nothing stored', () async {
      expect(await SubscriptionService.getCategories(), isEmpty);
    });

    test('brands and categories are stored independently', () async {
      await SubscriptionService.addBrand('Nestlé');
      await SubscriptionService.addCategory('alimentation');
      final brands = await SubscriptionService.getBrands();
      final cats = await SubscriptionService.getCategories();
      expect(brands, contains('Nestlé'));
      expect(cats, contains('alimentation'));
      expect(brands, isNot(contains('alimentation')));
    });
  });
}
