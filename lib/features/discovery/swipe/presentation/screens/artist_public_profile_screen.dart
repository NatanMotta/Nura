import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/services/audio_preview_service.dart';
import '../../../../../core/services/supabase_bootstrap.dart';

import '../../../../artist/profile/presentation/screens/nura_score_analytics_screen.dart';
import '../../../../artist/profile/data/artist_stats_service.dart';

class ArtistPublicProfileScreen extends ConsumerStatefulWidget {
  final String artistId;
  final String artistName;
  final VoidCallback? onBack;

  const ArtistPublicProfileScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.onBack,
  });

  @override
  ConsumerState<ArtistPublicProfileScreen> createState() =>
      _ArtistPublicProfileScreenState();
}

class _ArtistPublicProfileScreenState extends ConsumerState<ArtistPublicProfileScreen> {
  final _audio = AudioPreviewService.instance;
  final ScrollController _scrollController = ScrollController();
  
  bool _loading = true;
  bool _following = false;
  
  String? _displayName;
  String? _imageAsset;
  List<Map<String, dynamic>> _tracks = const [];
  
  final NuuraScore _nuuraScore = NuuraScore(
    totalFeedbacks: 124,
    totalScore: 63,
    vibeScore: 71,
    productionScore: 58,
    lyricsScore: 65,
    marketPotentialScore: 60,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!SupabaseBootstrap.isInitialized) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final client = Supabase.instance.client;
      final profile = await client.from('profiles').select('display_name,image_asset').eq('id', widget.artistId).maybeSingle().timeout(const Duration(seconds: 4));
      final rows = await client
          .from('tracks')
          .select('id,title,genre,duration_seconds,storage_path')
          .eq('artist_id', widget.artistId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 4));

      if (mounted) {
        setState(() {
          _displayName = profile?['display_name'];
          _imageAsset = profile?['image_asset'];
          _tracks = List<Map<String, dynamic>>.from(rows);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleFollow() {
    HapticFeedback.mediumImpact();
    setState(() {
      _following = !_following;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: NuraBrand.pink));

    final artistName = _displayName ?? widget.artistName;
    final safeTop = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _audio.stop();
        if (context.mounted) {
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.of(context).pop(result);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent, // Background handled by Stack
        body: Stack(
          children: [
            // PARALLAX BACKGROUND
            Positioned.fill(
              child: CustomPaint(
                painter: ParallaxOrganicMeshPainter(
                  scrollOffset: 0.0, 
                  musicuraBlu: NuraBrand.deep,
                  nuraPink: NuraBrand.pink,
                ),
              ),
            ),

            // SCROLL CONTENT
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: safeTop + 16),
                        child: _buildHeroIdentity(artistName),
                      ),
                      Positioned(
                        top: safeTop + 8,
                        left: 16,
                        child: GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            await _audio.stop();
                            if (context.mounted) {
                              if (widget.onBack != null) {
                                widget.onBack!();
                              } else {
                                Navigator.of(context).pop();
                              }
                            }
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
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildStatsRow(),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'I brani di $artistName',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
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

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildTrackTile(_tracks[index], index + 1);
                      },
                      childCount: _tracks.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroIdentity(String artistName) {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            image: _imageAsset != null && _imageAsset!.isNotEmpty
                ? DecorationImage(
                    image: AssetImage(_imageAsset!),
                    fit: BoxFit.cover,
                  )
                : const DecorationImage(
                    image: AssetImage('assets/images/artists/aiony-haust-3TLl_97HNJo-unsplash.jpg'),
                    fit: BoxFit.cover,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              artistName,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: NuraBrand.pink,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '@${artistName.toLowerCase().replaceAll(' ', '_')}',
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _toggleFollow,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              color: _following ? Colors.black.withValues(alpha: 0.05) : NuraBrand.pink,
              borderRadius: BorderRadius.circular(24),
              border: _following ? Border.all(color: Colors.black.withValues(alpha: 0.1)) : null,
              boxShadow: !_following
                  ? [
                      BoxShadow(
                        color: NuraBrand.pink.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Text(
              _following ? 'Segui già' : 'Segui',
              style: TextStyle(
                color: _following ? Colors.black87 : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
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
          _buildStatCol(icon: Icons.music_note, iconColor: NuraBrand.pink, value: '${_tracks.length}', label: 'BRANI'),
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
        const SizedBox(height: 2),
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
            vibe: NuraVibe.premium,
            globalScore: _nuuraScore,
            tracks: _tracks,
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

  Widget _buildTrackTile(Map<String, dynamic> track, int rank) {
    final trackId = track['id'] ?? 'mock_id_$rank';
    final title = track['title'] ?? 'Brano $rank';
    final genre = track['genre'] ?? 'Pop Indie';
    final baseScore = track['score'] ?? 63;

    return ValueListenableBuilder<String?>(
      valueListenable: _audio.playingTrackId,
      builder: (context, playingId, _) {
        final isPlaying = playingId == trackId;
        return GestureDetector(
          onTap: () => _playTrack(track),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPlaying ? NuraBrand.pink.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPlaying ? NuraBrand.pink.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/labels/milad-fakurian-PGdW_bHDbpI-unsplash.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (isPlaying)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.pause, color: Colors.white, size: 28),
                        ),
                      )
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: isPlaying ? FontWeight.w900 : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        genre,
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
                          const Text(
                            '12 feedback',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => NuraScoreAnalyticsScreen(
                        vibe: NuraVibe.premium,
                        globalScore: _nuuraScore,
                        tracks: _tracks,
                      ),
                    ));
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: NuraBrand.pink.withValues(alpha: 0.3), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$baseScore',
                      style: const TextStyle(
                        color: NuraBrand.pink,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (!isPlaying)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.black87, size: 20),
                  ),
                if (isPlaying)
                  const SizedBox(width: 32),
              ],
            ),
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

class ParallaxOrganicMeshPainter extends CustomPainter {
  final double scrollOffset;
  final Color musicuraBlu;
  final Color nuraPink;

  ParallaxOrganicMeshPainter({required this.scrollOffset, required this.musicuraBlu, required this.nuraPink});

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
  bool shouldRepaint(covariant ParallaxOrganicMeshPainter oldDelegate) => oldDelegate.scrollOffset != scrollOffset;
}
