import '../../models/app_user.dart';
import '../../models/user_role.dart';

abstract class AuthRepository {
  static const defaultAdminUsername = 'admin';
  static const defaultAdminPassword = 'admin123';

  Future<List<AppUser>> loadUsers();

  Future<void> seedDefaultAdminIfNeeded();

  Future<AppUser?> currentUser();

  Stream<AppUser?> get authStateChanges;

  /// Email/password (or username/password) login for Designers, Managers,
  /// QC, and Admins who use password auth.
  Future<AppUser?> login(String emailOrUsername, String password);

  /// Google Sign-In — **Admin only**. Never auto-creates accounts.
  ///
  /// Returns the Admin [AppUser] on success, `null` if the user cancels,
  /// or throws [StateError] when the account is unauthorized.
  Future<AppUser?> loginWithGoogle();

  Future<void> logout();

  Future<AppUser> createUser({
    required String username,
    required String email,
    required String displayName,
    required String password,
    required UserRole role,
  });

  Future<void> updateUser(AppUser user);

  Future<void> setPassword(String userId, String newPassword);

  Future<void> forgotPassword(String email);

  Future<void> deactivateUser(String userId, {required String currentUserId});

  Future<void> reactivateUser(String userId);
}
