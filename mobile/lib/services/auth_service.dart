import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../models/user_profile.dart';

/// Keys used for flutter_secure_storage (native only).
const _kAccessToken = 'access_token';
const _kRefreshToken = 'refresh_token';

/// Handles the full auth lifecycle for the Nexus mobile app.
///
/// Platform split:
///   Web    → Supabase OAuth redirect flow (signInWithOAuth)
///   Native → google_sign_in ID token → Supabase REST token exchange
///
/// This service does NOT import ApiClient to avoid a circular dependency.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _storage = FlutterSecureStorage();

  // Native only — Google Sign-In SDK
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId:
        ApiConfig.googleClientId.isNotEmpty ? ApiConfig.googleClientId : null,
  );

  // Native only — Dio pointed at Supabase Auth REST for token exchange/refresh
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

  // Dio pointed at the Next.js API — no interceptors to avoid circular calls
  final _apiDio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
    ),
  );

  SupabaseClient get _supabase => Supabase.instance.client;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Signs in with Google.
  ///
  /// Web: triggers Supabase OAuth redirect — returns null because the browser
  ///      navigates away. Session is restored by [getStoredSession] on reload.
  /// Native: opens Google account picker, exchanges ID token with Supabase,
  ///         stores tokens, returns the user's profile.
  Future<UserProfile?> signInWithGoogle() async {
    if (kIsWeb) {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // Redirect back to the current origin (e.g. http://localhost:PORT).
        // Must be listed in Supabase Dashboard → Auth → URL Configuration.
        redirectTo: Uri.base.origin,
      );
      return null; // Browser redirects — never reached in practice
    }
    return _signInWithGoogleNative();
  }

  /// Checks for a valid stored session on app start.
  ///
  /// Web: reads from Supabase's localStorage-backed session.
  /// Native: reads from flutter_secure_storage; tries token refresh on 401.
  Future<UserProfile?> getStoredSession() async {
    if (kIsWeb) {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;
      try {
        return await _fetchProfile(session.accessToken);
      } catch (_) {
        return null;
      }
    }

    final accessToken = await _storage.read(key: _kAccessToken);
    if (accessToken == null) return null;

    try {
      return await _fetchProfile(accessToken);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await refreshToken();
        if (!refreshed) return null;
        final newToken = await _storage.read(key: _kAccessToken);
        if (newToken == null) return null;
        return _fetchProfile(newToken);
      }
      return null;
    }
  }

  /// Refreshes the access token.
  ///
  /// Called automatically by ApiClient interceptor on 401 responses.
  /// Returns true if new tokens were stored successfully.
  Future<bool> refreshToken() async {
    if (kIsWeb) {
      try {
        final response = await _supabase.auth.refreshSession();
        return response.session != null;
      } catch (_) {
        await clearTokens();
        return false;
      }
    }

    final storedRefresh = await _storage.read(key: _kRefreshToken);
    if (storedRefresh == null) return false;

    try {
      final response = await _supabaseDio.post(
        '/token?grant_type=refresh_token',
        data: {'refresh_token': storedRefresh},
      );
      await _storeTokens(
        response.data['access_token'] as String,
        response.data['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  /// Signs the user out and clears all session data.
  Future<void> signOut() async {
    if (kIsWeb) {
      try {
        await _supabase.auth.signOut();
      } catch (_) {}
      return;
    }

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

  /// Returns the current access token. Used by ApiClient interceptor.
  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      return _supabase.auth.currentSession?.accessToken;
    }
    return _storage.read(key: _kAccessToken);
  }

  /// Clears all stored tokens. Called on refresh failure or explicit sign-out.
  Future<void> clearTokens() async {
    if (kIsWeb) {
      try {
        await _supabase.auth.signOut();
      } catch (_) {}
      return;
    }
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<UserProfile> _signInWithGoogleNative() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw Exception('Failed to get Google ID token');

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
    await _storeTokens(accessToken, refreshToken);
    return _fetchProfile(accessToken);
  }

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
