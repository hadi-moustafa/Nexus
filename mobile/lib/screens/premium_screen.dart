import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/stripe_service.dart';
import '../services/payment_callback_service.dart';
import '../theme/app_theme.dart';

class PremiumScreen extends StatefulWidget {
  final bool isDark;
  const PremiumScreen({super.key, required this.isDark});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with WidgetsBindingObserver {
  SubscriptionStatus? _subscription;
  bool _loading = true;
  String? _error;
  bool _success = false;

  // plan selection
  String _selectedPlan = 'annual';

  // checkout flow state
  bool _checkoutInProgress = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PaymentCallbackService.instance.pendingSessionId.addListener(_onDeepLinkPayment);
    PaymentCallbackService.instance.paymentCanceled.addListener(_onPaymentCanceled);
    _loadSubscription();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PaymentCallbackService.instance.pendingSessionId.removeListener(_onDeepLinkPayment);
    PaymentCallbackService.instance.paymentCanceled.removeListener(_onPaymentCanceled);
    super.dispose();
  }

  // Called when the Stripe redirect deep link fires and session_id was captured
  void _onDeepLinkPayment() {
    final sessionId = PaymentCallbackService.instance.pendingSessionId.value;
    if (sessionId != null && sessionId.isNotEmpty) {
      PaymentCallbackService.instance.pendingSessionId.value = null;
      _verifySession(sessionId);
    }
  }

  void _onPaymentCanceled() {
    if (PaymentCallbackService.instance.paymentCanceled.value && mounted) {
      setState(() {
        _checkoutInProgress = false;
        _error = 'Checkout was canceled.';
      });
    }
  }

  // App-resume fallback: if deep link wasn't captured, poll subscription status
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _checkoutInProgress) {
      _pollSubscription();
    }
  }

  Future<void> _loadSubscription() async {
    setState(() { _loading = true; _error = null; });
    try {
      final sub = await StripeService.instance.fetchSubscription();
      if (mounted) setState(() { _subscription = sub; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _startCheckout() async {
    setState(() { _error = null; _verifying = true; });
    try {
      final url = await StripeService.instance.createCheckoutSession(_selectedPlan);
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) setState(() { _checkoutInProgress = true; _verifying = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not open payment page. Please try again.';
          _verifying = false;
        });
      }
    }
  }

  // Primary path: verify-session with the session_id from the deep link
  Future<void> _verifySession(String sessionId) async {
    if (_verifying) return;
    setState(() { _verifying = true; _error = null; });
    try {
      final sub = await StripeService.instance.verifySession(sessionId);
      if (mounted) {
        setState(() {
          _subscription = sub;
          _verifying = false;
          _checkoutInProgress = false;
          _success = true;
        });
      }
    } catch (e) {
      // Verify-session failed — fall back to polling subscription status
      if (mounted) await _pollSubscription();
    }
  }

  // Fallback path: poll GET /user/subscription (works once webhook fires)
  Future<void> _pollSubscription() async {
    if (_verifying) return;
    setState(() { _verifying = true; _error = null; });
    try {
      final sub = await StripeService.instance.fetchSubscription();
      if (mounted) {
        setState(() {
          _subscription = sub;
          _verifying = false;
          if (sub != null && sub.isPremium) {
            _checkoutInProgress = false;
            _success = true;
          } else {
            _error = 'Payment not confirmed yet. Please wait a moment and try again.';
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() { _verifying = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Nexus Premium',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: NexusColors.teal, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: (_subscription != null && _subscription!.isPremium) || _success
                  ? _buildActiveSubscription(colors)
                  : _checkoutInProgress
                      ? _buildWaitingForPayment(colors)
                      : _buildUpgradeFlow(colors),
            ),
    );
  }

  // ── Already premium ────────────────────────────────────────────────────────

  Widget _buildActiveSubscription(DynamicColors colors) {
    final sub = _subscription;
    final endDate = sub?.endDate;
    final autoRenew = sub?.autoRenew ?? true;
    final endStr = endDate != null
        ? '${endDate.day}/${endDate.month}/${endDate.year}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: NexusColors.amber.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.stars, color: NexusColors.amber, size: 44),
        ),
        const SizedBox(height: 24),
        Text(
          'You\'re Premium!',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enjoy unlimited access to all Nexus features.',
          style: TextStyle(fontSize: 16, color: colors.textSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        if (endStr != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  autoRenew ? 'Renews on' : 'Access until',
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
                Text(endStr,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ],
            ),
          ),
          if (!autoRenew) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: NexusColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NexusColors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: NexusColors.amber, size: 15),
                  SizedBox(width: 6),
                  Text(
                    'Auto-renewal is off — won\'t renew after this date.',
                    style: TextStyle(fontSize: 12, color: NexusColors.amber),
                  ),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 24),
        _buildFeatureList(colors),
      ],
    );
  }

  // ── Waiting for payment ────────────────────────────────────────────────────

  Widget _buildWaitingForPayment(DynamicColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: NexusColors.teal.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: _verifying
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: NexusColors.teal, strokeWidth: 2.5),
                )
              : const Icon(Icons.payment, color: NexusColors.teal, size: 44),
        ),
        const SizedBox(height: 24),
        Text(
          'Complete payment in your browser',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Stripe will return you here automatically once payment is complete. Or tap the button below.',
          style: TextStyle(fontSize: 15, color: colors.textSecondary, height: 1.6),
          textAlign: TextAlign.center,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _verifying ? null : _pollSubscription,
            style: ElevatedButton.styleFrom(
              backgroundColor: NexusColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: colors.muted,
            ),
            child: _verifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'I\'ve Completed Payment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _checkoutInProgress = false),
          child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
      ],
    );
  }

  // ── Upgrade flow ───────────────────────────────────────────────────────────

  Widget _buildUpgradeFlow(DynamicColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: NexusColors.amber.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars, color: NexusColors.amber, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Upgrade to Premium',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Unlimited bookmarks, Arabic feed, 2× XP,\nad-free reading, and more.',
                style: TextStyle(fontSize: 15, color: colors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Plan cards
        _PlanCard(
          label: 'Annual',
          price: '\$39.99',
          period: 'per year',
          badge: 'Best Value',
          subtext: 'Just \$3.33/month — save 33%',
          selected: _selectedPlan == 'annual',
          isDark: widget.isDark,
          onTap: () => setState(() => _selectedPlan = 'annual'),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          label: 'Monthly',
          price: '\$4.99',
          period: 'per month',
          badge: null,
          subtext: 'Flexible, cancel anytime',
          selected: _selectedPlan == 'monthly',
          isDark: widget.isDark,
          onTap: () => setState(() => _selectedPlan = 'monthly'),
        ),
        const SizedBox(height: 28),

        // Feature list
        _buildFeatureList(colors),
        const SizedBox(height: 28),

        // Error
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red, fontSize: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // CTA
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _verifying ? null : _startCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: NexusColors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: colors.muted,
            ),
            child: _verifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Upgrade Now — ${_selectedPlan == 'annual' ? '\$39.99/yr' : '\$4.99/mo'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Secure payment via Stripe · Cancel anytime',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFeatureList(DynamicColors colors) {
    const features = [
      (Icons.bookmark_added, NexusColors.teal, 'Unlimited bookmarks', 'Free users are limited to 5 saved articles'),
      (Icons.translate, NexusColors.amber, 'Arabic & multilingual feed', 'Full Arabic content — free users get English only'),
      (Icons.bolt, NexusColors.amber, '2× XP on every quiz', 'Premium subscribers earn double XP, climb faster'),
      (Icons.block, Color(0xFF7C83FF), 'Ad-free reading', 'Zero ads, zero distractions across all articles'),
      (Icons.newspaper, NexusColors.teal, 'Exclusive journalist content', 'Premium posts, deep-dives & newsletters'),
      (Icons.download_rounded, Color(0xFF7C83FF), 'Offline reading mode', 'Save articles to read without internet'),
      (Icons.bar_chart_rounded, NexusColors.amber, 'Advanced quiz analytics', 'Track your topic accuracy and improvement over time'),
      (Icons.star_rounded, NexusColors.teal, 'Early access to new features', 'Be first to try everything new on Nexus'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: f.$2.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(f.$1, color: f.$2, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.$3,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(f.$4,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

// ── Plan card ──────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final String label;
  final String price;
  final String period;
  final String? badge;
  final String subtext;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _PlanCard({
    required this.label,
    required this.price,
    required this.period,
    required this.badge,
    required this.subtext,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? NexusColors.teal.withOpacity(0.06) : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? NexusColors.teal : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? NexusColors.teal : colors.border,
                  width: 2,
                ),
                color: selected ? NexusColors.teal : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: NexusColors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: NexusColors.amber,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtext,
                      style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: selected ? NexusColors.teal : colors.textPrimary,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
