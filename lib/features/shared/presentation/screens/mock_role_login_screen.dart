import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/supabase_bootstrap.dart';
import '../../domain/user_role.dart';
import '../providers/user_role_provider.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../discovery/swipe/data/remote_tracks_service.dart';
import '../../../discovery/swipe/presentation/screens/home_feed.dart';

class MockRoleLoginScreen extends ConsumerStatefulWidget {
  const MockRoleLoginScreen({super.key});

  @override
  ConsumerState<MockRoleLoginScreen> createState() => _MockRoleLoginScreenState();
}

class _MockRoleLoginScreenState extends ConsumerState<MockRoleLoginScreen> {
  UserRole? _loadingRole;

  Future<void> _handleLogin(UserRole role, MockProfileIdentity identity) async {
    if (_loadingRole != null) return;
    setState(() => _loadingRole = role);

    try {
      // Pre-warm the cache of tracks so HomeFeed is instantly ready (No Blue Screen)
      final tracks = await const RemoteTracksService().fetchTracks();
      if (tracks.isNotEmpty) {
        final firstCover = tracks[0].coverAsset;
        if (firstCover != null && firstCover.startsWith('assets/')) {
          await HeavyComputations.extractDominantColorSafe(firstCover);
          if (mounted) {
            await precacheImage(AssetImage(firstCover), context);
          }
        }
      }
      // Small artificial delay to guarantee frame rendering
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      ref.read(userRoleProvider.notifier).setRole(role);
      ref.read(mockProfileIdentityProvider.notifier).setIdentity(identity);
    } finally {
      if (mounted) {
        setState(() => _loadingRole = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    role: UserRole.artist,
                    label: 'Entra come Artista',
                    icon: Icons.mic_none,
                    identity: const MockProfileIdentity(
                      displayName: 'Luca Neon',
                      username: 'luca.neon',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _roleButton(
                    role: UserRole.user,
                    label: 'Entra come Utente',
                    icon: Icons.person_outline,
                    identity: const MockProfileIdentity(
                      displayName: 'Giulia Wave',
                      username: 'giulia.wave',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _roleButton(
                    role: UserRole.label,
                    label: 'Entra come Etichetta',
                    icon: Icons.apartment_outlined,
                    identity: const MockProfileIdentity(
                      displayName: 'Marta A&R',
                      username: 'marta.label',
                    ),
                  ),
                  if (supabaseReady) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _loadingRole != null ? null : () {
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

  Widget _roleButton({
    required UserRole role,
    required String label,
    required IconData icon,
    required MockProfileIdentity identity,
  }) {
    final isLoading = _loadingRole == role;
    final isDisabled = _loadingRole != null && _loadingRole != role;

    return ElevatedButton.icon(
      onPressed: isDisabled || isLoading ? null : () => _handleLogin(role, identity),
      icon: isLoading 
          ? const SizedBox(
              width: 18, 
              height: 18, 
              child: CircularProgressIndicator(strokeWidth: 2, color: NuraBrand.deepest)
            )
          : Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(isLoading ? 'Caricamento feed...' : label),
      ),
    );
  }
}
