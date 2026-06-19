import 'package:flutter_test/flutter_test.dart';
import 'package:vigiconso/utils/image_utils.dart';

void main() {
  group('ImageUtils.proxiedUrl', () {
    test('returns wsrv.nl URL for a standard URL', () {
      const input = 'http://example.com/img.jpg';
      final result = ImageUtils.proxiedUrl(input);
      expect(result, startsWith('https://wsrv.nl/?url='));
      expect(result, contains('&output=jpg&q=85'));
    });

    test('encodes special characters in URL', () {
      const input = 'http://example.com/img with spaces.jpg';
      final result = ImageUtils.proxiedUrl(input);
      expect(result, isNot(contains(' ')));
    });

    test('result contains encoded source URL', () {
      const input = 'https://source.example.com/photo.png';
      final result = ImageUtils.proxiedUrl(input);
      expect(result, contains(Uri.encodeComponent(input)));
    });
  });
}
