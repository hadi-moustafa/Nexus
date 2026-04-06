import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';
import '../models/user_profile.dart';

/// Keys used for flutter_secure_storage
const _kAccessToken = 'access_token';
const _kRefreshToken = 'refresh_token';

/// Handles the full auth lifecycle for the Nexus mobile app.
///
/// Auth flow:
///   1. signInWithGoogle() → Google ID token → Supabase REST → store tokens
///   2. All subsequent API calls use the stored access_token (via ApiClient interceptor)
///   3. On 401, ApiClient calls refreshToken() → new tokens stored
///   4. signOut() → clear storage
///
/// This service does NOT import ApiClient to avoid a circular dependency.
/// It uses its own Dio instances for Supabase Auth REST calls.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _storage = FlutterSecureStorage();

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // Dio pointed at Supabase Auth REST — used for token exchange and refresh only
  final _supabaseDio = Dio(
    BaseOptions(
      baseUrl: '${ApiConfig.supabaseUrl}/auth/v1',
      headers: {
        'apikey': ApiConfig.supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
    ),
  );

  // Dio pointed at the Next.js API — used for session validation only,
  // without the auth interceptor (to avoid circular calls)
  final _apiDio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
    ),
  );

  // ── Public API ────────────────────────────────────────────────────────────

  /// Signs the user in with Google.
  ///
  /// 1. Opens the Google account picker on device.
  /// 2. Exchanges the Google ID token with Supabase Auth REST.
  /// 3. Stores access_token + refresh_token in secure storage.
  /// 4. Returns the UserProfile fetched from the Next.js API.
  Future<UserProfile> signInWithGoogle() async {
    // Step 1 — get Google ID token
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw Exception('Failed to get Google ID token');

    // Step 2 — exchange with Supabase Auth
    final response = await _supabaseDio.post(
      '/token?grant_type=id_token',
      data: {
        'provider': 'google',
        'id_token': idToken,
        if (googleAuth.accessToken != null)
          'access_token': googleAuth.accessToken,
      },
    );

    final accessToken = response.data['access_token'] as String;
    final refreshToken = response.data['refresh_token'] as String;

    // Step 3 — persist tokens
    await _storeTokens(accessToken, refreshToken);

    // Step 4 — fetch the user profile from our API
    return _fetchProfile(accessToken);
  }

  /// Checks whether a valid session already exists on device.
  ///
  /// Reads the stored access_token and validates it against the API.
  /// Returns null if no session exists or tokens are invalid and unrefreshable.
  Future<UserProfile?> getStoredSession() async {
    final accessToken = await _storage.read(key: _kAccessToken);
    if (accessToken == null) return null;

    try {
      return await _fetchProfile(accessToken);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token expired — try refreshing
        final refreshed = await refreshToken();
        if (!refreshed) return null;
        final newToken = await _storage.read(key: _kAccessToken);
        if (newToken == null) return null;
        return _fetchProfile(newToken);
      }
      return null;
    }
  }

  /// Refreshes the access token using the stored refresh token.
  ///
  /// Called automatically by ApiClient interceptor on 401 responses.
  /// Returns true if the refresh succeeded and new tokens were stored.
  Future<bool> refreshToken() async {
    final refreshToken = await _storage.read(key: _kRefreshToken);
    if (refreshToken == null) return false;

    try {
      final response = await _supabaseDio.post(
        '/token?grant_type=refresh_token',
        data: {'refresh_token': refreshToken},
      );

      final newAccess = response.data['access_token'] as String;
      final newRefresh = response.data['refresh_token'] as String;
      await _storeTokens(newAccess, newRefresh);
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  /// Signs the user out — clears secure storage.
  /// Optionally calls the API signout endpoint to invalidate the server session.
  Future<void> signOut() async {
    final accessToken = await _storage.read(key: _kAccessToken);
    if (accessToken != null) {
      try {
        await _apiDio.post(
          '/auth/signout',
          options: Options(
            headers: {'Authorization': 'Bearer $accessToken'},
          ),
        );
      } catch (_) {
        // Best-effort — clear local storage regardless
      }
    }
    await clearTokens();
    await _googleSignIn.signOut();
  }

  /// Reads the stored access token. Used by ApiClient interceptor.
  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);

  /// Clears all stored tokens (called on refresh failure or explicit sign-out).
  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
  }

  Future<UserProfile> _fetchProfile(String accessToken) async {
    final response = await _apiDio.get(
      '/auth/session',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
    return UserProfile.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
