/// Stub for flutter_stripe package.
///
/// Stripe native plugin is mobile-only. On web, throw NotImplementedError
/// to prevent runtime crashes. Note: Stripe.js can work via URL handlers
/// (e.g., stripe://) or external payment flows.

Never throwNotImplementedError() {
  throw UnsupportedError(
    'Stripe native integration is not supported in web build. '
    'Use a web payment redirect instead.',
  );
}

class Stripe {
  Stripe._();

  static String publishableKey = '';
  static String? deferredPrompt;

  static Future<void> initPaymentSheet({
    required SetupPaymentSheetParameters paymentSheetParameters,
  }) async {
    throwNotImplementedError();
  }

  static Future<void> presentPaymentSheet() async {
    throwNotImplementedError();
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

class SetupPaymentSheetParameters {
  const SetupPaymentSheetParameters();
}

class PaymentSheetGooglePayParameters {
  const PaymentSheetGooglePayParameters();
}

class PaymentSheetApplePayParameters {
  const PaymentSheetApplePayParameters();
}

class PaymentSheetPaymentGatewayParameters {
  const PaymentSheetPaymentGatewayParameters();
}
