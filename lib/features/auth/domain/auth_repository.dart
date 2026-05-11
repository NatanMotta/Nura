import '../../shared/domain/user_role.dart';
import 'auth_user.dart';

abstract class AuthRepository {
  Stream<AppAuthUser?> authStateChanges();
  Future<AppAuthUser?> getCurrentUser();
  Future<void> signInWithPassword({required String email, required String password});
  Future<void> signUpWithPassword({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
  });
  Future<void> signOut();
}
