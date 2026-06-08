import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/mono.dart';

class EmptyEventsTab extends StatelessWidget {
  final NuraVibe vibe;
  final Color accent;
  final double safeTop, safeBottom;

  const EmptyEventsTab({
    super.key,
    required this.vibe,
    required this.accent,
    required this.safeTop,
    required this.safeBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A11),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_seat_rounded, size: 64, color: accent.withValues(alpha: 0.6)),
            const SizedBox(height: 24),
            const Text(
              'Eventi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Mono(
              'presto disponibili',
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
