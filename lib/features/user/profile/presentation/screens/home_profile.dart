import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/services/audio_preview_service.dart';
import '../../../../../core/services/supabase_bootstrap.dart';
import '../../../../auth/domain/auth_user.dart';
import '../../../../auth/presentation/auth_providers.dart';
import '../../../../social/data/social_engagement_service.dart';
import '../../../../shared/domain/user_role.dart';
import 'profile_settings_screen.dart';
import 'track_detail_screen.dart';

class _ProfileTrack {
  final String id;
  final String title;
  final String genre;
  final int durationSeconds;
  final String? storagePath;
  final String? artistName;
  final String? artistId;

  const _ProfileTrack({
    required this.id,
    required this.title,
    required this.genre,
    required this.durationSeconds,
    required this.storagePath,
    required this.artistName,
    required this.artistId,
  });
}

class HomeProfile extends ConsumerStatefulWidget {
  final NuraVibe vibe;
  final Color accent;
  final double safeTop, safeBottom;

  const HomeProfile({
    super.key,
    required this.vibe,
    required this.accent,
    required this.safeTop,
    required this.safeBottom,
  });

  @override
  ConsumerState<HomeProfile> createState() => _HomeProfileState();
}

class _HomeProfileState extends ConsumerState<HomeProfile> {
  final _social = const SocialEngagementService();
  final _audio = AudioPreviewService.instance;

  bool _loading = true;
  AppAuthUser? _authUser;
  String? _displayName;
  String? _username;
  String? _profileImageAsset;

  List<_ProfileTrack> _tracks = const [];
  Map<String, EngagementCounts> _engagementByTrack = const {};
  Map<String, List<TrackComment>> _commentsPreviewByTrack = const {};
  Set<String> _likedTrackIds = <String>{};
  Set<String> _savedTrackIds = <String>{};

  bool _showMiniPlayer = false;
  bool _playerExpanded = false;
  int? _currentTrackIndex;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final authUser = await ref.read(authRepositoryProvider).getCurrentUser();
      String? displayName;
      String? username;

      if (authUser != null && SupabaseBootstrap.isInitialized) {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('display_name,image_asset')
            .eq('id', authUser.id)
            .maybeSingle();
        displayName = row?['display_name'] as String?;
        _profileImageAsset = row?['image_asset'] as String?;
        final email = authUser.email;
        if (email != null && email.contains('@')) {
          username = email.split('@').first;
        }
      }

      final tracks = await _loadRealTracks(authUser?.id);
      final trackIds = tracks.map((t) => t.id).toList(growable: false);
      final counts = await _social.fetchCountsForTrackIds(trackIds);
      final previews = await _loadCommentsPreview(trackIds);

      Set<String> liked = <String>{};
      Set<String> saved = <String>{};
      if (authUser != null && trackIds.isNotEmpty) {
        liked = await _social.fetchUserLikedTrackIds(authUser.id, trackIds);
        saved = await _social.fetchUserSavedTrackIds(authUser.id, trackIds);
      }

      if (!mounted) return;
      setState(() {
        _authUser = authUser;
        _displayName = displayName;
        _username = username;
        _tracks = tracks;
        _engagementByTrack = counts;
        _commentsPreviewByTrack = previews;
        _likedTrackIds = liked;
        _savedTrackIds = saved;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<List<_ProfileTrack>> _loadRealTracks(String? userId) async {
    if (!SupabaseBootstrap.isInitialized) return const [];
    final client = Supabase.instance.client;

    List<dynamic> rows = [];

    if (userId != null) {
      rows = await client
          .from('tracks')
          .select(
              'id,title,genre,duration_seconds,storage_path,artist_id,profiles!tracks_artist_id_fkey(display_name)')
          .eq('artist_id', userId)
          .not('storage_path', 'is', null)
          .order('created_at', ascending: false)
          .limit(12);
    }

    if (rows.isEmpty) {
      rows = await client
          .from('tracks')
          .select(
              'id,title,genre,duration_seconds,storage_path,artist_id,profiles!tracks_artist_id_fkey(display_name)')
          .not('storage_path', 'is', null)
          .order('created_at', ascending: false)
          .limit(12);
    }

    return rows.whereType<Map<String, dynamic>>().map((row) {
      final profile = row['profiles'];
      return _ProfileTrack(
        id: row['id'] as String? ?? 'unknown-track',
        title: row['title'] as String? ?? 'Untitled',
        genre: row['genre'] as String? ?? 'music',
        durationSeconds: (row['duration_seconds'] as num?)?.toInt() ?? 0,
        storagePath: row['storage_path'] as String?,
        artistName:
            profile is Map<String, dynamic> ? profile['display_name'] as String? : null,
        artistId: row['artist_id'] as String?,
      );
    }).toList(growable: false);
  }

  Future<Map<String, List<TrackComment>>> _loadCommentsPreview(
      List<String> trackIds) async {
    final out = <String, List<TrackComment>>{};
    for (final trackId in trackIds) {
      final comments = await _social.fetchComments(trackId, limit: 2);
      out[trackId] = comments;
    }
    return out;
  }

  String _roleLabel(UserRole? role) {
    return switch (role) {
      UserRole.artist => 'Artist',
      UserRole.label => 'Label',
      UserRole.user => 'User',
      null => 'Guest',
    };
  }

  String get _name {
    if (_displayName != null && _displayName!.trim().isNotEmpty) {
      return _displayName!.trim();
    }
    final email = _authUser?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Utente';
  }

  String get _handle {
    if (_username != null && _username!.trim().isNotEmpty) {
      return '@${_username!.trim()}';
    }
    final email = _authUser?.email;
    if (email != null && email.contains('@')) {
      return '@${email.split('@').first}';
    }
    return '@guest';
  }

  String get _initials {
    final source = _name.trim();
    if (source.isEmpty) return 'U';
    final parts = source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _profileAvatar({double size = 84}) {
    if (_profileImageAsset != null && _profileImageAsset!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          _profileImageAsset!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackAvatar(size),
        ),
      );
    }
    return _fallbackAvatar(size);
  }

  Widget _fallbackAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.accent.withOpacity(0.16),
        border: Border.all(color: widget.vibe.cardBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: widget.accent,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.28,
        ),
      ),
    );
  }

  String _durationLabel(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String? _localAssetFromStoragePath(String? storagePath) {
    if (storagePath == null || storagePath.isEmpty) return null;
    final fileName = storagePath.split('/').last;
    if (!fileName.toLowerCase().endsWith('.mp3')) return null;
    return 'assets/audio/$fileName';
  }

  int get _totalLikes => _engagementByTrack.values.fold(0, (a, b) => a + b.likes);
  int get _totalSaves => _engagementByTrack.values.fold(0, (a, b) => a + b.saves);

  Future<void> _toggleLike(String trackId) async {
    final userId = _authUser?.id;
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
    final userId = _authUser?.id;
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

  Future<void> _onTapTrack(_ProfileTrack track) async {
    final localAsset = _localAssetFromStoragePath(track.storagePath);
    if (localAsset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anteprima non disponibile per questo brano')),
      );
      return;
    }

    final isCurrent = _audio.playingTrackId.value == track.id;
    if (isCurrent && _audio.isPlaying.value) {
      await _audio.pause();
      return;
    }
    if (isCurrent && !_audio.isPlaying.value) {
      await _audio.resume();
      return;
    }
    await _audio.playTrack(trackId: track.id, assetPath: localAsset);
    if (!mounted) return;
    setState(() {
      _showMiniPlayer = true;
      _currentTrackIndex = _tracks.indexWhere((t) => t.id == track.id);
    });
  }

  Future<void> _openTrackDetail(_ProfileTrack track) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TrackDetailScreen(
          trackId: track.id,
          initialTitle: track.title,
          initialGenre: track.genre,
          initialDurationSeconds: track.durationSeconds,
          initialCoverImageAsset: null,
          ownerArtistId: track.artistId,
          currentUserId: _authUser?.id,
        ),
      ),
    );
    if (changed == true) {
      await _loadProfile();
    }
  }

  Future<void> _openCommentsSheet(_ProfileTrack track) async {
    final userId = _authUser?.id;
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
              final fetched = await _social.fetchComments(track.id);
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
                await _social.addComment(trackId: track.id, userId: userId, body: text);
                controller.clear();
                comments = await _social.fetchComments(track.id);
                setModalState(() {});
                await _refreshTrackData(track.id);
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
                      'Commenti · ${track.title}',
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
                          icon: Icon(Icons.send, color: widget.accent),
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

  Future<void> _deleteTrack(String trackId) async {
    final userId = _authUser?.id;
    if (userId == null) return _showLoginRequired();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NuraBrand.deepMid,
        title: const Text('Eliminare il brano?', style: TextStyle(color: NuraBrand.mint)),
        content: const Text(
          'Questa azione rimuove il brano dal profilo.',
          style: TextStyle(color: NuraBrand.mint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina')),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('tracks').delete().eq('id', trackId);
      await _loadProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore eliminazione: $e')),
      );
    }
  }

  void _showLoginRequired() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login richiesto per like/save/commenti')),
    );
  }

  Future<void> _playAtIndex(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    await _onTapTrack(_tracks[index]);
  }

  Widget _miniPlayer() {
    return AnimatedBuilder(
      animation: Listenable.merge(
        [_audio.playingTrackId, _audio.isPlaying, _audio.position, _audio.duration],
      ),
      builder: (context, _) {
        final activeTrackId = _audio.playingTrackId.value;
        final playingIndex = _tracks.indexWhere((t) => t.id == activeTrackId);
        final index = _currentTrackIndex ?? (playingIndex >= 0 ? playingIndex : -1);
        final shouldShow = _showMiniPlayer || playingIndex >= 0;
        final hidden = !shouldShow || index < 0 || index >= _tracks.length;
        if (hidden) return const SizedBox.shrink();

        final track = _tracks[index];
        final duration = _audio.duration.value ?? Duration(seconds: track.durationSeconds);
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
              border: Border(top: BorderSide(color: widget.vibe.cardBorder)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: widget.accent.withOpacity(0.15),
                      ),
                      child: Icon(Icons.music_note, color: widget.accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: NuraBrand.mint,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            track.genre,
                            style: TextStyle(
                              color: NuraBrand.mintAlpha(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _audio.isPlaying,
                      builder: (context, isPlaying, _) => IconButton(
                        onPressed: () => isPlaying ? _audio.pause() : _audio.resume(),
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
                      ),
                    ),
                  ],
                ),
                if (_playerExpanded) ...[
                  Slider(
                    value: currentPosition.inMilliseconds.toDouble(),
                    max: duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds.toDouble(),
                    min: 0,
                    activeColor: NuraBrand.mint,
                    inactiveColor: NuraBrand.mintAlpha(0.2),
                    onChanged: (v) => _audio.seek(Duration(milliseconds: v.floor())),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: canPrev ? () => _playAtIndex(index - 1) : null,
                        icon: const Icon(Icons.skip_previous_rounded),
                        color: NuraBrand.mint,
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _audio.isPlaying,
                        builder: (context, isPlaying, _) => IconButton(
                          onPressed: () => isPlaying ? _audio.pause() : _audio.resume(),
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                            size: 42,
                          ),
                          color: NuraBrand.mint,
                        ),
                      ),
                      IconButton(
                        onPressed: canNext ? () => _playAtIndex(index + 1) : null,
                        icon: const Icon(Icons.skip_next_rounded),
                        color: NuraBrand.mint,
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, widget.safeTop, 16, 170 + widget.safeBottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profilo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: NuraBrand.mint,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProfileSettingsScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: NuraBrand.mintAlpha(0.82),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: NuraBrand.deepMidAlpha(0.34),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NuraBrand.mintAlpha(0.14)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 110,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _profileAvatar(size: 74),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _SummaryMetric(
                                      label: 'post',
                                      value: _tracks.length.toString(),
                                      center: true,
                                    ),
                                    _SummaryMetric(
                                      label: 'follower',
                                      value: (_totalLikes + 128).toString(),
                                      center: true,
                                    ),
                                    _SummaryMetric(
                                      label: 'seguiti',
                                      value: ((_totalSaves ~/ 2) + 42).toString(),
                                      center: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: NuraBrand.mint,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_handle · ${_roleLabel(_authUser?.role)}',
                            style: TextStyle(
                              color: NuraBrand.mintAlpha(0.64),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const ProfileSettingsScreen(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: NuraBrand.mint,
                                    side: BorderSide(color: NuraBrand.mintAlpha(0.35)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: const Text('Modifica profilo'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: NuraBrand.mint,
                                  side: BorderSide(color: NuraBrand.mintAlpha(0.35)),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                ),
                                child: const Icon(Icons.share_outlined, size: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                'Le tue canzoni',
                style: TextStyle(
                  color: NuraBrand.mintAlpha(0.95),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Post recenti con metriche reali',
                style: TextStyle(
                  color: NuraBrand.mintAlpha(0.56),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              if (_tracks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: NuraBrand.deepMidAlpha(0.32),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: NuraBrand.mintAlpha(0.1)),
                  ),
                  child: Center(
                    child: Text(
                      'Nessuna traccia disponibile',
                      style: TextStyle(color: NuraBrand.mintAlpha(0.6), fontSize: 12),
                    ),
                  ),
                )
              else
                AnimatedBuilder(
                  animation: Listenable.merge([_audio.playingTrackId, _audio.isPlaying]),
                  builder: (context, _) => Column(
                    children: [
                      for (final t in _tracks)
                        _TrackPostCard(
                          track: t,
                          stats: _engagementByTrack[t.id] ?? const EngagementCounts(),
                          commentsPreview: _commentsPreviewByTrack[t.id] ?? const [],
                          isLiked: _likedTrackIds.contains(t.id),
                          isSaved: _savedTrackIds.contains(t.id),
                          isCurrentTrack: _audio.playingTrackId.value == t.id,
                          isPlaying: _audio.isPlaying.value && _audio.playingTrackId.value == t.id,
                          durationLabel: _durationLabel(t.durationSeconds),
                          canEditDelete: _authUser?.id != null && _authUser!.id == t.artistId,
                          onPlayPause: () => _onTapTrack(t),
                          onTitleTap: () => _openTrackDetail(t),
                          onLike: () => _toggleLike(t.id),
                          onSave: () => _toggleSave(t.id),
                          onComment: () => _openCommentsSheet(t),
                          onDelete: () => _deleteTrack(t.id),
                          accent: widget.accent,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: _miniPlayer()),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool center;

  const _SummaryMetric({
    required this.label,
    required this.value,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: NuraBrand.mint,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: NuraBrand.mintAlpha(0.55), fontSize: 10)),
      ],
    );
  }
}

class _TrackPostCard extends StatelessWidget {
  final _ProfileTrack track;
  final EngagementCounts stats;
  final List<TrackComment> commentsPreview;
  final bool isLiked;
  final bool isSaved;
  final bool isCurrentTrack;
  final bool isPlaying;
  final String durationLabel;
  final bool canEditDelete;
  final VoidCallback onPlayPause;
  final VoidCallback onTitleTap;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback onDelete;
  final Color accent;

  const _TrackPostCard({
    required this.track,
    required this.stats,
    required this.commentsPreview,
    required this.isLiked,
    required this.isSaved,
    required this.isCurrentTrack,
    required this.isPlaying,
    required this.durationLabel,
    required this.canEditDelete,
    required this.onPlayPause,
    required this.onTitleTap,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    required this.onDelete,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 11),
        decoration: BoxDecoration(
          color: NuraBrand.deepMidAlpha(0.30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NuraBrand.mintAlpha(0.11)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      color: accent.withOpacity(0.16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (track.artistName ?? 'A').substring(0, 1).toUpperCase(),
                      style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.artistName ?? 'Artist',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: NuraBrand.mint,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${track.genre} · $durationLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: NuraBrand.mintAlpha(0.55),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    iconSize: 20,
                    icon: Icon(Icons.more_horiz, color: NuraBrand.mintAlpha(0.75)),
                    color: NuraBrand.deepMid,
                    onSelected: (v) {
                      if (v == 'open') onTitleTap();
                      if (v == 'edit' && canEditDelete) onTitleTap();
                      if (v == 'delete' && canEditDelete) onDelete();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: canEditDelete ? 'edit' : 'open',
                        child: Text(
                          canEditDelete ? 'Modifica' : 'Dettaglio',
                          style: const TextStyle(color: NuraBrand.mint),
                        ),
                      ),
                      if (canEditDelete)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Elimina', style: TextStyle(color: Colors.redAccent)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onTitleTap,
              child: Container(
                height: 180,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withOpacity(0.35), NuraBrand.deepMid],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 10,
                      right: 58,
                      bottom: 10,
                      child: Text(
                        track.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: NuraBrand.mint,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: IconButton(
                        onPressed: onPlayPause,
                        icon: Icon(
                          isCurrentTrack
                              ? (isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill)
                              : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _Action(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    onTap: onLike,
                    color: isLiked ? accent : NuraBrand.mint,
                  ),
                  const SizedBox(width: 14),
                  _Action(
                    icon: Icons.chat_bubble_outline,
                    onTap: onComment,
                    color: NuraBrand.mint,
                  ),
                  const SizedBox(width: 14),
                  _Action(
                    icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    onTap: onSave,
                    color: isSaved ? accent : NuraBrand.mint,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${stats.likes} mi piace · ${stats.comments} commenti · ${stats.saves} salvati',
                style: TextStyle(
                  color: NuraBrand.mintAlpha(0.74),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: NuraBrand.mintAlpha(0.78), fontSize: 11),
                  children: [
                    TextSpan(
                      text: '${track.artistName ?? 'artist'} ',
                      style: const TextStyle(
                        color: NuraBrand.mint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: track.title),
                  ],
                ),
              ),
            ),
            if (commentsPreview.isNotEmpty) ...[
              const SizedBox(height: 7),
              for (final c in commentsPreview.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 3, left: 12, right: 12),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: NuraBrand.mintAlpha(0.78), fontSize: 11),
                      children: [
                        TextSpan(
                          text: '${c.authorName ?? 'utente'}: ',
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
            ],
            const SizedBox(height: 2),
            GestureDetector(
              onTap: onComment,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  stats.comments > commentsPreview.length
                      ? 'Vedi tutti i commenti (${stats.comments})'
                      : 'Apri commenti',
                  style: TextStyle(
                    color: NuraBrand.mintAlpha(0.55),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _Action({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) => InkResponse(
    onTap: onTap,
    radius: 18,
    child: Icon(icon, size: 20, color: color),
  );
}
