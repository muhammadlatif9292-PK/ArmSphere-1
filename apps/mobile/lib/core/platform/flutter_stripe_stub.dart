/// Stub for flutter_stripe package.
///
/// Stripe native plugin is mobile-only. On web, throw NotImplementedError
/// to prevent runtime crashes. Note: Stripe.js can work via URL handlers
/// (e.g., stripe://) or external payment flows.

class _StripeStub {
  static throwNotImplementedError() {
    throw NotImplementedError(
      'Stripe native integration is not supported in web build. '
      'Stripe.js can be integrated via URL schemes or server-side redirects for web payments. '
      'See: https://stripe.com/docs/payments/accept-a-payment',
    );
  }
}

// Re-export the Stripe class but throw on instantiation
export 'package:flutter_stripe/flutter_stripe.dart' hide Card;

class Stripe {
  Stripe._();

  static String publishableKey = '';
  static String? deferredPrompt;

  static void initPaymentSheet({
    required SetupPaymentSheetParameters paymentSheetParameters,
  }) {
    throwNotImplementedError();
  }

  static Future<PaymentResult> presentPaymentSheet() async {
    throwNotImplementedError();
    return PaymentResult.failure();
  }

  static Future<void> initGooglePay(
    PaymentSheetGooglePayParameters parameters,
  ) async {
    throwNotImplementedError();
  }

  static Future<void> initApplePay(
    PaymentSheetApplePayParameters parameters,
  ) async {
    throwNotImplementedError();
  }

  static Future<void> presentPaymentGateway(
    PaymentSheetPaymentGatewayParameters parameters,
  ) async {
    throwNotImplementedError();
  }
}

// Re-export PaymentResult enum
export 'package:flutter_stripe/flutter_stripe.dart' show PaymentResult;

enum PaymentResult {
  succeeded,
  failed,
  canceled,
}

// Re-export PaymentSheetParameters types
export 'package:flutter_stripe/flutter_stripe.dart' show
    PaymentSheetParameters,
    SetupPaymentSheetParameters,
    PaymentSheetGooglePayParameters,
    PaymentSheetApplePayParameters,
    PaymentSheetPaymentGatewayParameters;
