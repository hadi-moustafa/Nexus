import 'api_client.dart';

class StripeService {
  StripeService._();
  static final instance = StripeService._();

  Future<SubscriptionStatus?> fetchSubscription() async {
    final response = await ApiClient.instance.get('/user/subscription');
    final data = response.data['data'];
    if (data == null) return null;
    return SubscriptionStatus.fromJson(data as Map<String, dynamic>);
  }

  // The server builds the success/cancel URLs from NEXT_PUBLIC_APP_URL so
  // they always point to a network-accessible address the phone's browser
  // can reach — never localhost.
  Future<String> createCheckoutSession(String plan) async {
    final response = await ApiClient.instance.post(
      '/stripe/checkout',
      data: {'plan': plan},
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
