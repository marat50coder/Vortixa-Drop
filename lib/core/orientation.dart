import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class VxOrientation {
  VxOrientation._();

  static bool get isTablet {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return false;
    final view = views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    return size.shortestSide >= 600;
  }

  /// Phones may rotate on loading. iPad / tablets stay portrait.
  static Future<void> allowAny() {
    if (isTablet) return lockPortrait();
    return SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  static Future<void> lockPortrait() {
    return SystemChrome.setPreferredOrientations(
      isTablet
          ? const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]
          : const [DeviceOrientation.portraitUp],
    );
  }
}
