import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/global_mini_player.dart';
import '../../../core/services/audio_preview_service.dart';
import '../../discovery/swipe/presentation/screens/artist_public_profile_screen.dart';
import '../../discovery/swipe/presentation/screens/home_feed.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/presentation/screens/empty_events_tab.dart';
import '../../shared/presentation/providers/user_role_provider.dart';
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
  // State maps per tab
  final Map<String, bool> _navVisibilityMap = {};
  final Map<String, bool> _isScrolledMap = {};
  
  // Listeners to drive UI
  final ValueNotifier<bool> _currentNavVisibility = ValueNotifier(true);
  final ValueNotifier<bool> _currentIsScrolled = ValueNotifier(false);
  
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
      // Tap on active tab: scroll to top (mocked by resetting state)
      _navVisibilityMap[value] = true;
      _isScrolledMap[value] = false;
      // In a real app we would use PrimaryScrollController.of(context).animateTo(0), 
      // but here we just reset the UI state.
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

    final int currentIndex = switch (_screen) {
      RouteNames.search => 1,
      'events' => 2,
      _artistProfileRoute => 3,
      RouteNames.profile => 4,
      _ => 0,
    };

    final String? headerTitle = switch (_screen) {
      RouteNames.search => 'Cerca',
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
              safeTop: contentSafeTop,
              safeBottom: safeBottom,
            ),
          ),
        ),
        TickerMode(
          enabled: currentIndex == 2,
          child: IgnorePointer(
            ignoring: currentIndex != 2,
            child: EmptyEventsTab(
              key: const PageStorageKey('events_tab'),
              vibe: widget.vibe,
              accent: widget.accent,
              safeTop: contentSafeTop,
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
        TickerMode(
          enabled: currentIndex == 4,
          child: IgnorePointer(
            ignoring: currentIndex != 4,
            child: HomeProfile(
              key: const PageStorageKey('home_profile'),
              vibe: widget.vibe,
              accent: widget.accent,
              safeTop: safeTop,
              safeBottom: safeBottom,
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
                      colors: [widget.accent.withValues(alpha: 0.33), Colors.transparent],
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
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
                    if (direction == ScrollDirection.reverse && _currentNavVisibility.value) {
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
                    opacity: isVisible && _screen != _artistProfileRoute ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !(isVisible && _screen != _artistProfileRoute),
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
          ],
        ),
      ),
    );
  }
}

class GlobalHeader extends ConsumerWidget {
  final NuraVibe vibe;
  final Color accent;
  final double safeTop;
  final double safeBottom;
  final String? title;
  final bool isScrolled;
  final VoidCallback onAvatarTap;

  const GlobalHeader({
    super.key,
    required this.vibe,
    required this.accent,
    required this.safeTop,
    required this.safeBottom,
    this.title,
    this.isScrolled = false,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(mockProfileIdentityProvider);
    final avatarAsset = ref.watch(mockProfileImageAssetProvider);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: avatarAsset != null
                  ? DecorationImage(
                      image: AssetImage(avatarAsset),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: avatarAsset == null ? Colors.white12 : null,
              border: avatarAsset == null ? Border.all(color: Colors.white24, width: 1.5) : null,
            ),
            alignment: Alignment.center,
            child: avatarAsset == null
                ? Text(
                    identity != null && identity.displayName.isNotEmpty
                        ? identity.displayName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
        ),
        if (title != null) ...[
          const SizedBox(width: 14),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isScrolled ? 0.0 : 1.0,
            child: Text(
              title!,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
