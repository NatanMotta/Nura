import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/supabase_bootstrap.dart';
import '../../../shared/domain/user_role.dart';
import '../auth_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  UserRole _selectedRole = UserRole.user;
  bool _isSignUpMode = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool isSignUp}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      if (isSignUp) {
        await repo.signUpWithPassword(
          email: _email.text.trim(),
          password: _password.text,
          role: _selectedRole,
          displayName: _displayName.text.trim().isEmpty
              ? null
              : _displayName.text.trim(),
        );
      } else {
        await repo.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } catch (e) {
      setState(() {
        final raw = e.toString();
        if (raw.contains('EMAIL_CONFIRMATION_REQUIRED')) {
          _error =
              'Account creato. Controlla la tua email, conferma il link e poi fai login.';
          _isSignUpMode = false;
        } else {
          _error = raw;
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
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
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nura Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: NuraBrand.mint,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!supabaseReady)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Supabase non inizializzato. Avvia con --dart-define SUPABASE_URL e SUPABASE_ANON_KEY.',
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                    ),
                  if (_isSignUpMode) ...[
                    TextField(
                      controller: _displayName,
                      style: const TextStyle(color: NuraBrand.mint),
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        labelStyle: TextStyle(color: NuraBrand.mint),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      value: _selectedRole,
                      dropdownColor: NuraBrand.deep,
                      style: const TextStyle(color: NuraBrand.mint),
                      decoration: const InputDecoration(
                        labelText: 'Ruolo',
                        labelStyle: TextStyle(color: NuraBrand.mint),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: UserRole.user,
                          child: Text('User'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.artist,
                          child: Text('Artist'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.label,
                          child: Text('Label / Curatore'),
                        ),
                      ],
                      onChanged: _loading
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _selectedRole = value);
                            },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: NuraBrand.mint),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: NuraBrand.mint),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    style: const TextStyle(color: NuraBrand.mint),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: NuraBrand.mint),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: (_loading || !supabaseReady)
                        ? null
                        : () => _submit(isSignUp: _isSignUpMode),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isSignUpMode ? 'Create account' : 'Login'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: (_loading || !supabaseReady)
                        ? null
                        : () => setState(() => _isSignUpMode = !_isSignUpMode),
                    child: Text(
                      _isSignUpMode
                          ? 'Ho gia un account'
                          : 'Non hai un account? Sign up',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
