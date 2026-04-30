import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const String primaryFont = 'InterTight';
  static const String monoFont = 'JetBrainsMono';
  static const List<String> monoFallback = ['Menlo', 'Consolas', 'monospace'];

  static const TextStyle screenTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
}
