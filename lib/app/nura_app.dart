import 'package:flutter/material.dart';

import '../features/shared/presentation/screens/role_gate.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class NuraApp extends StatefulWidget {
  const NuraApp({super.key});

  @override
  State<NuraApp> createState() => _NuraAppState();
}

class _NuraAppState extends State<NuraApp> {
  VibeId vibeId = VibeId.premium;
  Color accent = NuraBrand.pink;
  String waveform = 'bars'; // bars · wave · pulse

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nura',
      debugShowCheckedModeBanner: false,
      theme: buildNuraTheme(),
      home: RoleGate(
        vibe: NuraVibe.of(vibeId),
        accent: accent,
        waveform: waveform,
      ),
    );
  }
}
