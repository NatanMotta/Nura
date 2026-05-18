import 'package:flutter/material.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/global_mini_player.dart';
import '../../discovery/swipe/presentation/screens/artist_public_profile_screen.dart';
import '../../discovery/swipe/presentation/screens/home_feed.dart';
import '../profile/presentation/screens/home_profile.dart';
import '../search/presentation/screens/home_search.dart';

class UserShell extends StatefulWidget {
  final NuraVibe vibe;
  final Color accent;
  final String waveform;

  const UserShell({
    super.key,
    required this.vibe,
    required this.accent,
    required this.waveform,
  });

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  String _screen = RouteNames.home;

  // Artist profile navigation state
  String? _artistId;
  String? _artistName;
  static const _artistProfileRoute = 'artist_profile';

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

    final body = switch (_screen) {
      RouteNames.search => HomeSearch(
          vibe: widget.vibe,
          accent: widget.accent,
          waveform: widget.waveform,
          safeTop: safeTop,
          safeBottom: safeBottom,
        ),
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
            if (widget.vibe.bloom)
              Positioned(
                top: -120,
                right: -80,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [widget.accent.withOpacity(0.33), Colors.transparent],
                    ),
                  ),
                ),
              ),
            Positioned.fill(child: body),
            // Mini player — solo nel profilo artista, sopra la nav bar
            if (_screen == _artistProfileRoute)
              Positioned(
                left: 0,
                right: 0,
                bottom: 72 + safeBottom,
                child: GlobalMiniPlayer(vibe: widget.vibe),
              ),
            // Bottom Nav — always visible
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
