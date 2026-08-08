import 'package:festival_tracker/data/repositories/local_auth_repository.dart';
import 'package:festival_tracker/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default admin seeds and login works', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalAuthRepository(prefs);
    await repo.seedDefaultAdminIfNeeded();

    final bad = await repo.login('admin', 'wrong');
    expect(bad, isNull);

    final user = await repo.login('admin', 'admin123');
    expect(user, isNotNull);
    expect(user!.role, UserRole.admin);
    expect(user.lastLogin, isNotNull);
  });

  test('admin can create designer account', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalAuthRepository(prefs);
    await repo.seedDefaultAdminIfNeeded();

    final designer = await repo.createUser(
      username: 'test_designer',
      email: 'test_designer@test.com',
      displayName: 'Test Designer',
      password: 'password123',
      role: UserRole.designer,
    );
    expect(designer.role, UserRole.designer);

    final login = await repo.login('test_designer', 'password123');
    expect(login?.displayName, 'Test Designer');
  });

  test('Google Sign-In is unavailable in local mode', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalAuthRepository(prefs);
    await repo.seedDefaultAdminIfNeeded();

    expect(
      () => repo.loginWithGoogle(),
      throwsA(isA<StateError>()),
    );
  });
}
