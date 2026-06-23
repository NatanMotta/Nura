import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/services/audio_preview_service.dart';
import '../../../../../core/widgets/vinyl_track_cover.dart';
import '../../../upload_track/presentation/screens/artist_track_upload_screen.dart';
import '../../../../user/profile/presentation/screens/profile_settings_screen.dart';
import '../../data/artist_stats_service.dart';
import 'nura_score_analytics_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../social/data/follows_repository.dart';

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
  String? _displayName;
  String? _bio;
  String? _avatarUrl;
  int _followersCount = 0;
  List<Map<String, dynamic>> _tracks = [];
  bool _loading = true;

  late NuuraScore _nuuraScore = NuuraScore.empty();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffsetNotifier =
      ValueNotifier<double>(0.0);
  final _audio = AudioPreviewService.instance;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffsetNotifier.value = _scrollController.offset;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch Profile
      final profileResponse = await client
          .from('profiles')
          .select('display_name, bio, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse != null) {
        _displayName = profileResponse['display_name'] as String?;
        _bio = profileResponse['bio'] as String?;
        _avatarUrl = profileResponse['avatar_url'] as String?;
      }

      // 2. Fetch Followers
      final followsRepo = FollowsRepository(client);
      _followersCount = await followsRepo.getFollowersCount(user.id);

      // 3. Fetch Tracks
      final tracksResponse = await client
          .from('tracks')
          .select('*')
          .eq('artist_id', user.id)
          .order('created_at', ascending: false);

      final rawTracks = List<Map<String, dynamic>>.from(tracksResponse);

      // 4. Fetch NuuraScore
      final statsService = ref.read(artistStatsServiceProvider);
      _nuuraScore = await statsService.getArtistNuuraScore(user.id);

      // 5. Fetch score per ogni traccia
      for (var i = 0; i < rawTracks.length; i++) {
        final trackScore =
            await statsService.getTrackNuuraScore(rawTracks[i]['id'] as String);
        rawTracks[i]['score'] =
            trackScore.totalScore > 0 ? trackScore.totalScore : null;
        rawTracks[i]['trackScore'] = trackScore;
      }
      _tracks = rawTracks;
    } catch (e) {
      debugPrint('Error loading artist profile data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollOffsetNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(
          child: CircularProgressIndicator(color: NuraBrand.mint),
        ),
      );
    }

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
                    musicuraBlu: NuraBrand
                        .deepMid, // Usa i colori scuri/vibranti per i blob
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
                          child: const Icon(Icons.settings_outlined,
                              color: Colors.black87, size: 22),
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

              // 2.5 UPLOAD BUTTON BANNER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 24),
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final uploaded = await Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ArtistTrackUploadScreen()),
                      );
                      if (uploaded == true) {
                        _loadData();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: NuraBrand.pink,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: NuraBrand.pink.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Carica nuovo brano',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. HEADER "I tuoi brani"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 24, bottom: 12),
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
                sliver: _tracks.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'Nessun brano caricato ancora.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.68,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _buildTrackTile(_tracks[i]),
                          childCount: _tracks.length > 6
                              ? 6
                              : (_tracks.length - (_tracks.length % 2)),
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
                  image: _avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _avatarUrl == null
                    ? const Icon(Icons.person, size: 50, color: Colors.black12)
                    : null,
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
                    border:
                        Border.all(color: const Color(0xFFF8F9FA), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child:
                      const Icon(Icons.edit, color: Colors.black87, size: 15),
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
            Text(
              _displayName ?? 'Utente',
              style: const TextStyle(
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
        // Bio
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _bio ?? 'Nessuna biografia inserita.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
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
          _buildStatCol(
              icon: Icons.music_note,
              value: _tracks.length.toString(),
              label: 'BRANI'),
          _buildVerticalDivider(),
          _buildStatCol(
              icon: Icons.people_alt,
              value: _followersCount.toString(),
              label: 'FOLLOWER'),
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
            tracks: _tracks,
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
                        coverAsset: track['cover_url'] ??
                            'assets/images/labels/milad-fakurian-PGdW_bHDbpI-unsplash.jpg',
                        size: coverSize,
                        isNetwork: track['cover_url'] != null,
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
                                tracks: _tracks,
                              ),
                            ));
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.black12, width: 1.5),
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
                        fontWeight:
                            isPlaying ? FontWeight.w900 : FontWeight.w700,
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
    final audioUrl = track['audio_url'] as String?;

    if (id == null || audioUrl == null) return;

    if (_audio.playingTrackId.value == id) {
      if (_audio.isPlaying.value) {
        await _audio.pause();
      } else {
        await _audio.resume();
      }
    } else {
      await _audio.playTrack(trackId: id, assetPath: audioUrl);
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
            child:
                const Icon(Icons.lock_outline, color: NuraBrand.pink, size: 20),
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

  ParallaxOrganicMeshPainter(
      {required this.scrollOffset,
      required this.musicuraBlu,
      required this.nuraPink});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFFF8F9FA); // Sfondo base chiaro
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    void drawReflection(
        Offset center, double radius, Color color, double opacity) {
      final glowPaint = Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 55, sigmaY: 55)
        ..color = color.withValues(alpha: opacity);
      final parallaxCenter =
          Offset(center.dx, center.dy - (scrollOffset * 0.15));
      canvas.drawCircle(parallaxCenter, radius, glowPaint);
    }

    // Blob colorati sparsi che creano il "misto con i colori dell'app"
    drawReflection(Offset(size.width * 0.15, size.height * 0.1),
        size.width * 0.5, musicuraBlu, 0.15);
    drawReflection(Offset(size.width * 0.9, size.height * 0.6),
        size.width * 0.4, musicuraBlu, 0.12);
    drawReflection(Offset(size.width * 0.4, size.height * 0.8),
        size.width * 0.35, musicuraBlu, 0.10);
    drawReflection(Offset(size.width * 0.85, size.height * 0.2),
        size.width * 0.25, nuraPink, 0.05);
    drawReflection(Offset(size.width * 0.05, size.height * 0.6),
        size.width * 0.3, nuraPink, 0.04);
  }

  @override
  bool shouldRepaint(covariant ParallaxOrganicMeshPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}

class AudioVisualizerAnimation extends StatefulWidget {
  const AudioVisualizerAnimation({super.key});
  @override
  State<AudioVisualizerAnimation> createState() =>
      _AudioVisualizerAnimationState();
}

class _AudioVisualizerAnimationState extends State<AudioVisualizerAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  final int _count = 3;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_count, (i) {
      return AnimationController(
          vsync: this, duration: Duration(milliseconds: 400 + (i * 100)))
        ..repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
          _count,
          (i) => AnimatedBuilder(
                animation: _controllers[i],
                builder: (context, _) => Container(
                  width: 3,
                  height: 4 + (_controllers[i].value * 12),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2)),
                ),
              )),
    );
  }
}
