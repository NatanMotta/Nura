import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

final authStateProvider = StreamProvider<AppAuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
