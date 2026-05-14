import 'package:flutter/material.dart';

const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);
const _red = Color(0xFFCC0000);
const _green = Color(0xFF339933);

class SlateColors {
  final Color background;
  final Color foreground;
  final Color font;

  const SlateColors({
    required this.background,
    required this.foreground,
    required this.font,
  });

  static const markWhite = SlateColors(
    background: _white,
    foreground: _black,
    font: _white,
  );

  static const markRed = SlateColors(
    background: _black,
    foreground: _red,
    font: _white,
  );

  static const markGreen = SlateColors(
    background: _black,
    foreground: _green,
    font: _black,
  );
}
