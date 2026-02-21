// Fix for missing createLocalImageConfiguration
// Add this extension to your project

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

extension BuildContextExtensions on BuildContext {
  ImageConfiguration createLocalImageConfiguration([Size? size]) {
    return ImageConfiguration(
      size: size,
      devicePixelRatio: MediaQuery.of(this).devicePixelRatio,
      platform: defaultTargetPlatform,
      locale: Localizations.maybeLocaleOf(this),
      textDirection: Directionality.maybeOf(this),
    );
  }
}

// Then add this extension to any classes that need to use createLocalImageConfiguration
extension WidgetStateExtensions on State {
  ImageConfiguration createLocalImageConfiguration([Size? size]) {
    return context.createLocalImageConfiguration(size);
  }
}

// For classes that directly need the method
extension StatelessWidgetExtensions on StatelessWidget {
  ImageConfiguration createLocalImageConfiguration(BuildContext context,
      [Size? size]) {
    return context.createLocalImageConfiguration(size);
  }
}

// For Image-related issues, ensure you've imported:
// import 'package:flutter/widgets.dart'; 
// And if needed:
// import 'package:flutter/painting.dart';

// Example of how to use these in a class like Table:
/*
class MyTableWidget extends Table {
  @override
  Widget build(BuildContext context) {
    final ImageConfiguration config = context.createLocalImageConfiguration();
    // Use config as needed
    return super.build(context);
  }
}
*/