/// Central API configuration for the Nexus mobile app.
///
/// Values are injected at build time via --dart-define:
///   flutter run \
///     --dart-define=API_BASE_URL=https://nexus.example.com/api/v1 \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJh...
///
/// API_BASE_URL defaults:
///   Android emulator → http://10.0.2.2:3000/api/v1  (host machine localhost)
///   iOS simulator    → http://localhost:3000/api/v1
///   Physical device  → set to your local network IP, e.g. http://192.168.1.x:3000/api/v1
class ApiConfig {
  ApiConfig._();

  /// Base URL for the Next.js API (all /api/v1/* routes)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  /// Supabase project URL — used only for the Google OAuth token exchange.
  /// The anon key is safe to bundle; it only allows public/unauthenticated access.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gfbcwqeocdrzbyaenlnh.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_-m1X2AYSipLmAQ5OYafaDA_ruIVwSR6',
  );

  /// Default request timeout.
  static const Duration timeout = Duration(seconds: 15);
}
