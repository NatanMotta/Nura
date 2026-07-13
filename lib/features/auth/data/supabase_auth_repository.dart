import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
    final result =
        await client.auth.signInWithPassword(email: email, password: password);
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
      UserRole.curator => 'curator',
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
  Future<void> signInWithGoogle() async {
    const webClientId = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue:
          '93053908417-u6bpd1h42k3tobgacujlfnl7kcs5h6ia.apps.googleusercontent.com',
    );
    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign In annullato');

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw Exception('Token mancanti dal Google Sign In');
    }

    final client = _requireClient();
    final response = await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final user = response.user;
    if (user == null) throw Exception('Login Supabase con Google fallito');

    await _ensureProfile(user);
  }

  @override
  Future<void> signInWithApple() async {
    final client = _requireClient();
    final rawNonce = client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) throw Exception('Token mancante da Apple Sign In');

    final response = await client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    final user = response.user;
    if (user == null) throw Exception('Login Supabase con Apple fallito');

    await _ensureProfile(
      user,
      displayName: credential.givenName != null
          ? '${credential.givenName} ${credential.familyName ?? ''}'
          : null,
    );
  }

  @override
  Future<void> signOut() async {
    final client = _requireClient();
    await GoogleSignIn().signOut().catchError((_) => null);
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
          .select('role, avatar_url, bio')
          .eq('id', user.id)
          .maybeSingle();

      final roleRaw = (row?['role'] as String?)?.toLowerCase();
      final role = _toRole(roleRaw);

      final avatarUrl = row?['avatar_url'] as String?;
      final bio = row?['bio'] as String?;
      final isComplete = avatarUrl != null &&
          avatarUrl.isNotEmpty &&
          bio != null &&
          bio.isNotEmpty;

      return AppAuthUser(
        id: user.id,
        email: user.email,
        role: role,
        isProfileComplete: isComplete,
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

      final metadataRole =
          (user.userMetadata?['requested_role'] as String?)?.toLowerCase();
      final resolvedRole = metadataRole == null ? role : _toRole(metadataRole);
      final metadataDisplayName = user.userMetadata?['display_name'] as String?;

      await client.from('profiles').insert({
        'id': user.id,
        'role': switch (resolvedRole) {
          UserRole.artist => 'artist',
          UserRole.curator => 'curator',
          UserRole.user => 'user',
        },
        'display_name': metadataDisplayName ??
            displayName ??
            (user.email ?? 'user').split('@').first,
      });
    } catch (e) {
      debugPrint('[Auth] _ensureProfile fallito: $e');
    }
  }

  UserRole _toRole(String? raw) {
    return switch (raw) {
      'artist' => UserRole.artist,
      'curator' => UserRole.curator,
      _ => UserRole.user,
    };
  }
}
