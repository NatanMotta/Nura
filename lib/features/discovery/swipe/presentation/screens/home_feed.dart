import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/models/track.dart';
import '../../../../../core/services/audio_preview_service.dart';
import '../../../../../core/widgets/mono.dart';
import '../../../../../core/widgets/nura_mark.dart';
import '../../../../../core/widgets/striped_panel.dart';
import '../../../../../core/widgets/waveform.dart';
import '../../../../social/data/social_engagement_service.dart';
import '../../../../shared/data/mock_nura_data.dart';
import '../../data/remote_tracks_service.dart';
import 'artist_public_profile_screen.dart';

class HomeFeed extends StatefulWidget {
  final NuraVibe vibe;
  final Color accent;
  final String waveform;
  final double safeTop, safeBottom;
  final void Function(String artistId, String artistName)? onArtistTap;
  const HomeFeed(
      {super.key,
      required this.vibe,
      required this.accent,
      required this.waveform,
      required this.safeTop,
      required this.safeBottom,
      this.onArtistTap});
  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed>
    with SingleTickerProviderStateMixin {
  late List<Track> deck;
  late List<Track> _sourceDeck;
  final _audio = AudioPreviewService.instance;
  final _remoteTracks = const RemoteTracksService();
  final _social = const SocialEngagementService();
  String? impulse;
  int likes = 12, skips = 38;
  bool _deckReady = false;
  final ValueNotifier<double> _topDragDx = ValueNotifier<double>(0);
  String? _lastAudioErrorShown;
  Map<String, EngagementCounts> _engagementByTrack = const {};
  Set<String> _likedTrackIds = <String>{};
  Set<String> _savedTrackIds = <String>{};
  String? _authUserId;
  late final AnimationController _deckIntroController;
  bool _deckIntroPlayed = false;

  @override
  void initState() {
    super.initState();
    _deckIntroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _audio.lastError.addListener(_onAudioError);
    _sourceDeck = List.of(kTracks);
    deck = const [];
    _loadDeckFromCloud();
  }

  void _onAudioError() {
    final error = _audio.lastError.value;
    if (!mounted || error == null || error.isEmpty) return;
    if (_lastAudioErrorShown == error) return;
    _lastAudioErrorShown = error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  Future<void> _loadDeckFromCloud() async {
    List<Track> selected = List.of(kTracks);
    try {
      final remote = await _remoteTracks.fetchTracks();
      if (remote.isNotEmpty) {
        selected = List.of(remote);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Nessuna traccia remota valida con artista reale trovata.',
              ),
            ),
          );
        }
      }
    } catch (_) {
      // keep selected = mock deck
    }

    if (!mounted) return;

    // Warm-up first covers to avoid first-frame visual jump on real devices.
    for (final t in selected.take(3)) {
      final cover = t.coverAsset;
      if (cover != null && cover.startsWith('assets/')) {
        unawaited(precacheImage(AssetImage(cover), context));
      }
    }

    setState(() {
      _sourceDeck = selected;
      deck = List.of(selected);
      _deckReady = true;
    });
    if (!_deckIntroPlayed) {
      _deckIntroPlayed = true;
      _deckIntroController
        ..value = 0
        ..forward();
    }

    unawaited(_loadEngagement(selected));

    // Start audio only after deck is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playTopTrackPreview();
    });
  }

  Future<void> _loadEngagement(List<Track> tracks) async {
    try {
      final trackIds = tracks.map((t) => t.id).toList(growable: false);
      final counts = await _social.fetchCountsForTrackIds(trackIds);

      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id;
      Set<String> liked = <String>{};
      Set<String> saved = <String>{};
      if (userId != null) {
        liked = await _social.fetchUserLikedTrackIds(userId, trackIds);
        saved = await _social.fetchUserSavedTrackIds(userId, trackIds);
      }

      if (!mounted) return;
      setState(() {
        _engagementByTrack = counts;
        _likedTrackIds = liked;
        _savedTrackIds = saved;
        _authUserId = userId;
      });
    } catch (_) {
      // fallback: keep local counters
    }
  }

  Future<void> _toggleSaveTopTrack() async {
    if (deck.isEmpty) return;
    final userId = _authUserId;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login richiesto per salvare brani')),
      );
      return;
    }

    final trackId = deck.first.id;
    final wasSaved = _savedTrackIds.contains(trackId);
    final nextSaved = !wasSaved;

    setState(() {
      if (nextSaved) {
        _savedTrackIds.add(trackId);
      } else {
        _savedTrackIds.remove(trackId);
      }
    });

    try {
      await _social.setSave(
        trackId: trackId,
        userId: userId,
        shouldSave: nextSaved,
      );
      await _refreshTrackEngagement(trackId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _savedTrackIds.add(trackId);
        } else {
          _savedTrackIds.remove(trackId);
        }
      });
    }
  }

  Future<void> _refreshTrackEngagement(String trackId) async {
    final rows = await _social.fetchCountsForTrackIds([trackId]);
    if (!mounted) return;
    setState(() {
      _engagementByTrack = {
        ..._engagementByTrack,
        ...rows,
      };
    });
  }

  void _decide(String action) {
    final decidedTrack = deck.first;
    final userId = _authUserId;
    setState(() {
      if (action == 'like') {
        likes++;
        _likedTrackIds.add(decidedTrack.id);
      } else {
        skips++;
      }
      deck.removeAt(0);
      if (deck.isEmpty) deck = List.of(_sourceDeck);
      impulse = null;
      _topDragDx.value = 0;
    });

    if (action == 'like' && userId != null) {
      unawaited(_social.setLike(
        trackId: decidedTrack.id,
        userId: userId,
        shouldLike: true,
      ));
      unawaited(_refreshTrackEngagement(decidedTrack.id));
    }
    _playTopTrackPreview();
  }

  Future<void> _openArtistProfile(Track track) async {
    final artistId = track.artistId;

    if (!mounted) return;
    if (artistId == null || artistId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilo artista non disponibile')),
      );
      return;
    }

    if (widget.onArtistTap != null) {
      widget.onArtistTap!(artistId, track.artist);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ArtistPublicProfileScreen(
            artistId: artistId,
            artistName: track.artist,
          ),
        ),
      );
    }
  }

  Future<void> _playTopTrackPreview() async {
    if (deck.isEmpty) return;
    final top = deck.first;
    if (top.audioAsset == null || !top.audioAsset!.startsWith('assets/')) {
      await _audio.stop();
      return;
    }
    await _audio.togglePreview(trackId: top.id, assetPath: top.audioAsset);
  }

  String _formatMmSs(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audio.lastError.removeListener(_onAudioError);
    _audio.stop();
    _topDragDx.dispose();
    _deckIntroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = 86 + widget.safeBottom; // bottom nav height incl. safe area
    if (!_deckReady || deck.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final topTrack = deck.first;
    final topStats = _engagementByTrack[topTrack.id] ?? const EngagementCounts();
    final dragNorm = (_topDragDx.value.abs() / 120).clamp(0.0, 1.0);
    return Stack(children: [
        Positioned.fill(
          child: CustomPaint(
            painter: ParallaxOrganicMeshPainter(
              scrollOffset: 0,
              musicuraBlu: NuraBrand.deep,
              nuraPink: NuraBrand.pink,
            ),
          ),
        ),
        // Header
        Padding(
          padding: EdgeInsets.fromLTRB(18, widget.safeTop, 18, 8),
          child: Row(children: [
            NuraMark(size: 26, color: widget.accent, dropShadow: true),
            const SizedBox(width: 8),
            const Text('nura',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.4)),
            const Spacer(),
            Mono('♥ $likes', color: Color(0xFF1A1A1A)),
            const SizedBox(width: 8),
            Mono('↳ $skips', color: Colors.black45),
          ]),
        ),
        // While dragging, push everything else visually to the background.
        if (dragNorm > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                color: Colors.black.withValues(alpha: 0.12 * dragNorm),
              ),
            ),
          ),
        // Card stack
        Positioned(
          top: widget.safeTop + 50,
          left: 16,
          right: 16,
          bottom: nav + 100,
          child: Stack(children: [
            AnimatedBuilder(
              animation: _deckIntroController,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_deckIntroController.value);
                return Stack(
                  children: [
                    for (int i = math.min(2, deck.length - 1); i >= 0; i--)
                      Transform.translate(
                        offset: _introOffsetForDepth(i, t),
                        child: Transform.scale(
                          scale: _introScaleForDepth(i, t),
                          child: Opacity(
                            opacity: _introOpacityForDepth(i, t),
                            child: SwipeCard(
                              key: ValueKey('${deck[i].id}-${deck.length}-$i'),
                              track: deck[i],
                              vibe: widget.vibe,
                              accent: widget.accent,
                              waveStyle: widget.waveform,
                              depth: i,
                              isTop: i == 0,
                              timeLabel: deck[i].dur,
                              playingTrackId: _audio.playingTrackId,
                              isPlaying: _audio.isPlaying,
                              position: _audio.position,
                              duration: _audio.duration,
                              formatMmSs: _formatMmSs,
                              onTogglePreview: i == 0
                                  ? () => _audio.togglePreview(
                                      trackId: deck[i].id,
                                      assetPath: deck[i].audioAsset,
                                    )
                                  : null,
                              onOpenArtist: () async => _openArtistProfile(deck[i]),
                              manualImpulse: i == 0 ? impulse : null,
                              onDragChanged: i == 0
                                  ? (dx) {
                                      if (!mounted) return;
                                      if ((dx - _topDragDx.value).abs() < 3) return;
                                      _topDragDx.value = dx;
                                    }
                                  : null,
                              onDecide: _decide,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ]),
        ),
        // Action buttons
        Positioned(
          left: 0,
          right: 0,
          bottom: nav + 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ValueListenableBuilder<double>(
              valueListenable: _topDragDx,
              builder: (_, dx, __) {
                final norm = (dx.abs() / 120).clamp(0.0, 1.0);
                final skipBtnOpacity = dx > 0 ? (1.0 - norm) : 1.0;
                final likeBtnOpacity = dx < 0 ? (1.0 - norm) : 1.0;
                return Row(children: [
                  Expanded(
                    child: Opacity(
                      opacity: skipBtnOpacity,
                      child: _RoundBtn(
                        height: 52,
                        border: Colors.black.withValues(alpha: 0.10),
                        onTap: () => setState(() => impulse = 'skip'),
                        child: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Opacity(
                      opacity: likeBtnOpacity,
                      child: _RoundBtn(
                        height: 52,
                        fill: widget.accent,
                        border: Colors.transparent,
                        onTap: () => setState(() => impulse = 'like'),
                        child: const Icon(Icons.favorite, size: 22, color: Colors.white),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
        
      ]);
  }

  Offset _introOffsetForDepth(int depth, double t) {
    const starts = <Offset>[
      Offset(0, 46),
      Offset(-58, 16),
      Offset(66, -26),
    ];
    final start = starts[depth.clamp(0, 2)];
    return Offset(start.dx * (1 - t), start.dy * (1 - t));
  }

  double _introScaleForDepth(int depth, double t) {
    const starts = <double>[0.95, 0.92, 0.90];
    final start = starts[depth.clamp(0, 2)];
    return start + ((1.0 - start) * t);
  }

  double _introOpacityForDepth(int depth, double t) {
    final base = depth == 0 ? 0.85 : 0.68;
    return (base + ((1 - base) * t)).clamp(0.0, 1.0);
  }

  Future<void> _openCommentsSheet(Track track) async {
    final userId = _authUserId;
    final controller = TextEditingController();
    List<TrackComment> comments = const [];
    bool loading = true;
    bool posting = false;
    bool requested = false;

    if (mounted) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: NuraBrand.deepest,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> load() async {
                final fetched = await _social.fetchComments(track.id);
                setModalState(() {
                  comments = fetched;
                  loading = false;
                });
              }

              if (loading && !requested) {
                requested = true;
                unawaited(load());
              }

              Future<void> post() async {
                final text = controller.text.trim();
                if (text.isEmpty || userId == null || posting) return;
                setModalState(() => posting = true);
                try {
                  await _social.addComment(
                    trackId: track.id,
                    userId: userId,
                    body: text,
                  );
                  controller.clear();
                  final fetched = await _social.fetchComments(track.id);
                  setModalState(() => comments = fetched);
                  await _refreshTrackEngagement(track.id);
                } finally {
                  setModalState(() => posting = false);
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  left: 16,
                  right: 16,
                  top: 14,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.64,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commenti · ${track.track}',
                        style: const TextStyle(
                          color: NuraBrand.mint,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: loading
                            ? const Center(child: CircularProgressIndicator())
                            : comments.isEmpty
                                ? Center(
                                    child: Text(
                                      'Nessun commento',
                                      style: TextStyle(
                                          color: NuraBrand.mintAlpha(0.55)),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: comments.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: NuraBrand.mintAlpha(0.10),
                                    ),
                                    itemBuilder: (_, i) {
                                      final c = comments[i];
                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          c.authorName ?? 'Utente',
                                          style: const TextStyle(
                                            color: NuraBrand.mint,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          c.body,
                                          style: TextStyle(
                                            color: NuraBrand.mintAlpha(0.8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        style: const TextStyle(color: NuraBrand.mint),
                        enabled: userId != null && !posting,
                        decoration: InputDecoration(
                          hintText: userId == null
                              ? 'Fai login per commentare'
                              : 'Scrivi un commento...',
                          hintStyle: TextStyle(color: NuraBrand.mintAlpha(0.45)),
                          filled: true,
                          fillColor: NuraBrand.deepMidAlpha(0.6),
                          suffixIcon: IconButton(
                            onPressed: (userId == null || posting) ? null : post,
                            icon: Icon(Icons.send, color: widget.accent),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: NuraBrand.mintAlpha(0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: NuraBrand.mintAlpha(0.2)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }
}

class _RoundBtn extends StatelessWidget {
  final double height;
  final Widget child;
  final Color border;
  final Color? fill;
  final VoidCallback onTap;
  const _RoundBtn(
      {required this.height,
      required this.child,
      required this.border,
      this.fill,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            color: fill ?? Colors.white.withValues(alpha: 0.55),
            border: Border.all(color: border),
          ),
          child: child,
        ),
      );
}

class _SocialStatChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _SocialStatChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class SwipeCard extends StatefulWidget {
  final Track track;
  final NuraVibe vibe;
  final Color accent;
  final String waveStyle;
  final int depth;
  final bool isTop;
  final String timeLabel;
  final ValueListenable<String?> playingTrackId;
  final ValueListenable<bool> isPlaying;
  final ValueListenable<Duration> position;
  final ValueListenable<Duration?> duration;
  final String Function(Duration) formatMmSs;
  final VoidCallback? onTogglePreview;
  final VoidCallback? onOpenArtist;
  final String? manualImpulse;
  final ValueChanged<double>? onDragChanged;
  final ValueChanged<String> onDecide;
  const SwipeCard(
      {super.key,
      required this.track,
      required this.vibe,
      required this.accent,
      required this.waveStyle,
      required this.depth,
      required this.isTop,
      required this.timeLabel,
      required this.playingTrackId,
      required this.isPlaying,
      required this.position,
      required this.duration,
      required this.formatMmSs,
      required this.onTogglePreview,
      required this.onOpenArtist,
      required this.manualImpulse,
      required this.onDragChanged,
      required this.onDecide});
  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<Offset> _drag = ValueNotifier(Offset.zero);
  String? exit;

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTop && widget.manualImpulse != null && exit == null) {
      exit = widget.manualImpulse;
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) widget.onDecide(widget.manualImpulse!);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!widget.isTop || exit != null) return;
    final next = _drag.value + d.delta;
    _drag.value = next;
    widget.onDragChanged?.call(next.dx);
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isTop || exit != null) return;
    const threshold = 95.0;
    const flingVelocity = 700.0;
    final drag = _drag.value;
    final vx = details.velocity.pixelsPerSecond.dx;
    if (drag.dx > threshold || vx > flingVelocity) {
      setState(() => exit = 'like');
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) widget.onDecide('like');
      });
    } else if (drag.dx < -threshold || vx < -flingVelocity) {
      setState(() => exit = 'skip');
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) widget.onDecide('skip');
      });
    } else {
      _drag.value = Offset.zero;
      widget.onDragChanged?.call(0);
    }
  }

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stackOffset = widget.depth * 12.0;
    final stackScale = 1 - widget.depth * 0.04;
    return ValueListenableBuilder<Offset>(
      valueListenable: _drag,
      builder: (context, drag, _) {
        final tx = drag.dx;
        final ty = drag.dy;
        final dragRotation = drag.dx / 18 * math.pi / 180;
        final isExiting = exit != null;
        final exitingLike = exit == 'like';
        final exitingSkip = exit == 'skip';
        final slideOffset = exitingLike
            ? const Offset(1.35, 0)
            : exitingSkip
                ? const Offset(-1.35, 0)
                : Offset.zero;
        final targetRotation = exitingLike
            ? (24 * math.pi / 180)
            : exitingSkip
                ? (-24 * math.pi / 180)
                : dragRotation;

        return Padding(
          padding: EdgeInsets.only(top: stackOffset, bottom: stackOffset),
          child: AnimatedSlide(
            offset: slideOffset,
            duration: Duration(milliseconds: isExiting ? 280 : 0),
            curve: Curves.easeOutCubic,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: targetRotation),
              duration: Duration(milliseconds: isExiting ? 280 : 0),
              curve: Curves.easeOutCubic,
              builder: (context, animatedRotation, child) {
                return Transform.rotate(
                  angle: animatedRotation,
                  child: Transform.translate(
                    // Keep current drag offset while exiting to avoid snap-back bounce.
                    offset: Offset(tx, ty),
                    child: child,
                  ),
                );
              },
              child: Transform.scale(
                scale: stackScale,
                child: GestureDetector(
                  behavior: widget.isTop
                      ? HitTestBehavior.translucent
                      : HitTestBehavior.deferToChild,
                  onPanUpdate: widget.isTop ? _onPanUpdate : null,
                  onPanEnd: widget.isTop ? _onPanEnd : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.vibe.radius),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: widget.track.coverAsset != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      widget.track.coverAsset!,
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.low,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.12),
                                            NuraBrand.deepMidAlpha(0.38),
                                            NuraBrand.deepMidAlpha(0.62),
                                          ],
                                          stops: const [0.0, 0.55, 1.0],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          center: Alignment.center,
                                          radius: 1.15,
                                          colors: [
                                            Colors.transparent,
                                            NuraBrand.deepMidAlpha(0.16),
                                          ],
                                          stops: const [0.72, 1.0],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : StripedPanel(
                                  hue: widget.track.hue,
                                  vibe: widget.vibe,
                                ),
                        ),
                        Positioned(
                          top: 14,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Mono(widget.track.genre,
                                  color: NuraBrand.mintAlpha(0.85)),
                              Mono('${widget.track.bpm} BPM',
                                  color: NuraBrand.mintAlpha(0.85)),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 12,
                          right: 12,
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(widget.vibe.radius - 4),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: NuraBrand.deepMidAlpha(0.62),
                                border: Border.all(color: widget.vibe.cardBorder),
                                borderRadius: BorderRadius.circular(
                                  widget.vibe.radius - 4,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: widget.onOpenArtist,
                                              child: Text(
                                                widget.track.artist,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: NuraBrand.mintAlpha(0.65),
                                                  letterSpacing: 0.4,
                                                  decoration:
                                                      widget.onOpenArtist != null
                                                          ? TextDecoration
                                                              .underline
                                                          : TextDecoration.none,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              widget.track.track,
                                              style: const TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.w600,
                                                color: NuraBrand.mint,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: widget.onTogglePreview,
                                        child: AnimatedBuilder(
                                          animation: Listenable.merge([
                                            widget.playingTrackId,
                                            widget.isPlaying,
                                          ]),
                                          builder: (context, _) {
                                            final isCurrentTrack =
                                                widget.playingTrackId.value ==
                                                    widget.track.id;
                                            final showPause = widget.isTop &&
                                                isCurrentTrack &&
                                                widget.isPlaying.value;
                                            return Container(
                                              width: 38,
                                              height: 38,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                              child: Icon(
                                                showPause
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RepaintBoundary(
                                          child: Waveform(
                                            style: widget.waveStyle,
                                            color: NuraBrand.mint,
                                            height: 22,
                                            count: 24,
                                            seed: widget.track.id.codeUnitAt(1),
                                            animate:
                                                widget.isTop && exit == null,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      if (!widget.isTop)
                                        Mono(widget.timeLabel,
                                            color: NuraBrand.mintAlpha(0.55))
                                      else
                                        AnimatedBuilder(
                                          animation: Listenable.merge([
                                            widget.playingTrackId,
                                            widget.position,
                                            widget.duration,
                                          ]),
                                          builder: (context, _) {
                                            final playingId =
                                                widget.playingTrackId.value;
                                            if (playingId != widget.track.id) {
                                              return Mono(widget.timeLabel,
                                                  color:
                                                      NuraBrand.mintAlpha(0.55));
                                            }
                                            return Mono(
                                              '${widget.formatMmSs(widget.position.value)} / ${widget.formatMmSs(widget.duration.value ?? Duration.zero)}',
                                              color: NuraBrand.mintAlpha(0.55),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(8)),
        child: Text(text,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 2.5,
                fontFamily: 'JetBrainsMono',
                fontFamilyFallback: const ['monospace'])),
      );
}
