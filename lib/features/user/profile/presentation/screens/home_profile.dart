import 'dart:async';
import 'dart:ui' as ui show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/services/audio_preview_service.dart';
import '../../../../../core/services/supabase_bootstrap.dart';
import '../../../../../core/widgets/global_mini_player.dart';
import '../../../../auth/domain/auth_user.dart';
import '../../../../auth/presentation/auth_providers.dart';
import '../../../../discovery/swipe/presentation/screens/artist_public_profile_screen.dart';
import '../../../../shared/domain/user_role.dart';
import '../../../../shared/presentation/providers/user_role_provider.dart';
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

class _NuraScoreMetric {
  final String label;
  final int value;

  const _NuraScoreMetric({
    required this.label,
    required this.value,
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
  static const String _defaultProfileHeroImage =
      'assets/images/artists/michael-dam-mEZ3PoFGs_k-unsplash.jpg';
  static const double _bottomNavHeight = 74;
  static final Map<String, Color> _profileColorCache = {};

  final _audio = AudioPreviewService.instance;
  final ScrollController _scrollController = ScrollController();

  AppAuthUser? _authUser;
  String? _displayName;
  String? _username;
  String? _profileImageAsset;
  String? _resolvedProfileSwatchAsset;
  Color _profileSwatch = NuraBrand.deep;

  List<_ProfileTrack> _tracks = const [];
  int? _currentTrackIndex;
  final ValueNotifier<double> _scrollNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollNotifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    _scrollNotifier.value = _scrollController.offset;
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

      if (!mounted) return;
      setState(() {
        _authUser = authUser;
        _displayName = displayName;
        _username = username;
        _tracks = tracks;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {});
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

  String get _name {
    if (_displayName != null && _displayName!.trim().isNotEmpty) {
      return _displayName!.trim();
    }
    final mockIdentity = ref.read(mockProfileIdentityProvider);
    if (mockIdentity != null && mockIdentity.displayName.trim().isNotEmpty) {
      return mockIdentity.displayName.trim();
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
    final mockIdentity = ref.read(mockProfileIdentityProvider);
    if (mockIdentity != null && mockIdentity.username.trim().isNotEmpty) {
      return '@${mockIdentity.username.trim()}';
    }
    final email = _authUser?.email;
    if (email != null && email.contains('@')) {
      return '@${email.split('@').first}';
    }
    return '@guest';
  }

  UserRole? get _effectiveRole => _authUser?.role ?? ref.read(userRoleProvider);

  bool get _showMockNuraScore => _effectiveRole == UserRole.artist;

  ImageProvider? _imageProviderForSource(String imageSource) {
    if (imageSource.isEmpty) return null;
    if (imageSource.startsWith('assets/')) {
      return AssetImage(imageSource);
    }
    if (imageSource.startsWith('http://') || imageSource.startsWith('https://')) {
      return NetworkImage(imageSource);
    }
    return null;
  }

  Color _normalizeProfileSwatch(Color color) {
    final hsl = HSLColor.fromColor(color);
    final normalizedSaturation = hsl.saturation.clamp(0.22, 0.72).toDouble();
    final normalizedLightness = hsl.lightness.clamp(0.34, 0.62).toDouble();
    return hsl
        .withSaturation(normalizedSaturation)
        .withLightness(normalizedLightness)
        .toColor();
  }

  Future<void> _resolveProfileSwatch(String imageSource) async {
    final provider = _imageProviderForSource(imageSource);
    if (provider == null) {
      _resolvedProfileSwatchAsset = imageSource;
      if (mounted) {
        setState(() => _profileSwatch = NuraBrand.deep);
      } else {
        _profileSwatch = NuraBrand.deep;
      }
      return;
    }

    if (_profileColorCache.containsKey(imageSource)) {
      _resolvedProfileSwatchAsset = imageSource;
      final cached = _profileColorCache[imageSource]!;
      if (mounted) {
        setState(() => _profileSwatch = cached);
      } else {
        _profileSwatch = cached;
      }
      return;
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        size: const Size(24, 24),
        maximumColorCount: 6,
      );
      final resolved = _normalizeProfileSwatch(
        palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          NuraBrand.deep,
      );
      _profileColorCache[imageSource] = resolved;
      if (!mounted) {
        _resolvedProfileSwatchAsset = imageSource;
        _profileSwatch = resolved;
        return;
      }
      setState(() {
        _resolvedProfileSwatchAsset = imageSource;
        _profileSwatch = resolved;
      });
    } catch (_) {
      _profileColorCache[imageSource] = NuraBrand.deep;
      if (!mounted) {
        _resolvedProfileSwatchAsset = imageSource;
        _profileSwatch = NuraBrand.deep;
        return;
      }
      setState(() {
        _resolvedProfileSwatchAsset = imageSource;
        _profileSwatch = NuraBrand.deep;
      });
    }
  }

  Color get _scoreGlassColor => _profileSwatch.withValues(alpha: 0.24);

  String get _nuraScoreStableKey {
    final mockIdentity = ref.read(mockProfileIdentityProvider);
    return _authUser?.id ??
        mockIdentity?.username.trim() ??
        _handle.replaceFirst('@', '').trim();
  }

  int _stableScoreValue(String salt) {
    final stableKey = '$_nuraScoreStableKey:$salt';
    if (stableKey.trim().isEmpty) return 0;
    final hash = stableKey.codeUnits.fold<int>(
      0,
      (value, codeUnit) => ((value * 31) + codeUnit) & 0x7fffffff,
    );
    return hash % 101;
  }

  List<_NuraScoreMetric> get _mockNuraScoreMetrics => [
        _NuraScoreMetric(label: 'Parametro 1', value: _stableScoreValue('par1')),
        _NuraScoreMetric(label: 'Parametro 2', value: _stableScoreValue('par2')),
        _NuraScoreMetric(label: 'Parametro 3', value: _stableScoreValue('par3')),
        _NuraScoreMetric(label: 'Parametro 4', value: _stableScoreValue('par4')),
        _NuraScoreMetric(label: 'Parametro 5', value: _stableScoreValue('par5')),
      ];

  int get _mockNuraScore {
    final metrics = _mockNuraScoreMetrics;
    return (metrics.fold<int>(0, (sum, metric) => sum + metric.value) /
            metrics.length)
        .round();
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

  int get _mockFollowers => (_tracks.length * 37) + 120;
  int get _mockFollowing => 42 + (_tracks.length * 2);

  Future<void> _onTapTrack(_ProfileTrack track) async {
    final localAsset = _localAssetFromStoragePath(track.storagePath);
    if (localAsset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anteprima non disponibile per questo brano')),
      );
      return;
    }

    final targetIndex = _tracks.indexWhere((t) => t.id == track.id);
    if (mounted) {
      setState(() {
        _currentTrackIndex = targetIndex >= 0 ? targetIndex : _currentTrackIndex;
      });
    }

    final isCurrent = _audio.playingTrackId.value == track.id;
    if (isCurrent && _audio.isPlaying.value) {
      await _audio.pause();
      if (!mounted) return;
      setState(() {
        _currentTrackIndex = targetIndex >= 0 ? targetIndex : _currentTrackIndex;
      });
      return;
    }
    if (isCurrent && !_audio.isPlaying.value) {
      await _audio.resume();
      if (!mounted) return;
      setState(() {
        _currentTrackIndex = targetIndex >= 0 ? targetIndex : _currentTrackIndex;
      });
      return;
    }
    await _audio.playTrack(trackId: track.id, assetPath: localAsset);
    if (!mounted) return;
    setState(() {
      _currentTrackIndex = targetIndex >= 0 ? targetIndex : _currentTrackIndex;
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

  void _openNuraScoreDetail(String imageSource) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NuraScoreDetailScreen(
          artistName: _name,
          artistHandle: _handle,
          imageSource: imageSource,
          totalScore: _mockNuraScore,
          metrics: _mockNuraScoreMetrics,
          scoreColor: _scoreGlassColor,
          accent: widget.accent,
        ),
      ),
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

  void _showSocialMockInfo() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Like e commenti sono in mock (coming soon)')),
    );
  }

  void _showLoginRequired() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login richiesto')),
    );
  }

  Widget _miniPlayer() {
    return ValueListenableBuilder<String?>(
      valueListenable: _audio.playingTrackId,
      builder: (context, trackId, _) {
        final hasActiveTrack = trackId != null && trackId.isNotEmpty;
        if (!hasActiveTrack) return const SizedBox.shrink();
        return GlobalMiniPlayer(vibe: widget.vibe);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mockImageAsset = ref.watch(mockProfileImageAssetProvider);
    final effectiveProfileImageAsset =
        mockImageAsset ?? _profileImageAsset ?? _defaultProfileHeroImage;
    if (_resolvedProfileSwatchAsset != effectiveProfileImageAsset) {
      _resolvedProfileSwatchAsset = effectiveProfileImageAsset;
      unawaited(_resolveProfileSwatch(effectiveProfileImageAsset));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _scrollNotifier,
            builder: (context, scrollOffset, _) {
              final overscroll = scrollOffset < 0 ? -scrollOffset : 0.0;
              final collapsedOffset = scrollOffset > 0 ? scrollOffset : 0.0;
              final heroTop = scrollOffset < 0 ? -(overscroll * 0.32) : -collapsedOffset;
              final heroHeight = 380.0 + overscroll;
              final heroOpacity = (1.0 - (collapsedOffset / 260)).clamp(0.0, 1.0);
              return Stack(
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: ParallaxOrganicMeshPainter(
                          scrollOffset: scrollOffset,
                          musicuraBlu: NuraBrand.deep,
                          nuraPink: NuraBrand.pink,
                        ),
                      ),
                    ),
                  ),
                  if (effectiveProfileImageAsset.isNotEmpty)
                    Positioned(
                      top: heroTop,
                      left: 0,
                      right: 0,
                      height: heroHeight,
                      child: RepaintBoundary(
                        child: Opacity(
                          opacity: heroOpacity,
                          child: ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white, Colors.white, Colors.transparent],
                              stops: [0.0, 0.45, 0.95],
                            ).createShader(rect),
                            blendMode: BlendMode.dstIn,
                            child: Image.asset(
                              effectiveProfileImageAsset,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(0, 0, 0, 170 + widget.safeBottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(24, widget.safeTop + 18, 24, 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 240),
                      Text(
                        _name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _handle,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatSlot(
                            _statItem(_tracks.length.toString(), 'POST'),
                          ),
                          _vDivider(),
                          _buildStatSlot(
                            _statItem(_mockFollowers.toString(), 'FOLLOWERS'),
                          ),
                          _vDivider(),
                          _buildStatSlot(
                            _statItem(_mockFollowing.toString(), 'SEGUITI'),
                          ),
                          if (_showMockNuraScore) ...[
                            _vDivider(),
                            _buildStatSlot(
                              _nuraScoreStatItem(
                                '$_mockNuraScore',
                                onTap: () => _openNuraScoreDetail(
                                  effectiveProfileImageAsset,
                                ),
                              ),
                              flex: 2,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 56),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'BRANI',
                            style: TextStyle(
                              color: const Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const _UploadTrackMockScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1A1A1A)),
                          tooltip: 'Carica brano (mock)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Le tue canzoni',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_tracks.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE4E8EE)),
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
                            for (var i = 0; i < _tracks.length; i++)
                              _TrackPostCard(
                                rank: i + 1,
                                track: _tracks[i],
                                mockLikes: 20 + (_tracks[i].id.hashCode.abs() % 240),
                                mockComments: 3 + (_tracks[i].id.hashCode.abs() % 48),
                                hideInlinePlay: _audio.playingTrackId.value == _tracks[i].id,
                                isCurrentTrack:
                                    _audio.playingTrackId.value == _tracks[i].id,
                                isPlaying: _audio.isPlaying.value &&
                                    _audio.playingTrackId.value == _tracks[i].id,
                                durationLabel: _durationLabel(_tracks[i].durationSeconds),
                                canEditDelete:
                                    _authUser?.id != null &&
                                    _authUser!.id == _tracks[i].artistId,
                                onPlayPause: () => _onTapTrack(_tracks[i]),
                                onTitleTap: () => _openTrackDetail(_tracks[i]),
                                onLike: _showSocialMockInfo,
                                onComment: _showSocialMockInfo,
                                onDelete: () => _deleteTrack(_tracks[i].id),
                                accent: widget.accent,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
          Positioned(
            left: 0,
            right: 0,
            bottom: _bottomNavHeight + widget.safeBottom,
            child: _miniPlayer(),
          ),
          Positioned(
            top: widget.safeTop + 8,
            right: 16,
            child: ValueListenableBuilder<double>(
              valueListenable: _scrollNotifier,
              builder: (context, scrollOffset, _) {
                return Opacity(
                  opacity: (1.0 - (scrollOffset / 260)).clamp(0.0, 1.0),
                  child: IconButton(
                    tooltip: 'Impostazioni profilo',
                    visualDensity: VisualDensity.compact,
                    iconSize: 20,
                    icon: const Icon(Icons.settings_outlined),
                    color: Colors.white.withValues(alpha: 0.92),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                      builder: (_) => const ProfileSettingsScreen(),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildStatSlot(Widget child, {int flex = 1}) {
    return Expanded(flex: flex, child: Center(child: child));
  }

  Widget _statItem(String value, String label, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _nuraScoreStatItem(String value, {required VoidCallback onTap}) {
    return Semantics(
      button: true,
      label: 'Apri dettaglio Nura Score',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Material(
              color: _scoreGlassColor,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: Color.lerp(
                            NuraBrand.pink,
                            Colors.white,
                            0.18,
                          ),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.9,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NURA SCORE',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.75,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 20,
        color: Colors.black.withValues(alpha: 0.05),
      );
}

class _TrackPostCard extends StatelessWidget {
  final int rank;
  final _ProfileTrack track;
  final int mockLikes;
  final int mockComments;
  final bool hideInlinePlay;
  final bool isCurrentTrack;
  final bool isPlaying;
  final String durationLabel;
  final bool canEditDelete;
  final VoidCallback onPlayPause;
  final VoidCallback onTitleTap;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onDelete;
  final Color accent;

  const _TrackPostCard({
    required this.rank,
    required this.track,
    required this.mockLikes,
    required this.mockComments,
    required this.hideInlinePlay,
    required this.isCurrentTrack,
    required this.isPlaying,
    required this.durationLabel,
    required this.canEditDelete,
    required this.onPlayPause,
    required this.onTitleTap,
    required this.onLike,
    required this.onComment,
    required this.onDelete,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: isCurrentTrack ? NuraBrand.pink : Colors.black26,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onPlayPause,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: Colors.black12,
                      child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                    ),
                  ),
                  if (!(isCurrentTrack && isPlaying))
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  if (isCurrentTrack && isPlaying)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(child: AudioVisualizerAnimation()),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                onTap: onTitleTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF1A1A1A),
                        fontSize: 15,
                        fontWeight: isCurrentTrack ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 10, color: Colors.black12),
                        const SizedBox(width: 2),
                        Text('$mockLikes', style: const TextStyle(color: Colors.black26, fontSize: 10)),
                        const SizedBox(width: 8),
                        const Icon(Icons.chat_bubble, size: 10, color: Colors.black12),
                        const SizedBox(width: 2),
                        Text('$mockComments', style: const TextStyle(color: Colors.black26, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Text(
              durationLabel,
              style: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontSize: 12),
            ),
            PopupMenuButton<String>(
              iconSize: 18,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_horiz, color: Colors.black38),
              color: Colors.white,
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
                    style: const TextStyle(color: Color(0xFF1A1A1A)),
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
    );
  }
}

class _NuraScoreDetailScreen extends StatelessWidget {
  final String artistName;
  final String artistHandle;
  final String imageSource;
  final int totalScore;
  final List<_NuraScoreMetric> metrics;
  final Color scoreColor;
  final Color accent;

  const _NuraScoreDetailScreen({
    required this.artistName,
    required this.artistHandle,
    required this.imageSource,
    required this.totalScore,
    required this.metrics,
    required this.scoreColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final mutedPink = Color.lerp(NuraBrand.pink, Colors.white, 0.18)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
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
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _profileImage(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artistName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              artistHandle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF1A1A1A)
                                    .withValues(alpha: 0.48),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 26,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$totalScore',
                          style: TextStyle(
                            color: mutedPink,
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            height: 0.96,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'NURA SCORE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'MEDIE CURATOR',
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.82),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final metric in metrics) ...[
                    _ScoreMetricRow(
                      label: metric.label,
                      value: metric.value,
                      accent: mutedPink,
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 18),
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF1A1A1A),
                  ),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileImage() {
    if (imageSource.startsWith('http://') ||
        imageSource.startsWith('https://')) {
      return Image.network(
        imageSource,
        width: 68,
        height: 68,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(),
      );
    }

    return Image.asset(
      imageSource,
      width: 68,
      height: 68,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imageFallback(),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: 68,
      height: 68,
      color: Colors.black.withValues(alpha: 0.08),
      child: Icon(
        Icons.person_rounded,
        color: Colors.black.withValues(alpha: 0.32),
      ),
    );
  }
}

class _ScoreMetricRow extends StatelessWidget {
  final String label;
  final int value;
  final Color accent;

  const _ScoreMetricRow({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$value',
                style: TextStyle(
                  color: accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadTrackMockScreen extends StatelessWidget {
  const _UploadTrackMockScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NuraBrand.deepest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: NuraBrand.mint,
        title: const Text('Upload Traccia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NuraBrand.deepMidAlpha(0.42),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NuraBrand.mintAlpha(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload mock',
                      style: TextStyle(
                        color: NuraBrand.mint,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Questa schermata e solo UI mock. Caricamento reale in arrivo.',
                      style: TextStyle(
                        color: NuraBrand.mintAlpha(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _mockField('Titolo brano'),
              const SizedBox(height: 10),
              _mockField('Genere'),
              const SizedBox(height: 10),
              _mockField('Mood / Tag principali'),
              const SizedBox(height: 10),
              _mockField('BPM'),
              const SizedBox(height: 10),
              _mockField('Tonalita (es. C#m)'),
              const SizedBox(height: 10),
              _mockField('ISRC (opzionale)'),
              const SizedBox(height: 10),
              _mockField('Descrizione breve'),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mock: selezione file non ancora attiva')),
                  );
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Seleziona file audio'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mock: upload artwork non ancora attivo')),
                  );
                },
                icon: const Icon(Icons.image_outlined),
                label: const Text('Carica artwork / copertina'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NuraBrand.deepMidAlpha(0.38),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: NuraBrand.mintAlpha(0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview swipe (15s)',
                      style: TextStyle(
                        color: NuraBrand.mint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Punto di start preview: 00:30 (mock)',
                      style: TextStyle(color: NuraBrand.mintAlpha(0.72), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: 30,
                      min: 0,
                      max: 120,
                      onChanged: (_) {},
                      activeColor: NuraBrand.mint,
                      inactiveColor: NuraBrand.mintAlpha(0.25),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NuraBrand.deepMidAlpha(0.38),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: NuraBrand.mintAlpha(0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visibilita',
                      style: TextStyle(
                        color: NuraBrand.mint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.public, size: 16),
                            label: const Text('Pubblica'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.lock_outline, size: 16),
                            label: const Text('Privato'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mock: upload non ancora attivo')),
                  );
                },
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Pubblica traccia'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mockField(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: NuraBrand.deepMidAlpha(0.38),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NuraBrand.mintAlpha(0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(color: NuraBrand.mintAlpha(0.7), fontSize: 12),
      ),
    );
  }
}
