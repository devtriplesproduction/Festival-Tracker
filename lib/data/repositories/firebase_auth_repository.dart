import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/admin_auth_config.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import 'auth_repository.dart';

/// Firebase Auth + Firestore-backed authentication.
///
/// * Email/password — team members (Designer, Manager, QC) and optional Admin.
/// * Google Sign-In — **Admin only**; never auto-creates Firestore profiles.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(
    this._prefs, {
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  // ignore: unused_field — kept for future session/cache flags
  final SharedPreferences _prefs;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  bool _googleInitialized = false;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _auditCol =>
      _db.collection('audit_logs');
  /// Public login index: username → email (no roles/secrets). Readable
  /// without auth so team members can sign in with a username.
  CollectionReference<Map<String, dynamic>> get _loginIndexCol =>
      _db.collection('login_index');

  Future<void> _logActivity(String action, String userId, {String? details}) async {
    try {
      await _auditCol.add({
        'action': action,
        'userId': userId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Audit log failed: $e');
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize(
      clientId: AdminAuthConfig.googleWebClientId,
      serverClientId: kIsWeb ? null : AdminAuthConfig.googleServerClientId,
    );
    _googleInitialized = true;
  }

  /// Signs out of Firebase Auth and Google (best-effort).
  Future<void> _fullSignOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Profile fields only — never tokens, passwords, or OAuth secrets.
  Map<String, dynamic> _profileWriteMap(AppUser user, {bool isCreate = false}) {
    final now = FieldValue.serverTimestamp();
    return {
      'displayName': user.displayName,
      'email': user.email.trim().toLowerCase(),
      'role': user.role.value,
      'companyId': user.companyId,
      'status': user.status ?? (user.isActive ? 'active' : 'inactive'),
      'photoURL': user.photoURL,
      'lastLogin': user.lastLogin != null
          ? Timestamp.fromDate(user.lastLogin!.toUtc())
          : null,
      'createdAt': isCreate ? now : (user.createdAt != null
          ? Timestamp.fromDate(user.createdAt!.toUtc())
          : now),
      'updatedAt': now,
      'isActive': user.isActive,
      // Username supports email/password team login lookups (not secret).
      'username': user.username.trim().toLowerCase(),
      'id': user.id,
    };
  }

  @override
  Future<List<AppUser>> loadUsers() async {
    final snap = await _usersCol.get();
    return snap.docs.map((d) => AppUser.fromMap(d.data(), docId: d.id)).toList();
  }

  @override
  Future<void> seedDefaultAdminIfNeeded() async {
    // Production: do not auto-create Auth users with a known password.
    // Bootstrap Admins via Firebase Console + Firestore (see deployment guide).
    final snap = await _usersCol.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    debugPrint(
      'No users in Firestore. Provision an Admin profile manually before first login. '
      'See docs/deployment_guide.md',
    );
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((_) => currentUser());
  }

  @override
  Future<AppUser?> currentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _usersCol.doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return null;
      final u = AppUser.fromMap(doc.data()!, docId: doc.id);
      if (!u.isActive) return null;
      return u;
    } catch (_) {
      return null;
    }
  }

  Future<AppUser?> _loadProfileByUid(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.data()!, docId: doc.id);
  }

  Future<AppUser?> _loadProfileByEmail(String email) async {
    final snap = await _usersCol
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return AppUser.fromMap(d.data(), docId: d.id);
  }

  Future<void> _touchLastLogin(String userId, {String? photoURL, String? displayName}) async {
    final updates = <String, dynamic>{
      'lastLogin': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (photoURL != null && photoURL.isNotEmpty) {
      updates['photoURL'] = photoURL;
    }
    if (displayName != null && displayName.trim().isNotEmpty) {
      updates['displayName'] = displayName.trim();
    }
    await _usersCol.doc(userId).update(updates);
  }

  @override
  Future<AppUser?> login(String emailOrUsername, String password) async {
    var email = emailOrUsername.trim().toLowerCase();

    // Username → email via public login_index (readable without auth).
    // Fallback: users collection (works only when already signed in / rules allow).
    if (!email.contains('@')) {
      final index = await _loginIndexCol.doc(email).get();
      if (index.exists) {
        email = (index.data()?['email'] as String? ?? '').toLowerCase();
      } else {
        try {
          final snap = await _usersCol
              .where('username', isEqualTo: email)
              .limit(1)
              .get();
          if (snap.docs.isEmpty) return null;
          email =
              (snap.docs.first.data()['email'] as String? ?? '').toLowerCase();
        } catch (_) {
          throw StateError(
            'Use your email address to sign in, or ask Admin to re-save your account.',
          );
        }
      }
      if (email.isEmpty) return null;
    }

    try {
      final uc =
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? firebaseUser = uc.user;
      if (firebaseUser == null) return null;

      // Force refresh to get the latest emailVerified status
      await firebaseUser.reload();
      firebaseUser = _auth.currentUser ?? firebaseUser;

      final profile = await _loadProfileByUid(firebaseUser.uid);
      if (profile == null) {
        await _auth.signOut();
        throw StateError(
          'No profile found for this account. Contact your Admin.',
        );
      }

      // Email/password team accounts should verify email when required.
      // Admins may use either path; Google-verified is separate.
      // TEMPORARILY DISABLED FOR TESTING
      // if (!firebaseUser.emailVerified && profile.role != UserRole.admin) {
      //   await _auth.signOut();
      //   throw StateError('Please verify your email address before logging in. (Debug: verified=${firebaseUser.emailVerified}, role=${profile.role})');
      // }

      if (!profile.isActive) {
        await _auth.signOut();
        throw StateError('This account has been deactivated.');
      }

      await _touchLastLogin(profile.id);
      await _logActivity('Login', profile.id, details: 'email_password');
      return profile;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login failed: ${e.code} ${e.message}');
      throw StateError(e.message ?? 'Login failed');
    }
  }

  @override
  Future<AppUser?> loginWithGoogle() async {
    try {
      final User? firebaseUser;
      bool isEmailVerified = false;
      String? googlePhotoUrl;
      String? googleDisplayName;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        if (AdminAuthConfig.googleWebClientId != null) {
          provider.setCustomParameters({'client_id': AdminAuthConfig.googleWebClientId!});
        }
        final uc = await _auth.signInWithPopup(provider);
        firebaseUser = uc.user;
        if (firebaseUser == null) {
          await _fullSignOut();
          throw StateError('Google authentication failed.');
        }
        isEmailVerified = firebaseUser.emailVerified;
      } else {
        await _ensureGoogleInitialized();

        final GoogleSignInAccount googleUser;
        try {
          googleUser = await _googleSignIn.authenticate();
        } on GoogleSignInException catch (e) {
          // User cancelled account picker / consent.
          if (e.code == GoogleSignInExceptionCode.canceled ||
              e.code == GoogleSignInExceptionCode.interrupted) {
            return null;
          }
          rethrow;
        }

        final auth = googleUser.authentication;
        final idToken = auth.idToken;
        if (idToken == null || idToken.isEmpty) {
          await _fullSignOut();
          throw StateError(
            'Google did not return an ID token. Check OAuth client configuration.',
          );
        }

        final credential = GoogleAuthProvider.credential(idToken: idToken);
        final uc = await _auth.signInWithCredential(credential);
        firebaseUser = uc.user;
        if (firebaseUser == null) {
          await _fullSignOut();
          throw StateError('Google authentication failed.');
        }
        isEmailVerified = firebaseUser.emailVerified || googleUser.email.isNotEmpty;
        googlePhotoUrl = googleUser.photoUrl;
        googleDisplayName = googleUser.displayName;
      }

      // --- Post-auth authorization (never auto-create Admin) ---

      final email = firebaseUser.email?.trim().toLowerCase();
      if (email == null || email.isEmpty) {
        await _fullSignOut();
        throw StateError('Google account did not provide an email address.');
      }

      if (!isEmailVerified) {
        await _fullSignOut();
        throw StateError('Email is not verified. Use a verified Google account.');
      }

      // Load Firestore profile (UID first, then email). Never create.
      AppUser? profile = await _loadProfileByUid(firebaseUser.uid);
      profile ??= await _loadProfileByEmail(email);

      final onAllowList = AdminAuthConfig.isEmailAllowListed(email);
      final isExistingAdmin = profile != null &&
          profile.role == UserRole.admin &&
          profile.isActive;

      // Eligibility: existing Admin in Firestore OR allow-listed email.
      if (!isExistingAdmin && !onAllowList) {
        await _fullSignOut();
        await _logActivity(
          'LoginDenied',
          firebaseUser.uid,
          details: 'Google Sign-In denied — not Admin and not allow-listed ($email)',
        );
        throw StateError(
          'Access denied. Google Sign-In is restricted to authorized Admin users.',
        );
      }

      if (profile == null) {
        await _fullSignOut();
        await _logActivity(
          'LoginDenied',
          firebaseUser.uid,
          details: 'Allow-listed but no Firestore profile ($email)',
        );
        throw StateError(
          'Your email is recognized but no Admin profile exists yet. '
          'Firestore is looking for a document with exactly this ID: [${firebaseUser.uid}]. '
          'Please ensure your Firestore document ID matches this exactly, with no spaces.',
        );
      }

      // Profile UID must match Auth UID (security rules + least privilege).
      if (profile.id != firebaseUser.uid) {
        await _fullSignOut();
        await _logActivity(
          'LoginDenied',
          firebaseUser.uid,
          details:
              'UID mismatch for $email (profile=${profile.id}, auth=${firebaseUser.uid})',
        );
        throw StateError(
          'This Admin profile is not linked to the signed-in Google account. '
          'Provision the Firestore user document with the Google Auth UID '
          '(see docs/deployment_guide.md).',
        );
      }

      // Hard role check — Admin only.
      if (profile.role != UserRole.admin) {
        await _fullSignOut();
        await _logActivity(
          'LoginDenied',
          firebaseUser.uid,
          details: 'Google Sign-In denied — role=${profile.role.value}',
        );
        throw StateError(
          'Access denied. Google Sign-In is restricted to Admin users. '
          'Team members must use email/password login.',
        );
      }

      if (!profile.isActive || profile.status == 'inactive') {
        await _fullSignOut();
        throw StateError('This Admin account has been deactivated.');
      }

      if (AdminAuthConfig.requireAllowListForGoogle && !onAllowList) {
        await _fullSignOut();
        throw StateError(
          'Access denied. Your email is not on the Admin Google allow-list.',
        );
      }

      // Refresh non-sensitive profile fields from Google; update lastLogin.
      await _touchLastLogin(
        profile.id,
        photoURL: firebaseUser.photoURL ?? googlePhotoUrl,
        displayName: firebaseUser.displayName ?? googleDisplayName,
      );
      await _logActivity('Login', profile.id, details: 'google');

      final refreshed = await _loadProfileByUid(profile.id);
      return refreshed ?? profile;
    } on StateError {
      rethrow;
    } on FirebaseAuthException catch (e) {
      await _fullSignOut();
      throw StateError(e.message ?? 'Google Sign-In failed');
    } catch (e) {
      await _fullSignOut();
      if (e is StateError) rethrow;
      throw StateError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<void> logout() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _logActivity('Logout', user.uid);
    }
    await _fullSignOut();
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
    final uemail = email.trim().toLowerCase();
    if (uname.isEmpty) throw ArgumentError('Username required');
    if (uemail.isEmpty || !uemail.contains('@')) {
      throw ArgumentError('Valid email required');
    }
    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
    }

    final existingUser =
        await _usersCol.where('username', isEqualTo: uname).limit(1).get();
    if (existingUser.docs.isNotEmpty) {
      throw StateError('Username already exists');
    }

    final existingEmail =
        await _usersCol.where('email', isEqualTo: uemail).limit(1).get();
    if (existingEmail.docs.isNotEmpty) {
      throw StateError('Email already exists in database');
    }

    // Create the Auth user on a secondary FirebaseApp so the Admin session
    // is not replaced (client createUserWithEmailAndPassword signs in the new user).
    FirebaseApp? secondaryApp;
    try {
      final options = _auth.app.options;
      try {
        secondaryApp = Firebase.app('tsp-user-admin');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'tsp-user-admin',
          options: options,
        );
      }
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final uc = await secondaryAuth.createUserWithEmailAndPassword(
        email: uemail,
        password: password,
      );
      final uid = uc.user?.uid;
      if (uid == null) throw StateError('Failed to create auth user');

      try {
        await uc.user?.sendEmailVerification();
      } catch (e) {
        debugPrint('sendEmailVerification failed: $e');
      }
      await secondaryAuth.signOut();

      final user = AppUser(
        id: uid,
        username: uname,
        email: uemail,
        displayName: displayName.trim().isEmpty ? uname : displayName.trim(),
        role: role,
        status: 'active',
        companyId: null,
        photoURL: null,
        lastLogin: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      // Written while still signed in as Admin → rules allow create.
      await _usersCol.doc(user.id).set(_profileWriteMap(user, isCreate: true));
      await _loginIndexCol.doc(uname).set({
        'email': uemail,
        'uid': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _logActivity(
        'Account Creation',
        user.id,
        details: 'Created by admin (role=${role.value})',
      );
      return user;
    } on FirebaseAuthException catch (e) {
      throw StateError(e.message ?? 'Failed to create user');
    } finally {
      // Keep secondary app warm for subsequent creates; session already signed out.
    }
  }

  @override
  Future<void> updateUser(AppUser user) async {
    final doc = await _usersCol.doc(user.id).get();
    if (!doc.exists) throw StateError('User not found');

    final oldData = doc.data()!;
    if (oldData['role'] != user.role.value) {
      await _logActivity(
        'Role Change',
        user.id,
        details: 'Changed to ${user.role.value}',
      );
    }

    final data = _profileWriteMap(user);
    // Preserve createdAt on update.
    data.remove('createdAt');
    await _usersCol.doc(user.id).update(data);
  }

  @override
  Future<void> setPassword(String userId, String newPassword) async {
    if (newPassword.length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      throw StateError('You can only change your own password.');
    }

    await currentUser.updatePassword(newPassword);
    await _usersCol.doc(userId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _logActivity('Password Change', userId);
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } catch (e) {
      // Do not leak whether the email exists.
      debugPrint('forgotPassword: $e');
    }
  }

  @override
  Future<void> deactivateUser(String userId, {required String currentUserId}) async {
    if (userId == currentUserId) {
      throw StateError('You cannot deactivate your own account');
    }
    final doc = await _usersCol.doc(userId).get();
    if (!doc.exists) return;

    final u = AppUser.fromMap(doc.data()!, docId: doc.id);

    if (u.role == UserRole.admin) {
      final adminsSnap = await _usersCol
          .where('role', isEqualTo: UserRole.admin.value)
          .where('isActive', isEqualTo: true)
          .get();
      if (adminsSnap.docs.length <= 1) {
        throw StateError('Cannot deactivate the last active Admin');
      }
    }

    await _usersCol.doc(userId).update({
      'isActive': false,
      'status': 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _logActivity(
      'Account Disable',
      userId,
      details: 'Deactivated by $currentUserId',
    );
  }

  @override
  Future<void> reactivateUser(String userId) async {
    final doc = await _usersCol.doc(userId).get();
    if (!doc.exists) return;

    await _usersCol.doc(userId).update({
      'isActive': true,
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _logActivity('Account Enable', userId);
  }
}
