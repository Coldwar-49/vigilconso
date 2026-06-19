// lib/utils/image_utils.dart
// Extracted from: home_screen.dart, rappel_screen.dart, favorites_screen.dart,
// rappel_details_page.dart (4 duplicate _proxiedUrl/_proxiedImageUrl methods).
// After this extraction, all 4 files must import this and call ImageUtils.proxiedUrl().

class ImageUtils {
  ImageUtils._(); // private constructor — pure static utility

  /// Returns a wsrv.nl proxied URL for reliable cross-platform image loading.
  /// Replace all calls to _proxiedUrl() or _proxiedImageUrl() with this method.
  static String proxiedUrl(String url) {
    final encoded = Uri.encodeComponent(url);
    return 'https://wsrv.nl/?url=$encoded&output=jpg&q=85';
  }
}
