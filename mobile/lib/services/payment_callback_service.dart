import 'package:flutter/foundation.dart';

/// Holds the Stripe session_id received via deep link after a successful checkout.
/// main.dart writes to [pendingSessionId]; PremiumScreen reads and clears it.
class PaymentCallbackService {
  PaymentCallbackService._();
  static final instance = PaymentCallbackService._();

  final ValueNotifier<String?> pendingSessionId = ValueNotifier(null);
  final ValueNotifier<bool> paymentCanceled = ValueNotifier(false);

  void onSuccess(String sessionId) {
    pendingSessionId.value = sessionId;
  }

  void onCanceled() {
    paymentCanceled.value = true;
    // Reset after a tick so listeners can react once
    Future.microtask(() => paymentCanceled.value = false);
  }
}
