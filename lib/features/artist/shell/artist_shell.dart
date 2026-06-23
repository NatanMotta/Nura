import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/audio_preview_service.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/global_mini_player.dart';
import '../../discovery/swipe/presentation/screens/artist_public_profile_screen.dart';
import '../../discovery/swipe/presentation/screens/home_feed.dart';
import '../../events/presentation/screens/empty_events_tab.dart';
import '../profile/presentation/screens/artist_personal_profile_screen.dart';
import '../../user/search/presentation/screens/home_search.dart';
import '../../user/shell/user_shell.dart' show GlobalHeader;
import '../upload_track/presentation/screens/artist_track_upload_screen.dart';
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

  // State maps per tab
  final Map<String, bool> _navVisibilityMap = {};
  final Map<String, bool> _isScrolledMap = {};

  // Listeners to drive UI
  final ValueNotifier<bool> _currentNavVisibility = ValueNotifier(true);
  final ValueNotifier<bool> _currentIsScrolled = ValueNotifier(false);

  String _screen = RouteNames.home;
  bool _isFeedReady = false;

  String? _artistId;
  String? _artistName;

  void _onArtistTap(String artistId, String artistName) {
    setState(() {
      _artistId = artistId;
      _artistName = artistName;
      _screen = _artistProfileRoute;
      _updateCurrentState();
    });
  }

  void _onArtistBack() {
    setState(() {
      _screen = RouteNames.home;
      _artistId = null;
      _artistName = null;
      _updateCurrentState();
    });
  }

  void _updateCurrentState() {
    _currentNavVisibility.value = _navVisibilityMap[_screen] ?? true;
    _currentIsScrolled.value = _isScrolledMap[_screen] ?? false;
  }

  void _handleTabTap(String value) {
    if (_screen == value) {
      _navVisibilityMap[value] = true;
      _isScrolledMap[value] = false;
    } else {
      _screen = value;
      _artistId = null;
      _artistName = null;
    }
    setState(() {
      _updateCurrentState();
    });
  }

  @override
  void initState() {
    super.initState();
    _updateCurrentState();
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
      'events' => 3,
      RouteNames.profile => 4,
      _artistProfileRoute => 5,
      _ => 0,
    };

    final String? headerTitle = switch (_screen) {
      RouteNames.search => 'Cerca',
      _pitch => 'Invio Pitch',
      'events' => 'Eventi',
      RouteNames.profile => null,
      _artistProfileRoute => null,
      RouteNames.home => 'Discovery',
      _ => 'Discovery',
    };

    final double contentSafeTop = safeTop + 56.0;

    final body = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical) {
          final isScrolled = notification.metrics.pixels > 20;
          if (_currentIsScrolled.value != isScrolled) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _currentIsScrolled.value = isScrolled;
              _isScrolledMap[_screen] = isScrolled;
            });
          }
        }
        return false;
      },
      child: IndexedStack(
        index: currentIndex,
        children: [
          TickerMode(
            enabled: currentIndex == 0 || currentIndex == 4,
            child: IgnorePointer(
              ignoring: !(currentIndex == 0 || currentIndex == 4),
              child: HomeFeed(
                key: const PageStorageKey('home_feed'),
                vibe: widget.vibe,
                accent: widget.accent,
                waveform: widget.waveform,
                safeTop: safeTop,
                safeBottom: safeBottom,
                isActive: _screen == RouteNames.home ||
                    _screen == _artistProfileRoute,
                onArtistTap: _onArtistTap,
                onFeedReady: () {
                  if (mounted && !_isFeedReady) {
                    setState(() => _isFeedReady = true);
                  }
                },
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
                safeTop: contentSafeTop,
                safeBottom: safeBottom,
              ),
            ),
          ),
          TickerMode(
            enabled: currentIndex == 2,
            child: IgnorePointer(
              ignoring: currentIndex != 2,
              child: ArtistPitchScreen(
                key: const PageStorageKey('artist_pitch'),
                isActive: _screen == _pitch,
                safeTop: safeTop,
                safeBottom: safeBottom,
              ),
            ),
          ),
          TickerMode(
            enabled: currentIndex == 3,
            child: IgnorePointer(
              ignoring: currentIndex != 3,
              child: EmptyEventsTab(
                vibe: widget.vibe,
                accent: widget.accent,
                safeTop: contentSafeTop,
                safeBottom: safeBottom,
              ),
            ),
          ),
          TickerMode(
            enabled: currentIndex == 4,
            child: IgnorePointer(
              ignoring: currentIndex != 4,
              child: ArtistPersonalProfileScreen(
                key: const PageStorageKey('artist_personal_profile'),
                vibe: widget.vibe,
                accent: widget.accent,
                safeTop: safeTop,
                safeBottom: safeBottom,
              ),
            ),
          ),
          TickerMode(
            enabled: currentIndex == 5,
            child: IgnorePointer(
              ignoring: currentIndex != 5,
              child: ArtistPublicProfileScreen(
                key: const PageStorageKey('artist_profile'),
                artistId: _artistId ?? 'mock',
                artistName: _artistName ?? 'Artist',
                onBack: _onArtistBack,
              ),
            ),
          ),
        ],
      ),
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
                  if (notification.metrics.outOfRange ||
                      notification.metrics.pixels <= 0) {
                    if (!_currentNavVisibility.value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _currentNavVisibility.value = true;
                        _navVisibilityMap[_screen] = true;
                      });
                    }
                    return false;
                  }

                  if (notification is UserScrollNotification) {
                    final direction = notification.direction;
                    if (direction == ScrollDirection.reverse &&
                        _currentNavVisibility.value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _currentNavVisibility.value = false;
                        _navVisibilityMap[_screen] = false;
                      });
                    } else if (direction == ScrollDirection.forward &&
                        !_currentNavVisibility.value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _currentNavVisibility.value = true;
                        _navVisibilityMap[_screen] = true;
                      });
                    } else if (direction == ScrollDirection.idle &&
                        !_currentNavVisibility.value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _currentNavVisibility.value = true;
                        _navVisibilityMap[_screen] = true;
                      });
                    }
                  } else if (notification is ScrollEndNotification) {
                    if (!_currentNavVisibility.value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _currentNavVisibility.value = true;
                        _navVisibilityMap[_screen] = true;
                      });
                    }
                  }

                  return false;
                },
                child: body,
              ),
            ),
            // Global Header
            Positioned(
              top: safeTop,
              left: 16,
              right: 16,
              child: ValueListenableBuilder<bool>(
                valueListenable: _currentNavVisibility,
                builder: (context, isVisible, child) {
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity:
                        isVisible && _screen != _artistProfileRoute && _screen != RouteNames.profile ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !(isVisible && _screen != _artistProfileRoute && _screen != RouteNames.profile),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _currentIsScrolled,
                        builder: (context, isScrolled, child) {
                          return GlobalHeader(
                            vibe: widget.vibe,
                            accent: widget.accent,
                            safeTop: safeTop,
                            safeBottom: safeBottom,
                            title: headerTitle,
                            isScrolled: isScrolled,
                            onAvatarTap: () {
                              setState(() {
                                _screen = RouteNames.profile;
                                _artistId = null;
                                _artistName = null;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            // Mini player e Bottom Nav avvolti in ValueListenableBuilder
            ValueListenableBuilder<bool>(
              valueListenable: _currentNavVisibility,
              builder: (context, isVisible, child) {
                return Stack(
                  children: [
                    // 2. MINI PLAYER PRO (Stile Spotify)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      right: 0,
                      bottom: isVisible ? 84 + safeBottom : -100, // Calm UX
                      child: ValueListenableBuilder<String?>(
                        valueListenable: audio.playingTrackId,
                        builder: (context, trackId, _) {
                          // Show player on both Profile screens
                          if (_screen != _artistProfileRoute && _screen != RouteNames.profile) {
                            return const SizedBox.shrink();
                          }
                          if (trackId == null || trackId.isEmpty) {
                            return const SizedBox.shrink();
                          }
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
                      bottom: isVisible ? 0 : -120, // Calm UX Floating Nav
                      child: BottomNav(
                        active: _screen == _artistProfileRoute
                            ? RouteNames.home
                            : _screen,
                        onChange: _handleTabTap,
                        vibe: widget.vibe,
                        accent: widget.accent,
                        safeBottom: safeBottom,
                      ),
                    ),
                  ],
                );
              },
            ),
            // OVERLAY DI CARICAMENTO (Nasconde tutto finché il feed non è pronto)
            if (!_isFeedReady)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFFF8F9FA),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF0A75)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
