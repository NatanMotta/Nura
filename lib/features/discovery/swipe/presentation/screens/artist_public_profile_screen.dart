import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/services/audio_preview_service.dart';
import '../../../../../core/services/supabase_bootstrap.dart';

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
  bool _showAllTracks = false;

  String? _displayName;
  String? _imageAsset;
  List<Map<String, dynamic>> _tracks = const [];

  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  Future<void> _load() async {
    if (!SupabaseBootstrap.isInitialized) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final client = Supabase.instance.client;
      final profile = await client.from('profiles').select('display_name,image_asset').eq('id', widget.artistId).maybeSingle();
      final rows = await client
          .from('tracks')
          .select('id,title,genre,duration_seconds,storage_path')
          .eq('artist_id', widget.artistId)
          .order('created_at', ascending: false);

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

  String _durationLabel(int? seconds) {
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: NuraBrand.pink));

    final artistName = _displayName ?? widget.artistName;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // 1. PARALLAX BACKGROUND
          Positioned.fill(
            child: CustomPaint(
              painter: ParallaxOrganicMeshPainter(
                scrollOffset: _scrollOffset,
                musicuraBlu: NuraBrand.deep,
                nuraPink: NuraBrand.pink,
              ),
            ),
          ),

          // 2. HERO BANNER IMAGE (Scrolls 1:1 with transparency & Linear Gradient Mask)
          if (_imageAsset != null && _imageAsset!.isNotEmpty)
            Positioned(
              top: -_scrollOffset, // Normal 1:1 scrolling rate
              left: 0,
              right: 0,
              height: 380,
              child: Opacity(
                opacity: (1.0 - (_scrollOffset / 260)).clamp(0.0, 1.0),
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.45, 0.95],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    _imageAsset!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // 3. NORMAL SCROLLABLE CONTENT
          Positioned.fill(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // MAIN ARTIST HEADER (Opaque, scrolls normally up and away)
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Transparent spacer pushed down to 280px to clear the artist's face completely
                      const SizedBox(height: 280),
                      
                      const SizedBox(height: 24),
                      Text(artistName, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 10),
                      const Text('Electronic / Synthwave', style: TextStyle(color: Colors.black45, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                      const SizedBox(height: 48),
                      
                      // Follow/Battle Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(child: _mainBtn(label: _following ? 'Following' : 'Follow', isSolid: _following, onTap: () => setState(() => _following = !_following))),
                            const SizedBox(width: 12),
                            Expanded(child: _mainBtn(label: 'Battle', isSolid: false, onTap: () {})),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      // Stats Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem('1.2M', 'FOLLOWERS'),
                            _vDivider(),
                            _statItem('4.5M', 'MONTHLY'),
                            _vDivider(),
                            _statItem('28', 'RELEASES'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 64),
                      
                      // BRANI Title
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Text(
                          'BRANI',
                          style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Tracks List
                ValueListenableBuilder<String?>(
                  valueListenable: _audio.playingTrackId,
                  builder: (context, trackId, _) {
                    final hasPlayer = trackId != null && trackId.isNotEmpty;
                    final displayCount = (_showAllTracks || _tracks.length <= 5) ? _tracks.length : 5;
                    final hasMore = _tracks.length > 5;
                    
                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, hasPlayer ? 280 : 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == displayCount) {
                              if (!_showAllTracks && hasMore) {
                                return Center(
                                  child: TextButton(
                                    onPressed: () => setState(() => _showAllTracks = true),
                                    child: const Text('MOSTRA TUTTI I BRANI', style: TextStyle(color: NuraBrand.pink, fontSize: 11, fontWeight: FontWeight.w900)),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }
                            return _trackRow(_tracks[index], index + 1);
                          },
                          childCount: displayCount + ((!_showAllTracks && hasMore) ? 1 : 0),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 3. FLOATING BACK BUTTON WITH SOFT GLASS BACKPLATE
          Positioned(
            top: 40, left: 16,
            child: ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.25),
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                    padding: EdgeInsets.zero,
                    onPressed: widget.onBack,
                  ),
                ),
              ),
            ),
          ),

          // 4. FLOATING OPTIONS BUTTON WITH SOFT GLASS BACKPLATE
          Positioned(
            top: 40, right: 16,
            child: ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.25),
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.black87, size: 20),
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainBtn({required String label, required bool isSolid, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isSolid ? NuraBrand.pink : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(26),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: isSolid ? Colors.white : Colors.black87, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }

  Widget _trackRow(Map<String, dynamic> track, int rank) {
    final id = track['id'] as String;
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: NuraBrand.pink.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.favorite, color: Colors.white),
      ),
      onDismissed: (_) { HapticFeedback.mediumImpact(); },
      confirmDismiss: (_) async { HapticFeedback.lightImpact(); return false; },
      child: ValueListenableBuilder<String?>(
        valueListenable: _audio.playingTrackId,
        builder: (context, playingId, _) {
          final isPlaying = playingId == id;
          return GestureDetector(
            onTap: () => _playTrack(track),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Colors.transparent,
              child: Row(
                children: [
                  SizedBox(width: 20, child: Text(rank.toString(), style: TextStyle(color: isPlaying ? NuraBrand.pink : Colors.black26, fontSize: 12))),
                  const SizedBox(width: 10),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(6), child: Container(width: 44, height: 44, color: Colors.black12, child: const Icon(Icons.music_note, color: Colors.white, size: 20))),
                      if (isPlaying)
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(6)), child: const Center(child: AudioVisualizerAnimation())),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track['title'] ?? '', style: TextStyle(color: const Color(0xFF1A1A1A), fontSize: 15, fontWeight: isPlaying ? FontWeight.w900 : FontWeight.w700)),
                        const Row(
                          children: [
                            Icon(Icons.favorite, size: 10, color: Colors.black12),
                            SizedBox(width: 2),
                            Text('124', style: TextStyle(color: Colors.black26, fontSize: 10)),
                            SizedBox(width: 8),
                            Icon(Icons.chat_bubble, size: 10, color: Colors.black12),
                            SizedBox(width: 2),
                            Text('12', style: TextStyle(color: Colors.black26, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(_durationLabel(track['duration_seconds'] as int?), style: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _vDivider() { return Container(width: 1, height: 20, color: Colors.black.withValues(alpha: 0.05)); }

  Future<void> _playTrack(Map<String, dynamic> track) async {
    final id = track['id'] as String;
    final storagePath = track['storage_path'] as String?;
    if (storagePath == null) return;
    final fileName = storagePath.split('/').last;
    final assetPath = 'assets/audio/$fileName';

    if (_audio.playingTrackId.value == id) {
      if (_audio.isPlaying.value) await _audio.pause();
      else await _audio.resume();
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
