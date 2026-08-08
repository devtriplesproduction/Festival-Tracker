import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._repo);

  final AuthRepository _repo;

  AppUser? user;
  List<AppUser> team = [];
  bool ready = false;
  String? error;
  StreamSubscription<AppUser?>? _authSub;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  bool get isLoggedIn => user != null;
  UserRole? get role => user?.role;

  Future<void> init() async {
    await _repo.seedDefaultAdminIfNeeded();
    user = await _repo.currentUser();
    team = await _repo.loadUsers();
    ready = true;
    notifyListeners();

    _authSub = _repo.authStateChanges.listen((u) async {
      user = u;
      team = await _repo.loadUsers();
      notifyListeners();
    });
  }

  Future<bool> login(String username, String password) async {
    error = null;
    try {
      final result = await _repo.login(username, password);
      if (result == null) {
        error = 'Invalid username or password';
        notifyListeners();
        return false;
      }
      user = result;
      team = await _repo.loadUsers();
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Bad state: ', '').replaceFirst('Invalid argument(s): ', '');
      notifyListeners();
      return false;
    }
  }

  /// Admin-only Google Sign-In. Returns `true` on success, `false` on cancel
  /// or authorization failure (see [error]).
  Future<bool> loginWithGoogle() async {
    error = null;
    try {
      final result = await _repo.loginWithGoogle();
      if (result == null) {
        // User cancelled the Google account picker.
        notifyListeners();
        return false;
      }
      user = result;
      team = await _repo.loadUsers();
      notifyListeners();
      return true;
    } catch (e) {
      error = e
          .toString()
          .replaceFirst('Bad state: ', '')
          .replaceFirst('Invalid argument(s): ', '')
          .replaceFirst('Exception: ', '');
      user = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    user = null;
    notifyListeners();
  }

  Future<void> refreshTeam() async {
    team = await _repo.loadUsers();
    notifyListeners();
  }

  Future<void> createUser({
    required String username,
    required String email,
    required String displayName,
    required String password,
    required UserRole role,
  }) async {
    await _repo.createUser(
      username: username,
      email: email,
      displayName: displayName,
      password: password,
      role: role,
    );
    await refreshTeam();
  }

  Future<void> setPassword(String userId, String password) async {
    await _repo.setPassword(userId, password);
    await refreshTeam();
  }

  Future<void> deactivateUser(String userId) async {
    final me = user;
    if (me == null) return;
    await _repo.deactivateUser(userId, currentUserId: me.id);
    await refreshTeam();
  }

  Future<void> reactivateUser(String userId) async {
    await _repo.reactivateUser(userId);
    await refreshTeam();
  }
}
