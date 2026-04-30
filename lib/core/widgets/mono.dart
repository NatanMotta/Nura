import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class Mono extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;
  const Mono(this.text, {super.key, this.color, this.size = 10});
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontFamilyFallback: const ['Menlo', 'Consolas', 'monospace'],
          fontSize: size,
          letterSpacing: 1.4,
          color: color ?? NuraBrand.mintAlpha(0.72),
        ),
      );
}
