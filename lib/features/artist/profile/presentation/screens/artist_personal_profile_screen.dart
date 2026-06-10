import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../discovery/swipe/presentation/screens/artist_public_profile_screen.dart' show ParallaxOrganicMeshPainter;

// --- MOCKS ---
class _MockTrack {
  final String title;
  final String duration;
  final int plays;
  const _MockTrack(this.title, this.duration, this.plays);
}

final _mockTracks = [
  const _MockTrack('Neon Midnight', '3:45', 12450),
  const _MockTrack('Cybernetic Groove', '4:10', 8300),
  const _MockTrack('Electric Rain', '2:55', 21000),
  const _MockTrack('Synthetic Soul', '5:20', 4500),
  const _MockTrack('Analog Dreams', '4:05', 3200),
  const _MockTrack('Void Walker', '3:12', 18900),
];

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
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollNotifier.value = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double coverHeight = 300.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Sfondo Organico Allineato al resto dell'app
          ValueListenableBuilder<double>(
            valueListenable: _scrollNotifier,
            builder: (context, scrollOffset, _) {
              return Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: ParallaxOrganicMeshPainter(
                      scrollOffset: scrollOffset,
                      musicuraBlu: NuraBrand.deepMid,
                      nuraPink: NuraBrand.pink,
                    ),
                  ),
                ),
              );
            },
          ),

          // 1. Cover Image (Parallax & Elastic)
          ValueListenableBuilder<double>(
            valueListenable: _scrollNotifier,
            builder: (context, scrollOffset, _) {
              double parallaxOffset = 0;
              double scale = 1.0;
              
              if (scrollOffset > 0) {
                parallaxOffset = scrollOffset * 0.5;
              } else {
                scale = 1.0 + (-scrollOffset / coverHeight);
              }
              
              final double coverOpacity = (1.0 - (scrollOffset / (coverHeight * 0.8))).clamp(0.0, 1.0);

              return Positioned(
                top: -parallaxOffset,
                left: 0,
                right: 0,
                height: coverHeight,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.bottomCenter,
                  child: Opacity(
                    opacity: coverOpacity,
                    child: Image.asset(
                      'assets/images/artists/michael-dam-mEZ3PoFGs_k-unsplash.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey[800]),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // 2. Custom Scroll View (Main Content)
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Spazio vuoto per rivelare la cover
              SliverToBoxAdapter(
                child: SizedBox(height: coverHeight - 100),
              ),
              
              // Identity Glass Card & Bento
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildIdentityGlassCard(),
                      const SizedBox(height: 16),
                      _buildNuuraBentoGrid(),
                    ],
                  ),
                ),
              ),

              // Spaziatura per "respiro"
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),

              // Sticky Header "BRANI"
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySectionHeaderDelegate(
                  title: 'BRANI',
                  safeTop: widget.safeTop,
                ),
              ),

              // Lista dei Brani
              SliverPadding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 0.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = _mockTracks[index];
                      return _buildTrackTile(track, index);
                    },
                    childCount: _mockTracks.length,
                  ),
                ),
              ),

              // Padding finale per non coprire col MiniPlayer
              SliverToBoxAdapter(
                child: SizedBox(height: widget.safeBottom + 140),
              ),
            ],
          ),
          
          // 3. Top Buttons (Floating Settings)
          Positioned(
            top: widget.safeTop + 8,
            right: 16,
            child: _buildGlassIconButton(Icons.settings_outlined, onTap: () {}),
          ),
        ],
      ),
    );
  }

  // --- COMPONENTI UI ---

  Widget _buildGlassIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16), // Squircle-ish
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4), // Dark Glassmorphism
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1), // Rim light
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar con Glow Ring (Nuura Score)
              _buildSquircleAvatarWithGlow(score: 88),
              
              const SizedBox(width: 20),
              
              // Testi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Michael Dam',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PRODUCER',
                      style: TextStyle(
                        color: NuraBrand.mint.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquircleAvatarWithGlow({required int score}) {
    // Definiamo il colore in base allo score (Glow Ring)
    Color glowColor;
    if (score >= 67) {
      glowColor = const Color(0xFF39FF14); // Elite Tier
    } else if (score >= 34) {
      glowColor = Colors.orangeAccent; // Growth Tier
    } else {
      glowColor = Colors.lightBlueAccent; // Base Tier
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black,
        // ContinuousRectangleBorder crea uno squircle perfetto
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset.zero,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/images/artists/michael-dam-mEZ3PoFGs_k-unsplash.jpg',
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildNuuraBentoGrid() {
    return Column(
      children: [
        // Prima riga: Followers / Following (Social Validation)
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                child: _buildStatColumn('14.2K', 'FOLLOWERS'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                child: _buildStatColumn('320', 'FOLLOWING'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Seconda riga: Nuura Score Dettagliato
        _buildBentoCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.diamond_outlined, color: NuraBrand.pink, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Nuura Score',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '88',
                    style: TextStyle(
                      color: const Color(0xFF39FF14),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // I 5 parametri dei curatori
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniParameter('Comp.', 82),
                  _buildMiniParameter('Orig.', 90),
                  _buildMiniParameter('Mix', 88),
                  _buildMiniParameter('Pot.', 85),
                  _buildMiniParameter('Eng.', 95),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBentoCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16.0),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniParameter(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackTile(_MockTrack track, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // Copertina minuscola
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.music_note, color: Colors.white54, size: 20),
          ),
          const SizedBox(width: 16),
          // Info brano
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${track.plays} ascolti • ${track.duration}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Tasto opzioni
          Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.3), size: 20),
        ],
      ),
    );
  }
}

// --- STICKY HEADER DELEGATE ---
class _StickySectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final double safeTop;

  _StickySectionHeaderDelegate({required this.title, required this.safeTop});

  @override
  double get minExtent => 60.0 + safeTop; // altezza minima (bloccata in alto)
  @override
  double get maxExtent => 60.0 + safeTop; // altezza massima

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Sfondo che diventa opaco man mano che si stacca dal fondo
    final double opacity = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    
    return Container(
      color: Color.lerp(Colors.transparent, NuraBrand.deepest.withValues(alpha: 0.95), opacity),
      padding: EdgeInsets.only(top: safeTop, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          // Bottone Add (+) Squircle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
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
