import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../artist/shell/artist_shell.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../label/shell/label_shell.dart';
import '../../../user/shell/user_shell.dart';
import '../../domain/user_role.dart';
import '../providers/user_role_provider.dart';
import 'mock_role_login_screen.dart';

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
    final authState = ref.watch(authStateProvider);
    final mockRole = ref.watch(userRoleProvider);

    return authState.when(
      data: (authUser) {
        final role = authUser?.role ?? mockRole;
        if (role == null) return const MockRoleLoginScreen();

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
      },
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Auth error: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
