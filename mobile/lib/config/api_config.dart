import 'package:flutter/foundation.dart' show kIsWeb;

/// Central API configuration for the Nexus mobile app.
///
/// ── Physical device (Samsung, Pixel, etc.) ──────────────────────────────────
/// `10.0.2.2` is the Android EMULATOR loopback to the host machine.
/// It does NOT work on a real phone.
///
/// For a real phone, use the helper script from the repo root:
///   ./run_mobile.sh
///
/// Or pass the URL manually (replace IP with your machine's local IP):
///   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000/api/v1
///
/// Your machine's local IP:  run `ip addr show` or `ifconfig | grep inet`
///
/// Also make sure the Next.js server is running with:
///   cd web && npm run dev   (now binds to 0.0.0.0 — reachable from phone)
/// ────────────────────────────────────────────────────────────────────────────
class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    const defined = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (defined.isNotEmpty) return defined;
    return kIsWeb
        ? 'http://localhost:3000/api/v1'
        : 'http://10.0.2.2:3000/api/v1'; // emulator only — see note above
  }

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gfbcwqeocdrzbyaenlnh.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_-m1X2AYSipLmAQ5OYafaDA_ruIVwSR6',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '259756726649-e3mnp9uab1cu2g0vu37ulip2k0bbfv9u.apps.googleusercontent.com',
  );

  static const Duration timeout = Duration(seconds: 15);
}
