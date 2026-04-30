import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class NuraMark extends StatelessWidget {
  final double size;
  final Color? color;
  final bool dropShadow;
  const NuraMark(
      {super.key, this.size = 28, this.color, this.dropShadow = false});
  @override
  Widget build(BuildContext context) {
    final c = color ?? NuraBrand.pink;
    final w = SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _NuraMarkPainter(c)));
    if (!dropShadow) return w;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: c.withOpacity(0.33), blurRadius: 16)],
      ),
      child: w,
    );
  }
}

class _NuraMarkPainter extends CustomPainter {
  final Color c;
  _NuraMarkPainter(this.c);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = c;
    final s = size.width / 32.0;
    // Dome: M6 13.5 a10 7 0 0 1 20 0 V15 H6 Z
    final dome = Path()
      ..moveTo(6 * s, 13.5 * s)
      ..arcToPoint(Offset(26 * s, 13.5 * s),
          radius: Radius.elliptical(10 * s, 7 * s), clockwise: true)
      ..lineTo(26 * s, 15 * s)
      ..lineTo(6 * s, 15 * s)
      ..close();
    canvas.drawPath(dome, p);
    // Three trailing pills
    final pills = [
      Rect.fromLTWH(9.5 * s, 17 * s, 3 * s, 7 * s),
      Rect.fromLTWH(14.5 * s, 17 * s, 3 * s, 11 * s),
      Rect.fromLTWH(19.5 * s, 17 * s, 3 * s, 6 * s)
    ];
    for (final r in pills) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(1.5 * s)), p);
    }
  }

  @override
  bool shouldRepaint(_NuraMarkPainter o) => o.c != c;
}
