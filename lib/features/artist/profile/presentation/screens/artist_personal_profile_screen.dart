import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../data/artist_stats_service.dart';

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
    extends ConsumerState<ArtistPersonalProfileScreen>
    with TickerProviderStateMixin {
  // Dati Mock
  final List<Map<String, dynamic>> _mockTracks = [
    {'title': 'Passerà', 'genre': 'Pop Indie', 'feedback': 12, 'trend': null, 'score': 63},
    {'title': 'Velvet Static', 'genre': 'Dream Pop', 'feedback': 18, 'trend': null, 'score': 71},
    {'title': 'maiLOVER', 'genre': 'Alt Pop', 'feedback': 9, 'trend': 'Migliorata +5 ↗', 'score': 68},
  ];

  late NuuraScore _nuuraScore;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier(0.0);

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
    _scrollController.dispose();
    _scrollOffsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handle globally or in shell
      body: Stack(
        children: [
          // MESH ORGANICA IN PARALLASSE (Mantiene i colori dell'app)
          Positioned.fill(
            child: ValueListenableBuilder<double>(
              valueListenable: _scrollOffsetNotifier,
              builder: (context, offset, _) => CustomPaint(
                painter: _DarkOrganicMeshPainter(
                  scrollOffset: offset,
                  primaryColor: NuraBrand.deep,
                  accentColor: NuraBrand.pink,
                ),
              ),
            ),
          ),

          // SCROLL CONTENT
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: widget.safeTop + 16),
              ),
              
              // 1. HERO IDENTITY (Avatar, Name, Bio)
              SliverToBoxAdapter(
                child: _buildHeroIdentity(),
              ),

              // 2. STATS ROW
              SliverToBoxAdapter(
                child: _buildStatsRow(),
              ),

              // 3. HIGHLIGHTS (Storie)
              SliverToBoxAdapter(
                child: _buildHighlights(),
              ),

              // 4. HEADER "I tuoi brani"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'I tuoi brani',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Vedi tutti >',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. LISTA BRANI
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildTrackTile(_mockTracks[i], i),
                    childCount: _mockTracks.length,
                  ),
                ),
              ),

              // 6. PRO BANNER
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

          // TOP FLOATING BUTTONS
          _buildFloatingTopBar(),
        ],
      ),
    );
  }

  Widget _buildFloatingTopBar() {
    return Positioned(
      top: widget.safeTop + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Button (Initials)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'L',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          // Right Button (Settings)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar con Glow
        Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Glow
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NuraBrand.pink.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            // Avatar
            Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/artists/michael-dam-mEZ3PoFGs_k-unsplash.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Edit Button
            Positioned(
              bottom: 0,
              right: 10,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit, color: Colors.black, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Name & Username
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'giovami____',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 6),
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
        Text(
          '@giovami___',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        // Bio testuale
        const Text(
          'Ig: giovami_ ✨\nKOcco, fuori ora ovunque!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        // Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link, color: Colors.white.withOpacity(0.8), size: 18),
            const SizedBox(width: 4),
            Text(
              'https://ada.lnk.to/KOcco',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
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
      color: Colors.white.withOpacity(0.1),
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
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCol() {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
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
                color: NuraBrand.deep,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${_nuuraScore.totalScore}',
                style: const TextStyle(
                  color: NuraBrand.pink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'NURA SCORE',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlights() {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nuovo Highlight
            Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5), // Ideally dashed
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.add, color: Colors.white.withOpacity(0.6), size: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nuovo',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // KOcco Highlight
            Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/artists/michael-dam-mEZ3PoFGs_k-unsplash.jpg'), // Mock image
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'KOcco',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTile(Map<String, dynamic> track, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), // Dark Theme adaptation of white card
        borderRadius: BorderRadius.circular(20),
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
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track['genre'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
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
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (track['trend'] != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        track['trend'],
                        style: const TextStyle(
                          color: NuraBrand.mint,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Score
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: NuraBrand.pink.withOpacity(0.5), width: 1.5), // Simplified border gradient
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
          const SizedBox(width: 12),
          // Play button
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
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
            NuraBrand.mint.withOpacity(0.1),
            NuraBrand.pink.withOpacity(0.1),
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
              color: NuraBrand.pink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline, color: NuraBrand.pink, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sblocca Nura Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vedi i punteggi completi e l\'analisi dettagliata.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
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

// Organic Mesh Painter
class _DarkOrganicMeshPainter extends CustomPainter {
  final double scrollOffset;
  final Color primaryColor;
  final Color accentColor;

  _DarkOrganicMeshPainter({
    required this.scrollOffset,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = primaryColor,
    );

    final offsetFactor = scrollOffset * 0.2;
    
    _drawBlob(
      canvas,
      size,
      Offset(size.width * 0.8, size.height * 0.2 - offsetFactor),
      size.width * 0.6,
      accentColor.withOpacity(0.08),
    );

    _drawBlob(
      canvas,
      size,
      Offset(size.width * 0.1, size.height * 0.6 - offsetFactor * 0.6),
      size.width * 0.8,
      const Color(0xFF00D4AA).withOpacity(0.05),
    );
  }

  void _drawBlob(Canvas canvas, Size size, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _DarkOrganicMeshPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.accentColor != accentColor;
  }
}
