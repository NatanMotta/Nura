import 'package:flutter/material.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/audio_preview_service.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/global_mini_player.dart';
import '../../discovery/swipe/presentation/screens/artist_public_profile_screen.dart';
import '../../discovery/swipe/presentation/screens/home_feed.dart';
import '../../user/profile/presentation/screens/home_profile.dart';
import '../../user/search/presentation/screens/home_search.dart';
import '../submissions/presentation/screens/artist_pitch_screen.dart';

class ArtistShell extends StatefulWidget {
  final NuraVibe vibe;
  final Color accent;
  final String waveform;

  const ArtistShell({
    super.key,
    required this.vibe,
    required this.accent,
    required this.waveform,
  });

  @override
  State<ArtistShell> createState() => _ArtistShellState();
}

class _ArtistShellState extends State<ArtistShell> {
  static const _pitch = 'artist_pitch';
  static const _artistProfileRoute = 'artist_profile';
  String _screen = RouteNames.home;

  String? _artistId;
  String? _artistName;

  void _onArtistTap(String artistId, String artistName) {
    setState(() {
      _artistId = artistId;
      _artistName = artistName;
      _screen = _artistProfileRoute;
    });
  }

  void _onArtistBack() {
    setState(() {
      _screen = RouteNames.home;
      _artistId = null;
      _artistName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding;
    final safeTop = inset.top > 0 ? inset.top : 16.0;
    final safeBottom = inset.bottom > 0 ? inset.bottom : 16.0;
    final audio = AudioPreviewService.instance;

    final body = switch (_screen) {
      RouteNames.search => HomeSearch(
          vibe: widget.vibe,
          accent: widget.accent,
          waveform: widget.waveform,
          safeTop: safeTop,
          safeBottom: safeBottom,
        ),
      _pitch => const ArtistPitchScreen(),
      RouteNames.profile => HomeProfile(
          vibe: widget.vibe,
          accent: widget.accent,
          safeTop: safeTop,
          safeBottom: safeBottom,
        ),
      _artistProfileRoute => ArtistPublicProfileScreen(
          artistId: _artistId!,
          artistName: _artistName!,
          onBack: _onArtistBack,
        ),
      _ => HomeFeed(
          vibe: widget.vibe,
          accent: widget.accent,
          waveform: widget.waveform,
          safeTop: safeTop,
          safeBottom: safeBottom,
          onArtistTap: _onArtistTap,
        ),
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: widget.vibe.bgGradient),
        child: Stack(
          children: [
            // 1. IL CORPO DELLA SCHERMATA
            Positioned.fill(child: body),
            
            // 2. MINI PLAYER PRO (Stile Spotify)
            // Il Positioned DEVE essere figlio diretto dello Stack
            Positioned(
              left: 0,
              right: 0,
              bottom: 84 + safeBottom,
              child: ValueListenableBuilder<String?>(
                valueListenable: audio.playingTrackId,
                builder: (context, trackId, _) {
                  // Show player ONLY on Artist Profile screen
                  if (_screen != _artistProfileRoute) return const SizedBox.shrink();
                  if (trackId == null || trackId.isEmpty) return const SizedBox.shrink();
                  return GlobalMiniPlayer(vibe: widget.vibe);
                },
              ),
            ),

            // 3. BOTTOM NAV (Sempre visibile)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNav(
                active: _screen == _artistProfileRoute ? RouteNames.home : _screen,
                onChange: (value) => setState(() {
                  _screen = value;
                  _artistId = null;
                  _artistName = null;
                }),
                vibe: widget.vibe,
                accent: widget.accent,
                safeBottom: safeBottom,
                items: const [
                  BottomNavItem(RouteNames.home, 'Home', Icons.home_outlined),
                  BottomNavItem(RouteNames.search, 'Cerca', Icons.search),
                  BottomNavItem(_pitch, 'Pitch', Icons.send_outlined),
                  BottomNavItem(RouteNames.profile, 'Profilo', Icons.person_outline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
