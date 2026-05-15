import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/user_role.dart';

class MockProfileIdentity {
  final String displayName;
  final String username;

  const MockProfileIdentity({
    required this.displayName,
    required this.username,
  });
}

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

class MockProfileIdentityNotifier extends StateNotifier<MockProfileIdentity?> {
  MockProfileIdentityNotifier() : super(null);

  void setIdentity(MockProfileIdentity identity) {
    state = identity;
  }

  void clear() {
    state = null;
  }
}

final mockProfileIdentityProvider =
    StateNotifierProvider<MockProfileIdentityNotifier, MockProfileIdentity?>(
  (ref) => MockProfileIdentityNotifier(),
);
