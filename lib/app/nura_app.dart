import 'package:flutter/material.dart';

import '../core/widgets/bottom_nav.dart';
import 'router/app_router.dart';
import 'router/route_names.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class NuraApp extends StatefulWidget {
  const NuraApp({super.key});
  @override
  State<NuraApp> createState() => _NuraAppState();
}

class _NuraAppState extends State<NuraApp> {
  VibeId vibeId = VibeId.premium;
  String screen = RouteNames.home;
  Color accent = NuraBrand.pink;
  String waveform = 'bars'; // bars · wave · pulse

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nura',
      debugShowCheckedModeBanner: false,
      theme: buildNuraTheme(),
      home: NuraShell(
        vibe: NuraVibe.of(vibeId),
        accent: accent,
        screen: screen,
        waveform: waveform,
        onNav: (s) => setState(() => screen = s),
        onVibe: (v) => setState(() => vibeId = v),
        onAccent: (c) => setState(() => accent = c),
        onWaveform: (w) => setState(() => waveform = w),
      ),
    );
  }
}

class NuraShell extends StatelessWidget {
  final NuraVibe vibe;
  final Color accent;
  final String screen, waveform;
  final ValueChanged<String> onNav, onWaveform;
  final ValueChanged<VibeId> onVibe;
  final ValueChanged<Color> onAccent;

  const NuraShell({
    super.key,
    required this.vibe,
    required this.accent,
    required this.screen,
    required this.waveform,
    required this.onNav,
    required this.onVibe,
    required this.onAccent,
    required this.onWaveform,
  });

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding;
    final safeTop = inset.top > 0 ? inset.top : 16.0;
    final safeBottom = inset.bottom > 0 ? inset.bottom : 16.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: vibe.bgGradient),
        child: Stack(children: [
          if (vibe.bloom)
            Positioned(
              top: -120,
              right: -80,
              child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                        colors: [accent.withOpacity(0.33), Colors.transparent]),
                  )),
            ),

          // Active screen
          Positioned.fill(
            child: buildCurrentScreen(
              screen: screen,
              vibe: vibe,
              accent: accent,
              waveform: waveform,
              safeTop: safeTop,
              safeBottom: safeBottom,
            ),
          ),

          // Bottom nav — flush
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNav(
                active: screen,
                onChange: onNav,
                vibe: vibe,
                accent: accent,
                safeBottom: safeBottom),
          ),
        ]),
      ),
    );
  }
}
