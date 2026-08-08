# Building Android APK & iOS IPA

## Responsive UI (this project)

The app uses adaptive layout helpers in `lib/core/utils/responsive.dart`:

| Breakpoint | Width | Layout |
|------------|-------|--------|
| Compact | &lt; 600 | Phone: bottom tabs, single column |
| Medium | 600–900 | Large phone / small tablet |
| Expanded | ≥ 900 | 2-column grids, side navigation rail (≥ 700 width) |

All primary screens use page padding, content max-width, and safe list bottom insets.

---

## Android APK (Windows / macOS / Linux)

### Prerequisites

- Flutter stable (3.27+)
- Android SDK (API 34/35), platform-tools, build-tools
- JDK 17 (Android Studio JBR is fine)

```powershell
# Example environment (Windows)
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
flutter config --android-sdk $env:ANDROID_HOME
```

### Build

```bash
flutter pub get
flutter build apk --release
```

**Output:**

- `build/app/outputs/flutter-apk/app-release.apk`
- Convenience copy: `release/FestivalTracker-android-release.apk`

### Notes

- `minSdk` is **23** (Firebase Auth requirement).
- Release is signed with **debug keys** for internal testing. For Play Store, create a keystore and configure `android/app/build.gradle` signingConfigs.
- Gradle is pinned to **8.7** / AGP **8.3.2** for Flutter 3.27 compatibility.

### Install on device

```bash
adb install -r release/FestivalTracker-android-release.apk
```

Or copy the APK to the phone and open it (enable “Install unknown apps”).

---

## iOS IPA (macOS only)

**iOS builds cannot be produced on Windows.** Use a Mac with Xcode.

```bash
# On macOS
cd "Festival Tracker"
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
```

**Output:** `build/ios/ipa/*.ipa`

### Requirements

- macOS + latest Xcode
- Apple Developer account (for device / App Store distribution)
- Signing team configured in Xcode → Runner target
- `ios/Runner/GoogleService-Info.plist` + URL schemes for Google Sign-In

### Simulator (no IPA)

```bash
flutter run -d "iPhone 15"
# or
flutter build ios --simulator
```

---

## Quick verify after install

1. Login screen scales on phone + tablet.
2. Pipeline metrics wrap on small phones.
3. Tablet (≥ ~700 dp width): side navigation rail.
4. Landscape usable without overflow.
5. Admin Google Sign-In / team email login still work.
