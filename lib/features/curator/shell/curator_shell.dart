import 'package:flutter/material.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/services/audio_preview_service.dart';
import '../../../core/widgets/global_mini_player.dart';
import '../../discovery/swipe/presentation/screens/artist_public_profile_screen.dart';
import '../../discovery/swipe/presentation/screens/home_feed.dart';
import '../../events/presentation/screens/empty_events_tab.dart';
import '../../user/profile/presentation/screens/home_profile.dart';
import '../../user/search/presentation/screens/home_search.dart';
import '../../user/shell/user_shell.dart' show GlobalHeader;
import '../received_tracks/presentation/screens/curator_pitch_review_screen.dart';

class CuratorShell extends StatefulWidget {
  final NuraVibe vibe;
  final Color accent;
  final String waveform;

  const CuratorShell({
    super.key,
    required this.vibe,
    required this.accent,
    required this.waveform,
  });

  @override
  State<CuratorShell> createState() => _CuratorShellState();
}

class _CuratorShellState extends State<CuratorShell> {
  static const _received = 'label_pitch_received';
  
  // State maps per tab
  final Map<String, bool> _isScrolledMap = {};
  
  // Listeners to drive UI
  final ValueNotifier<bool> _currentIsScrolled = ValueNotifier(false);
  
  String _screen = RouteNames.home;
  bool _isFeedReady = false;

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
    _currentIsScrolled.value = _isScrolledMap[_screen] ?? false;
  }

  void _handleTabTap(String value) {
    if (_screen == value) {
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
    final String? headerTitle = switch (_screen) {
      RouteNames.search => 'Cerca',
      'events' => 'Eventi',
      RouteNames.profile => null,
      _artistProfileRoute => null,
      _received => 'Pitch Ricevuti',
      RouteNames.home => 'Discovery',
      _ => 'Discovery',
    };

    final double contentSafeTop = safeTop + 56.0;

    final int currentIndex = switch (_screen) {
      RouteNames.search => 1,
      _received => 2,
      'events' => 3,
      RouteNames.profile => 4,
      _artistProfileRoute => 5,
      _ => 0,
    };

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
          enabled: currentIndex == 0 || currentIndex == 5,
          child: IgnorePointer(
            ignoring: !(currentIndex == 0 || currentIndex == 5),
            child: HomeFeed(
              key: const PageStorageKey('home_feed'),
              vibe: widget.vibe,
              accent: widget.accent,
              waveform: widget.waveform,
              safeTop: safeTop,
              safeBottom: safeBottom,
              isActive: _screen == RouteNames.home || _screen == _artistProfileRoute,
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
            child: CuratorPitchReviewScreen(
              key: const PageStorageKey('curator_pitch'),
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
            Positioned.fill(child: body),
            // Global Header
            Positioned(
              top: safeTop,
              left: 16,
              right: 16,
              child: IgnorePointer(
                ignoring: _screen == _artistProfileRoute,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _screen == _artistProfileRoute ? 0.0 : 1.0,
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
              ),
            ),
            // Mini player ?" solo nel profilo artista, sopra la nav bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 84 + safeBottom,
              child: ValueListenableBuilder<String?>(
                valueListenable: AudioPreviewService.instance.playingTrackId,
                builder: (context, trackId, _) {
                  if (_screen != _artistProfileRoute) return const SizedBox.shrink();
                  if (trackId == null || trackId.isEmpty) return const SizedBox.shrink();
                  return GlobalMiniPlayer(vibe: widget.vibe);
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNav(
                active: _screen == _artistProfileRoute ? RouteNames.home : _screen,
                onChange: _handleTabTap,
                vibe: widget.vibe,
                accent: widget.accent,
                safeBottom: safeBottom,
                items: const [
                  BottomNavItem(RouteNames.home, 'Home', Icons.home_outlined),
                  BottomNavItem(RouteNames.search, 'Cerca', Icons.search),
                  BottomNavItem(_received, 'Ricevuti', Icons.inbox_outlined),
                  BottomNavItem('events', 'Eventi', Icons.event_rounded),
                ],
              ),
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
