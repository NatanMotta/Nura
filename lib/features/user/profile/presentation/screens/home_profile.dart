import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/services/supabase_bootstrap.dart';
import '../../../../../core/widgets/glass.dart';
import '../../../../../core/widgets/mono.dart';
import '../../../../auth/domain/auth_user.dart';
import '../../../../auth/presentation/auth_providers.dart';
import '../../../../shared/domain/user_role.dart';
import 'profile_settings_screen.dart';

class HomeProfile extends ConsumerStatefulWidget {
  final NuraVibe vibe;
  final Color accent;
  final double safeTop, safeBottom;

  const HomeProfile({
    super.key,
    required this.vibe,
    required this.accent,
    required this.safeTop,
    required this.safeBottom,
  });

  @override
  ConsumerState<HomeProfile> createState() => _HomeProfileState();
}

class _HomeProfileState extends ConsumerState<HomeProfile> {
  bool _loading = true;
  AppAuthUser? _authUser;
  String? _displayName;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final authUser = await ref.read(authRepositoryProvider).getCurrentUser();
      String? displayName;
      String? username;

      if (authUser != null && SupabaseBootstrap.isInitialized) {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('display_name,username')
            .eq('id', authUser.id)
            .maybeSingle();
        displayName = row?['display_name'] as String?;
        username = row?['username'] as String?;
      }

      if (!mounted) return;
      setState(() {
        _authUser = authUser;
        _displayName = displayName;
        _username = username;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _roleLabel(UserRole? role) {
    return switch (role) {
      UserRole.artist => 'Artist',
      UserRole.label => 'Label',
      UserRole.user => 'User',
      null => 'Guest',
    };
  }

  String get _name {
    if (_displayName != null && _displayName!.trim().isNotEmpty) {
      return _displayName!.trim();
    }
    final email = _authUser?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Utente';
  }

  String get _handle {
    if (_username != null && _username!.trim().isNotEmpty) {
      return '@${_username!.trim()}';
    }
    final email = _authUser?.email;
    if (email != null && email.contains('@')) {
      return '@${email.split('@').first}';
    }
    return '@guest';
  }

  String get _initials {
    final source = _name.trim();
    if (source.isEmpty) return 'U';
    final parts = source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, widget.safeTop, 16, 100 + widget.safeBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profilo',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: NuraBrand.mint,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileSettingsScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: NuraBrand.mintAlpha(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Glass(
            vibe: widget.vibe,
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [widget.accent, NuraBrand.deep],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: NuraBrand.mint,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _handle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: NuraBrand.mintAlpha(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: NuraBrand.mintAlpha(0.10),
                                    border: Border.all(color: widget.vibe.cardBorder),
                                  ),
                                  child: Mono(
                                    _roleLabel(_authUser?.role),
                                    color: NuraBrand.mint,
                                    size: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _authUser?.email ?? 'Nessun account collegato',
                        style: TextStyle(
                          fontSize: 12,
                          color: NuraBrand.mintAlpha(0.65),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Glass(
            vibe: widget.vibe,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                _ProfileTile(
                  icon: Icons.person_outline,
                  title: 'Dettagli account',
                  subtitle: 'Nome, username e ruolo',
                  onTap: () {},
                ),
                Divider(height: 1, color: widget.vibe.cardBorder),
                _ProfileTile(
                  icon: Icons.notifications_none,
                  title: 'Notifiche',
                  subtitle: 'Preferenze e avvisi',
                  onTap: () {},
                ),
                Divider(height: 1, color: widget.vibe.cardBorder),
                _ProfileTile(
                  icon: Icons.settings_outlined,
                  title: 'Impostazioni',
                  subtitle: 'Apri impostazioni profilo',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: NuraBrand.mintAlpha(0.9), size: 20),
      title: Text(
        title,
        style: const TextStyle(
          color: NuraBrand.mint,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: NuraBrand.mintAlpha(0.55), fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: NuraBrand.mintAlpha(0.4)),
      onTap: onTap,
      dense: true,
    );
  }
}
