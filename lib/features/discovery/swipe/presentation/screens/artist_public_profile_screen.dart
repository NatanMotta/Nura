import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/services/audio_preview_service.dart';
import '../../../../../core/services/supabase_bootstrap.dart';
import '../../../../../core/widgets/mono.dart';

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

  bool _loading = true;
  bool _following = false;
  bool _playerExpanded = false;
  bool _showMiniPlayer = false;
  int? _currentTrackIndex;
  String? _displayName;
  String? _imageAsset;
  String? _bio;
  List<Map<String, dynamic>> _tracks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!SupabaseBootstrap.isInitialized) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final client = Supabase.instance.client;

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

      if (!mounted) return;
      setState(() {
        _displayName = profile?['display_name'] as String?;
        _imageAsset = profile?['image_asset'] as String?;
        _bio = profile?['bio'] as String?;
        _tracks = rows.whereType<Map<String, dynamic>>().toList(growable: false);
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
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _statPill('Tracce', '${_tracks.length}'),
                            const SizedBox(width: 8),
                            _statPill('Battle', '${_tracks.length + 5}'),
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
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: NuraBrand.mint,
                                  foregroundColor: NuraBrand.deep,
                                ),
                                icon: const Icon(Icons.flash_on, size: 16),
                                label: const Text('Invita Battle'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _genreChip('Latest'),
                            const SizedBox(width: 8),
                            _genreChip('Top Plays'),
                            const SizedBox(width: 8),
                            _genreChip('Battle Cuts'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) =>
                        _trackCard(_tracks[index], vibe.cardBorder),
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

  Widget _genreChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: NuraBrand.mintAlpha(0.08),
          border: Border.all(color: NuraBrand.mintAlpha(0.22)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: NuraBrand.mintAlpha(0.82),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _trackCard(Map<String, dynamic> row, Color border) {
    final id = row['id'] as String? ?? 'unknown-track';
    final title = row['title'] as String? ?? 'Untitled';
    final genre = row['genre'] as String? ?? 'demo';
    final duration = row['duration_seconds'] as int?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: NuraBrand.deepMidAlpha(0.55),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
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
                const SizedBox(height: 2),
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
        [_audio.playingTrackId, _audio.isPlaying, _audio.position, _audio.duration],
      ),
      builder: (context, _) {
        final activeTrackId = _audio.playingTrackId.value;
        final playingIndex =
            _tracks.indexWhere((t) => (t['id'] as String?) == activeTrackId);
        final index = _currentTrackIndex ?? (playingIndex >= 0 ? playingIndex : -1);

        final shouldShow = _showMiniPlayer || playingIndex >= 0;
        final hidden = !shouldShow || _tracks.isEmpty || index < 0 || index >= _tracks.length;
        if (hidden) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
            child: const SizedBox.shrink(key: ValueKey('mini-hidden')),
          );
        }

        final row = _tracks[index];
        final title = row['title'] as String? ?? 'Untitled';
        final genre = row['genre'] as String? ?? 'demo';
        final durationSec = row['duration_seconds'] as int? ?? 15;
        final duration = _audio.duration.value ?? Duration(seconds: durationSec);
        final currentPosition = _audio.position.value > duration ? duration : _audio.position.value;
        final canPrev = index > 0;
        final canNext = index < _tracks.length - 1;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
          child: SafeArea(
            key: const ValueKey('mini-visible'),
            top: false,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: NuraBrand.deepMidAlpha(0.96),
                border: Border(top: BorderSide(color: vibe.cardBorder)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_playerExpanded)
                    GestureDetector(
                      onTap: () => setState(() => _playerExpanded = false),
                      child: Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: NuraBrand.mintAlpha(0.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
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
                      if (!_playerExpanded)
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
                              color: NuraBrand.mint,
                              size: 34,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
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
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: currentPosition.inMilliseconds.toDouble(),
                        max: duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds.toDouble(),
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
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: canPrev ? () => _playAtIndex(index - 1) : null,
                          icon: const Icon(Icons.skip_previous_rounded, size: 34),
                          color: NuraBrand.mint,
                          disabledColor: NuraBrand.mintAlpha(0.25),
                        ),
                        const SizedBox(width: 8),
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
                              size: 46,
                            ),
                            color: NuraBrand.mint,
                          ),
                        ),
                        const SizedBox(width: 8),
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
          ),
        );
      },
    );
  }
}
