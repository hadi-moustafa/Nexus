import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/api_client.dart';
import 'models/user_profile.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  void initState() {
    super.initState();
    _checkSession();

    // Listen for auth expiry from the ApiClient interceptor.
    // When token refresh fails mid-session, force back to login.
    ApiClient.instance.needsLoginNotifier.addListener(_onNeedsLogin);
  }

  @override
  void dispose() {
    ApiClient.instance.needsLoginNotifier.removeListener(_onNeedsLogin);
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    final screens = [
      HomeScreen(isDark: widget.isDark, onToggleTheme: widget.onToggleTheme),
      FeedScreen(isDark: widget.isDark),
      QuizScreen(isDark: widget.isDark),
      ProfileScreen(
        isDark: widget.isDark,
        currentUser: widget.currentUser,
        onSignOut: widget.onSignOut,
      ),
    ];

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
              children: [
                _buildNavItem(icon: Icons.public,          label: 'Globe',   index: 0, colors: colors),
                _buildNavItem(icon: Icons.article_outlined, label: 'Feed',    index: 1, colors: colors),
                _buildNavItem(icon: Icons.quiz_outlined,    label: 'Quiz',    index: 2, colors: colors),
                _buildNavItem(icon: Icons.person_outline,   label: 'Profile', index: 3, colors: colors),
              ],
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
