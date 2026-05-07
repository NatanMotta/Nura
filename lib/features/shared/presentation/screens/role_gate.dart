import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../artist/shell/artist_shell.dart';
import '../../../label/shell/label_shell.dart';
import '../../../user/shell/user_shell.dart';

enum MockRole { user, artist, label }

class RoleGate extends StatelessWidget {
  final MockRole role;
  final NuraVibe vibe;
  final Color accent;
  final String waveform;

  const RoleGate({
    super.key,
    this.role = MockRole.user,
    required this.vibe,
    required this.accent,
    required this.waveform,
  });

  @override
  Widget build(BuildContext context) {
    return switch (role) {
      MockRole.artist => ArtistShell(
          vibe: vibe,
          accent: accent,
          waveform: waveform,
        ),
      MockRole.label => LabelShell(
          vibe: vibe,
          accent: accent,
          waveform: waveform,
        ),
      MockRole.user => UserShell(
          vibe: vibe,
          accent: accent,
          waveform: waveform,
        ),
    };
  }
}
