import 'package:flutter/material.dart';

class NuraBrand {
  static const Color deep = Color(0xFF005D6D); // Misicura — primary background
  static const Color mint = Color(0xFFACE7D5); // Bianco Nura — text & icons
  static const Color pink = Color(0xFFFF0A75); // Nura Pink — primary CTA
  static const Color deepest = Color(0xFF00343C);
  static const Color deepMid = Color(0xFF004956);

  static Color mintAlpha(double a) => mint.withOpacity(a);
  static Color pinkAlpha(double a) => pink.withOpacity(a);
  static Color tealAlpha(double a) => deep.withOpacity(a);
  static Color deepMidAlpha(double a) => deepMid.withOpacity(a);
}
