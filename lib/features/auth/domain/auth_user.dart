import '../../shared/domain/user_role.dart';

class AppAuthUser {
  final String id;
  final String? email;
  final UserRole role;

  const AppAuthUser({
    required this.id,
    required this.email,
    required this.role,
  });
}
