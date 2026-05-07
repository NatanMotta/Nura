import 'package:flutter/material.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../discovery/swipe/presentation/screens/home_feed.dart';
import '../../user/profile/presentation/screens/home_profile.dart';
import '../../user/search/presentation/screens/home_search.dart';

class LabelShell extends StatefulWidget {
  final NuraVibe vibe;
  final Color accent;
  final String waveform;

  const LabelShell({
    super.key,
    required this.vibe,
    required this.accent,
    required this.waveform,
  });

  @override
  State<LabelShell> createState() => _LabelShellState();
}

class _LabelShellState extends State<LabelShell> {
  static const _received = 'label_pitch_received';
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
      _received => const _PlaceholderScreen(
          title: 'Pitch Ricevuti',
          subtitle: 'Inbox etichetta/curatore (mock shell)',
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
                  BottomNavItem(_received, 'Pitch Ricevuti', Icons.inbox_outlined),
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

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PlaceholderScreen({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
