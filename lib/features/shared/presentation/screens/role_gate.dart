import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/user_role.dart';
import '../providers/user_role_provider.dart';
import '../../../artist/shell/artist_shell.dart';
import '../../../label/shell/label_shell.dart';
import '../../../user/shell/user_shell.dart';

class RoleGate extends ConsumerWidget {
  final NuraVibe vibe;
  final Color accent;
  final String waveform;

  const RoleGate({
    super.key,
    required this.vibe,
    required this.accent,
    required this.waveform,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);

    return switch (role) {
      UserRole.artist => ArtistShell(
          vibe: vibe,
          accent: accent,
          waveform: waveform,
        ),
      UserRole.label => LabelShell(
          vibe: vibe,
          accent: accent,
          waveform: waveform,
        ),
      UserRole.user => UserShell(
          vibe: vibe,
          accent: accent,
          waveform: waveform,
        ),
    };
  }
}
