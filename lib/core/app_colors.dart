import 'package:flutter/material.dart';

class VxColors {
  VxColors._();

  static const voidBlack = Color(0xFF050510);
  static const deepNavy = Color(0xFF08081A);
  static const graphite = Color(0xFF141428);
  static const card = Color(0xD6121228);
  static const stroke = Color(0x33FFFFFF);
  static const text = Color(0xFFFFFFFF);
  static const textMuted = Color(0xB3E8E8F8);

  static const cyan = Color(0xFF00E8FF);
  static const magenta = Color(0xFFFF2BD6);
  static const violet = Color(0xFFB24DFF);
  static const lime = Color(0xFF7CFF3A);
  static const blue = Color(0xFF2B6BFF);
  static const orange = Color(0xFFFF8A1A);
  static const pink = Color(0xFFFF4DA6);
  static const turquoise = Color(0xFF2DFFE8);

  static const ballTints = <Color>[
    cyan,
    magenta,
    violet,
    lime,
    blue,
    orange,
    pink,
    turquoise,
  ];

  static const neonGradient = LinearGradient(
    colors: [cyan, violet, magenta],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const buttonGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF7A3DFF), Color(0xFFFF2BD6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
