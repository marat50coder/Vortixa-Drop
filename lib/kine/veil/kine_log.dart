import 'package:flutter/foundation.dart';

/// Debug-only log. Release/profile never run the builder.
void kineLog(String Function() build) {
  assert(() {
    debugPrint(build());
    return true;
  }());
}
