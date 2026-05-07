import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final void Function(UserProfile user) onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = DynamicColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // ── Logo ──────────────────────────────────────────────────
              Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: NexusColors.teal,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: NexusColors.teal.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
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
                  const SizedBox(height: 16),
                  Text(
                    'Nexus',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Geo-contextual news, explored',
                    style: TextStyle(fontSize: 15, color: colors.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ── Tab bar ───────────────────────────────────────────────
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: colors.textPrimary,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  padding: const EdgeInsets.all(4),
                  tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
                ),
              ),

              const SizedBox(height: 28),

              // ── Forms ─────────────────────────────────────────────────
              SizedBox(
                // Let the taller sign-up form set the height; sign-in form
                // will also have enough room.
                height: 420,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _SignInForm(
                      colors: colors,
                      onSuccess: widget.onLoginSuccess,
                    ),
                    _SignUpForm(
                      colors: colors,
                      onSuccess: widget.onLoginSuccess,
                    ),
                  ],
                ),
              ),

              // ── Divider ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Divider(color: colors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or continue with',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ),
                  Expanded(child: Divider(color: colors.border)),
                ],
              ),

              const SizedBox(height: 20),

              // ── Google OAuth button ───────────────────────────────────
              _GoogleButton(colors: colors, onSuccess: widget.onLoginSuccess),

              const SizedBox(height: 24),

              Text(
                'By continuing you agree to our terms of service.',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sign-In form ──────────────────────────────────────────────────────────────

class _SignInForm extends StatefulWidget {
  final DynamicColors colors;
  final void Function(UserProfile) onSuccess;
  const _SignInForm({required this.colors, required this.onSuccess});

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.instance.signInWithEmail(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      if (mounted) widget.onSuccess(user);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(e.toString());
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EmailField(ctrl: _emailCtrl, colors: c),
          const SizedBox(height: 14),
          _PasswordField(
            ctrl: _passCtrl,
            colors: c,
            obscure: _obscure,
            onToggle: () => setState(() => _obscure = !_obscure),
            label: 'Password',
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            _ErrorBox(message: _error!),
          ],
          const SizedBox(height: 24),
          _PrimaryButton(
            label: 'Sign In',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ── Sign-Up form ──────────────────────────────────────────────────────────────

class _SignUpForm extends StatefulWidget {
  final DynamicColors colors;
  final void Function(UserProfile) onSuccess;
  const _SignUpForm({required this.colors, required this.onSuccess});

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  bool _awaitingOtp = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      // 1. Check if email is already registered
      final exists = await AuthService.instance.checkEmailExists(_emailCtrl.text.trim());
      if (!mounted) return;
      if (exists) {
        setState(() {
          _error = 'An account with this email already exists. Please sign in.';
          _loading = false;
        });
        return;
      }
      // 2. Send OTP via SMTP
      await AuthService.instance.sendSignUpOtp(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() { _awaitingOtp = true; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(e.toString());
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;

    if (_awaitingOtp) {
      return _OtpInput(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        colors: c,
        onVerified: widget.onSuccess,
        onBack: () => setState(() => _awaitingOtp = false),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EmailField(ctrl: _emailCtrl, colors: c),
          const SizedBox(height: 14),
          _PasswordField(
            ctrl: _passCtrl,
            colors: c,
            obscure: _obscurePass,
            onToggle: () => setState(() => _obscurePass = !_obscurePass),
            label: 'Password',
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'At least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _PasswordField(
            ctrl: _confirmCtrl,
            colors: c,
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            label: 'Confirm password',
            validator: (v) {
              if (v != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            _ErrorBox(message: _error!),
          ],
          const SizedBox(height: 24),
          _PrimaryButton(
            label: 'Create Account',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ── Google OAuth button ────────────────────────────────────────────────────────

class _GoogleButton extends StatefulWidget {
  final DynamicColors colors;
  final void Function(UserProfile) onSuccess;
  const _GoogleButton({required this.colors, required this.onSuccess});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _loading = false;
  bool _browserOpen = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; _browserOpen = false; });
    try {
      await AuthService.instance.signInWithGoogle();
      // Browser opened successfully. Session arrives async via onAuthStateChange.
      // Show a waiting state so the user knows to complete sign-in in the browser.
      if (mounted) setState(() { _loading = false; _browserOpen = true; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not open Google Sign-In. Try again.';
          _loading = false;
        });
      }
    }
  }

  void _cancel() => setState(() { _browserOpen = false; _error = null; });

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading)
          const Center(
            child: CircularProgressIndicator(color: NexusColors.teal, strokeWidth: 2),
          )
        else if (_browserOpen)
          _BrowserWaitingCard(colors: c, onCancel: _cancel)
        else
          OutlinedButton(
            onPressed: _signIn,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: c.border),
              backgroundColor: c.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CustomPaint(painter: _GoogleLogoPainter()),
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          _ErrorBox(message: _error!),
        ],
      ],
    );
  }
}

class _BrowserWaitingCard extends StatelessWidget {
  final DynamicColors colors;
  final VoidCallback onCancel;
  const _BrowserWaitingCard({required this.colors, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: NexusColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NexusColors.teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.open_in_browser_outlined, color: NexusColors.teal, size: 32),
          const SizedBox(height: 10),
          Text(
            'Complete sign-in in your browser',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Return to the app once you\'ve signed in with Google.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(color: NexusColors.teal, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared form widgets ────────────────────────────────────────────────────────

class _EmailField extends StatelessWidget {
  final TextEditingController ctrl;
  final DynamicColors colors;
  const _EmailField({required this.ctrl, required this.colors});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      style: TextStyle(color: colors.textPrimary),
      decoration: _inputDeco(colors, 'Email', Icons.email_outlined),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required';
        if (!v.contains('@')) return 'Enter a valid email';
        return null;
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final DynamicColors colors;
  final bool obscure;
  final VoidCallback onToggle;
  final String label;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.ctrl,
    required this.colors,
    required this.obscure,
    required this.onToggle,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      textInputAction: TextInputAction.done,
      style: TextStyle(color: colors.textPrimary),
      decoration: _inputDeco(colors, label, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: colors.textSecondary,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator ??
          (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            return null;
          },
    );
  }
}

InputDecoration _inputDeco(DynamicColors c, String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: c.textSecondary, fontSize: 14),
    prefixIcon: Icon(icon, color: c.textSecondary, size: 20),
    filled: true,
    fillColor: c.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: NexusColors.teal, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.red.shade400),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: NexusColors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade400, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── OTP Input widget ──────────────────────────────────────────────────────────

class _OtpInput extends StatefulWidget {
  final String email;
  final String password;
  final DynamicColors colors;
  final void Function(UserProfile) onVerified;
  final VoidCallback onBack;
  const _OtpInput({
    required this.email,
    required this.password,
    required this.colors,
    required this.onVerified,
    required this.onBack,
  });

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes  = List.generate(6, (_) => FocusNode());
  bool _loading  = false;
  bool _resending = false;
  bool _resent   = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes)  f.dispose();
    super.dispose();
  }

  String get _token => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int idx, String value) {
    if (value.length > 1) {
      // Handle paste
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 6) {
        for (int i = 0; i < 6; i++) {
          _controllers[i].text = digits[i];
        }
        _submit();
        return;
      }
    }
    if (value.isNotEmpty && idx < 5) {
      _focusNodes[idx + 1].requestFocus();
    }
    if (_token.length == 6) _submit();
  }

  void _onKeyEvent(int idx, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[idx].text.isEmpty &&
        idx > 0) {
      _focusNodes[idx - 1].requestFocus();
    }
  }

  Future<void> _submit() async {
    if (_token.length < 6) return;
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.instance.verifySignUpOtp(widget.email, _token, widget.password);
      if (mounted) widget.onVerified(user);
    } catch (_) {
      if (mounted) {
        for (final c in _controllers) c.clear();
        _focusNodes[0].requestFocus();
        setState(() {
          _error = 'Invalid or expired code. Please try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; });
    try {
      await AuthService.instance.sendSignUpOtp(widget.email);
      if (mounted) setState(() { _resending = false; _resent = true; });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _resent = false);
      });
    } catch (_) {
      if (mounted) setState(() { _resending = false; _error = 'Could not resend. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: NexusColors.teal.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined, color: NexusColors.teal, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          'Check your email',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to\n${widget.email}',
          style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // ── 6 digit boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) => Container(
            width: 44,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (e) => _onKeyEvent(i, e),
              child: TextFormField(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                enabled: !_loading,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: NexusColors.teal, width: 2),
                  ),
                ),
                onChanged: (v) => _onDigitChanged(i, v),
              ),
            ),
          )),
        ),

        if (_error != null) ...[
          const SizedBox(height: 16),
          _ErrorBox(message: _error!),
        ],
        if (_loading) ...[
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: NexusColors.teal, strokeWidth: 2),
        ],
        const SizedBox(height: 24),

        if (_resent)
          Text(
            'Code resent!',
            style: const TextStyle(color: NexusColors.teal, fontWeight: FontWeight.w600, fontSize: 13),
          )
        else
          TextButton(
            onPressed: _resending ? null : _resend,
            child: Text(
              _resending ? 'Resending…' : 'Resend code',
              style: const TextStyle(color: NexusColors.teal, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        TextButton(
          onPressed: widget.onBack,
          child: Text(
            'Back',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ── Google "G" logo ────────────────────────────────────────────────────────────

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rect = Offset.zero & size;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.52, 1.57, true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 1.05, 1.57, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.62, 1.57, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 4.19, 1.57, true, paint);

    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Error string normaliser ────────────────────────────────────────────────────

String _friendlyError(String raw) {
  final msg = raw.toLowerCase();
  if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
    return 'Incorrect email or password.';
  }
  if (msg.contains('email already') || msg.contains('already registered')) {
    return 'An account with this email already exists.';
  }
  if (msg.contains('weak password') || msg.contains('password should')) {
    return 'Password is too weak — use at least 6 characters.';
  }
  if (msg.contains('network') || msg.contains('socket') || msg.contains('connection')) {
    return 'Network error. Check your connection and try again.';
  }
  return 'Something went wrong. Please try again.';
}
