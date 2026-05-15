import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../auth/presentation/auth_providers.dart';
import '../../../../shared/presentation/providers/user_role_provider.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _logoutAccount() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signOut();
      ref.read(userRoleProvider.notifier).clear();
      ref.read(mockProfileIdentityProvider.notifier).clear();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _exitMockRole() {
    ref.read(userRoleProvider.notifier).clear();
    ref.read(mockProfileIdentityProvider.notifier).clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NuraBrand.deepest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: NuraBrand.mint,
        title: const Text('Impostazioni'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: NuraBrand.deepMidAlpha(0.55),
              leading: const Icon(Icons.person_off_outlined, color: NuraBrand.mint),
              title: const Text('Esci dal ruolo mock',
                  style: TextStyle(color: NuraBrand.mint)),
              subtitle: Text(
                'Torna alla schermata Login Mock',
                style: TextStyle(color: NuraBrand.mintAlpha(0.65)),
              ),
              onTap: _loading ? null : _exitMockRole,
              ),
            const SizedBox(height: 12),
            _mockSettingTile(
              icon: Icons.badge_outlined,
              title: 'Nome profilo',
              subtitle: 'Modifica display name (mock UI)',
            ),
            const SizedBox(height: 10),
            _mockSettingTile(
              icon: Icons.short_text_rounded,
              title: 'Bio',
              subtitle: 'Aggiungi o aggiorna bio profilo (mock UI)',
            ),
            const SizedBox(height: 10),
            _mockSettingTile(
              icon: Icons.image_outlined,
              title: 'Immagine profilo',
              subtitle: 'Carica/ritaglia avatar (mock UI)',
            ),
            const SizedBox(height: 10),
            _mockSettingTile(
              icon: Icons.alternate_email_rounded,
              title: 'Username',
              subtitle: 'Aggiorna handle @utente (mock UI)',
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: NuraBrand.deepMidAlpha(0.55),
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout account',
                  style: TextStyle(color: NuraBrand.mint)),
              subtitle: Text(
                'Disconnette l\'account Supabase',
                style: TextStyle(color: NuraBrand.mintAlpha(0.65)),
              ),
              onTap: _loading ? null : _logoutAccount,
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mockSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: NuraBrand.deepMidAlpha(0.45),
      leading: Icon(icon, color: NuraBrand.mint),
      title: Text(title, style: const TextStyle(color: NuraBrand.mint)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: NuraBrand.mintAlpha(0.65)),
      ),
      trailing: Icon(Icons.chevron_right, color: NuraBrand.mintAlpha(0.7)),
      onTap: _loading
          ? null
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funzione in mock, non ancora attiva')),
              );
            },
    );
  }
}
