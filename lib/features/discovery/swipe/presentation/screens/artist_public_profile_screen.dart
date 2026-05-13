import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/services/audio_preview_service.dart';
import '../../../../../core/services/supabase_bootstrap.dart';
import '../../../../../core/widgets/mono.dart';
import '../../../../auth/presentation/auth_providers.dart';
import '../../../../shared/domain/user_role.dart';
import '../../../../shared/presentation/providers/user_role_provider.dart';

class ArtistPublicProfileScreen extends ConsumerStatefulWidget {
  final String artistId;
  final String artistName;

  const ArtistPublicProfileScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  ConsumerState<ArtistPublicProfileScreen> createState() =>
      _ArtistPublicProfileScreenState();
}

class _ArtistPublicProfileScreenState extends ConsumerState<ArtistPublicProfileScreen> {
  final _audio = AudioPreviewService.instance;
  String? _lastAudioErrorShown;

  bool _loading = true;
  bool _following = false;
  bool _showMiniPlayer = false;
  int? _currentTrackIndex;
  String? _displayName;
  String? _imageAsset;
  String? _bio;
  bool _showAllTracks = false;
  List<Map<String, dynamic>> _tracks = const [];

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
    _audio.stop(); // Stop audio when leaving the screen
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
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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

    final authState = ref.watch(authStateProvider);
    final mockRole = ref.watch(userRoleProvider);
    final role = authState.valueOrNull?.role ?? mockRole;

    return Scaffold(
      backgroundColor: NuraBrand.deep,
      bottomNavigationBar: _miniPlayer(vibe),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: NuraBrand.mint, size: 22),
                    onPressed: () async {
                      await _audio.stop();
                      if (mounted) Navigator.of(context).pop();
                    },
                  ),
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
                            if (role == UserRole.artist) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: NuraBrand.pink,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.flash_on, size: 16),
                                  label: const Text('Invita Battle'),
                                ),
                              ),
                            ],
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
                    itemBuilder: (context, index) {
                      final displayTracks = _showAllTracks ? _tracks : _tracks.take(5).toList();
                      if (index == displayTracks.length && !_showAllTracks && _tracks.length > 5) {
                        return Center(
                          child: TextButton(
                            onPressed: () => setState(() => _showAllTracks = true),
                            style: TextButton.styleFrom(foregroundColor: NuraBrand.mintAlpha(0.8)),
                            child: const Text('Mostra tutti i brani', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        );
                      }
                      return _trackCard(displayTracks[index], vibe.cardBorder);
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: _showAllTracks ? _tracks.length : (_tracks.length > 5 ? 6 : _tracks.length),
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

    return AnimatedBuilder(
      animation: Listenable.merge([_audio.playingTrackId, _audio.isPlaying]),
      builder: (context, _) {
        final isCurrentTrack = _audio.playingTrackId.value == id;
        final showPause = isCurrentTrack && _audio.isPlaying.value;
        final borderColor = isCurrentTrack ? NuraBrand.pink : border;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: NuraBrand.deepMidAlpha(0.55),
            border: Border.all(color: borderColor, width: isCurrentTrack ? 0.8 : 0.5),
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
              IconButton(
                onPressed: () => _playTrackById(id),
                icon: Icon(
                  showPause ? Icons.pause_circle : Icons.play_circle,
                  color: NuraBrand.mint,
                  size: 30,
                ),
              ),
            ],
          ),
        );
      },
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
        
        if (hidden) return const SizedBox.shrink();

        final row = _tracks[index];
        final title = row['title'] as String? ?? 'Untitled';
        final durationSec = row['duration_seconds'] as int? ?? 15;
        final duration = _audio.duration.value ?? Duration(seconds: durationSec);
        final currentPosition = _audio.position.value > duration ? duration : _audio.position.value;

        return Container(
          height: 72,
          decoration: BoxDecoration(
            color: NuraBrand.deepMid,
            border: Border(top: BorderSide(color: vibe.cardBorder.withOpacity(0.2))),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final progress = duration.inMilliseconds > 0 
                  ? currentPosition.inMilliseconds / duration.inMilliseconds 
                  : 0.0;
              
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  final pct = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                  _audio.seek(Duration(milliseconds: (pct * duration.inMilliseconds).floor()));
                },
                onTapDown: (details) {
                  final pct = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                  _audio.seek(Duration(milliseconds: (pct * duration.inMilliseconds).floor()));
                },
                child: Stack(
                  children: [
                    // Background Progress Fill
                    Container(
                      width: constraints.maxWidth * progress,
                      height: double.infinity,
                      color: NuraBrand.pink.withOpacity(0.08),
                    ),
                    // Player Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [NuraBrand.mintAlpha(0.2), NuraBrand.deep],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.music_note, color: NuraBrand.mint, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
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
                                  '${_durationLabel(currentPosition.inSeconds)} / ${_durationLabel(duration.inSeconds)}',
                                  style: TextStyle(
                                    color: NuraBrand.mintAlpha(0.5),
                                    fontSize: 11,
                                    fontFamily: 'monospace',
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
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: NuraBrand.mint,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Top progress line
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 2,
                          width: constraints.maxWidth * progress,
                          color: NuraBrand.pink,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
