import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class Waveform extends StatefulWidget {
  final String style;
  final Color color;
  final double height;
  final int count;
  final int seed;
  const Waveform(
      {super.key,
      this.style = 'bars',
      this.color = NuraBrand.mint,
      this.height = 28,
      this.count = 32,
      this.seed = 0});
  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 60))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.lastElapsedDuration?.inMilliseconds ?? 0;
        final time = t / 1000.0;
        return CustomPaint(
          size: Size.fromHeight(widget.height),
          painter: _WavePainter(
              widget.style, widget.color, widget.count, widget.seed, time),
          child: SizedBox(height: widget.height, width: double.infinity),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final String style;
  final Color color;
  final int count, seed;
  final double t;
  _WavePainter(this.style, this.color, this.count, this.seed, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height, w = size.width;
    if (style == 'wave') {
      final paths = [(0.0, 0.35, 1.2), (1.4, 1.0, 1.6)];
      for (final tup in paths) {
        final phase = tup.$1, alpha = tup.$2, sw = tup.$3;
        final p = Path()..moveTo(0, h / 2);
        for (int i = 1; i <= 40; i++) {
          final x = (i / 40) * w;
          final y = h / 2 +
              math.sin((i / 40) * math.pi * 4 + t * 2.4 + phase) *
                  (h * 0.36) *
                  (0.6 + math.sin(i * 0.7 + t) * 0.4);
          p.lineTo(x, y);
        }
        canvas.drawPath(
            p,
            Paint()
              ..color = color.withOpacity(alpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = sw);
      }
      return;
    }
    if (style == 'pulse') {
      const n = 18;
      const gap = 6.0;
      const totalW = n * 10 + (n - 1) * gap;
      var x = (w - totalW) / 2;
      for (int i = 0; i < n; i++) {
        final v = math.sin(i * 0.6 + t * 2 + seed).abs();
        final sz = 4 + v * 6;
        canvas.drawCircle(Offset(x + sz / 2, h / 2), sz / 2,
            Paint()..color = color.withOpacity(0.4 + v * 0.6));
        x += sz + gap;
      }
      return;
    }
    // bars
    final n = count;
    const barW = 3.0;
    const gap = 3.0;
    final totalW = n * barW + (n - 1) * gap;
    var x = (w - totalW) / 2;
    for (int i = 0; i < n; i++) {
      final v = math.sin(i * 0.5 + t * 4 + seed).abs() *
          math.cos(i * 0.21 + t * 1.3).abs();
      final bh = math.max(2.0, v * h);
      final r = Rect.fromLTWH(x, (h - bh) / 2, barW, bh);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)),
          Paint()..color = color.withOpacity(0.55 + v * 0.45));
      x += barW + gap;
    }
  }

  @override
  bool shouldRepaint(_WavePainter o) => true;
}
