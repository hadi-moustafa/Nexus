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
import 'screens/journalist_profile_screen.dart';
import 'services/auth_service.dart';
import 'services/api_client.dart';
import 'services/payment_callback_service.dart';
import 'services/notification_service.dart';
import 'models/user_profile.dart';
import 'widgets/nexus_logo.dart';
import 'screens/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
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

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && _authState != _AuthState.authenticated) {
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

    ApiClient.instance.needsLoginNotifier.addListener(_onNeedsLogin);
    _linkSubscription = AppLinks().uriLinkStream.listen(_handleDeepLink);
    // Handle deep link when app is launched from a killed state
    AppLinks().getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
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
      ApiClient.instance.needsLoginNotifier.value = false;
      setState(() {
        _authState = _AuthState.unauthenticated;
        _currentUser = null;
      });
    }
  }

  Future<void> _checkSession() async {
    final user = await AuthService.instance.getStoredSession();
    if (user != null) {
      final supaId = Supabase.instance.client.auth.currentUser?.id;
      if (supaId != null) NotificationService.instance.subscribe(supaId);
    }
    setState(() {
      _authState = user != null ? _AuthState.authenticated : _AuthState.unauthenticated;
      _currentUser = user;
    });
  }

  void _onLoginSuccess(UserProfile user) {
    final supaId = Supabase.instance.client.auth.currentUser?.id;
    if (supaId != null) NotificationService.instance.subscribe(supaId);
    setState(() {
      _authState = _AuthState.authenticated;
      _currentUser = user;
    });
  }

  Future<void> _onSignOut() async {
    NotificationService.instance.unsubscribe();
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

// ── Animated splash screen ────────────────────────────────────────────────────

class _SplashScreen extends StatefulWidget {
  final bool isDark;
  const _SplashScreen({required this.isDark});

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _taglineSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scaleIn = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.55, curve: Curves.elasticOut)),
    );
    _taglineSlide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 0.85, curve: Curves.easeOut)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scaleIn,
                  child: const NexusLogoDark(size: 120, showText: false),
                ),
              ),
              const SizedBox(height: 24),

              // NEXUS text
              FadeTransition(
                opacity: _fadeIn,
                child: const Text(
                  'NEXUS',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 6,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Tagline (slides up)
              Transform.translate(
                offset: Offset(0, _taglineSlide.value),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _ctrl,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                  ),
                  child: Text(
                    'NEWS APP',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 56),

              // Pulse loader
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _ctrl,
                  curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
                ),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: NexusColors.teal,
                    strokeWidth: 2.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Main navigator (floating bottom tabs) ────────────────────────────────────

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

class _MainNavigatorState extends State<MainNavigator>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _navAnim;

  bool get _isJournalist => widget.currentUser?.isJournalist == true;

  @override
  void initState() {
    super.initState();
    _navAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _navAnim.forward();
  }

  @override
  void dispose() {
    _navAnim.dispose();
    super.dispose();
  }

  List<Widget> _buildScreens() {
    final profileScreen = _isJournalist
        ? JournalistProfileScreen(
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
            currentUser: widget.currentUser!,
            onSignOut: widget.onSignOut,
          )
        : ProfileScreen(
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
            currentUser: widget.currentUser,
            onSignOut: widget.onSignOut,
          );

    final base = [
      HomeScreen(isDark: widget.isDark, onToggleTheme: widget.onToggleTheme),
      FeedScreen(isDark: widget.isDark),
      JournalistFeedScreen(isDark: widget.isDark),
      QuizScreen(isDark: widget.isDark),
      profileScreen,
    ];
    if (_isJournalist) {
      base.insert(base.length - 1, JournalistStudioScreen(isDark: widget.isDark));
    }
    return base;
  }

  List<({IconData icon, IconData activeIcon, String label})> _buildTabs() {
    final base = [
      (icon: Icons.public_outlined, activeIcon: Icons.public, label: 'Globe'),
      (icon: Icons.article_outlined, activeIcon: Icons.article, label: 'Feed'),
      (icon: Icons.newspaper_outlined, activeIcon: Icons.newspaper, label: 'Posts'),
      (icon: Icons.quiz_outlined, activeIcon: Icons.quiz, label: 'Quiz'),
      (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
    ];
    if (_isJournalist) {
      base.insert(base.length - 1,
          (icon: Icons.edit_note_outlined, activeIcon: Icons.edit_note, label: 'Studio'));
    }
    return base;
  }

  void _onTabTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);
    final screens = _buildScreens();
    final tabs = _buildTabs();
    if (_currentIndex >= screens.length) _currentIndex = 0;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Screen content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: screens[_currentIndex],
            ),
          ),

          // Floating bottom navigation
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: _FloatingNavBar(
              tabs: tabs,
              currentIndex: _currentIndex,
              isDark: widget.isDark,
              onTap: _onTabTap,
              notificationBadge: ValueListenableBuilder<int>(
                valueListenable: NotificationService.instance.unreadCount,
                builder: (_, count, __) => count > 0
                    ? _NotificationBell(
                        count: count,
                        isDark: widget.isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationsScreen(isDark: widget.isDark),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating nav bar ──────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final List<({IconData icon, IconData activeIcon, String label})> tabs;
  final int currentIndex;
  final bool isDark;
  final void Function(int) onTap;
  final Widget? notificationBadge;

  const _FloatingNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
    this.notificationBadge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (notificationBadge != null) ...[
          notificationBadge!,
          const SizedBox(height: 6),
        ],
        Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF141519).withOpacity(0.95)
            : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final selected = currentIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? NexusColors.teal.withOpacity(0.14) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        selected ? tab.activeIcon : tab.icon,
                        key: ValueKey(selected),
                        color: selected ? NexusColors.teal : colors.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        color: selected ? NexusColors.teal : colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
        ), // Container (pill nav bar)
      ], // Column children
    ); // Column
  }
}

// ── Notification bell button ──────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  final int count;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationBell({
    required this.count,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF141519).withOpacity(0.95)
              : Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: NexusColors.teal.withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_rounded, color: NexusColors.teal, size: 18),
            const SizedBox(width: 5),
            Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: NexusColors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
