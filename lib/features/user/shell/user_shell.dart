import 'package:flutter/material.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/bottom_nav.dart';
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
      _ => HomeFeed(
          vibe: widget.vibe,
          accent: widget.accent,
          waveform: widget.waveform,
          safeTop: safeTop,
          safeBottom: safeBottom,
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNav(
                active: _screen,
                onChange: (value) => setState(() => _screen = value),
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
