/// Persisted account roles. Keep wire names stable for Firestore and SQLite.
enum UserRole { customer, store, superAdmin, courier }

extension UserRoleDetails on UserRole {
  String get label => switch (this) {
        UserRole.customer => 'عميل',
        UserRole.store => 'متجر',
        UserRole.superAdmin => 'سوبر أدمن',
        UserRole.courier => 'مندوب',
      };
  bool get canSelfRegister =>
      this == UserRole.customer || this == UserRole.store;
}

UserRole? parseUserRole(String? value) {
  if (value == 'admin') return UserRole.superAdmin;
  for (final role in UserRole.values) {
    if (role.name == value) return role;
  }
  return null;
}
