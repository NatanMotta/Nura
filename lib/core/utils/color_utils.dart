import 'package:flutter/material.dart';

// HSL approximation of `oklch(L C h)` → hue-anchored color blend used for
// genre tiles and saved-track swatches in the original. Close enough at small
// sizes, no extra package needed.
Color hueColor(double l, double c, double h) {
  final hsl = HSLColor.fromAHSL(1.0, h, c.clamp(0.0, 1.0), l.clamp(0.0, 1.0));
  return hsl.toColor();
}
