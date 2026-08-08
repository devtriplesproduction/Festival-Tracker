import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/app_user.dart';
import '../../models/user_role.dart';
import 'auth_repository.dart';

/// Local account store — Admin creates users; no Google / OAuth.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._prefs);

  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  static const _kUsers = 'auth_users_v1';
  static const _kPasswords = 'auth_passwords_v1';
  static const _kSession = 'auth_session_user_id_v1';
  static const _kSeeded = 'auth_seeded_default_admin_v1';

  /// Default TSP admin (change password after first login).
  static const defaultAdminUsername = 'admin';
  static const defaultAdminPassword = 'admin123';

  final _authStateController = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  Future<List<AppUser>> loadUsers() async {
    final raw = _prefs.getString(_kUsers);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => AppUser.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _saveUsers(List<AppUser> users) async {
    final encoded = jsonEncode(users.map((u) => u.toMap()).toList());
    await _prefs.setString(_kUsers, encoded);
  }

  Future<Map<String, String>> _loadPasswords() async {
    final raw = _prefs.getString(_kPasswords);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> _savePasswords(Map<String, String> passwords) async {
    await _prefs.setString(_kPasswords, jsonEncode(passwords));
  }

  String hashPassword(String password, {String salt = 'tsp_festival_tracker_v1'}) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  @override
  Future<void> seedDefaultAdminIfNeeded() async {
    final currentUsers = await loadUsers();
    if (_prefs.getBool(_kSeeded) == true && currentUsers.isNotEmpty) return;
    final hasAdmin = currentUsers.any((u) => u.role == UserRole.admin);
    if (!hasAdmin) {
      final id = _uuid.v4();
      currentUsers.add(
        AppUser(
          id: id,
          username: defaultAdminUsername,
          email: 'admin@local.test',
          displayName: 'TSP Admin',
          role: UserRole.admin,
        ),
      );
      final passwords = await _loadPasswords();
      passwords[id] = hashPassword(defaultAdminPassword);
      await _savePasswords(passwords);
      await _saveUsers(currentUsers);
    }
    await _prefs.setBool(_kSeeded, true);
  }

  @override
  Future<AppUser?> currentUser() async {
    final id = _prefs.getString(_kSession);
    if (id == null) return null;
    try {
      final currentUsers = await loadUsers();
      return currentUsers.firstWhere((u) => u.id == id && u.isActive);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppUser?> login(String emailOrUsername, String password) async {
    final uname = emailOrUsername.trim().toLowerCase();
    final users = await loadUsers();
    AppUser? match;
    for (final u in users) {
      if ((u.username.toLowerCase() == uname || u.email.toLowerCase() == uname) && u.isActive) {
        match = u;
        break;
      }
    }
    if (match == null) return null;
    
    final passwords = await _loadPasswords();
    if (passwords[match.id] != hashPassword(password)) return null;
    
    final withLogin = match.copyWith(lastLogin: DateTime.now());
    final idx = users.indexWhere((u) => u.id == match!.id);
    if (idx >= 0) {
      users[idx] = withLogin;
      await _saveUsers(users);
    }

    await _prefs.setString(_kSession, withLogin.id);
    _authStateController.add(withLogin);
    return withLogin;
  }

  @override
  Future<AppUser?> loginWithGoogle() async {
    throw StateError(
      'Google Sign-In is only available in cloud mode with Firebase. '
      'Local mode supports email/password only.',
    );
  }

  @override
  Future<void> logout() async {
    await _prefs.remove(_kSession);
    _authStateController.add(null);
  }

  @override
  Future<AppUser> createUser({
    required String username,
    required String email,
    required String displayName,
    required String password,
    required UserRole role,
  }) async {
    final uname = username.trim().toLowerCase();
    final userEmail = email.trim().toLowerCase();
    if (uname.isEmpty) throw ArgumentError('Username required');
    if (userEmail.isEmpty) throw ArgumentError('Email required');
    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
    }
    final users = await loadUsers();
    if (users.any((u) => u.username.toLowerCase() == uname)) {
      throw StateError('Username already exists');
    }
    if (users.any((u) => u.email.toLowerCase() == userEmail)) {
      throw StateError('Email already exists');
    }
    final id = _uuid.v4();
    final user = AppUser(
      id: id,
      username: uname,
      email: userEmail,
      displayName: displayName.trim().isEmpty ? uname : displayName.trim(),
      role: role,
    );
    users.add(user);
    
    final passwords = await _loadPasswords();
    passwords[id] = hashPassword(password);
    await _savePasswords(passwords);
    await _saveUsers(users);
    
    return user;
  }

  @override
  Future<void> updateUser(AppUser user) async {
    final users = await loadUsers();
    final i = users.indexWhere((u) => u.id == user.id);
    if (i < 0) throw StateError('User not found');
    users[i] = user;
    await _saveUsers(users);
  }

  @override
  Future<void> setPassword(String userId, String newPassword) async {
    if (newPassword.length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
    }
    final passwords = await _loadPasswords();
    passwords[userId] = hashPassword(newPassword);
    await _savePasswords(passwords);
  }

  @override
  Future<void> forgotPassword(String email) async {
    // Cannot send real emails in local mode, so just simulate success.
    final users = await loadUsers();
    if (!users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      throw StateError('User not found');
    }
    // Simulation only.
  }

  @override
  Future<void> deactivateUser(String userId, {required String currentUserId}) async {
    if (userId == currentUserId) throw StateError('Cannot deactivate yourself');
    final users = await loadUsers();
    final i = users.indexWhere((u) => u.id == userId);
    if (i < 0) throw StateError('User not found');
    users[i] = users[i].copyWith(isActive: false);
    await _saveUsers(users);
  }

  @override
  Future<void> reactivateUser(String userId) async {
    final users = await loadUsers();
    final i = users.indexWhere((u) => u.id == userId);
    if (i < 0) throw StateError('User not found');
    users[i] = users[i].copyWith(isActive: true);
    await _saveUsers(users);
  }
}
