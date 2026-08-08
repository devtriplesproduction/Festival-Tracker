/// Production configuration for Admin Google Sign-In.
///
/// Google Sign-In is **Admin-only**. Accounts are never auto-created after
/// a successful Google OAuth — the Firestore profile must already exist
/// with `role == admin`, or the email must be pre-approved on the allow-list
/// *and* still resolve to an active Admin profile (see auth flow docs).
class AdminAuthConfig {
  AdminAuthConfig._();

  /// Emails pre-approved for Admin Google Sign-In (lowercase).
  ///
  /// Keep this list short. Prefer Google Workspace addresses.
  /// Update and redeploy the app when the Admin roster changes.
  ///
  /// Existing active Admin profiles in Firestore may also use Google Sign-In
  /// even if not listed here (see [requireAllowListForGoogle]).
  static const Set<String> googleAdminAllowList = {
    // Default seed / bootstrap Admin — replace with real TSP Admin emails.
    'admin@tsp.com','developer.triplesproduction@gmail.com', 'khulapeshital8@gmail.com', // 'you@triplesproduction.com',
  };

  /// When `true`, the Google account email **must** appear on
  /// [googleAdminAllowList] in addition to having an active Admin profile.
  ///
  /// When `false` (default), either an existing Admin profile **or** an
  /// allow-listed email that maps to an Admin profile is accepted.
  static const bool requireAllowListForGoogle = true;

  /// Optional Web OAuth client ID for Google Sign-In (required on web /
  /// some desktop targets). Use the **Web client** ID from Google Cloud
  /// Console → APIs & Services → Credentials (also shown in Firebase
  /// Console → Authentication → Sign-in method → Google).
  ///
  /// Leave null to rely on platform config (`google-services.json` /
  /// `GoogleService-Info.plist` / meta tags).
  static const String? googleWebClientId = '67998510522-vbgas2j4ef9q3e1fvhsdpf7ir17hitc8.apps.googleusercontent.com';

  /// Optional server client ID (Web client) used as `serverClientId` so
  /// Firebase receives a valid `idToken` on mobile.
  static const String? googleServerClientId = googleWebClientId;

  static bool isEmailAllowListed(String email) {
    return googleAdminAllowList.contains(email.trim().toLowerCase());
  }
}
