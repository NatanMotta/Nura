import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/global_mini_player.dart';
import '../../../core/services/audio_preview_service.dart';
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
  final ValueNotifier<bool> _navVisibilityNotifier = ValueNotifier<bool>(true);
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

    final int currentIndex = switch (_screen) {
      RouteNames.search => 1,
      RouteNames.profile => 2,
      _artistProfileRoute => 3,
      _ => 0,
    };

    final body = IndexedStack(
      index: currentIndex,
      children: [
        TickerMode(
          enabled: currentIndex == 0 || currentIndex == 3,
          child: IgnorePointer(
            ignoring: !(currentIndex == 0 || currentIndex == 3),
            child: HomeFeed(
              key: const PageStorageKey('home_feed'),
              vibe: widget.vibe,
              accent: widget.accent,
              waveform: widget.waveform,
              safeTop: safeTop,
              safeBottom: safeBottom,
              isActive: _screen == RouteNames.home || _screen == _artistProfileRoute,
              onArtistTap: _onArtistTap,
            ),
          ),
        ),
        TickerMode(
          enabled: currentIndex == 1,
          child: IgnorePointer(
            ignoring: currentIndex != 1,
            child: HomeSearch(
              key: const PageStorageKey('home_search'),
              vibe: widget.vibe,
              accent: widget.accent,
              waveform: widget.waveform,
              safeTop: safeTop,
              safeBottom: safeBottom,
            ),
          ),
        ),
        TickerMode(
          enabled: currentIndex == 2,
          child: IgnorePointer(
            ignoring: currentIndex != 2,
            child: HomeProfile(
              key: const PageStorageKey('home_profile'),
              vibe: widget.vibe,
              accent: widget.accent,
              safeTop: safeTop,
              safeBottom: safeBottom,
            ),
          ),
        ),
        TickerMode(
          enabled: currentIndex == 3,
          child: IgnorePointer(
            ignoring: currentIndex != 3,
            child: ArtistPublicProfileScreen(
              key: const PageStorageKey('artist_profile'),
              artistId: _artistId ?? 'mock',
              artistName: _artistName ?? 'Artist',
              onBack: _onArtistBack,
            ),
          ),
        ),
      ],
    );

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
                      colors: [
                        widget.accent.withValues(alpha: 0.33),
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Se stiamo "rimbalzando" in cima o in fondo, ignora l'evento
                  if (notification.metrics.outOfRange ||
                      notification.metrics.pixels <= 0) {
                    if (!_navVisibilityNotifier.value) _navVisibilityNotifier.value = true;
                    return false;
                  }

                  if (notification is UserScrollNotification) {
                    final direction = notification.direction;
                    if (direction == ScrollDirection.reverse && _navVisibilityNotifier.value) {
                      _navVisibilityNotifier.value = false;
                    } else if (direction == ScrollDirection.forward &&
                        !_navVisibilityNotifier.value) {
                      _navVisibilityNotifier.value = true;
                    } else if (direction == ScrollDirection.idle &&
                        !_navVisibilityNotifier.value) {
                      _navVisibilityNotifier.value = true;
                    }
                  } else if (notification is ScrollEndNotification) {
                    if (!_navVisibilityNotifier.value) _navVisibilityNotifier.value = true;
                  }

                  return false;
                },
                child: body,
              ),
            ),
            // Mini player e Bottom Nav avvolti in ValueListenableBuilder
            ValueListenableBuilder<bool>(
              valueListenable: _navVisibilityNotifier,
              builder: (context, isVisible, child) {
                return Stack(
                  children: [
                    // Mini player — solo nel profilo artista, sopra la nav bar
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      right: 0,
                      bottom: isVisible ? 84 + safeBottom : -100, // Calm UX
                      child: ValueListenableBuilder<String?>(
                        valueListenable: AudioPreviewService.instance.playingTrackId,
                        builder: (context, trackId, _) {
                          if (_screen != _artistProfileRoute) {
                            return const SizedBox.shrink();
                          }
                          if (trackId == null || trackId.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return GlobalMiniPlayer(vibe: widget.vibe);
                        },
                      ),
                    ),
                    // Bottom Nav — always visible
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      right: 0,
                      bottom: isVisible ? 0 : -120, // Calm UX Floating Nav
                      child: BottomNav(
                        active:
                            _screen == _artistProfileRoute ? RouteNames.home : _screen,
                        onChange: (value) => setState(() {
                          _screen = value;
                          _artistId = null;
                          _artistName = null;
                          _navVisibilityNotifier.value = true; // reset
                        }),
                        vibe: widget.vibe,
                        accent: widget.accent,
                        safeBottom: safeBottom,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
