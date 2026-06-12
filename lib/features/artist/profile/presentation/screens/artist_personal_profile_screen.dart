import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/services/audio_preview_service.dart';
import '../../../../../core/widgets/vinyl_track_cover.dart';
import '../../../../user/profile/presentation/screens/profile_settings_screen.dart';
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
    {'id': 'mock_1', 'title': 'Passerà', 'genre': 'Pop Indie', 'feedback': 12, 'trend': null, 'score': 63, 'storage_path': 'preview_audio_1.mp3'},
    {'id': 'mock_2', 'title': 'Velvet Static', 'genre': 'Dream Pop', 'feedback': 18, 'trend': null, 'score': 71, 'storage_path': 'preview_audio_2.mp3'},
    {'id': 'mock_3', 'title': 'maiLOVER', 'genre': 'Alt Pop', 'feedback': 9, 'trend': 'Migliorata +5', 'score': 68, 'storage_path': 'preview_audio_3.mp3'},
    {'id': 'mock_4', 'title': 'Midnight City', 'genre': 'Synth Pop', 'feedback': 24, 'trend': null, 'score': 75, 'storage_path': 'preview_audio_4.mp3'},
    {'id': 'mock_5', 'title': 'Lost in Tokyo', 'genre': 'Lo-Fi', 'feedback': 5, 'trend': null, 'score': 60, 'storage_path': 'preview_audio_5.mp3'},
    {'id': 'mock_6', 'title': 'Neon Lights', 'genre': 'Electro Pop', 'feedback': 32, 'trend': 'Migliorata +12', 'score': 82, 'storage_path': 'preview_audio_6.mp3'},
    {'id': 'mock_7', 'title': 'Summer Breeze', 'genre': 'Acoustic', 'feedback': 15, 'trend': null, 'score': 66, 'storage_path': 'preview_audio_7.mp3'},
  ];

  late NuuraScore _nuuraScore;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier<double>(0.0);
  final _audio = AudioPreviewService.instance;

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
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. HERO IDENTITY & TOP BAR
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Hero Identity (Avatar, Name, Bio)
                    Padding(
                      padding: EdgeInsets.only(top: widget.safeTop + 16),
                      child: _buildHeroIdentity(),
                    ),
                    // Settings Gear in top left
                    Positioned(
                      top: widget.safeTop + 8,
                      left: 16,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const ProfileSettingsScreen(),
                          ));
                        },
                        child: Container(
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
                      ),
                    ),
                  ],
                ),
              ),

              // 2. STATS ROW
              SliverToBoxAdapter(
                child: _buildStatsRow(),
              ),

              // 3. HEADER "I tuoi brani"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
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
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // TODO: Navigate to all tracks
                        },
                        child: const Text(
                          'Vedi tutti >',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. LISTA BRANI
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildTrackTile(_mockTracks[i]),
                    childCount: _mockTracks.length > 6 ? 6 : (_mockTracks.length - (_mockTracks.length % 2)),
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

              // Spazio per Bottom Nav e Mini Player
              SliverToBoxAdapter(
                child: SizedBox(height: widget.safeBottom + 160),
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
                  border: Border.all(color: Colors.white, width: 3),
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
            const SizedBox(height: 16),
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Produttore e DJ indipendente. Esplorando nuovi suoni e vibrazioni.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCol(icon: Icons.music_note, value: '12', label: 'BRANI'),
          _buildVerticalDivider(),
          _buildStatCol(icon: Icons.people_alt, value: '74.883', label: 'FOLLOWER'),
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
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.black87, size: 22),
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
            fontSize: 10,
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${_nuuraScore.totalScore}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NURA SCORE',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 8, color: Colors.black87),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTile(Map<String, dynamic> track) {
    final trackId = track['id'];

    return ValueListenableBuilder<String?>(
      valueListenable: _audio.playingTrackId,
      builder: (context, playingId, _) {
        final isPlaying = playingId == trackId;
        return GestureDetector(
          onTap: () => _playTrack(track),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final coverSize = constraints.maxWidth;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover and Score Stack
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      VinylTrackCover(
                        isPlaying: isPlaying,
                        coverAsset: 'assets/images/labels/milad-fakurian-PGdW_bHDbpI-unsplash.jpg',
                        size: coverSize,
                      ),
                      // Score Overlay
                      Positioned(
                        top: -4,
                        right: 4,
                        child: GestureDetector(
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
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black12, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${track['score']}',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      track['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF1A1A1A),
                        fontSize: 14,
                        fontWeight: isPlaying ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Genre
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      track['genre'].toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isPlaying ? NuraBrand.pink : Colors.black38,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _playTrack(Map<String, dynamic> track) async {
    HapticFeedback.lightImpact();
    final id = track['id'] as String?;
    final storagePath = track['storage_path'] as String?;
    if (id == null || storagePath == null) return;
    
    final fileName = storagePath.split('/').last;
    final assetPath = 'assets/audio/$fileName';

    if (_audio.playingTrackId.value == id) {
      if (_audio.isPlaying.value) {
        await _audio.pause();
      } else {
        await _audio.resume();
      }
    } else {
      await _audio.playTrack(trackId: id, assetPath: assetPath);
    }
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

class AudioVisualizerAnimation extends StatefulWidget {
  const AudioVisualizerAnimation({super.key});
  @override
  State<AudioVisualizerAnimation> createState() => _AudioVisualizerAnimationState();
}

class _AudioVisualizerAnimationState extends State<AudioVisualizerAnimation> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  final int _count = 3;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_count, (i) {
      return AnimationController(vsync: this, duration: Duration(milliseconds: 400 + (i * 100)))..repeat(reverse: true);
    });
  }

  @override
  void dispose() { for (var c in _controllers) { c.dispose(); } super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(_count, (i) => AnimatedBuilder(
        animation: _controllers[i],
        builder: (context, _) => Container(
          width: 3, height: 4 + (_controllers[i].value * 12),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
        ),
      )),
    );
  }
}
