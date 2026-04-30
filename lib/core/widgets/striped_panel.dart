import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../utils/color_utils.dart';

class StripedPanel extends StatelessWidget {
  final int hue;
  final NuraVibe vibe;
  const StripedPanel({super.key, required this.hue, required this.vibe});
  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      // Gradient base — teal-anchored, hue is a small accent
      DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
        begin: const Alignment(-0.6, -1.0),
        end: const Alignment(0.6, 1.0),
        colors: [
          hueColor(0.46, 0.10, hue.toDouble()),
          hueColor(0.32, 0.07, 195)
        ],
      ))),
      // Diagonal stripe overlay
      CustomPaint(painter: StripesPainter(NuraBrand.mintAlpha(0.10))),
      // Bottom vignette
      DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [NuraBrand.deepMidAlpha(0), NuraBrand.deepMidAlpha(0.72)],
        stops: const [0.5, 1.0],
      ))),
      // Corner crosshairs
      const _Corner(top: 12, left: 12),
      const _Corner(top: 12, right: 12),
      const _Corner(bottom: 12, left: 12),
      const _Corner(bottom: 12, right: 12),
    ]);
  }
}

class StripesPainter extends CustomPainter {
  final Color color;
  StripesPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 14;
    const step = 28.0;
    final diag = size.width + size.height;
    for (double d = -diag; d < diag; d += step) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), p);
    }
  }

  @override
  bool shouldRepaint(StripesPainter oldDelegate) => oldDelegate.color != color;
}

class _Corner extends StatelessWidget {
  final double? top, left, right, bottom;
  const _Corner({this.top, this.left, this.right, this.bottom});
  @override
  Widget build(BuildContext context) {
    final c = NuraBrand.mintAlpha(0.42);
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            border: Border(
              top: top != null ? BorderSide(color: c) : BorderSide.none,
              bottom: bottom != null ? BorderSide(color: c) : BorderSide.none,
              left: left != null ? BorderSide(color: c) : BorderSide.none,
              right: right != null ? BorderSide(color: c) : BorderSide.none,
            ),
          )),
    );
  }
}
