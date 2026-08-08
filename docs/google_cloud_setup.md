# Google Drive setup (Admin account · Year → Festival → Client)

Festival Tracker stores **all uploaded designs** on the **Admin Google account Drive**, not in a custom DB for files.

## Storage layout

Created automatically on first upload if folders do not exist:

```text
Festival Posters/
  └── {year}/                 e.g. 2026
        └── {festivalName}/   e.g. Diwali
              └── {clientName}/
                    └── {year}_{Festival}_{Client}_v1.jpg
```

Pipeline (Cloud Function `onPosterUpload`):

1. Designer uploads poster → Firebase Storage `temp_posters/`
2. Function builds path **Year → Festival → Client**
3. File lands on Admin Drive with versioning (`_v1`, `_v2`, …)
4. Share URL + metadata written back to Firestore `assignments/{id}`
5. Temp Storage object cleaned up after success

OAuth uses the **Admin** account only. Refresh token is stored in **Google Secret Manager** (`drive_refresh_token`), never in Firestore.

---

## Why Connect Drive fails with `[internal]`

`generateAuthUrl` builds the Google login link using:

| Config key | Env var |
|------------|---------|
| `drive.client_id` | `DRIVE_CLIENT_ID` |
| `drive.client_secret` | `DRIVE_CLIENT_SECRET` |
| `drive.redirect_uri` | `DRIVE_REDIRECT_URI` (optional) |

If **client id / secret are missing** on the deployed function, the backend throws before any login screen appears → Firebase surfaces **`[internal]`** (or `failed-precondition` after the latest functions deploy).

---

## 1. Enable APIs (project `posterflow-6c0cb`)

1. [Google Cloud Console](https://console.cloud.google.com/) → project **posterflow-6c0cb**
2. **APIs & Services → Library** → enable:
   - **Google Drive API**
   - **Secret Manager API**
3. Billing: Firebase **Blaze** plan required for Cloud Functions + outbound OAuth.

---

## 2. OAuth consent screen

1. **APIs & Services → OAuth consent screen**
2. User type: **External** (or Internal if Workspace-only)
3. App name e.g. `Festival Tracker Drive`
4. Support / developer email = your admin email
5. Scopes → add:
   - `https://www.googleapis.com/auth/drive.file`
6. **Test users** (while in Testing): add the **Admin Google account** that will own the Drive folders

---

## 3. Create OAuth Web client

1. **APIs & Services → Credentials → Create credentials → OAuth client ID**
2. Application type: **Web application**
3. Name: `Festival Tracker Drive Functions`
4. **Authorized redirect URIs** — add **exactly**:

```text
https://us-central1-posterflow-6c0cb.cloudfunctions.net/oauth2callback
```

(If you deploy to another region, change `us-central1` to match.)

5. Create → copy **Client ID** and **Client Secret**

---

## 4. Set OAuth credentials on Cloud Functions (required)

**Confirmed failure mode:** if `firebase functions:config:get` is `{}` and
`functions/.env` is missing, Connect Drive always fails.

### Option A — script (Windows, recommended)

From the **repo root**:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\setup_drive_oauth.ps1
```

Paste Client ID + Secret when prompted. The script writes `functions/.env` and deploys.

### Option B — manual `.env`

1. Copy `functions/.env.example` → `functions/.env`
2. Fill:

```env
DRIVE_CLIENT_ID=xxxxx.apps.googleusercontent.com
DRIVE_CLIENT_SECRET=xxxxx
DRIVE_REDIRECT_URI=https://us-central1-posterflow-6c0cb.cloudfunctions.net/oauth2callback
```

3. Deploy:

```bash
firebase use posterflow-6c0cb
cd functions && npm install && cd ..
firebase deploy --only functions
```

### Verify server

Open in a browser:

```text
https://us-central1-posterflow-6c0cb.cloudfunctions.net/driveHealth
```

You want `"configured": true`. If `false` or the URL 404s, credentials are missing or functions are not deployed.

> Do **not** commit `functions/.env`.

---

## 5. Secret Manager IAM

Cloud Functions runtime service account needs access to create/read `drive_refresh_token`:

1. **IAM & Admin → IAM**
2. Find `posterflow-6c0cb@appspot.gserviceaccount.com` (or your Functions SA)
3. Grant:
   - **Secret Manager Secret Accessor**
   - **Secret Manager Admin** (only if the secret does not exist yet; can remove Admin after first successful connect)

---

## 6. Deploy functions

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

Deployed endpoints of interest:

| Function | Role |
|----------|------|
| `generateAuthUrl` | Callable — Admin app “Connect Drive” |
| `oauth2callback` | HTTP — Google redirect, saves refresh token |
| `exchangeAuthCode` | Callable — optional manual code exchange |
| `driveConfigStatus` | Callable — Admin check: is client id/secret present? |
| `onPosterUpload` | Storage trigger — Year → Festival → Client upload |

---

## 7. Connect from the app

1. Sign in as **Admin**
2. **Account → Google Drive Integration → Connect Drive**
3. Browser opens Google consent for the **Admin Drive account**
4. After allow → `oauth2callback` stores refresh token → success page
5. Return to app → status should show connected (refresh if needed)

Uploads then create folders under **Festival Posters / year / festival / client**.

---

## 8. Troubleshooting

| Symptom | Fix |
|---------|-----|
| `[internal]` / `failed-precondition` on Connect | Config not set or functions not redeployed after `config:set` |
| `redirect_uri_mismatch` | Redirect URI on OAuth client must match config exactly |
| No refresh token | Revoke app at [Google permissions](https://myaccount.google.com/permissions), connect again (`prompt=consent`) |
| Secret Manager permission denied | Grant Secret Accessor/Admin on Functions SA |
| Upload fails “not connected” | Connect Drive once as Admin before designers upload |
| Wrong Google account | Use the Admin account that should own all festival folders |

Check logs:

```bash
firebase functions:log --only generateAuthUrl,oauth2callback
```

---

## Security notes

- **Never** put Client Secret or refresh tokens in the Flutter app or Firestore.
- Firestore `settings/drive_integration` holds only status metadata (`connectedAt`, `rootFolderId`, …).
- Only users with `users/{uid}.role == admin` may call connect callables (`assertAdmin`).
