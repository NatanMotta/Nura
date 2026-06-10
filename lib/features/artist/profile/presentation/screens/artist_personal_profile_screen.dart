import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../discovery/swipe/presentation/screens/artist_public_profile_screen.dart' show ParallaxOrganicMeshPainter;
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
  ConsumerState<ArtistPersonalProfileScreen> createState() => _ArtistPersonalProfileScreenState();
}

class _ArtistPersonalProfileScreenState extends ConsumerState<ArtistPersonalProfileScreen> {
  final List<Map<String, dynamic>> _mockTracks = [
    {
      'title': 'Midnight Neon',
      'duration_seconds': 184,
      'plays': 12400,
    },
    {
      'title': 'Synthwave Dreams',
      'duration_seconds': 212,
      'plays': 8900,
    },
    {
      'title': 'Retro Future',
      'duration_seconds': 195,
      'plays': 15600,
    },
    {
      'title': 'Cybernetic Heart',
      'duration_seconds': 208,
      'plays': 7200,
    },
  ];

  NuuraScore? _nuuraScore;
  final String _artistName = 'Michael Dam';
  final String _artistBio = 'Electronic Music Producer';

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffsetNotifier.value = _scrollController.offset;
    });
    
    // Dati completamente Mockati come richiesto (senza delay)
    _nuuraScore = const NuuraScore(
      totalScore: 88,
      lyricsScore: 85,
      vibeScore: 92,
      productionScore: 89,
      marketPotentialScore: 86,
      totalFeedbacks: 14,
    );
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
      backgroundColor: NuraBrand.deepest,
      body: Stack(
        children: [
          // 1. Sfondo Organico Mesh (Allineato con il resto dell'app)
          Positioned.fill(
            child: ValueListenableBuilder<double>(
              valueListenable: _scrollOffsetNotifier,
              builder: (context, offset, child) {
                return CustomPaint(
                  painter: ParallaxOrganicMeshPainter(
                    scrollOffset: offset,
                    musicuraBlu: NuraBrand.deepMid,
                    nuraPink: NuraBrand.pink,
                  ),
                );
              },
            ),
          ),

          // 2. Contenuto Scrollabile
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: widget.safeTop + 60),
              ),
              
              // 3. Nuura Score & Identity Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      _buildIdentityGlassCard(),
                      const SizedBox(height: 24),
                      if (_nuuraScore != null) _buildNuuraBentoGrid(_nuuraScore!),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // 4. Intestazione Sticky Brani
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySectionHeaderDelegate(
                  title: 'BRANI',
                  safeTop: 0, 
                ),
              ),

              // 5. Lista dei Brani Mockata
              SliverPadding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 0.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildTrackTile(_mockTracks[index], index);
                    },
                    childCount: _mockTracks.length,
                  ),
                ),
              ),

              // Spazio per il MiniPlayer in fondo
              SliverToBoxAdapter(
                child: SizedBox(height: widget.safeBottom + 140),
              ),
            ],
          ),

          // Bottone Impostazioni Fluttuante in alto a destra
          Positioned(
            top: widget.safeTop + 8,
            right: 16,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- IDENTITY CARD ---
  Widget _buildIdentityGlassCard() {
    final score = _nuuraScore?.totalScore ?? 0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildGamifiedAvatar('assets/images/artists/michael-dam-mEZ3PoFGs_k-unsplash.jpg', score),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _artistName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _artistBio,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGamifiedAvatar(String imageUrl, int score) {
    Color ringColor = score >= 90 ? const Color(0xFF39FF14) : 
                      score >= 80 ? NuraBrand.mint : 
                      score >= 70 ? Colors.yellow : NuraBrand.pink;
                      
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Avatar Image
          ClipRRect(
            borderRadius: BorderRadius.circular(55),
            child: Image.asset(
              imageUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              cacheWidth: 300,
            ),
          ),
          // Circular Progress Ring
          SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(
              value: score / 100.0,
              strokeWidth: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Nuura Score Badge
          Positioned(
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: NuraBrand.deepest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ringColor, width: 2),
              ),
              child: Text(
                score.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NUURA BENTO GRID ---
  Widget _buildNuuraBentoGrid(NuuraScore score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nuura Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildBentoStat('TESTO', score.lyricsScore, NuraBrand.pink)),
            const SizedBox(width: 12),
            Expanded(child: _buildBentoStat('VIBE', score.vibeScore, const Color(0xFF9D00FF))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildBentoStat('PROD.', score.productionScore, NuraBrand.mint)),
            const SizedBox(width: 12),
            Expanded(child: _buildBentoStat('MERCATO', score.marketPotentialScore, const Color(0xFF39FF14))),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100.0,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // --- TRACK TILE ---
  Widget _buildTrackTile(Map<String, dynamic> track, int index) {
    final title = track['title'] as String;
    final durSecs = track['duration_seconds'] as int;
    final plays = track['plays'] as int;
    
    final min = durSecs ~/ 60;
    final sec = (durSecs % 60).toString().padLeft(2, '0');
    final durationStr = '$min:$sec';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.music_note, color: Colors.white54, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$plays ascolti • $durationStr',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.3), size: 24),
        ],
      ),
    );
  }
}

class _StickySectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final double safeTop;

  _StickySectionHeaderDelegate({required this.title, required this.safeTop});

  @override
  double get minExtent => 64.0 + safeTop; 
  @override
  double get maxExtent => 64.0 + safeTop; 

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double opacity = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    
    return Container(
      color: Color.lerp(Colors.transparent, NuraBrand.deepest.withValues(alpha: 0.98), opacity),
      padding: EdgeInsets.only(top: safeTop, left: 20, right: 20),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySectionHeaderDelegate oldDelegate) {
    return title != oldDelegate.title || safeTop != oldDelegate.safeTop;
  }
}
