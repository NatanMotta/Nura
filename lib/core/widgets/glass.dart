import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class Glass extends StatelessWidget {
  final NuraVibe vibe;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  const Glass(
      {super.key,
      required this.vibe,
      required this.child,
      this.padding,
      this.radius});
  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius ?? vibe.radius);
    final inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: vibe.cardBg,
        border: Border.all(color: vibe.cardBorder),
        borderRadius: r,
      ),
      child: child,
    );
    if (vibe.cardBlurSigma == 0) {
      return ClipRRect(borderRadius: r, child: inner);
    }
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: vibe.cardBlurSigma, sigmaY: vibe.cardBlurSigma),
          child: inner),
    );
  }
}
