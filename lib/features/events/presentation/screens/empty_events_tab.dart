import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/app_colors.dart';
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // PARALLAX ORGANIC MESH BACKGROUND
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _EventsParallaxOrganicMeshPainter(
                  scrollOffset: 0,
                  musicuraBlu: NuraBrand.deep,
                  nuraPink: NuraBrand.pink,
                ),
              ),
            ),
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  top: safeTop + 32,
                  bottom: safeBottom + 120, // Account for miniplayer & nav
                  left: 20,
                  right: 20,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title
                    const Text(
                      'Eventi & Battle',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Mono(
                      'SCOPRI COSA SUCCEDE INTORNO A TE',
                      color: Colors.black45,
                    ),
                    const SizedBox(height: 32),

                    // Highlight Event
                    _buildEventCard(
                      title: 'Battle in arrivo',
                      subtitle: 'La sfida finale tra producer emergenti. Chi dominerà il palco stasera?',
                      date: 'VEN, 15 LUG • 21:00',
                      location: 'Alcatraz, Milano',
                      icon: Icons.flash_on_rounded,
                      color: NuraBrand.pink,
                      isHighlighted: true,
                    ),
                    const SizedBox(height: 16),

                    // Generic Event 1
                    _buildEventCard(
                      title: 'Evento generico 1',
                      subtitle: 'Serata di networking e ascolto per A&R e artisti indipendenti.',
                      date: 'SAB, 23 LUG • 18:30',
                      location: 'Base Milano',
                      icon: Icons.mic_external_on_rounded,
                      color: const Color(0xFF7C5BFF),
                      isHighlighted: false,
                    ),
                    const SizedBox(height: 16),

                    // Generic Event
                    _buildEventCard(
                      title: 'Evento generico',
                      subtitle: 'Showcase live e presentazione nuove release dell\'etichetta.',
                      date: 'GIO, 28 LUG • 20:00',
                      location: 'Apollo Club',
                      icon: Icons.album_outlined,
                      color: const Color(0xFF00C9A7),
                      isHighlighted: false,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String subtitle,
    required String date,
    required String location,
    required IconData icon,
    required Color color,
    required bool isHighlighted,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isHighlighted 
              ? Colors.white.withValues(alpha: 0.8) 
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isHighlighted 
                ? color.withValues(alpha: 0.3) 
                : Colors.black.withValues(alpha: 0.05),
            width: isHighlighted ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted 
                  ? color.withValues(alpha: 0.15) 
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Bottom Info Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, size: 14, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.location_on_rounded, size: 14, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(
                    location,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsParallaxOrganicMeshPainter extends CustomPainter {
  final double scrollOffset;
  final Color musicuraBlu;
  final Color nuraPink;

  _EventsParallaxOrganicMeshPainter({required this.scrollOffset, required this.musicuraBlu, required this.nuraPink});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFFF8F9FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    void drawReflection(Offset center, double radius, Color color, double opacity) {
      final glowPaint = Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 55, sigmaY: 55)..color = color.withValues(alpha: opacity);
      final parallaxCenter = Offset(center.dx, center.dy - (scrollOffset * 0.15));
      canvas.drawCircle(parallaxCenter, radius, glowPaint);
    }

    drawReflection(Offset(size.width * 0.15, size.height * 0.1), size.width * 0.5, musicuraBlu, 0.15);
    drawReflection(Offset(size.width * 0.9, size.height * 0.6), size.width * 0.4, musicuraBlu, 0.12);
    drawReflection(Offset(size.width * 0.4, size.height * 0.8), size.width * 0.35, musicuraBlu, 0.10);
    drawReflection(Offset(size.width * 0.85, size.height * 0.2), size.width * 0.25, nuraPink, 0.05);
    drawReflection(Offset(size.width * 0.05, size.height * 0.6), size.width * 0.3, nuraPink, 0.04);
  }

  @override
  bool shouldRepaint(covariant _EventsParallaxOrganicMeshPainter oldDelegate) => oldDelegate.scrollOffset != scrollOffset;
}
