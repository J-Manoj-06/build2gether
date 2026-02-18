/// Payment Service for Razorpay Integration
///
/// Handles all payment-related operations using Razorpay
library;

import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  late Razorpay _razorpay;

  PaymentService() {
    _razorpay = Razorpay();
  }

  /// Open Razorpay checkout
  Future<void> openCheckout({
    required double amount,
    required String name,
    required String email,
    required String contact,
    required String description,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(Map<String, dynamic>) onFailure,
  }) async {
    // Convert amount to paise (Razorpay requires amount in smallest currency unit)
    final amountInPaise = (amount * 100).toInt();

    print(
      'DEBUG Payment: Opening Razorpay with amount: ₹$amount ($amountInPaise paise)',
    );

    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your actual Razorpay key
      'amount': amountInPaise,
      'name': 'Build2gether',
      'description': description,
      'prefill': {'contact': contact, 'email': email, 'name': name},
      'theme': {'color': '#2E7D32'},
    };

    // Set up event listeners
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
      print('✅ Payment Success: $response');
      onSuccess(response as Map<String, dynamic>);
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      print('❌ Payment Error: $response');
      onFailure(response as Map<String, dynamic>);
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (response) {
      print('💳 External Wallet: $response');
      // Handle external wallet selection if needed
      onFailure({
        'code': 'external_wallet',
        'message': 'External wallet selected: ${response['wallet_name']}',
      });
    });

    try {
      _razorpay.open(options);
    } catch (e) {
      print('❌ Error opening Razorpay: $e');
      onFailure({
        'code': 'error',
        'message': 'Failed to open payment gateway: $e',
      });
    }
  }

  /// Dispose Razorpay instance
  void dispose() {
    _razorpay.clear();
  }
}
