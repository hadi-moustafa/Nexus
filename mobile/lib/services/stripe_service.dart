import 'api_client.dart';

class StripeService {
  StripeService._();
  static final instance = StripeService._();

  static const String _paybackCallbackBase =
      'com.example.nexus://payment-callback/';

  Future<SubscriptionStatus?> fetchSubscription() async {
    final response = await ApiClient.instance.get('/user/subscription');
    final data = response.data['data'];
    if (data == null) return null;
    return SubscriptionStatus.fromJson(data as Map<String, dynamic>);
  }

  Future<String> createCheckoutSession(String plan) async {
    final response = await ApiClient.instance.post(
      '/stripe/checkout',
      data: {
        'plan': plan,
        'successUrl':
            '$_paybackCallbackBase?status=success&session_id={CHECKOUT_SESSION_ID}',
        'cancelUrl': '$_paybackCallbackBase?status=canceled',
      },
    );
    return response.data['data']['url'] as String;
  }

  Future<SubscriptionStatus> verifySession(String sessionId) async {
    final response = await ApiClient.instance.post(
      '/stripe/verify-session',
      data: {'sessionId': sessionId},
    );
    return SubscriptionStatus.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> cancelSubscription() async {
    await ApiClient.instance.delete('/user/subscription');
  }
}

class SubscriptionStatus {
  final String? status;
  final String? plan;
  final DateTime? endDate;
  final bool autoRenew;

  const SubscriptionStatus({
    this.status,
    this.plan,
    this.endDate,
    this.autoRenew = true,
  });

  bool get isPremium => status == 'active';

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      status: json['status'] as String?,
      plan: json['plan'] as String?,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      autoRenew: json['auto_renew'] as bool? ?? true,
    );
  }
}
