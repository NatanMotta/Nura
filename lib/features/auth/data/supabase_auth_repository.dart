import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_bootstrap.dart';
import '../../shared/domain/user_role.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient? get _client =>
      SupabaseBootstrap.isInitialized ? Supabase.instance.client : null;

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        'SUPABASE_NOT_INITIALIZED: avvia con --dart-define SUPABASE_URL e SUPABASE_ANON_KEY',
      );
    }
    return client;
  }

  @override
  Stream<AppAuthUser?> authStateChanges() async* {
    final client = _client;
    if (client == null) {
      yield null;
      return;
    }

    final current = await getCurrentUser();
    yield current;

    yield* client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      await _ensureProfile(user);
      return _mapUserWithProfileLookup(user);
    });
  }

  @override
  Future<AppAuthUser?> getCurrentUser() async {
    final client = _client;
    if (client == null) return null;
    final user = client.auth.currentUser;
    if (user == null) return null;

    await _ensureProfile(user);
    return _mapUserWithProfileLookup(user);
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    final result = await client.auth
        .signInWithPassword(email: email, password: password);
    final user = result.user;
    if (user != null) {
      await _ensureProfile(user);
    }
  }

  @override
  Future<void> signUpWithPassword({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
  }) async {
    final client = _requireClient();
    final roleValue = switch (role) {
      UserRole.artist => 'artist',
      UserRole.label => 'label',
      UserRole.user => 'user',
    };

    final result = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'requested_role': roleValue,
        if (displayName != null && displayName.trim().isNotEmpty)
          'display_name': displayName.trim(),
      },
    );

    final user = result.user;
    if (user != null && result.session != null) {
      await _ensureProfile(
        user,
        role: role,
        displayName: displayName,
      );
    }

    // Se Confirm email è attivo, Supabase ritorna user ma session = null.
    // In questo caso il signup è riuscito e l'utente deve confermare via email.
    if (user != null && result.session == null) {
      throw StateError(
        'EMAIL_CONFIRMATION_REQUIRED: account creato. Conferma la mail e poi fai login.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    final client = _requireClient();
    await client.auth.signOut();
  }

  Future<AppAuthUser> _mapUserWithProfileLookup(User user) async {
    final client = _client;
    if (client == null) {
      return AppAuthUser(id: user.id, email: user.email, role: UserRole.user);
    }

    try {
      final row = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final roleRaw = (row?['role'] as String?)?.toLowerCase();
      final role = _toRole(roleRaw);

      return AppAuthUser(
        id: user.id,
        email: user.email,
        role: role,
      );
    } catch (_) {
      return AppAuthUser(id: user.id, email: user.email, role: UserRole.user);
    }
  }

  Future<void> _ensureProfile(
    User user, {
    UserRole role = UserRole.user,
    String? displayName,
  }) async {
    final client = _client;
    if (client == null) return;

    try {
      final existing = await client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing != null) return;

      final metadataRole = (user.userMetadata?['requested_role'] as String?)
          ?.toLowerCase();
      final resolvedRole = metadataRole == null ? role : _toRole(metadataRole);
      final metadataDisplayName = user.userMetadata?['display_name'] as String?;

      await client.from('profiles').insert({
        'id': user.id,
        'role': switch (resolvedRole) {
          UserRole.artist => 'artist',
          UserRole.label => 'label',
          UserRole.user => 'user',
        },
        'display_name': metadataDisplayName ??
            displayName ??
            (user.email ?? 'user').split('@').first,
      });
    } catch (_) {
      // noop: la creazione profilo dipende da policy/permessi ambiente
    }
  }

  UserRole _toRole(String? raw) {
    return switch (raw) {
      'artist' => UserRole.artist,
      'label' => UserRole.label,
      _ => UserRole.user,
    };
  }
}
