import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/user_role.dart';

class UserRoleNotifier extends StateNotifier<UserRole?> {
  UserRoleNotifier() : super(null);

  void setRole(UserRole role) {
    state = role;
  }

  void clear() {
    state = null;
  }
}

final userRoleProvider = StateNotifierProvider<UserRoleNotifier, UserRole?>(
  (ref) => UserRoleNotifier(),
);
