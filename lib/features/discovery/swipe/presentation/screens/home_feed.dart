import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/models/track.dart';
import '../../../../../core/services/music_player_manager.dart';
import '../../../../../core/widgets/mono.dart';
import '../../../../../core/widgets/nura_mark.dart';
import '../../../../social/data/social_engagement_service.dart';
import '../../../../shared/data/mock_nura_data.dart';
import '../../data/remote_tracks_service.dart';
import '../widgets/music_card.dart';
import '../widgets/physics_swiper.dart';
import 'artist_public_profile_screen.dart';

class HomeFeed extends StatefulWidget {
  final NuraVibe vibe;
  final Color accent;
  final String waveform;
  final double safeTop, safeBottom;
  final bool isActive;
  final void Function(String artistId, String artistName)? onArtistTap;
  const HomeFeed(
      {super.key,
      required this.vibe,
      required this.accent,
      required this.waveform,
      required this.safeTop,
      required this.safeBottom,
      this.isActive = true,
      this.onArtistTap});
  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class HeavyComputations {
  static final Map<String, Color> _colorCache = {};

  static Color? getCachedColor(String assetPath) => _colorCache[assetPath];

  static Future<Color> extractDominantColorSafe(String assetPath) async {
    if (_colorCache.containsKey(assetPath)) return _colorCache[assetPath]!;
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 12,
        targetHeight: 12,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      final palette = await PaletteGenerator.fromImage(
        frameInfo.image,
        maximumColorCount: 4,
      );

      final bestColor = palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          const Color(0xFF1E1E1E);

      _colorCache[assetPath] = bestColor;
      return bestColor;
    } catch (e) {
      debugPrint("Errore PaletteGenerator: $e");
      _colorCache[assetPath] = const Color(0xFF1E1E1E);
      return const Color(0xFF1E1E1E);
    }
  }
}

class _HomeFeedState extends State<HomeFeed>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late List<Track> deck;
  late List<Track> _sourceDeck;
  final _musicManager = MusicPlayerManager();
  final _remoteTracks = const RemoteTracksService();
  final _social = const SocialEngagementService();
  String? impulse;
  int likes = 12, skips = 38;
  bool _deckReady = false;
  final ValueNotifier<double> _topDragDx = ValueNotifier<double>(0);
  Map<String, EngagementCounts> _engagementByTrack = const {};
  Set<String> _likedTrackIds = <String>{};
  String? _authUserId;
  late final AnimationController _deckIntroController;
  bool _deckIntroPlayed = false;

  final Map<String, Color> _ambientGlowCache = {};
  final Map<String, GlobalKey> _cardKeys = {};

  /// Tracciamento monotono dei request ID per annullare Future orfani.
  /// Quando una carta viene espulsa, il suo ID viene rimosso → il Future
  /// in corso scarta il risultato e non chiama setState su un widget smontato.
  final Map<String, int> _glowRequestIds = {};

  GlobalKey _getCardKey(String id) {
    return _cardKeys.putIfAbsent(id, () => GlobalKey());
  }

  Future<void> _resolveGlow(Track track) async {
    if (_ambientGlowCache.containsKey(track.id)) return;

    // Genera un request ID univoco per questa estrazione.
    final requestId = (_glowRequestIds[track.id] ?? 0) + 1;
    _glowRequestIds[track.id] = requestId;

    if (track.coverAsset != null && track.coverAsset!.startsWith('assets/')) {
      try {
        final extractedColor =
            await HeavyComputations.extractDominantColorSafe(track.coverAsset!);
        // ANNULLAMENTO IMPLICITO: se il requestId è cambiato, questa
        // estrazione è obsoleta (la carta è stata espulsa). Scarta.
        if (!mounted || _glowRequestIds[track.id] != requestId) return;
        setState(() {
          _ambientGlowCache[track.id] = extractedColor;
        });
      } catch (e) {
        if (!mounted || _glowRequestIds[track.id] != requestId) return;
        setState(() {
          _ambientGlowCache[track.id] = track.swatch;
        });
      }
    } else {
      if (!mounted) return;
      setState(() {
        _ambientGlowCache[track.id] = track.swatch;
      });
    }
  }

  void _maintainRollingCache() {
    if (!mounted) return;

    for (int i = 0; i < math.min(4, deck.length); i++) {
      final t = deck[i];
      unawaited(_resolveGlow(t));

      final cover = t.coverAsset;
      if (cover != null && cover.startsWith('assets/')) {
        try {
          final targetWidth = (MediaQuery.of(context).size.width *
                  MediaQuery.of(context).devicePixelRatio)
              .toInt();
          unawaited(precacheImage(
              ResizeImage(AssetImage(cover), width: targetWidth), context));
        } catch (_) {}
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deckIntroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sourceDeck = List.of(kTracks);

    final cached = RemoteTracksService.cachedTracks;
    if (cached != null && cached.isNotEmpty) {
      deck = List.of(cached);
      _sourceDeck = List.of(cached);
      _deckReady = true;
      final firstCover = deck[0].coverAsset;
      if (firstCover != null) {
        final cachedColor = HeavyComputations.getCachedColor(firstCover);
        if (cachedColor != null) {
          _ambientGlowCache[deck[0].id] = cachedColor;
        } else {
          _ambientGlowCache[deck[0].id] = deck[0].swatch;
        }
      } else {
        _ambientGlowCache[deck[0].id] = deck[0].swatch;
      }
      // Trigger the intro animation instantly
      _deckIntroController.forward(from: 0.0);
      _deckIntroPlayed = true;
    } else {
      deck = const [];
      _deckReady = false;
    }

    _loadDeckFromCloud();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _musicManager.pause();
    } else if (state == AppLifecycleState.resumed) {
      _musicManager.resume();
    }
  }

  Future<void> _loadDeckFromCloud() async {
    if (!_deckReady) {
      setState(() {
        _deckReady = false;
      });
    }

    List<Track> selected = List.of(kTracks);
    try {
      final remote =
          await _remoteTracks.fetchTracks().timeout(const Duration(seconds: 5));
      if (remote.isNotEmpty) {
        selected = List.of(remote);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Nessuna traccia remota valida. Uso mock locali.',
              ),
            ),
          );
        }
      }
    } catch (_) {}

    if (!mounted) return;

    // FIX V: Sincronizzazione Rigida della VRAM.
    // Blocchiamo il rendering del deck finché la primissima copertina non è
    // fisicamente decodificata e presente nella memoria video (pre-cached).
    // Questo elimina il pop-in di 0.5 sec allo start.
    if (selected.isNotEmpty) {
      // Estraiamo il colore dominante dello shader prima di svelare la UI
      await _resolveGlow(selected[0]);
      if (!mounted) return;

      final cover = selected[0].coverAsset;
      if (cover != null && cover.startsWith('assets/')) {
        try {
          final targetWidth = (MediaQuery.of(context).size.width *
                  MediaQuery.of(context).devicePixelRatio)
              .toInt();
          await precacheImage(
              ResizeImage(AssetImage(cover), width: targetWidth), context);
        } catch (_) {}
      }
    }

    if (!mounted) return;

    setState(() {
      _sourceDeck = selected;
      deck = List.of(selected);
      _deckReady = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maintainRollingCache();
    });

    if (!_deckIntroPlayed) {
      _deckIntroPlayed = true;
      _deckIntroController
        ..value = 0
        ..forward();
    }

    unawaited(_loadEngagement(selected));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (deck.isNotEmpty) {
        _musicManager.initFirstTrack(deck[0].audioAsset ?? '');
        if (deck.length > 1) {
          _musicManager.preloadNext(deck[1].audioAsset ?? '');
        }
      }
    });
  }

  Future<void> _loadEngagement(List<Track> tracks) async {
    try {
      final trackIds = tracks.map((t) => t.id).toList(growable: false);
      final counts = await _social.fetchCountsForTrackIds(trackIds);

      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id;
      Set<String> liked = <String>{};
      if (userId != null) {
        liked = await _social.fetchUserLikedTrackIds(userId, trackIds);
      }

      if (!mounted) return;
      setState(() {
        _engagementByTrack = counts;
        _likedTrackIds = liked;
        _authUserId = userId;
      });
    } catch (_) {}
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
    if (deck.isEmpty) return;
    final decidedTrack = deck.first;
    final userId = _authUserId;

    // ANNULLAMENTO FUTURE ORFANI: invalida i requestId della carta espulsa.
    // Se l'estrazione PaletteGenerator è ancora in corso, il Future
    // scarterà il risultato grazie al controllo requestId != currentId.
    _glowRequestIds.remove(decidedTrack.id);

    final fallbackUrl = deck.length > 1 ? (deck[1].audioAsset ?? '') : '';
    _musicManager.swipeCrossfadeTransition(fallbackUrl);

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

    _maintainRollingCache();

    if (deck.length > 1) {
      _musicManager.preloadNext(deck[1].audioAsset ?? '');
    }

    if (action == 'like' && userId != null) {
      unawaited(_social.setLike(
        trackId: decidedTrack.id,
        userId: userId,
        shouldLike: true,
      ));
      unawaited(_refreshTrackEngagement(decidedTrack.id));
    }
  }

  Timer? _lifecycleDebouncer;

  @override
  void didUpdateWidget(HomeFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      _lifecycleDebouncer?.cancel();
      _lifecycleDebouncer = Timer(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        if (widget.isActive) {
          if (deck.isNotEmpty) {
            _musicManager.initFirstTrack(deck[0].audioAsset ?? '');
          }
        } else {
          _musicManager.pause();
        }
      });
    }
  }

  @override
  void dispose() {
    _lifecycleDebouncer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _deckIntroController.dispose();
    _musicManager.dispose();
    _topDragDx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = 86 + widget.safeBottom;
    if (!_deckReady) {
      return const SizedBox.shrink();
    }

    if (deck.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_off_rounded,
                size: 48, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'Nessun brano trovato',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDeckFromCloud,
              style: ElevatedButton.styleFrom(
                backgroundColor: NuraBrand.pink,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child:
                  const Text('Ricarica', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    return SizedBox.expand(
        child: Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: ParallaxOrganicMeshPainter(
                scrollOffset: 0,
                musicuraBlu: NuraBrand.deep,
                nuraPink: NuraBrand.pink,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(18, widget.safeTop, 18, 8),
          child: SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(Icons.favorite, size: 14, color: Color(0xFFE53935)),
                const SizedBox(width: 4),
                Mono('$likes', color: const Color(0xFF1A1A1A)),
                const SizedBox(width: 12),
                const Icon(Icons.turn_left, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Mono('$skips', color: Colors.black45),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final requiredHeight =
                  constraints.maxHeight - widget.safeTop - nav;
              final verticalPadding = requiredHeight < 500 ? 56.0 : 76.0;
              final bottomPadding =
                  requiredHeight < 500 ? nav + 20.0 : nav + 100.0;

              return Padding(
                padding: EdgeInsets.only(
                  top: widget.safeTop + verticalPadding,
                  bottom: bottomPadding,
                  left: 16,
                  right: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: Stack(
                    children: [
                      // CULLING N+2: Renderizza fino a 3 carte per assorbire
                      // il cold-start VRAM della terza carta durante swipe
                      // ad alta velocità (escape velocity > 1000px/s).
                      for (int i = math.min(2, deck.length - 1); i >= 0; i--)
                        if (i == 2)
                          // Terza carta: pre-inizializzata in VRAM, nascosta sotto.
                          // Non ha animazione di scala per risparmiare GPU.
                          Offstage(
                            offstage: false,
                            child: Transform.scale(
                              scale: 0.85,
                              child: MusicCard(
                                key: _getCardKey(deck[i].id),
                                track: deck[i],
                                isTopCard: false,
                                ambientGlow: _ambientGlowCache[deck[i].id] ??
                                    Colors.transparent,
                                onArtistTap: null,
                              ),
                            ),
                          )
                        else if (i == 1)
                          ValueListenableBuilder<double>(
                            valueListenable: _topDragDx,
                            builder: (context, dx, child) {
                              final progress = (dx.abs() /
                                      (MediaQuery.of(context).size.width / 2))
                                  .clamp(0.0, 1.0);
                              final scale = 0.90 + (0.10 * progress);
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - progress)),
                                child: Transform.scale(
                                  scale: scale,
                                  child: MusicCard(
                                    key: _getCardKey(deck[i].id),
                                    track: deck[i],
                                    isTopCard: false,
                                    ambientGlow:
                                        _ambientGlowCache[deck[i].id] ??
                                            Colors.transparent,
                                    onArtistTap: () {
                                      _musicManager.pause();
                                      if (widget.onArtistTap != null) {
                                        widget.onArtistTap!(
                                            deck[i].artistId ??
                                                'mock_artist_${deck[i].id}',
                                            deck[i].artist);
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          )
                        else if (i == 0)
                          PhysicsSwiper(
                            key: ValueKey(deck[i].id),
                            impulse: impulse,
                            onSwipe: (dir) => _decide(
                                dir == SwipeDirection.right ? 'like' : 'skip'),
                            onDragUpdate: (dx) => _topDragDx.value = dx,
                            child: ValueListenableBuilder<double>(
                              valueListenable: _topDragDx,
                              builder: (context, dx, child) {
                                return MusicCard(
                                  key: _getCardKey(deck[i].id),
                                  track: deck[i],
                                  isTopCard: true,
                                  isDragging: dx.abs() > 0.0,
                                  ambientGlow: _ambientGlowCache[deck[i].id] ??
                                      Colors.transparent,
                                  onArtistTap: () {
                                    _musicManager.pause();
                                    if (widget.onArtistTap != null) {
                                      widget.onArtistTap!(
                                          deck[i].artistId ??
                                              'mock_artist_${deck[i].id}',
                                          deck[i].artist);
                                    }
                                  },
                                );
                              },
                            ),
                          )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
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
                final skipBtnOpacity =
                    dx > 0 ? (1.0 - norm).clamp(0.0, 1.0) : 1.0;
                final likeBtnOpacity =
                    dx < 0 ? (1.0 - norm).clamp(0.0, 1.0) : 1.0;
                return Row(children: [
                  Expanded(
                    child: _RoundBtn(
                      height: 52,
                      fill:
                          Colors.white.withValues(alpha: 0.55 * skipBtnOpacity),
                      border:
                          Colors.black.withValues(alpha: 0.10 * skipBtnOpacity),
                      onTap: () => setState(() => impulse =
                          'skip_${DateTime.now().millisecondsSinceEpoch}'),
                      child: Icon(Icons.close_rounded,
                          size: 22,
                          color: const Color(0xFF1A1A1A)
                              .withValues(alpha: skipBtnOpacity)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RoundBtn(
                      height: 52,
                      fill: widget.accent.withValues(alpha: likeBtnOpacity),
                      border: Colors.transparent,
                      onTap: () => setState(() => impulse =
                          'like_${DateTime.now().millisecondsSinceEpoch}'),
                      child: Icon(Icons.favorite,
                          size: 22,
                          color:
                              Colors.white.withValues(alpha: likeBtnOpacity)),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      ],
    ));
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

              return DraggableScrollableSheet(
                initialChildSize: 0.64,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                expand: false,
                builder: (_, scrollController) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, top: 14),
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
                                      controller: scrollController,
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
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom +
                                  12),
                          child: TextField(
                            controller: controller,
                            style: const TextStyle(color: NuraBrand.mint),
                            enabled: userId != null && !posting,
                            decoration: InputDecoration(
                              hintText: userId == null
                                  ? 'Fai login per commentare'
                                  : 'Scrivi un commento...',
                              hintStyle:
                                  TextStyle(color: NuraBrand.mintAlpha(0.45)),
                              filled: true,
                              fillColor: NuraBrand.deepMidAlpha(0.6),
                              suffixIcon: IconButton(
                                onPressed:
                                    (userId == null || posting) ? null : post,
                                icon: Icon(Icons.send, color: widget.accent),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: NuraBrand.mintAlpha(0.2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: NuraBrand.mintAlpha(0.2)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
