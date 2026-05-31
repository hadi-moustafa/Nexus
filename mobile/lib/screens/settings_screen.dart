import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/stripe_service.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../widgets/nexus_logo.dart';
import 'about_screen.dart';
import 'premium_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onSignOut;
  final UserProfile? currentUser;

  const SettingsScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onSignOut,
    this.currentUser,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  bool _savingName = false;
  bool _signingOut = false;
  bool _notificationsEnabled = true;
  SubscriptionStatus? _subscription;
  bool _cancelingSubscription = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentUser?.displayName ?? '';
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final sub = await StripeService.instance.fetchSubscription();
      if (mounted) setState(() => _subscription = sub);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length > 50) {
      _showSnack('Name must be 1–50 characters');
      return;
    }
    setState(() => _savingName = true);
    try {
      await UserService.instance.updateDisplayName(name);
      if (mounted) _showSnack('Display name updated');
    } catch (_) {
      if (mounted) _showSnack('Failed to update name');
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            widget.isDark ? const Color(0xFF1E2130) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign out',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w700,
            color: widget.isDark ? Colors.white : const Color(0xFF0A1628),
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: widget.isDark
                ? Colors.white70
                : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: NexusColors.teal),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _signingOut = true);
    try {
      await AuthService.instance.signOut();
      if (mounted) widget.onSignOut();
    } catch (_) {
      if (mounted) _showSnack('Sign out failed');
      setState(() => _signingOut = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor:
            widget.isDark ? const Color(0xFF2A2D3E) : const Color(0xFF1A1F2E),
      ),
    );
  }

  void _navigateToAbout() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            AboutScreen(isDark: widget.isDark),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  void _navigateToPremium() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PremiumScreen(isDark: widget.isDark),
      ),
    ).then((_) => _loadSubscription());
  }

  Future<void> _confirmCancelSubscription() async {
    final endStr = _subscription?.endDate != null
        ? '${_subscription!.endDate!.day}/${_subscription!.endDate!.month}/${_subscription!.endDate!.year}'
        : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            widget.isDark ? const Color(0xFF1E2130) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel subscription?',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w700,
            color: widget.isDark ? Colors.white : const Color(0xFF0A1628),
          ),
        ),
        content: Text(
          endStr != null
              ? 'You\'ll keep premium access until $endStr. After that, your subscription won\'t renew.'
              : 'Your subscription won\'t renew after the current billing period.',
          style: TextStyle(
            color: widget.isDark ? Colors.white70 : Colors.black54,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Premium', style: TextStyle(color: NexusColors.teal)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel subscription',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelingSubscription = true);
    try {
      await StripeService.instance.cancelSubscription();
      await _loadSubscription();
      if (mounted) {
        _showSnack('Subscription canceled — access continues until end of period');
      }
    } catch (_) {
      if (mounted) _showSnack('Failed to cancel subscription');
    } finally {
      if (mounted) setState(() => _cancelingSubscription = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── Gradient header ──────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: const Color(0xFF0A1628),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A1628),
                        Color(0xFF0D2040),
                        Color(0xFF0B3D3A),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                      child: Row(
                        children: [
                          const NexusLogoDark(size: 52, showText: false),
                          const SizedBox(width: 16),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Settings',
                                style: TextStyle(
                                  fontFamily: 'Fraunces',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (widget.currentUser?.displayName != null)
                                Text(
                                  widget.currentUser!.displayName!,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              title: const Text(
                'Settings',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              titleSpacing: 0,
            ),

            // ── Content ──────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Profile
                  _SectionHeader(label: 'Profile', colors: colors),
                  const SizedBox(height: 8),
                  _Card(
                    colors: colors,
                    isDark: widget.isDark,
                    children: [
                      _Label(label: 'Display name', colors: colors),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              style: TextStyle(
                                  color: colors.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: widget.isDark
                                    ? const Color(0xFF1A1F2E)
                                    : const Color(0xFFF4F5F8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: colors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: colors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: NexusColors.teal, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                hintText: 'Your display name',
                                hintStyle: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 14),
                              ),
                              maxLength: 50,
                              buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                                  null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: NexusColors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: _savingName ? null : _saveDisplayName,
                              child: _savingName
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : const Text('Save',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Appearance
                  _SectionHeader(label: 'Appearance', colors: colors),
                  const SizedBox(height: 8),
                  _Card(
                    colors: colors,
                    isDark: widget.isDark,
                    children: [
                      _Row(
                        colors: colors,
                        icon: widget.isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: widget.isDark
                            ? const Color(0xFF7C83FF)
                            : const Color(0xFFF5A524),
                        label: 'Dark mode',
                        subtitle: widget.isDark ? 'On' : 'Off',
                        trailing: Switch(
                          value: widget.isDark,
                          onChanged: (_) => widget.onToggleTheme(),
                          activeColor: NexusColors.teal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Notifications
                  _SectionHeader(label: 'Notifications', colors: colors),
                  const SizedBox(height: 8),
                  _Card(
                    colors: colors,
                    isDark: widget.isDark,
                    children: [
                      _Row(
                        colors: colors,
                        icon: Icons.notifications_rounded,
                        iconColor: const Color(0xFF0EC4A0),
                        label: 'Push notifications',
                        subtitle: 'Breaking news alerts',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (v) =>
                              setState(() => _notificationsEnabled = v),
                          activeColor: NexusColors.teal,
                        ),
                      ),
                      _divider(colors),
                      _Row(
                        colors: colors,
                        icon: Icons.article_rounded,
                        iconColor: const Color(0xFF7C83FF),
                        label: 'Daily briefing',
                        subtitle: 'Top stories each morning',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (v) =>
                              setState(() => _notificationsEnabled = v),
                          activeColor: NexusColors.teal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Subscription
                  _SectionHeader(label: 'Subscription', colors: colors),
                  const SizedBox(height: 8),
                  _Card(
                    colors: colors,
                    isDark: widget.isDark,
                    children: [
                      if (_subscription != null && _subscription!.isPremium) ...[
                        _Row(
                          colors: colors,
                          icon: Icons.stars,
                          iconColor: NexusColors.amber,
                          label: 'Nexus Premium',
                          subtitle: () {
                            final s = _subscription!;
                            if (s.endDate == null) return 'Active';
                            final d = s.endDate!;
                            final dateStr = '${d.day}/${d.month}/${d.year}';
                            return s.autoRenew
                                ? 'Renews $dateStr'
                                : 'Expires $dateStr · auto-renew off';
                          }(),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: NexusColors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Active',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: NexusColors.amber)),
                          ),
                          onTap: _navigateToPremium,
                        ),
                        if (_subscription!.autoRenew) ...[
                          _divider(colors),
                          _Row(
                            colors: colors,
                            icon: Icons.cancel_outlined,
                            iconColor: Colors.redAccent,
                            label: 'Cancel subscription',
                            labelColor: Colors.redAccent,
                            subtitle: 'Turn off auto-renewal',
                            trailing: _cancelingSubscription
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.redAccent, strokeWidth: 2))
                                : const Icon(Icons.chevron_right_rounded,
                                    color: Colors.redAccent, size: 20),
                            onTap: _cancelingSubscription
                                ? null
                                : _confirmCancelSubscription,
                          ),
                        ],
                      ] else ...[
                        _Row(
                          colors: colors,
                          icon: Icons.stars_outlined,
                          iconColor: NexusColors.amber,
                          label: 'Upgrade to Premium',
                          subtitle: 'Unlimited bookmarks, Arabic feed, 2× XP & more',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: NexusColors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Upgrade',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: NexusColors.amber)),
                          ),
                          onTap: _navigateToPremium,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // About
                  _SectionHeader(label: 'About', colors: colors),
                  const SizedBox(height: 8),
                  _Card(
                    colors: colors,
                    isDark: widget.isDark,
                    children: [
                      _Row(
                        colors: colors,
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF0EC4A0),
                        label: 'About Nexus',
                        subtitle: 'Version, team & more',
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: colors.textSecondary, size: 20),
                        onTap: _navigateToAbout,
                      ),
                      _divider(colors),
                      _Row(
                        colors: colors,
                        icon: Icons.privacy_tip_outlined,
                        iconColor: const Color(0xFF7C83FF),
                        label: 'Privacy Policy',
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: colors.textSecondary, size: 20),
                      ),
                      _divider(colors),
                      _Row(
                        colors: colors,
                        icon: Icons.description_outlined,
                        iconColor: const Color(0xFFF5A524),
                        label: 'Terms of Service',
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: colors.textSecondary, size: 20),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Account
                  _SectionHeader(label: 'Account', colors: colors),
                  const SizedBox(height: 8),
                  _Card(
                    colors: colors,
                    isDark: widget.isDark,
                    children: [
                      if (widget.currentUser?.email != null) ...[
                        _Row(
                          colors: colors,
                          icon: Icons.email_outlined,
                          iconColor: colors.textSecondary,
                          label: widget.currentUser!.email,
                          trailing: const SizedBox.shrink(),
                        ),
                        _divider(colors),
                      ],
                      _Row(
                        colors: colors,
                        icon: Icons.logout_rounded,
                        iconColor: Colors.redAccent,
                        label: 'Sign out',
                        labelColor: Colors.redAccent,
                        trailing: _signingOut
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.redAccent, strokeWidth: 2))
                            : const Icon(Icons.chevron_right_rounded,
                                color: Colors.redAccent, size: 20),
                        onTap: _signingOut ? null : _confirmSignOut,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Footer
                  Center(
                    child: Text(
                      '© 2026 Nexus News · All rights reserved',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary.withOpacity(0.55),
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(DynamicColors colors) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Divider(
          height: 1,
          color: colors.border.withOpacity(0.6),
        ),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final DynamicColors colors;
  const _SectionHeader({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 2),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: NexusColors.teal.withOpacity(0.8),
            fontFamily: 'DM Sans',
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  final DynamicColors colors;
  final bool isDark;
  final List<Widget> children;
  const _Card(
      {required this.colors, required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
}

class _Label extends StatelessWidget {
  final String label;
  final DynamicColors colors;
  const _Label({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
          fontFamily: 'DM Sans',
        ),
      );
}

class _Row extends StatelessWidget {
  final DynamicColors colors;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _Row({
    required this.colors,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: labelColor ?? colors.textPrimary,
                        fontFamily: 'DM Sans',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      );
}
