import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/services/audio_preview_service.dart';
import '../../../../../core/services/supabase_bootstrap.dart';
import '../../../../../core/widgets/mono.dart';
import '../../../../social/data/social_engagement_service.dart';

class ArtistPublicProfileScreen extends StatefulWidget {
  final String artistId;
  final String artistName;

  const ArtistPublicProfileScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistPublicProfileScreen> createState() =>
      _ArtistPublicProfileScreenState();
}

class _ArtistPublicProfileScreenState extends State<ArtistPublicProfileScreen> {
  final _audio = AudioPreviewService.instance;
  final _social = const SocialEngagementService();
  String? _lastAudioErrorShown;

  bool _loading = true;
  bool _following = false;
  bool _playerExpanded = false;
  bool _showMiniPlayer = false;
  int? _currentTrackIndex;
  String? _displayName;
  String? _imageAsset;
  String? _bio;
  List<Map<String, dynamic>> _tracks = const [];

  Map<String, EngagementCounts> _engagementByTrack = const {};
  Map<String, List<TrackComment>> _commentsPreviewByTrack = const {};
  Set<String> _likedTrackIds = <String>{};
  Set<String> _savedTrackIds = <String>{};
  String? _authUserId;

  @override
  void initState() {
    super.initState();
    _audio.lastError.addListener(_onAudioError);
    _load();
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

  @override
  void dispose() {
    _audio.lastError.removeListener(_onAudioError);
    super.dispose();
  }

  Future<void> _load() async {
    if (!SupabaseBootstrap.isInitialized) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      final profile = await client
          .from('profiles')
          .select('display_name,image_asset,bio')
          .eq('id', widget.artistId)
          .maybeSingle();

      final rows = await client
          .from('tracks')
          .select('id,title,genre,duration_seconds,storage_path,created_at')
          .eq('artist_id', widget.artistId)
          .order('created_at', ascending: false);

      final tracks = rows.whereType<Map<String, dynamic>>().toList(growable: false);
      final trackIds = tracks.map((t) => t['id'] as String?).whereType<String>().toList();
      final counts = await _social.fetchCountsForTrackIds(trackIds);

      Map<String, List<TrackComment>> preview = {};
      for (final id in trackIds) {
        preview[id] = await _social.fetchComments(id, limit: 2);
      }

      Set<String> liked = <String>{};
      Set<String> saved = <String>{};
      if (user != null) {
        liked = await _social.fetchUserLikedTrackIds(user.id, trackIds);
        saved = await _social.fetchUserSavedTrackIds(user.id, trackIds);
      }

      if (!mounted) return;
      setState(() {
        _displayName = profile?['display_name'] as String?;
        _imageAsset = profile?['image_asset'] as String?;
        _bio = profile?['bio'] as String?;
        _tracks = tracks;
        _engagementByTrack = counts;
        _commentsPreviewByTrack = preview;
        _likedTrackIds = liked;
        _savedTrackIds = saved;
        _authUserId = user?.id;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _durationLabel(int? seconds) {
    final s = seconds ?? 0;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  String? _assetFromStoragePath(String? storagePath) {
    if (storagePath == null || storagePath.isEmpty) return null;
    final fileName = storagePath.split('/').last;
    if (!fileName.toLowerCase().endsWith('.mp3')) return null;
    return 'assets/audio/$fileName';
  }

  Future<void> _refreshTrackData(String trackId) async {
    final map = await _social.fetchCountsForTrackIds([trackId]);
    final comments = await _social.fetchComments(trackId, limit: 2);
    if (!mounted) return;
    setState(() {
      _engagementByTrack = {..._engagementByTrack, ...map};
      _commentsPreviewByTrack = {
        ..._commentsPreviewByTrack,
        trackId: comments,
      };
    });
  }

  Future<void> _toggleLike(String trackId) async {
    final userId = _authUserId;
    if (userId == null) return _showLoginRequired();
    final wasLiked = _likedTrackIds.contains(trackId);

    setState(() {
      if (wasLiked) {
        _likedTrackIds.remove(trackId);
      } else {
        _likedTrackIds.add(trackId);
      }
    });

    try {
      await _social.setLike(trackId: trackId, userId: userId, shouldLike: !wasLiked);
      await _refreshTrackData(trackId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasLiked) {
          _likedTrackIds.add(trackId);
        } else {
          _likedTrackIds.remove(trackId);
        }
      });
    }
  }

  Future<void> _toggleSave(String trackId) async {
    final userId = _authUserId;
    if (userId == null) return _showLoginRequired();
    final wasSaved = _savedTrackIds.contains(trackId);

    setState(() {
      if (wasSaved) {
        _savedTrackIds.remove(trackId);
      } else {
        _savedTrackIds.add(trackId);
      }
    });

    try {
      await _social.setSave(trackId: trackId, userId: userId, shouldSave: !wasSaved);
      await _refreshTrackData(trackId);
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

  Future<void> _openCommentsSheet(Map<String, dynamic> row) async {
    final trackId = row['id'] as String?;
    if (trackId == null) return;

    final userId = _authUserId;
    final controller = TextEditingController();
    List<TrackComment> comments = const [];
    bool loading = true;
    bool posting = false;
    bool requested = false;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NuraBrand.deepest,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> load() async {
              final fetched = await _social.fetchComments(trackId);
              setModalState(() {
                comments = fetched;
                loading = false;
              });
            }

            if (loading && !requested) {
              requested = true;
              load();
            }

            Future<void> post() async {
              final text = controller.text.trim();
              if (text.isEmpty || userId == null || posting) return;
              setModalState(() => posting = true);
              try {
                await _social.addComment(trackId: trackId, userId: userId, body: text);
                controller.clear();
                comments = await _social.fetchComments(trackId);
                setModalState(() {});
                await _refreshTrackData(trackId);
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
                height: MediaQuery.of(context).size.height * 0.62,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commenti · ${row['title'] ?? 'Brano'}',
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
                                    style: TextStyle(color: NuraBrand.mintAlpha(0.55)),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: comments.length,
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
                    TextField(
                      controller: controller,
                      enabled: userId != null && !posting,
                      style: const TextStyle(color: NuraBrand.mint),
                      decoration: InputDecoration(
                        hintText: userId == null
                            ? 'Fai login per commentare'
                            : 'Scrivi un commento...',
                        hintStyle: TextStyle(color: NuraBrand.mintAlpha(0.45)),
                        filled: true,
                        fillColor: NuraBrand.deepMidAlpha(0.6),
                        suffixIcon: IconButton(
                          onPressed: (userId == null || posting) ? null : post,
                          icon: const Icon(Icons.send, color: NuraBrand.mint),
                        ),
                        border: OutlineInputBorder(
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

  void _showLoginRequired() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login richiesto per like/save/commenti')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const vibe = NuraVibe.premium;
    final artistName = _displayName ?? widget.artistName;

    return Scaffold(
      backgroundColor: NuraBrand.deep,
      bottomNavigationBar: _miniPlayer(vibe),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: NuraBrand.deep,
                  foregroundColor: NuraBrand.mint,
                  pinned: true,
                  expandedHeight: 260,
                  title: Text(artistName),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        _imageAsset != null
                            ? Image.asset(
                                _imageAsset!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _fallbackBg(),
                              )
                            : _fallbackBg(),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.08),
                                NuraBrand.deep.withOpacity(0.88),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _statPill('Tracce', '${_tracks.length}'),
                            const SizedBox(width: 8),
                            _statPill('Seguiti', _following ? '1' : '0'),
                            const SizedBox(width: 8),
                            _statPill('Vibe', 'Top 12%'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() => _following = !_following);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: vibe.cardBorder),
                                  foregroundColor: NuraBrand.mint,
                                ),
                                icon: Icon(
                                  _following ? Icons.check : Icons.add,
                                  size: 16,
                                ),
                                label: Text(_following ? 'Seguito' : 'Segui'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _bio?.isNotEmpty == true
                              ? _bio!
                              : 'Artista emergente su Nura.',
                          style: TextStyle(
                            color: NuraBrand.mintAlpha(0.8),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) => _trackPostCard(_tracks[index]),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: _tracks.length,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _fallbackBg() => Container(
        color: NuraBrand.deepMid,
        alignment: Alignment.center,
        child: const Icon(Icons.music_note, color: NuraBrand.mint, size: 44),
      );

  Widget _statPill(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: NuraBrand.deepMidAlpha(0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: NuraBrand.mintAlpha(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Mono('$label ', color: NuraBrand.mintAlpha(0.6), size: 9),
            Text(
              value,
              style: const TextStyle(
                color: NuraBrand.mint,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Widget _trackPostCard(Map<String, dynamic> row) {
    final id = row['id'] as String? ?? 'unknown-track';
    final title = row['title'] as String? ?? 'Untitled';
    final genre = row['genre'] as String? ?? 'demo';
    final duration = row['duration_seconds'] as int?;
    final stats = _engagementByTrack[id] ?? const EngagementCounts();
    final isLiked = _likedTrackIds.contains(id);
    final isSaved = _savedTrackIds.contains(id);
    final commentsPreview = _commentsPreviewByTrack[id] ?? const <TrackComment>[];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: NuraBrand.deepMidAlpha(0.55),
        border: Border.all(color: NuraBrand.mintAlpha(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [NuraBrand.mintAlpha(0.35), NuraBrand.deep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.graphic_eq, color: NuraBrand.mint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: NuraBrand.mint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$genre · ${_durationLabel(duration)}',
                      style: TextStyle(
                        color: NuraBrand.mintAlpha(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: Listenable.merge([_audio.playingTrackId, _audio.isPlaying]),
                builder: (context, _) {
                  final isCurrentTrack = _audio.playingTrackId.value == id;
                  final showPause = isCurrentTrack && _audio.isPlaying.value;
                  return IconButton(
                    onPressed: () => _playTrackById(id),
                    icon: Icon(
                      showPause ? Icons.pause_circle : Icons.play_circle,
                      color: NuraBrand.mint,
                      size: 30,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleLike(id),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? NuraBrand.mint : NuraBrand.mintAlpha(0.85),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _openCommentsSheet(row),
                child: Icon(Icons.chat_bubble_outline,
                    color: NuraBrand.mintAlpha(0.85), size: 20),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _toggleSave(id),
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  color: isSaved ? NuraBrand.mint : NuraBrand.mintAlpha(0.85),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EngagementChip(
                icon: Icons.favorite,
                value: stats.likes,
                color: NuraBrand.mintAlpha(0.92),
              ),
              _EngagementChip(
                icon: Icons.chat_bubble_outline,
                value: stats.comments,
                color: NuraBrand.mintAlpha(0.88),
              ),
              _EngagementChip(
                icon: Icons.bookmark_outline,
                value: stats.saves,
                color: NuraBrand.mintAlpha(0.88),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final c in commentsPreview)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: NuraBrand.mintAlpha(0.8), fontSize: 11),
                  children: [
                    TextSpan(
                      text: 'Commento · ${c.authorName ?? 'utente'}: ',
                      style: const TextStyle(
                        color: NuraBrand.mint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: c.body),
                  ],
                ),
              ),
            ),
          GestureDetector(
            onTap: () => _openCommentsSheet(row),
            child: Text(
              stats.comments > commentsPreview.length
                  ? 'Vedi tutti i commenti (${stats.comments})'
                  : 'Apri commenti',
              style: TextStyle(
                color: NuraBrand.mintAlpha(0.55),
                fontSize: 11,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playTrackById(String trackId) async {
    final index = _tracks.indexWhere((t) => (t['id'] as String?) == trackId);
    if (index < 0) return;
    final row = _tracks[index];
    final localAsset = _assetFromStoragePath(row['storage_path'] as String?);
    if (localAsset == null) return;

    final isSameTrack = _audio.playingTrackId.value == trackId;
    if (isSameTrack && _audio.isPlaying.value) {
      await _audio.pause();
    } else if (isSameTrack && !_audio.isPlaying.value) {
      await _audio.resume();
    } else {
      await _audio.playTrack(trackId: trackId, assetPath: localAsset);
      if (!mounted) return;
      setState(() {
        _showMiniPlayer = true;
        _currentTrackIndex = index;
      });
    }
  }

  Future<void> _playAtIndex(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    final row = _tracks[index];
    final id = row['id'] as String? ?? '';
    if (id.isEmpty) return;
    final localAsset = _assetFromStoragePath(row['storage_path'] as String?);
    if (localAsset == null) return;
    await _audio.playTrack(trackId: id, assetPath: localAsset);
    if (!mounted) return;
    setState(() {
      _showMiniPlayer = true;
      _currentTrackIndex = index;
    });
  }

  Widget _miniPlayer(NuraVibe vibe) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_audio.playingTrackId, _audio.isPlaying, _audio.position, _audio.duration]),
      builder: (context, _) {
        final activeTrackId = _audio.playingTrackId.value;
        final playingIndex =
            _tracks.indexWhere((t) => (t['id'] as String?) == activeTrackId);
        final index = _currentTrackIndex ?? (playingIndex >= 0 ? playingIndex : -1);

        final shouldShow = _showMiniPlayer || playingIndex >= 0;
        final hidden =
            !shouldShow || _tracks.isEmpty || index < 0 || index >= _tracks.length;
        if (hidden) {
          return const SizedBox.shrink();
        }

        final row = _tracks[index];
        final title = row['title'] as String? ?? 'Untitled';
        final genre = row['genre'] as String? ?? 'demo';
        final durationSec = row['duration_seconds'] as int? ?? 15;
        final duration = _audio.duration.value ?? Duration(seconds: durationSec);
        final currentPosition =
            _audio.position.value > duration ? duration : _audio.position.value;
        final canPrev = index > 0;
        final canNext = index < _tracks.length - 1;

        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: NuraBrand.deepMidAlpha(0.96),
              border: Border(top: BorderSide(color: vibe.cardBorder)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [NuraBrand.mintAlpha(0.35), NuraBrand.deep],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.album, color: NuraBrand.mint),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: NuraBrand.mint,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            genre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: NuraBrand.mintAlpha(0.62),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _audio.isPlaying,
                      builder: (context, isPlaying, __) => IconButton(
                        onPressed: () {
                          if (isPlaying) {
                            _audio.pause();
                          } else {
                            _audio.resume();
                          }
                        },
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: NuraBrand.mint,
                          size: 34,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _playerExpanded = !_playerExpanded),
                      icon: Icon(
                        _playerExpanded ? Icons.expand_more : Icons.expand_less,
                        color: NuraBrand.mintAlpha(0.75),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                if (_playerExpanded) ...[
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: currentPosition.inMilliseconds.toDouble(),
                      max: duration.inMilliseconds <= 0
                          ? 1
                          : duration.inMilliseconds.toDouble(),
                      min: 0,
                      activeColor: NuraBrand.mint,
                      inactiveColor: NuraBrand.mintAlpha(0.22),
                      onChanged: (v) => _audio.seek(Duration(milliseconds: v.floor())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Mono(_durationLabel(currentPosition.inSeconds),
                            color: NuraBrand.mintAlpha(0.65)),
                        Mono(_durationLabel(duration.inSeconds),
                            color: NuraBrand.mintAlpha(0.65)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: canPrev ? () => _playAtIndex(index - 1) : null,
                        icon: const Icon(Icons.skip_previous_rounded, size: 34),
                        color: NuraBrand.mint,
                        disabledColor: NuraBrand.mintAlpha(0.25),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _audio.isPlaying,
                        builder: (context, isPlaying, __) => IconButton(
                          onPressed: () {
                            if (isPlaying) {
                              _audio.pause();
                            } else {
                              _audio.resume();
                            }
                          },
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            size: 46,
                          ),
                          color: NuraBrand.mint,
                        ),
                      ),
                      IconButton(
                        onPressed: canNext ? () => _playAtIndex(index + 1) : null,
                        icon: const Icon(Icons.skip_next_rounded, size: 34),
                        color: NuraBrand.mint,
                        disabledColor: NuraBrand.mintAlpha(0.25),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EngagementChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _EngagementChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: NuraBrand.deepMidAlpha(0.52),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NuraBrand.mintAlpha(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
