/// =============================================================================
/// API Configuration for BasicUserApp
/// =============================================================================
///
/// CONNECTION GUIDE FOR BEGINNERS:
/// 1. Android Emulator:
///    - Use `http://10.0.2.2:5000`
///    - Android Emulator runs inside a virtual router where `10.0.2.2` points
///      directly to the host computer's `localhost:5000`.
///
/// 2. Physical Android Phone (Same Wi-Fi network):
///    - Find your computer's local IP address (e.g. run `ipconfig` on Windows).
///    - Example: `http://192.168.1.100:5000`
///    - Both your phone and your computer must be connected to the exact same Wi-Fi.
///    - Make sure your computer's firewall allows incoming connections on port 5000.
///
/// 3. Remote Android Phone (Different network / Cellular data):
///    - Deploy your Node.js backend to a public hosting provider (e.g., Render, Railway, Fly.io).
///    - Use a public HTTPS URL (e.g., `https://my-backend.onrender.com`).
///    - Note: Android blocks unencrypted HTTP over the public internet by default.
///
/// 4. Localhost Caveat:
///    - NEVER use `http://localhost:5000` on an Android device or emulator.
///    - On Android, `localhost` refers to the mobile phone itself, NOT your computer!
/// =============================================================================
class ApiConfig {
  // Default base URL configured for the official Android Emulator
  static const String defaultEmulatorUrl = 'https://basicuserapp-backend.onrender.com';

  // Current active base URL (mutable so user can change to LAN IP at runtime if desired)
  static String baseUrl = defaultEmulatorUrl;

  // Current installed app version & build number
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
  static const int appBuildNumber = int.fromEnvironment(
    'APP_BUILD_NUMBER',
    defaultValue: 1,
  );

  // Endpoint routes
  static String get healthUrl => '$baseUrl/api/health';
  static String get usersUrl => '$baseUrl/api/users';
  static String get versionUrl => '$baseUrl/api/version';

  // Request timeout duration
  static const Duration timeoutDuration = Duration(seconds: 8);
}

