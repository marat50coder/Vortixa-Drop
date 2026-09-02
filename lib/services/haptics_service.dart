import 'package:flutter/services.dart';

class HapticsService {
  HapticsService._();
  static final instance = HapticsService._();

  bool enabled = true;

  void tap() {
    if (enabled) HapticFeedback.selectionClick();
  }

  void impact() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  void result() {
    if (enabled) HapticFeedback.heavyImpact();
  }
}
