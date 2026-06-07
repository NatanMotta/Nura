import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  bool _isNavVisible = true;

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

    final int currentIndex = switch (_screen) {
      RouteNames.search => 1,
      _pitch => 2,
      RouteNames.profile => 3,
      _artistProfileRoute => 4,
      _ => 0,
    };

    final body = IndexedStack(
      index: currentIndex,
      children: [
        HomeFeed(
          key: const PageStorageKey('home_feed'),
          vibe: widget.vibe,
          accent: widget.accent,
          waveform: widget.waveform,
          safeTop: safeTop,
          safeBottom: safeBottom,
          isActive: _screen == RouteNames.home || _screen == _artistProfileRoute,
          onArtistTap: _onArtistTap,
        ),
        HomeSearch(
          key: const PageStorageKey('home_search'),
          vibe: widget.vibe,
          accent: widget.accent,
          waveform: widget.waveform,
          safeTop: safeTop,
          safeBottom: safeBottom,
        ),
        const ArtistPitchScreen(key: PageStorageKey('artist_pitch')),
        HomeProfile(
          key: const PageStorageKey('home_profile'),
          vibe: widget.vibe,
          accent: widget.accent,
          safeTop: safeTop,
          safeBottom: safeBottom,
        ),
        ArtistPublicProfileScreen(
          key: const PageStorageKey('artist_profile'),
          artistId: _artistId ?? 'mock',
          artistName: _artistName ?? 'Artist',
          onBack: _onArtistBack,
        ),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: widget.vibe.bgGradient),
        child: Stack(
          children: [
            // 1. IL CORPO DELLA SCHERMATA
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Se stiamo "rimbalzando" in cima o in fondo, mantieni visibile e ignora
                  if (notification.metrics.outOfRange || notification.metrics.pixels <= 0) {
                    if (!_isNavVisible) setState(() => _isNavVisible = true);
                    return false;
                  }

                  if (notification is UserScrollNotification) {
                    final direction = notification.direction;
                    if (direction == ScrollDirection.reverse && _isNavVisible) {
                      setState(() => _isNavVisible = false);
                    } else if (direction == ScrollDirection.forward && !_isNavVisible) {
                      setState(() => _isNavVisible = true);
                    } else if (direction == ScrollDirection.idle && !_isNavVisible) {
                      setState(() => _isNavVisible = true);
                    }
                  } else if (notification is ScrollEndNotification) {
                    if (!_isNavVisible) setState(() => _isNavVisible = true);
                  }

                  return false;
                },
                child: body,
              ),
            ),
            
            // 2. MINI PLAYER PRO (Stile Spotify)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: _isNavVisible ? 84 + safeBottom : -100, // Calm UX
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
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: _isNavVisible ? 0 : -120, // Calm UX Floating Nav
              child: BottomNav(
                active: _screen == _artistProfileRoute ? RouteNames.home : _screen,
                onChange: (value) => setState(() {
                  _screen = value;
                  _artistId = null;
                  _artistName = null;
                  _isNavVisible = true; // reset
                }),
                vibe: widget.vibe,
                accent: widget.accent,
                safeBottom: safeBottom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
