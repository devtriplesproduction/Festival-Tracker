# Festival Tracker

Native Flutter app for **Triple S Production (TSP)** — tracks the yearly festival poster package for multiple clients so design, QC, ready, and send deadlines never depend on memory.

**Platforms:** iOS + Android from one codebase (Flutter / Dart).

---

## Login

| Method | Who |
|--------|-----|
| **Email / password** (or username) | Designers, Managers, QC, and optional Admin |
| **Google Sign-In** | **Authorized Admins only** — never auto-creates accounts |

Roles: **Admin** · **Designer** · **Manager** · **QC**

**Local/demo mode** seeds Admin `admin` / `admin123`.  
**Cloud mode:** provision Admins in Firestore first (see [docs/deployment_guide.md](docs/deployment_guide.md)).

Google Sign-In requires an existing Admin profile (`role: admin`) and optional allow-list in `lib/core/constants/admin_auth_config.dart`.

Security & ops docs:

- [Authentication flow](docs/authentication_flow.md)
- [Deployment guide](docs/deployment_guide.md)
- [Testing checklist](docs/testing_checklist.md)
- [Firestore security rules](docs/firebase_security_rules.md)

Log out from **Account** tab.

---

## Features

| Screen | What it does |
|--------|----------------|
| **Pipeline** | Client × festival jobs, stats, search/filters, full deadline grid, poster preview |
| **Attach poster** | Paste free Google Drive (or any) URL — **only the URL string is stored** (no Firebase Storage) |
| **WhatsApp** | Manager/Admin open `wa.me` with prefilled message + Drive link; marks **Sent** |
| **Festivals** | List + add (category, description). Defaults preloaded |
| **Clients** | Name, company, WhatsApp, notes, festival package multi-select |
| **Alerts** | In-app notification log + **Run daily check** (upload/send/overdue) |
| **Team** | Admin creates Designer / Manager / QC accounts |
| **Account** | Profile, **Deadline settings** (Admin), log out |

### Deadline rules (configurable)

Defaults (working backward from festival date):

| Stage | Due |
|-------|-----|
| Design | festival − 7 days |
| QC | festival − 5 days |
| Ready | festival − 3 days |
| Send | festival − 1 day (fixed) |

Admin can change Design / QC / Ready offsets under **Account → Deadline settings**. All assignments recalculate.

Statuses: `Not started → Design → QC → Ready → Sent`

### Role actions

| Role | Primary actions |
|------|-----------------|
| Designer | Upload / re-upload poster; set design → QC → ready |
| QC | Request changes (→ design) / Approve ready |
| Manager | Clients, assign work, WhatsApp send |
| Admin | Everything + team + deadline settings |

### Data model

```
festivals/{id}: { name, date, category, description?, isCustom }
clients/{id}: { name, whatsappNumber, companyName?, notes?, festivalIds[] }
assignments/{id}: {
  clientId, festivalId, status,
  designDueDate, qcDueDate, readyDueDate, sendDueDate,
  posterPreviewPath?, posterDriveUrl?, posterDriveFileId?,
  posterUploadedAt?, designerNotes?,
  sentAt?, sentByRole?, createdAt?
}
notifications/{id}: {
  assignmentId, clientName, festivalName, type, message,
  sentAt, recipientRole, read
}
_meta/deadline_config: { designDaysBefore, qcDaysBefore, readyDaysBefore, sendDaysBefore }
```

### Poster storage (free — no Firebase Storage)

1. Upload the image to **Google Drive** (or any free host).
2. Share → **Anyone with the link**.
3. In the app, paste the URL on the assignment.
4. Firestore / local store keeps only:
   - `posterDriveUrl` (the share link)
   - `posterDriveFileId` (optional, auto-extracted)
   - `posterPreviewPath` (preview helper URL)
   - `designerNotes`, `posterUploadedAt`

**No binary files** are uploaded to Firebase. Binary stays on Drive.

Until Firebase is configured, the app uses **on-device storage** (`SharedPreferences`) with the same models and repository API.

---

## Run

```bash
cd "Festival Tracker"
flutter pub get
flutter test
flutter run
```

### Firebase (optional)

1. Create a Firebase project; enable Firestore  
2. `dart pub global activate flutterfire_cli`  
3. `flutterfire configure`  
4. Set `DefaultFirebaseOptions.isConfigured = true` in `lib/firebase_options.dart`

### iOS setup checklist

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
brew install cocoapods   # if needed
cd ios && pod install && cd ..
flutter run -d ios
```

Bundle ID: `com.triples.festivalTracker`

---

## Architecture

```
lib/
  main.dart
  models/           # Festival, Client, Assignment, Notification, DeadlineConfig, roles
  data/repositories/# Local + Firestore AppRepository
  services/         # WhatsApp, poster storage, open/download
  providers/        # AppState, AuthState
  screens/          # Pipeline, Upload, Festivals, Clients, Alerts, Team, Settings
  widgets/          # Assignment card, status steps, overdue banner
```
