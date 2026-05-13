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
  const HomeFeed(
      {super.key,
      required this.vibe,
      required this.accent,
      required this.waveform,
      required this.safeTop,
      required this.safeBottom});
  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  late List<Track> deck;
  late List<Track> _sourceDeck;
  final _audio = AudioPreviewService.instance;
  final _remoteTracks = const RemoteTracksService();
  final _social = const SocialEngagementService();
  String? impulse;
  int likes = 12, skips = 38;
  bool _deckReady = false;
  String? _lastAudioErrorShown;
  Map<String, EngagementCounts> _engagementByTrack = const {};
  Set<String> _likedTrackIds = <String>{};
  Set<String> _savedTrackIds = <String>{};
  String? _authUserId;

  @override
  void initState() {
    super.initState();
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

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArtistPublicProfileScreen(
          artistId: artistId,
          artistName: track.artist,
        ),
      ),
    );
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
    final isSavedTop = _savedTrackIds.contains(topTrack.id);
    return Stack(children: [
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
                    color: NuraBrand.mint,
                    letterSpacing: 0.4)),
            const Spacer(),
            Mono('♥ $likes', color: NuraBrand.mint),
            const SizedBox(width: 8),
            Mono('↳ $skips', color: NuraBrand.mintAlpha(0.45)),
          ]),
        ),
        // Card stack
        Positioned(
          top: widget.safeTop + 50,
          left: 16,
          right: 16,
          bottom: nav + 100,
          child: Stack(children: [
            for (int i = math.min(2, deck.length - 1); i >= 0; i--)
              SwipeCard(
                key: ValueKey('${deck[i].id}-${deck.length}-$i'),
                track: deck[i],
                vibe: widget.vibe,
                accent: widget.accent,
                waveStyle: widget.waveform,
                depth: i,
                isTop: i == 0,
                timeLabel: deck[i].dur,
                playingTrackId: _audio.playingTrackId,
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
                onDecide: _decide,
              ),
          ]),
        ),
        // Action buttons
        Positioned(
          left: 0,
          right: 0,
          bottom: nav + 16,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _RoundBtn(
                size: 54,
                border: widget.vibe.cardBorder,
                onTap: () => setState(() => impulse = 'skip'),
                child:
                    const Icon(Icons.close, size: 22, color: NuraBrand.mint)),
            const SizedBox(width: 22),
            GestureDetector(
              onTap: () => setState(() => impulse = 'like'),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accent,
                  boxShadow: [
                    BoxShadow(
                        color: widget.accent.withOpacity(0.4),
                        blurRadius: 36,
                        offset: const Offset(0, 12))
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child:
                    const Icon(Icons.favorite, size: 26, color: Colors.white),
              ),
            ),
            const SizedBox(width: 22),
            _RoundBtn(
                size: 54,
                border: widget.vibe.cardBorder,
                onTap: () => _openCommentsSheet(topTrack),
                child: const Icon(Icons.chat_bubble_outline,
                    size: 19, color: NuraBrand.mint)),
            const SizedBox(width: 12),
            _RoundBtn(
                size: 54,
                border: widget.vibe.cardBorder,
                onTap: _toggleSaveTopTrack,
                child: Icon(
                    isSavedTop ? Icons.bookmark : Icons.bookmark_outline,
                    size: 20,
                    color: isSavedTop ? widget.accent : NuraBrand.mint)),
          ]),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: nav + 86,
          child: IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialStatChip(
                  icon: Icons.favorite,
                  value: topStats.likes,
                  color: NuraBrand.mintAlpha(0.9),
                ),
                const SizedBox(width: 10),
                _SocialStatChip(
                  icon: Icons.chat_bubble_outline,
                  value: topStats.comments,
                  color: NuraBrand.mintAlpha(0.85),
                ),
                const SizedBox(width: 10),
                _SocialStatChip(
                  icon: Icons.bookmark_outline,
                  value: topStats.saves,
                  color: NuraBrand.mintAlpha(0.85),
                ),
              ],
            ),
          ),
        ),
      ]);
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
  final double size;
  final Widget child;
  final Color border;
  final VoidCallback onTap;
  const _RoundBtn(
      {required this.size,
      required this.child,
      required this.border,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: NuraBrand.deepMidAlpha(0.7),
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
        color: NuraBrand.deepMidAlpha(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NuraBrand.mintAlpha(0.16)),
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
  final ValueListenable<Duration> position;
  final ValueListenable<Duration?> duration;
  final String Function(Duration) formatMmSs;
  final VoidCallback? onTogglePreview;
  final VoidCallback? onOpenArtist;
  final String? manualImpulse;
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
      required this.position,
      required this.duration,
      required this.formatMmSs,
      required this.onTogglePreview,
      required this.onOpenArtist,
      required this.manualImpulse,
      required this.onDecide});
  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  Offset drag = Offset.zero;
  String? exit;
  int _lastPanTickUs = 0;

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
    final nowUs = DateTime.now().microsecondsSinceEpoch;
    if (nowUs - _lastPanTickUs < 16000) return;
    _lastPanTickUs = nowUs;
    setState(() => drag += d.delta);
  }

  void _onPanEnd(DragEndDetails _) {
    if (!widget.isTop || exit != null) return;
    const threshold = 90.0;
    if (drag.dx > threshold) {
      setState(() => exit = 'like');
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) widget.onDecide('like');
      });
    } else if (drag.dx < -threshold) {
      setState(() => exit = 'skip');
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) widget.onDecide('skip');
      });
    } else {
      setState(() => drag = Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    double tx = drag.dx, ty = drag.dy, rotation = drag.dx / 18 * math.pi / 180;
    if (exit == 'like') {
      tx = 600;
      rotation = 24 * math.pi / 180;
    }
    if (exit == 'skip') {
      tx = -600;
      rotation = -24 * math.pi / 180;
    }

    final stackOffset = widget.depth * 12.0;
    final stackScale = 1 - widget.depth * 0.04;
    final likeOpacity = (drag.dx / 110).clamp(0.0, 1.0);
    final skipOpacity = (-drag.dx / 110).clamp(0.0, 1.0);

    return AnimatedPositioned(
      duration:
          Duration(milliseconds: exit != null || drag == Offset.zero ? 280 : 0),
      curve: Curves.easeOut,
      left: tx,
      right: -tx,
      top: ty + stackOffset,
      bottom: -ty - stackOffset,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: stackScale,
          child: GestureDetector(
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.vibe.radius),
              child: Stack(children: [
                Positioned.fill(
                  child: widget.track.coverAsset != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            // Lower filter quality keeps swipe smooth on real devices.
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
                                    Colors.black.withOpacity(0.20),
                                    Colors.black.withOpacity(0.45),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : StripedPanel(hue: widget.track.hue, vibe: widget.vibe),
                ),
                // Top meta
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
                      ]),
                ),
                // LIKE / SKIP badges
                Positioned(
                    top: 28,
                    left: 22,
                    child: Opacity(
                        opacity: likeOpacity,
                        child: Transform.rotate(
                            angle: -12 * math.pi / 180,
                            child:
                                _Badge(text: 'LIKE', color: widget.accent)))),
                Positioned(
                    top: 28,
                    right: 22,
                    child: Opacity(
                        opacity: skipOpacity,
                        child: Transform.rotate(
                            angle: 12 * math.pi / 180,
                            child: const _Badge(
                                text: 'SKIP', color: NuraBrand.mint)))),
                // Bottom overlay
                Positioned(
                  bottom: 16,
                  left: 12,
                  right: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.vibe.radius - 4),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: NuraBrand.deepMidAlpha(0.62),
                        border: Border.all(color: widget.vibe.cardBorder),
                        borderRadius:
                            BorderRadius.circular(widget.vibe.radius - 4),
                      ),
                      child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(children: [
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
                                            decoration: widget.onOpenArtist != null
                                                ? TextDecoration.underline
                                                : TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(widget.track.track,
                                          style: const TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w600,
                                              color: NuraBrand.mint)),
                                    ])),
                                GestureDetector(
                                  onTap: widget.onTogglePreview,
                                  child: ValueListenableBuilder<String?>(
                                    valueListenable: widget.playingTrackId,
                                    builder: (context, playingId, _) {
                                      final isPlaying = widget.isTop && playingId == widget.track.id;
                                      return Container(
                                        width: 38,
                                        height: 38,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: NuraBrand.mint,
                                        ),
                                        child: Icon(
                                          isPlaying ? Icons.pause : Icons.play_arrow,
                                          color: NuraBrand.deep,
                                          size: 18,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                Expanded(
                                    child: RepaintBoundary(
                                      child: Waveform(
                                        style: widget.waveStyle,
                                        color: NuraBrand.mint,
                                        height: 22,
                                        count: 24,
                                        seed: widget.track.id.codeUnitAt(1),
                                        animate:
                                            widget.isTop && drag == Offset.zero && exit == null,
                                      ),
                                    )),
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
                                      final playingId = widget.playingTrackId.value;
                                      if (playingId != widget.track.id) {
                                        return Mono(widget.timeLabel,
                                            color: NuraBrand.mintAlpha(0.55));
                                      }
                                      return Mono(
                                        '${widget.formatMmSs(widget.position.value)} / ${widget.formatMmSs(widget.duration.value ?? Duration.zero)}',
                                        color: NuraBrand.mintAlpha(0.55),
                                      );
                                    },
                                  ),
                              ]),
                            ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
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
