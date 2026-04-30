import 'package:flutter/material.dart';

import 'app_colors.dart';

enum VibeId { premium, maximalist, techy }

class NuraVibe {
  final String label;
  final Gradient bgGradient;
  final Color cardBg;
  final Color cardBorder;
  final double cardBlurSigma; // 0 == no blur (techy)
  final bool grain;
  final bool bloom;
  final double radius;

  const NuraVibe({
    required this.label,
    required this.bgGradient,
    required this.cardBg,
    required this.cardBorder,
    required this.cardBlurSigma,
    required this.grain,
    required this.bloom,
    required this.radius,
  });

  static const NuraVibe premium = NuraVibe(
    label: 'Premium · Glass',
    bgGradient: RadialGradient(
      center: Alignment(-0.4, -1.0),
      radius: 1.4,
      colors: [Color(0xFF00768A), Color(0xFF005D6D), Color(0xFF004956)],
      stops: [0.0, 0.55, 1.0],
    ),
    cardBg: Color(0x1AACE7D5), // rgba(172,231,213,0.10)
    cardBorder: Color(0x47ACE7D5), // rgba(172,231,213,0.28)
    cardBlurSigma: 24,
    grain: false, bloom: false, radius: 24,
  );

  static const NuraVibe maximalist = NuraVibe(
    label: 'Vibrant · Bloom',
    bgGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF00768A), Color(0xFF005D6D)],
    ),
    cardBg: Color(0x24ACE7D5), // rgba(172,231,213,0.14)
    cardBorder: Color(0x5CFF0A75), // rgba(255,10,117,0.36)
    cardBlurSigma: 28,
    grain: false, bloom: true, radius: 28,
  );

  static const NuraVibe techy = NuraVibe(
    label: 'Editorial · Tech',
    bgGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF005D6D), Color(0xFF004956)],
    ),
    cardBg: Color(0x8C005D6D), // rgba(0,93,109,0.55)
    cardBorder: Color(0x66ACE7D5), // rgba(172,231,213,0.40)
    cardBlurSigma: 0,
    grain: true, bloom: false, radius: 8,
  );

  static NuraVibe of(VibeId id) => switch (id) {
        VibeId.premium => premium,
        VibeId.maximalist => maximalist,
        VibeId.techy => techy,
      };
}

ThemeData buildNuraTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NuraBrand.deepest,
    fontFamily: 'InterTight',
    textTheme: const TextTheme().apply(
      bodyColor: NuraBrand.mint,
      displayColor: NuraBrand.mint,
    ),
  );
}
