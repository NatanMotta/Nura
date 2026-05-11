import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/supabase_bootstrap.dart';
import '../../domain/user_role.dart';
import '../providers/user_role_provider.dart';
import '../../../auth/presentation/screens/auth_screen.dart';

class MockRoleLoginScreen extends ConsumerWidget {
  const MockRoleLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabaseReady = SupabaseBootstrap.isInitialized;

    return Scaffold(
      backgroundColor: NuraBrand.deepest,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nura Login Mock',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: NuraBrand.mint,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entra rapidamente con un ruolo per testare shell e flussi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: NuraBrand.mintAlpha(0.72)),
                  ),
                  const SizedBox(height: 24),
                  _roleButton(
                    context,
                    ref,
                    role: UserRole.artist,
                    label: 'Entra come Artista',
                    icon: Icons.mic_none,
                  ),
                  const SizedBox(height: 10),
                  _roleButton(
                    context,
                    ref,
                    role: UserRole.user,
                    label: 'Entra come Utente',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 10),
                  _roleButton(
                    context,
                    ref,
                    role: UserRole.label,
                    label: 'Entra come Etichetta',
                    icon: Icons.apartment_outlined,
                  ),
                  if (supabaseReady) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AuthScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Vai al login email/password'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(
    BuildContext context,
    WidgetRef ref, {
    required UserRole role,
    required String label,
    required IconData icon,
  }) {
    return ElevatedButton.icon(
      onPressed: () {
        ref.read(userRoleProvider.notifier).setRole(role);
      },
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(label),
      ),
    );
  }
}
