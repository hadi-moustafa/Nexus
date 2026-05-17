import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';

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

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _savingName = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      if (mounted) _showSnack('Name updated');
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
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out',
                style: TextStyle(color: Colors.red)),
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
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Display name ──────────────────────────────────────────
          _Section(
            colors: colors,
            title: 'Profile',
            children: [
              _buildSectionContent(colors, [
                Text('Display name',
                    style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: TextStyle(color: colors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: colors.muted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: NexusColors.teal),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          hintText: 'Your display name',
                          hintStyle: TextStyle(color: colors.textSecondary),
                        ),
                        maxLength: 50,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NexusColors.teal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _savingName ? null : _saveDisplayName,
                        child: _savingName
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Save',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ]),
            ],
          ),
          const SizedBox(height: 16),

          // ── Appearance ────────────────────────────────────────────
          _Section(
            colors: colors,
            title: 'Appearance',
            children: [
              _buildSectionContent(colors, [
                _SettingsRow(
                  colors: colors,
                  icon: widget.isDark ? Icons.dark_mode : Icons.light_mode,
                  label: 'Dark mode',
                  trailing: Switch(
                    value: widget.isDark,
                    onChanged: (_) => widget.onToggleTheme(),
                    activeColor: NexusColors.teal,
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 16),

          // ── Account ───────────────────────────────────────────────
          _Section(
            colors: colors,
            title: 'Account',
            children: [
              _buildSectionContent(colors, [
                if (widget.currentUser?.email != null)
                  _SettingsRow(
                    colors: colors,
                    icon: Icons.email_outlined,
                    label: widget.currentUser!.email!,
                    trailing: const SizedBox.shrink(),
                  ),
                const SizedBox(height: 4),
                _SettingsRow(
                  colors: colors,
                  icon: Icons.logout,
                  label: 'Sign out',
                  labelColor: Colors.red.shade400,
                  trailing: _signingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.red, strokeWidth: 2))
                      : const Icon(Icons.chevron_right,
                          color: Colors.red, size: 18),
                  onTap: _signingOut ? null : _confirmSignOut,
                ),
              ]),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionContent(DynamicColors colors, List<Widget> children) =>
      Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _Section extends StatelessWidget {
  final DynamicColors colors;
  final String title;
  final List<Widget> children;

  const _Section(
      {required this.colors, required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: colors.textSecondary,
              ),
            ),
          ),
          ...children,
        ],
      );
}

class _SettingsRow extends StatelessWidget {
  final DynamicColors colors;
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.colors,
    required this.icon,
    required this.label,
    this.labelColor,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: labelColor ?? colors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: labelColor ?? colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing,
            ],
          ),
        ),
      );
}
