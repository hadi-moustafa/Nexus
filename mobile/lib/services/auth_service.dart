import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../models/user_profile.dart';

/// Deep-link URI Android uses to resume the app after OAuth.
///
/// ─── REQUIRED SUPABASE SETUP ──────────────────────────────────────────────
/// Add this URL to:
///   Supabase Dashboard → Authentication → URL Configuration → Redirect URLs
///     com.example.nexus://login-callback/
///
/// Without that entry Supabase rejects the redirect and OAuth never completes.
/// ──────────────────────────────────────────────────────────────────────────
const _kAndroidRedirect = 'com.example.nexus://login-callback/';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  // Separate Dio — no interceptors to avoid circular dependency with ApiClient.
  final _apiDio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
    ),
  );

  // ── Google OAuth ──────────────────────────────────────────────────────────

  /// Opens Google OAuth in an external browser.
  ///
  /// On native Android: uses PKCE flow (set in main.dart) so the redirect
  /// carries ?code= (query param), which Android intent handling preserves.
  /// LaunchMode.externalApplication opens real Chrome, not a Custom Tab,
  /// which is required for the deep-link redirect to reach the app.
  ///
  /// Returns immediately after opening the browser.
  /// Session delivery is async via onAuthStateChange in main.dart.
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : _kAndroidRedirect,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  // ── Email / Password ──────────────────────────────────────────────────────

  /// Returns true if the email is already registered in the app.
  Future<bool> checkEmailExists(String email) async {
    final response = await _apiDio.post(
      '/auth/check-email',
      data: {'email': email.trim().toLowerCase()},
    );
    return (response.data['data']?['exists'] as bool?) ?? false;
  }

  /// Sends a 6-digit OTP to [email] via SMTP.
  /// Throws DioException if the email already exists (409) or on server errors.
  Future<void> sendSignUpOtp(String email) async {
    await _apiDio.post(
      '/auth/otp',
      data: {'action': 'send', 'email': email.trim()},
    );
  }

  /// Verifies the OTP, creates the account, and signs the user in.
  /// Returns the UserProfile on success; throws on invalid code or server error.
  Future<UserProfile> verifySignUpOtp(
    String email,
    String token,
    String password,
  ) async {
    // Server creates the user and signs them in (sets web cookies).
    // For mobile we do a Supabase sign-in so the Flutter SDK holds the session.
    await _apiDio.post(
      '/auth/otp',
      data: {'action': 'verify', 'email': email.trim(), 'token': token, 'password': password},
    );

    // Now sign in via Supabase (user was created with email_confirm: true).
    final signIn = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    return _fetchProfileWithFallback(
      signIn.session!.accessToken,
      signIn.session!.user,
    );
  }

  /// Signs in with email + password. Throws AuthException on wrong credentials.
  Future<UserProfile> signInWithEmail(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return _fetchProfileWithFallback(
      response.session!.accessToken,
      response.session!.user,
    );
  }

  // ── Session management ────────────────────────────────────────────────────

  /// Restores the persisted session on app start.
  Future<UserProfile?> getStoredSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;
    try {
      return await _fetchProfileWithFallback(
        session.accessToken,
        session.user,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        try {
          final refreshed = await _supabase.auth.refreshSession();
          if (refreshed.session == null) return null;
          return _fetchProfileWithFallback(
            refreshed.session!.accessToken,
            refreshed.session!.user,
          );
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns the current access token. Used by ApiClient interceptor.
  Future<String?> getAccessToken() async {
    return _supabase.auth.currentSession?.accessToken;
  }

  /// Refreshes the access token. Called by ApiClient on 401.
  Future<bool> refreshToken() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response.session != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
  }

  // ── Private ───────────────────────────────────────────────────────────────

  /// Fetches the full profile from the backend. Falls back to building a
  /// UserProfile from Supabase user metadata when the backend is unreachable
  /// (e.g. running on a physical device against a local dev server).
  Future<UserProfile> _fetchProfileWithFallback(
    String accessToken,
    User supabaseUser,
  ) async {
    try {
      final response = await _apiDio.get(
        '/auth/session',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return UserProfile.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (_) {
      // Backend unreachable (e.g. physical device + local dev server).
      // Use Supabase user metadata so auth still completes successfully.
      return _profileFromSupabaseUser(supabaseUser);
    }
  }

  /// Builds a UserProfile directly from Supabase's User object.
  UserProfile _profileFromSupabaseUser(User user) {
    final meta = user.userMetadata ?? {};
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      displayName: (meta['full_name'] ?? meta['name']) as String?,
      avatarUrl: (meta['avatar_url'] ?? meta['picture']) as String?,
      createdAt: user.createdAt,
    );
  }
}
