import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/models/track.dart';
import '../../../../../core/services/supabase_bootstrap.dart';
import '../../../../../core/widgets/glass.dart';
import '../../../../../core/widgets/mono.dart';
import '../../../../auth/domain/auth_user.dart';
import '../../../../auth/presentation/auth_providers.dart';
import '../../../../social/data/social_engagement_service.dart';
import '../../../../shared/data/mock_nura_data.dart';
import '../../../../shared/domain/user_role.dart';
import 'profile_settings_screen.dart';

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
  bool _loading = true;
  AppAuthUser? _authUser;
  String? _displayName;
  String? _username;
  List<Track> _ownedTracks = const [];
  Map<String, EngagementCounts> _engagementByTrack = const {};

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
            .select('display_name,username')
            .eq('id', authUser.id)
            .maybeSingle();
        displayName = row?['display_name'] as String?;
        username = row?['username'] as String?;
      }

      final ownedTracks = _resolveOwnedTracks(
        displayName: displayName,
        username: username,
      );
      final counts = await _social.fetchCountsForTrackIds(
        ownedTracks.map((t) => t.id).toList(growable: false),
      );

      if (!mounted) return;
      setState(() {
        _authUser = authUser;
        _displayName = displayName;
        _username = username;
        _ownedTracks = ownedTracks;
        _engagementByTrack = counts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ownedTracks = _resolveOwnedTracks(displayName: null, username: null);
        _engagementByTrack = const {};
        _loading = false;
      });
    }
  }

  List<Track> _resolveOwnedTracks({String? displayName, String? username}) {
    final artistName = (displayName ?? '').trim().toLowerCase();
    if (artistName.isNotEmpty) {
      final byArtist =
          kTracks.where((t) => t.artist.toLowerCase() == artistName).toList();
      if (byArtist.isNotEmpty) return byArtist;
    }

    final handle = (username ?? '').trim().toLowerCase();
    if (handle.isNotEmpty) {
      final byHandle =
          kTracks.where((t) => t.artist.toLowerCase().contains(handle)).toList();
      if (byHandle.isNotEmpty) return byHandle;
    }

    return kTracks.take(4).toList();
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

  EngagementCounts _countsForTrack(String trackId, int index) {
    final db = _engagementByTrack[trackId];
    if (db != null) return db;
    // Fallback visivo se non ci sono ancora dati reali.
    final likes = 140 + ((trackId.hashCode.abs() + index * 91) % 900);
    final saves = (likes * 0.28).round() + (index * 11);
    return EngagementCounts(likes: likes, saves: saves, comments: 0);
  }

  int get _totalLikes {
    var total = 0;
    for (var i = 0; i < _ownedTracks.length; i++) {
      total += _countsForTrack(_ownedTracks[i].id, i).likes;
    }
    return total;
  }

  int get _totalSaves {
    var total = 0;
    for (var i = 0; i < _ownedTracks.length; i++) {
      total += _countsForTrack(_ownedTracks[i].id, i).saves;
    }
    return total;
  }

  int get _communityRank {
    final score = (_totalLikes * 0.7) + (_totalSaves * 1.2);
    final normalized = (score / 120).round();
    final rank = 500 - normalized;
    return rank.clamp(12, 9800);
  }

  String get _topPercentile {
    final pct = ((_communityRank / 10000) * 100).clamp(1, 99).round();
    return '$pct%';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, widget.safeTop, 16, 100 + widget.safeBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profilo',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: NuraBrand.mint,
                  letterSpacing: -0.5,
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
                  Icons.settings_outlined,
                  size: 20,
                  color: NuraBrand.mintAlpha(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Glass(
            vibe: widget.vibe,
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [widget.accent, NuraBrand.deep],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: NuraBrand.mint,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _handle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: NuraBrand.mintAlpha(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: NuraBrand.mintAlpha(0.10),
                                    border: Border.all(color: widget.vibe.cardBorder),
                                  ),
                                  child: Mono(
                                    _roleLabel(_authUser?.role),
                                    color: NuraBrand.mint,
                                    size: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _authUser?.email ?? 'Nessun account collegato',
                        style: TextStyle(
                          fontSize: 12,
                          color: NuraBrand.mintAlpha(0.65),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Glass(
            vibe: widget.vibe,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Mono('Ranking community', color: NuraBrand.mint),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MetricBox(
                        label: 'RANK',
                        value: '#$_communityRank',
                        accent: widget.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricBox(
                        label: 'TOP',
                        value: _topPercentile,
                        accent: widget.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricBox(
                        label: 'TRACKS',
                        value: _ownedTracks.length.toString(),
                        accent: widget.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Glass(
            vibe: widget.vibe,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Mono('Le tue canzoni', color: NuraBrand.mint),
                    Text(
                      '${_ownedTracks.length} brani',
                      style: TextStyle(color: NuraBrand.mintAlpha(0.6), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < _ownedTracks.length; i++) ...[
                  Builder(builder: (_) {
                    final counts = _countsForTrack(_ownedTracks[i].id, i);
                    return _OwnTrackTile(
                      track: _ownedTracks[i],
                      likes: counts.likes,
                      saves: counts.saves,
                      accent: widget.accent,
                    );
                  }),
                  if (i < _ownedTracks.length - 1)
                    Divider(height: 10, color: widget.vibe.cardBorder),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: NuraBrand.deepMidAlpha(0.45),
                    border: Border.all(color: widget.vibe.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Totale engagement',
                        style: TextStyle(color: NuraBrand.mintAlpha(0.7), fontSize: 12),
                      ),
                      Text(
                        '$_totalLikes likes · $_totalSaves salvataggi',
                        style: const TextStyle(
                          color: NuraBrand.mint,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: NuraBrand.deepMidAlpha(0.45),
        border: Border.all(color: NuraBrand.mintAlpha(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: NuraBrand.mintAlpha(0.55),
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnTrackTile extends StatelessWidget {
  final Track track;
  final int likes;
  final int saves;
  final Color accent;

  const _OwnTrackTile({
    required this.track,
    required this.likes,
    required this.saves,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withOpacity(0.9), NuraBrand.deep],
            ),
          ),
          child: const Icon(Icons.music_note_rounded, size: 19, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.track,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: NuraBrand.mint,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '${track.genre} · ${track.dur}',
                style: TextStyle(
                  color: NuraBrand.mintAlpha(0.55),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '♥ $likes',
              style: TextStyle(
                color: NuraBrand.mintAlpha(0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '⬚ $saves',
              style: TextStyle(
                color: NuraBrand.mintAlpha(0.65),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
