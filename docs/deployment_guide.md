# Deployment Guide — Auth & Google Sign-In (Admin)

Project: **posterflow-6c0cb** (see `.firebaserc` and `lib/firebase_options.dart`).

---

## 1. Flutter packages

Already declared in `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.14.0
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.6.9
  firebase_storage: ^12.0.0
  cloud_functions: ^5.0.0
  google_sign_in: ^7.1.1   # v7 API: initialize() + authenticate()
  shared_preferences: ^2.5.3
  provider: ^6.1.5
  # ...
```

Install:

```bash
flutter pub get
```

---

## 2. Firebase Authentication configuration

### Console

1. Open [Firebase Console](https://console.firebase.google.com/) → project **posterflow-6c0cb**.
2. **Authentication → Sign-in method**
   - Enable **Email/Password**.
   - Enable **Google**.
   - Set support email; download/configure OAuth consent if prompted.
3. **Authentication → Settings → Authorized domains**  
   Add production web domains if you ship web.

### Google Cloud OAuth clients

1. [Google Cloud Console](https://console.cloud.google.com/) → same project.
2. **APIs & Services → Credentials**
   - **Web client** (auto-created by Firebase for Google provider) — copy Client ID.
   - **Android**: create OAuth client with package name + SHA-1.
   - **iOS**: create OAuth client with bundle ID (`com.triples.festivalTracker`).
3. Optionally set in `lib/core/constants/admin_auth_config.dart`:

```dart
static const String? googleWebClientId = 'xxxxx.apps.googleusercontent.com';
static const String? googleServerClientId = 'xxxxx.apps.googleusercontent.com'; // Web client
```

`serverClientId` (Web client ID) is recommended on mobile so Firebase receives a valid `idToken`.

### Platform config files (recommended)

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=posterflow-6c0cb
```

This refreshes:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### Android

- Ensure `com.google.gms.google-services` plugin is applied.
- Add **debug and release SHA-1** fingerprints in Firebase Android app settings.
- Package name must match the OAuth Android client.

### iOS

- `GoogleService-Info.plist` in `ios/Runner`.
- URL scheme: reversed client ID from the plist (Google Sign-In).
- Bundle ID must match Firebase iOS app.

### Web

- In `web/index.html`, meta tag or `googleWebClientId` for Google Sign-In.
- Authorized JavaScript origins + redirect URIs in OAuth client.

---

## 3. Admin allow-list

Edit `lib/core/constants/admin_auth_config.dart`:

```dart
static const Set<String> googleAdminAllowList = {
  'admin@yourcompany.com',
};

// Optional: force allow-list even for existing Admins
static const bool requireAllowListForGoogle = false;
```

Rebuild the app after changes (this is client-side config; still backed by Firestore role checks and rules).

---

## 4. Provision first Admin (required)

Google Sign-In **will not** create the profile.

### Option A — Console (recommended)

1. Sign in once with Google on a device (Auth user appears in Authentication).
2. Copy the **UID**.
3. Firestore → `users` → document ID = **UID**:

```json
{
  "id": "<UID>",
  "username": "admin",
  "displayName": "TSP Admin",
  "email": "admin@yourcompany.com",
  "role": "admin",
  "companyId": null,
  "status": "active",
  "photoURL": null,
  "lastLogin": null,
  "createdAt": "<timestamp>",
  "updatedAt": "<timestamp>",
  "isActive": true
}
```

4. Add the same email to `googleAdminAllowList`.

### Option B — Email/password Admin first

1. Create Email/Password user in Authentication.
2. Create matching `users/{uid}` with `role: admin`.
3. For Google later: Auth UID from Google must **match** the document ID (link providers in Console, or create a new profile under the Google UID).

---

## 5. Deploy security rules & functions

```bash
# From repo root
npm install -g firebase-tools   # if needed
firebase login
firebase use posterflow-6c0cb

firebase deploy --only firestore:rules,storage
firebase deploy --only functions
```

Drive OAuth secrets (Cloud Functions):

```bash
firebase functions:config:set \
  drive.client_id="WEB_CLIENT_ID" \
  drive.client_secret="WEB_CLIENT_SECRET" \
  drive.redirect_uri="YOUR_REDIRECT_URI"
```

(Or use environment variables / Secret Manager per `docs/google_cloud_setup.md`.)

Ensure the Functions service account has **Secret Manager Secret Accessor**.

---

## 6. Firestore indexes

Composite indexes: add via Console when the app logs a link, or extend `firestore.indexes.json` and:

```bash
firebase deploy --only firestore:indexes
```

Single-field queries (`email`, `username`, `role`) work without composites.

---

## 7. App release checklist

- [ ] `DefaultFirebaseOptions.isConfigured == true`
- [ ] Google + Email providers enabled
- [ ] SHA-1 / bundle IDs correct
- [ ] First Admin profile provisioned (`role: admin`, correct UID)
- [ ] Allow-list emails updated
- [ ] Rules + functions deployed
- [ ] Drive connect tested as Admin only
- [ ] Designer/Manager/QC email-password login verified
- [ ] Unauthorized Google account denied and signed out

---

## 8. Rollback notes

- Revert app release if client auth logic regresses.
- Rules can be redeployed independently from a known-good `firestore.rules`.
- Disabling the Google provider in Firebase immediately blocks Google Sign-In without affecting email/password team logins.
