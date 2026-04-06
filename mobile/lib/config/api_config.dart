import 'package:flutter/foundation.dart' show kIsWeb;

/// Central API configuration for the Nexus mobile app.
///
/// Values are injected at build time via --dart-define:
///   flutter run \
///     --dart-define=API_BASE_URL=https://nexus.example.com/api/v1 \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJh...
class ApiConfig {
  ApiConfig._();

  /// Base URL for the Next.js API (all /api/v1/* routes).
  /// Defaults: web → localhost:3000, Android emulator → 10.0.2.2:3000
  static String get baseUrl {
    const defined = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (defined.isNotEmpty) return defined;
    return kIsWeb
        ? 'http://localhost:3000/api/v1'
        : 'http://10.0.2.2:3000/api/v1';
  }

  /// Supabase project URL.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gfbcwqeocdrzbyaenlnh.supabase.co',
  );

  /// Supabase anon key — safe to bundle, only allows public access.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_-m1X2AYSipLmAQ5OYafaDA_ruIVwSR6',
  );

  /// Google OAuth Web Client ID — required for Flutter Web builds.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '259756726649-e3mnp9uab1cu2g0vu37ulip2k0bbfv9u.apps.googleusercontent.com',
  );

  static const Duration timeout = Duration(seconds: 15);
}
