/// Stub for flutter_stripe package on web.
///
/// This file provides minimal, compile-time-safe placeholders used when
/// building the Flutter web target. They deliberately throw UnsupportedError
/// at runtime to avoid accidental usage in unsupported environments.

// Keep no export directives here; real package is used on mobile targets.

class UnsupportedStripeError extends UnsupportedError {
  UnsupportedStripeError([String message = 'Stripe native integration is not supported on this platform.']) : super(message);
}

class SetupPaymentSheetParameters {
  const SetupPaymentSheetParameters();
}

class PaymentSheetParameters {
  const PaymentSheetParameters();
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

enum PaymentResult { succeeded, failed, canceled }

class Stripe {
  Stripe._();

  static String publishableKey = '';

  static void initPaymentSheet({
    required SetupPaymentSheetParameters paymentSheetParameters,
  }) {
    throw UnsupportedStripeError();
  }

  static Future<PaymentResult> presentPaymentSheet() async {
    throw UnsupportedStripeError();
  }

  static Future<void> initGooglePay(PaymentSheetGooglePayParameters parameters) async {
    throw UnsupportedStripeError();
  }

  static Future<void> initApplePay(PaymentSheetApplePayParameters parameters) async {
    throw UnsupportedStripeError();
  }

  static Future<void> presentPaymentGateway(PaymentSheetPaymentGatewayParameters parameters) async {
    throw UnsupportedStripeError();
  }
}
