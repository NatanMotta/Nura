import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/user_role.dart';

class UserRoleNotifier extends StateNotifier<UserRole> {
  UserRoleNotifier() : super(UserRole.user);

  void setRole(UserRole role) {
    state = role;
  }
}

final userRoleProvider = StateNotifierProvider<UserRoleNotifier, UserRole>(
  (ref) => UserRoleNotifier(),
);
