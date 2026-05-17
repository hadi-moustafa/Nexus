import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/api_config.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/journalist_feed_screen.dart';
import 'screens/journalist_studio_screen.dart';
import 'services/auth_service.dart';
import 'services/api_client.dart';
import 'services/payment_callback_service.dart';
import 'models/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      // PKCE on native: redirect carries ?code= (query param) which Android
      // intent handling preserves. Implicit flow uses #fragment which Android
      // strips from deep-link URIs — tokens never arrive, session never set.
      // Web keeps implicit because PKCE's in-memory code verifier is lost on
      // a full page reload (the OAuth redirect reloads the page on web).
      authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
    ),
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const NexusApp());
}

// App-level auth state
enum _AuthState { loading, authenticated, unauthenticated }

class NexusApp extends StatefulWidget {
  const NexusApp({super.key});

  @override
  State<NexusApp> createState() => _NexusAppState();
}

class _NexusAppState extends State<NexusApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  _AuthState _authState = _AuthState.loading;
  UserProfile? _currentUser;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _checkSession();

    // Listen for Supabase auth state changes on all platforms.
    // On web: handles the OAuth redirect page reload.
    // On native: handles the deep-link OAuth callback and email sign-in.
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn &&
          _authState != _AuthState.authenticated) {
        _checkSession();
      } else if (data.event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _authState = _AuthState.unauthenticated;
            _currentUser = null;
          });
        }
      }
    });

    // Listen for auth expiry from the ApiClient interceptor.
    // When token refresh fails mid-session, force back to login.
    ApiClient.instance.needsLoginNotifier.addListener(_onNeedsLogin);

    // Listen for deep links (OAuth + payment callbacks).
    _linkSubscription = AppLinks().uriLinkStream.listen(_handleDeepLink);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _linkSubscription?.cancel();
    ApiClient.instance.needsLoginNotifier.removeListener(_onNeedsLogin);
    super.dispose();
  }

  void _handleDeepLink(Uri uri) {
    if (uri.host == 'payment-callback') {
      final status = uri.queryParameters['status'];
      final sessionId = uri.queryParameters['session_id'];
      if (status == 'success' && sessionId != null && sessionId.isNotEmpty) {
        PaymentCallbackService.instance.onSuccess(sessionId);
      } else {
        PaymentCallbackService.instance.onCanceled();
      }
    }
  }

  void _onNeedsLogin() {
    if (ApiClient.instance.needsLoginNotifier.value) {
      ApiClient.instance.needsLoginNotifier.value = false; // reset
      setState(() {
        _authState = _AuthState.unauthenticated;
        _currentUser = null;
      });
    }
  }

  Future<void> _checkSession() async {
    final user = await AuthService.instance.getStoredSession();
    setState(() {
      _authState = user != null ? _AuthState.authenticated : _AuthState.unauthenticated;
      _currentUser = user;
    });
  }

  void _onLoginSuccess(UserProfile user) {
    setState(() {
      _authState = _AuthState.authenticated;
      _currentUser = user;
    });
  }

  Future<void> _onSignOut() async {
    await AuthService.instance.signOut();
    setState(() {
      _authState = _AuthState.unauthenticated;
      _currentUser = null;
    });
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus',
      debugShowCheckedModeBanner: false,
      theme: NexusTheme.lightTheme,
      darkTheme: NexusTheme.darkTheme,
      themeMode: _themeMode,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    switch (_authState) {
      case _AuthState.loading:
        return _SplashScreen(isDark: _themeMode == ThemeMode.dark);
      case _AuthState.unauthenticated:
        return LoginScreen(onLoginSuccess: _onLoginSuccess);
      case _AuthState.authenticated:
        return MainNavigator(
          onToggleTheme: toggleTheme,
          isDark: _themeMode == ThemeMode.dark,
          currentUser: _currentUser,
          onSignOut: _onSignOut,
        );
    }
  }
}

// ── Main navigator (bottom tabs) ────────────────────────────────────────────

class MainNavigator extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;
  final UserProfile? currentUser;
  final VoidCallback onSignOut;

  const MainNavigator({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
    required this.currentUser,
    required this.onSignOut,
  });

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  bool get _isJournalist => widget.currentUser?.isJournalist == true;

  List<Widget> _buildScreens() {
    final base = [
      HomeScreen(isDark: widget.isDark, onToggleTheme: widget.onToggleTheme),
      FeedScreen(isDark: widget.isDark),
      JournalistFeedScreen(isDark: widget.isDark),
      QuizScreen(isDark: widget.isDark),
      ProfileScreen(
        isDark: widget.isDark,
        onToggleTheme: widget.onToggleTheme,
        currentUser: widget.currentUser,
        onSignOut: widget.onSignOut,
      ),
    ];
    if (_isJournalist) {
      // Insert Studio before Profile
      base.insert(base.length - 1, JournalistStudioScreen(isDark: widget.isDark));
    }
    return base;
  }

  List<({IconData icon, String label})> _buildTabs() {
    final base = [
      (icon: Icons.public,           label: 'Globe'),
      (icon: Icons.article_outlined,  label: 'Feed'),
      (icon: Icons.newspaper_outlined, label: 'Posts'),
      (icon: Icons.quiz_outlined,     label: 'Quiz'),
      (icon: Icons.person_outline,    label: 'Profile'),
    ];
    if (_isJournalist) {
      base.insert(base.length - 1, (icon: Icons.edit_note_outlined, label: 'Studio'));
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);
    final screens = _buildScreens();
    final tabs = _buildTabs();

    // Clamp index in case tab count changed
    if (_currentIndex >= screens.length) _currentIndex = 0;

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (i) => _buildNavItem(
                icon: tabs[i].icon,
                label: tabs[i].label,
                index: i,
                colors: colors,
              )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required DynamicColors colors,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? NexusColors.teal.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? NexusColors.teal : colors.textSecondary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? NexusColors.teal : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Splash screen (shown while checking stored session) ─────────────────────

class _SplashScreen extends StatelessWidget {
  final bool isDark;
  const _SplashScreen({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: NexusColors.teal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: NexusColors.teal,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
