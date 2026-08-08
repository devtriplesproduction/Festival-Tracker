# Firebase Security Rules

Production rules live at the repository root:

| File | Purpose |
|------|---------|
| `firestore.rules` | Firestore access control |
| `storage.rules` | Firebase Storage access control |
| `firebase.json` | Deploy mapping |

Deploy:

```bash
firebase deploy --only firestore:rules,storage
```

## Design principles

1. **Authentication required** for all app data.
2. **Role source of truth** is `users/{uid}.role` in Firestore (not custom claims only).
3. **Google Sign-In never auto-creates** user documents; only Admins may create profiles.
4. **No secrets in Firestore** — Drive refresh tokens stay in Secret Manager.
5. **Default deny** for unmatched paths.

## Roles

| Role | Value |
|------|--------|
| Admin | `admin` |
| Designer | `designer` |
| Manager | `manager` |
| QC | `qc` |

## Collections

### `users/{userId}`

Profile-only fields:

- `displayName`, `email`, `role`, `companyId`, `status`
- `photoURL`, `lastLogin`, `createdAt`, `updatedAt`, `isActive`
- `username`, `id` (supporting team email/password login)

| Action | Who |
|--------|-----|
| Get own profile | Any signed-in user (same UID) |
| List / read team | Active users |
| Create / delete | Admin |
| Update own non-privileged fields | Self (role, email, isActive locked) |
| Update any profile | Admin |

### `settings/{documentId}`

Includes `settings/drive_integration`.

| Action | Who |
|--------|-----|
| Read / write | **Admin only** |
| Forbidden keys | `refreshToken`, `accessToken`, `idToken`, `clientSecret` |

### Other

| Path | Read | Write |
|------|------|-------|
| `festivals` | Active users | Admin |
| `clients` | Active users | Manager / Admin |
| `assignments` | Active users | Create: Manager/Admin; update: active; delete: Admin |
| `notifications` | Active users | Update (mark read); create/delete: backend only |
| `audit_logs` | Admin | Create own events only |
| `activity_logs` | Admin | Backend only |
| `_meta/*` | Active users | Admin |

## Storage

- `temp_posters/{imageId}`: authenticated write, images &lt; 15MB, no client read.
- All other paths: deny.

## Cloud Functions

Callable Drive endpoints (`generateAuthUrl`, `exchangeAuthCode`) additionally enforce Admin via Admin SDK (`assertAdmin`), independent of client UI.

## Rules snippets (reference)

Full source: see `firestore.rules` and `storage.rules` in the repo root.
