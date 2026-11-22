// Widget tests for CacheIndicator (UX-05).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigiconso/widgets/cache_indicator.dart';

Widget _wrap(bool fromCache) => MaterialApp(
      home: Scaffold(body: CacheIndicator(fromCache: fromCache)),
    );

void main() {
  group('CacheIndicator (UX-05)', () {
    testWidgets('shows banner with cached icon and text when fromCache is true',
        (tester) async {
      await tester.pumpWidget(_wrap(true));
      expect(find.byIcon(Icons.cached), findsOneWidget);
      expect(find.textContaining('cache'), findsOneWidget);
    });

    testWidgets('is invisible when fromCache is false', (tester) async {
      await tester.pumpWidget(_wrap(false));
      expect(find.byIcon(Icons.cached), findsNothing);
      expect(find.textContaining('cache'), findsNothing);
      expect(tester.getSize(find.byType(CacheIndicator)), Size.zero);
    });

    testWidgets('banner spans full width when fromCache is true',
        (tester) async {
      await tester.pumpWidget(_wrap(true));
      final size = tester.getSize(find.byType(CacheIndicator));
      expect(size.width, tester.view.physicalSize.width / tester.view.devicePixelRatio);
    });
  });
}
