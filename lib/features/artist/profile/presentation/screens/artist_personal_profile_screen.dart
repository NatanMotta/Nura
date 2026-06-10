import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../data/artist_stats_service.dart';
import 'nura_score_analytics_screen.dart';

class ArtistPersonalProfileScreen extends ConsumerStatefulWidget {
  final NuraVibe vibe;
  final Color accent;
  final double safeTop;
  final double safeBottom;

  const ArtistPersonalProfileScreen({
    super.key,
    required this.vibe,
    required this.accent,
    required this.safeTop,
    required this.safeBottom,
  });

  @override
  ConsumerState<ArtistPersonalProfileScreen> createState() =>
      _ArtistPersonalProfileScreenState();
}

class _ArtistPersonalProfileScreenState
    extends ConsumerState<ArtistPersonalProfileScreen> {
  // Dati Mock
  final List<Map<String, dynamic>> _mockTracks = [
    {'title': 'Passerà', 'genre': 'Pop Indie', 'feedback': 12, 'trend': null, 'score': 63},
    {'title': 'Velvet Static', 'genre': 'Dream Pop', 'feedback': 18, 'trend': null, 'score': 71},
    {'title': 'maiLOVER', 'genre': 'Alt Pop', 'feedback': 9, 'trend': 'Migliorata +5 ↗', 'score': 68},
  ];

  late NuuraScore _nuuraScore;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _nuuraScore = const NuuraScore(
      totalScore: 63,
      lyricsScore: 85,
      vibeScore: 92,
      productionScore: 89,
      marketPotentialScore: 86,
      totalFeedbacks: 14,
    );
    _scrollController.addListener(() {
      _scrollOffsetNotifier.value = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollOffsetNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // BACKGROUND MIXED WITH APP COLORS
          Positioned.fill(
            child: ValueListenableBuilder<double>(
              valueListenable: _scrollOffsetNotifier,
              builder: (context, offset, _) {
                return CustomPaint(
                  painter: ParallaxOrganicMeshPainter(
                    scrollOffset: offset,
                    musicuraBlu: NuraBrand.deepMid, // Usa i colori scuri/vibranti per i blob
                    nuraPink: NuraBrand.pink,
                  ),
                );
              },
            ),
          ),

          // SCROLL CONTENT
          CustomScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              // 0. TOP BAR (Settings gear che scolla col contenuto)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: widget.safeTop + 8,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Button (Settings)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.settings_outlined, color: Colors.black87, size: 22),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 1. HERO IDENTITY (Avatar, Name, Bio pulita)
              SliverToBoxAdapter(
                child: _buildHeroIdentity(),
              ),

              // 2. STATS ROW
              SliverToBoxAdapter(
                child: _buildStatsRow(),
              ),

              // 3. HEADER "I tuoi brani"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'I tuoi brani',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Vedi tutti >',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. LISTA BRANI
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildTrackTile(_mockTracks[i]),
                    childCount: _mockTracks.length,
                  ),
                ),
              ),

              // 5. PRO BANNER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: _buildProBanner(),
                ),
              ),

              // Spazio per Bottom Nav
              SliverToBoxAdapter(
                child: SizedBox(height: widget.safeBottom + 100),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        // Avatar compatto con Edit button
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Avatar base
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: NuraBrand.pink.withValues(alpha: 0.08),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                  image: const DecorationImage(
                    image: AssetImage('assets/images/artists/michael-dam-mEZ3PoFGs_k-unsplash.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Edit Button (basso destra)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF8F9FA), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit, color: Colors.black87, size: 15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Name & Status
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'giovami____',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: NuraBrand.pink,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '@giovami___',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        // Bio essenziale Nura (senza riferimenti IG)
        const Text(
          'KOcco, fuori ora ovunque!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        // Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link, color: Colors.black54, size: 18),
            const SizedBox(width: 6),
            const Text(
              'https://ada.lnk.to/KOcco',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCol(icon: Icons.music_note, iconColor: NuraBrand.pink, value: '12', label: 'BRANI'),
          _buildVerticalDivider(),
          _buildStatCol(icon: Icons.people_alt, iconColor: const Color(0xFF9D00FF), value: '74.883', label: 'FOLLOWER'),
          _buildVerticalDivider(),
          _buildScoreCol(),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.black.withValues(alpha: 0.05),
    );
  }

  Widget _buildStatCol({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCol() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => NuraScoreAnalyticsScreen(
            vibe: widget.vibe,
            globalScore: _nuuraScore,
            tracks: _mockTracks,
          ),
        ));
      },
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [NuraBrand.pink, Color(0xFF9D00FF), NuraBrand.mint, NuraBrand.pink],
                  stops: [0.0, 0.33, 0.66, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.5),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${_nuuraScore.totalScore}',
                    style: const TextStyle(
                      color: NuraBrand.pink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'NURA SCORE',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 8, color: Colors.black87),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTile(Map<String, dynamic> track) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cover
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage('assets/images/labels/milad-fakurian-PGdW_bHDbpI-unsplash.jpg'), // Mock
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track['title'],
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track['genre'],
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF9D00FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${track['feedback']} feedback',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (track['trend'] != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          track['trend'],
                          style: const TextStyle(
                            color: Color(0xFF00BFA5), // Vibrant Green for positive trend
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Score
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => NuraScoreAnalyticsScreen(
                  vibe: widget.vibe,
                  globalScore: _nuuraScore,
                  tracks: _mockTracks,
                ),
              ));
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: NuraBrand.pink.withValues(alpha: 0.3), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '${track['score']}',
                style: const TextStyle(
                  color: NuraBrand.pink,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Play button
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.play_arrow_rounded, color: Colors.black87, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildProBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            NuraBrand.mint.withValues(alpha: 0.2),
            NuraBrand.pink.withValues(alpha: 0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NuraBrand.pink.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline, color: NuraBrand.pink, size: 20),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sblocca Nura Pro',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Vedi i punteggi completi e l\'analisi dettagliata.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [NuraBrand.pink, Color(0xFF9D00FF)],
              ),
            ),
            child: const Text(
              'Passa a Pro',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParallaxOrganicMeshPainter extends CustomPainter {
  final double scrollOffset;
  final Color musicuraBlu;
  final Color nuraPink;

  ParallaxOrganicMeshPainter({required this.scrollOffset, required this.musicuraBlu, required this.nuraPink});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFFF8F9FA); // Sfondo base chiaro
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    void drawReflection(Offset center, double radius, Color color, double opacity) {
      final glowPaint = Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 55, sigmaY: 55)..color = color.withValues(alpha: opacity);
      final parallaxCenter = Offset(center.dx, center.dy - (scrollOffset * 0.15));
      canvas.drawCircle(parallaxCenter, radius, glowPaint);
    }

    // Blob colorati sparsi che creano il "misto con i colori dell'app"
    drawReflection(Offset(size.width * 0.15, size.height * 0.1), size.width * 0.5, musicuraBlu, 0.15);
    drawReflection(Offset(size.width * 0.9, size.height * 0.6), size.width * 0.4, musicuraBlu, 0.12);
    drawReflection(Offset(size.width * 0.4, size.height * 0.8), size.width * 0.35, musicuraBlu, 0.10);
    drawReflection(Offset(size.width * 0.85, size.height * 0.2), size.width * 0.25, nuraPink, 0.05);
    drawReflection(Offset(size.width * 0.05, size.height * 0.6), size.width * 0.3, nuraPink, 0.04);
  }

  @override
  bool shouldRepaint(covariant ParallaxOrganicMeshPainter oldDelegate) => oldDelegate.scrollOffset != scrollOffset;
}
