# Authentication & Admin Google Sign-In — Testing Checklist

Use this before production release. Mark each item pass/fail.

---

## A. Environment

| # | Test | Pass |
|---|------|------|
| A1 | `flutter pub get` succeeds with `google_sign_in`, `firebase_auth`, `cloud_firestore` | ☐ |
| A2 | Firebase project matches `posterflow-6c0cb` | ☐ |
| A3 | Email/Password + Google providers enabled in Console | ☐ |
| A4 | `firestore.rules` and `storage.rules` deployed | ☐ |
| A5 | Cloud Functions deployed (`generateAuthUrl`, `exchangeAuthCode`) | ☐ |
| A6 | Admin allow-list contains real Admin email(s) | ☐ |
| A7 | At least one Firestore `users/{uid}` with `role: admin`, `isActive: true` | ☐ |

---

## B. Email / password (team)

| # | Test | Expected | Pass |
|---|------|----------|------|
| B1 | Designer login with correct credentials | Enters app; Designer permissions | ☐ |
| B2 | Manager login | Enters app; can manage clients / assign | ☐ |
| B3 | QC login | Enters app; QC actions only | ☐ |
| B4 | Wrong password | Error; stay on login | ☐ |
| B5 | Deactivated user | Denied; no session | ☐ |
| B6 | Username login (not email) | Resolves to email; success | ☐ |
| B7 | Unverified non-admin email | Denied with verify message | ☐ |
| B8 | Forgot password | No crash; no email enumeration leak | ☐ |
| B9 | `lastLogin` updated on success | Firestore timestamp refreshed | ☐ |

---

## C. Google Sign-In (Admin)

| # | Test | Expected | Pass |
|---|------|----------|------|
| C1 | Admin Google account with matching Firestore profile + UID | Success; Admin shell | ☐ |
| C2 | `lastLogin` (and optional `photoURL`) updated | Firestore fields updated | ☐ |
| C3 | Audit log entry `Login` / `google` | Present under `audit_logs` | ☐ |
| C4 | Random Gmail with no profile | Denied; signed out; no Firestore create | ☐ |
| C5 | Allow-listed email **without** profile | Denied; message about provisioning; no create | ☐ |
| C6 | Designer/Manager/QC Google account (even if Auth user exists) with non-admin role | Denied; signed out | ☐ |
| C7 | Admin profile exists but `isActive: false` | Denied | ☐ |
| C8 | Profile email matches but document ID ≠ Google UID | Denied; provisioning message | ☐ |
| C9 | User cancels Google picker | Returns to login; no error spam | ☐ |
| C10 | `requireAllowListForGoogle = true` and Admin not on list | Denied | ☐ |
| C11 | Logout after Google login | Clears Firebase + Google session; back to login | ☐ |

---

## D. Security / no auto-provision

| # | Test | Expected | Pass |
|---|------|----------|------|
| D1 | After denied Google login, count of `users` docs unchanged | No new documents | ☐ |
| D2 | Client cannot set `role: admin` on self via SDK | Rules reject | ☐ |
| D3 | Unauthenticated read of `users` | Denied | ☐ |
| D4 | Non-admin write to `settings/drive_integration` | Denied | ☐ |
| D5 | Write `refreshToken` to settings as Admin | Rules reject (forbidden keys) | ☐ |

---

## E. Google Drive (Admin only)

| # | Test | Expected | Pass |
|---|------|----------|------|
| E1 | Admin sees Drive integration in Account | Tile visible | ☐ |
| E2 | Non-admin does not see Drive tile | Hidden | ☐ |
| E3 | Deep-link / push `DriveConnectionScreen` as non-admin | Access denied banner | ☐ |
| E4 | Admin `generateAuthUrl` callable | Returns URL | ☐ |
| E5 | Non-admin callable (// via test or stolen token) | `permission-denied` | ☐ |
| E6 | Successful connect | `settings/drive_integration.status == active`; **no** token fields in Firestore | ☐ |
| E7 | Refresh token only in Secret Manager | Confirmed in GCP | ☐ |

---

## F. Regression / UI

| # | Test | Expected | Pass |
|---|------|----------|------|
| F1 | Login layout still matches prior style | Email/password form unchanged aside from Google CTA | ☐ |
| F2 | Role tabs (Pipeline, Team, etc.) unchanged | Same as before | ☐ |
| F3 | Local mode (if forced) | Email/password works; Google shows clear error | ☐ |
| F4 | Team screen create user | Creates profile fields; email verification sent | ☐ |

---

## G. Automated tests

```bash
flutter test test/auth_test.dart
flutter test
```

| # | Test | Pass |
|---|------|------|
| G1 | Local default admin seed + login | ☐ |
| G2 | Admin can create designer | ☐ |
| G3 | Widget: signed-out shows login | ☐ |
| G4 | Widget: admin login opens pipeline | ☐ |

---

## H. Production smoke (post-deploy)

| # | Test | Pass |
|---|------|------|
| H1 | Real Admin Google Sign-In on Android release build | ☐ |
| H2 | Real Admin Google Sign-In on iOS release build | ☐ |
| H3 | Team member email/password on both platforms | ☐ |
| H4 | Drive reconnect after token rotation | ☐ |

---

## Sign-off

| Role | Name | Date | Result |
|------|------|------|--------|
| Developer | | | |
| Admin stakeholder | | | |
