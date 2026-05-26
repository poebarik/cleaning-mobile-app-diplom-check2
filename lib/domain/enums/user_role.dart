// В UserRoleExtension добавьте manager
enum UserRole {
  client,
  cleaner,
  manager,  // NEW
  admin,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.client:
        return 'CLIENT';
      case UserRole.cleaner:
        return 'CLEANER';
      case UserRole.manager:  // NEW
        return 'MANAGER';
      case UserRole.admin:
        return 'ADMIN';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'CLIENT':
        return UserRole.client;
      case 'CLEANER':
        return UserRole.cleaner;
      case 'MANAGER':  // NEW
        return UserRole.manager;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.client;
    }
  }
}