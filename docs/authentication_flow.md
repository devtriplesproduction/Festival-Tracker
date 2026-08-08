# Authentication Flow

Festival Tracker uses **Firebase Authentication** with two paths:

| Path | Audience | Provider |
|------|----------|----------|
| Email / password (or username) | Designers, Managers, QC, optional Admin | Firebase Email/Password |
| Google Sign-In | **Admin only** | Firebase Google provider |

Accounts are **never** created automatically after Google login.

---

## Architecture

```
┌─────────────┐     email/password      ┌──────────────────┐
│ LoginScreen │ ───────────────────────►│ Firebase Auth    │
│             │     Google (Admin)      │  + Google IdP    │
└──────┬──────┘                         └────────┬─────────┘
       │                                         │
       │         AuthState / AuthRepository      │
       ▼                                         ▼
┌─────────────────────┐                 ┌─────────────────┐
│ Firestore users/{uid}│◄── profile ────│ Post-auth checks│
│ role, isActive, …   │                 └─────────────────┘
└─────────────────────┘
```

### Key files

| File | Role |
|------|------|
| `lib/core/constants/admin_auth_config.dart` | Admin Google allow-list & OAuth client IDs |
| `lib/data/repositories/auth_repository.dart` | Abstract API |
| `lib/data/repositories/firebase_auth_repository.dart` | Production auth |
| `lib/data/repositories/local_auth_repository.dart` | Offline/demo (no Google) |
| `lib/providers/auth_state.dart` | UI state |
| `lib/screens/auth/login_screen.dart` | Login UI |
| `firestore.rules` | Server-side enforcement |

---

## Email / password flow (team)

1. User enters **email or username** + password.
2. If username, resolve email via `users` where `username == input`.
3. `signInWithEmailAndPassword`.
4. Load `users/{uid}`.
5. Require profile exists, `isActive == true`.
6. Non-admin users must have `emailVerified == true`.
7. Update `lastLogin` (+ `updatedAt`).
8. Enter app shell with role-based tabs.

Used by: **Designer, Manager, QC** (and Admin if password is set).

---

## Google Sign-In flow (Admin only)

### Client steps

1. User taps **Continue with Google (Admin)**.
2. `GoogleSignIn.instance.initialize()` then `authenticate()` (google_sign_in v7).
3. Exchange Google `idToken` → `FirebaseAuth.signInWithCredential`.
4. **Authorization (no auto-provisioning):**

   | Check | On failure |
   |-------|------------|
   | Email present | Sign out + error |
   | Email verified | Sign out + error |
   | Profile at `users/{uid}` or by email | Sign out + error (never create) |
   | Email on allow-list **or** existing Admin profile | Sign out + deny |
   | Profile UID == Auth UID | Sign out + provisioning error |
   | `role == admin` | Sign out + deny |
   | `isActive` and not `status == inactive` | Sign out + deny |
   | If `requireAllowListForGoogle`, email on list | Sign out + deny |

5. Update `lastLogin`, optional `photoURL` / `displayName` from Google.
6. Audit log `Login` with detail `google`.
7. Session continues only with Admin role.

### Allow-list

Configured in `AdminAuthConfig.googleAdminAllowList`:

```dart
static const Set<String> googleAdminAllowList = {
  'admin@tsp.com',
  // 'you@company.com',
};
```

- **OR semantics (default):** active Admin profile **or** allow-listed email (still requires Admin profile + role check).
- **Strict mode:** set `requireAllowListForGoogle = true` so email must be listed **and** Admin.

### What is stored in Firestore

Profile document only (no tokens):

```json
{
  "id": "<firebaseAuthUid>",
  "username": "admin",
  "displayName": "TSP Admin",
  "email": "admin@tsp.com",
  "role": "admin",
  "companyId": null,
  "status": "active",
  "photoURL": "https://...",
  "lastLogin": "<timestamp>",
  "createdAt": "<timestamp>",
  "updatedAt": "<timestamp>",
  "isActive": true
}
```

---

## Provisioning an Admin for Google Sign-In

1. In Firebase Console → Authentication, ensure **Google** provider is enabled.
2. Have the Admin complete a one-time Google sign-in **or** create the user via Console so you know the **UID**.
3. Create/update Firestore `users/{uid}` with `role: "admin"`, `isActive: true`, matching `email`.
4. Add email to `AdminAuthConfig.googleAdminAllowList` (recommended).
5. Redeploy the app if the allow-list changed.

**Do not** rely on the old auto-create path (removed). Unauthorized Google accounts are signed out immediately.

---

## Google Drive connection (Admin only)

1. UI: Account → Drive integration (Admin tab only) + screen-level role guard.
2. Callable `generateAuthUrl` / `exchangeAuthCode` call `assertAdmin` (Firestore role check).
3. Refresh token → **Secret Manager** only.
4. Firestore `settings/drive_integration` stores non-sensitive metadata (`connectedBy`, `connectedAt`, `status`).
5. Security rules: Admin-only read/write; token field names forbidden.

---

## Logout

1. Write audit `Logout` when possible.
2. `FirebaseAuth.signOut()`.
3. `GoogleSignIn.signOut()` (best-effort).

---

## Local / demo mode

When Firebase is not configured, `LocalAuthRepository` is used:

- Email/password only.
- `loginWithGoogle()` throws a clear error.
- Default Admin seed: `admin` / `admin123` (local only).

---

## Threat model notes

| Threat | Mitigation |
|--------|------------|
| Random Google account becomes Admin | No auto-create; role + allow-list checks; sign-out on deny |
| Designer uses Google button | Role check rejects non-admin |
| Client tampers with role in Firestore | Rules lock `role` on self-update; Admin-only create |
| Drive OAuth by non-admin | UI + callable `assertAdmin` + rules |
| Token leakage in Firestore | Tokens not written; rules reject token keys |
| Stale session after deactivate | `isActive` checked on login and `currentUser` |
