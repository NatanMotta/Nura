import 'package:flutter/widgets.dart';

import '../../features/discovery/swipe/presentation/screens/home_feed.dart';
import '../../features/user/profile/presentation/screens/home_profile.dart';
import '../../features/user/search/presentation/screens/home_search.dart';
import '../theme/app_theme.dart';
import 'route_names.dart';

Widget buildCurrentScreen({
  required String screen,
  required NuraVibe vibe,
  required Color accent,
  required String waveform,
  required double safeTop,
  required double safeBottom,
}) {
  return switch (screen) {
    RouteNames.search => HomeSearch(
        vibe: vibe,
        accent: accent,
        waveform: waveform,
        safeTop: safeTop,
        safeBottom: safeBottom,
      ),
    RouteNames.profile => HomeProfile(
        vibe: vibe,
        accent: accent,
        safeTop: safeTop,
        safeBottom: safeBottom,
      ),
    _ => HomeFeed(
        vibe: vibe,
        accent: accent,
        waveform: waveform,
        safeTop: safeTop,
        safeBottom: safeBottom,
      ),
  };
}
