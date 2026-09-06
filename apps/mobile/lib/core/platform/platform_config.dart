/// Platform-specific configuration and imports.
///
/// This file provides conditional imports for packages that have no web
/// implementation, enabling Flutter Web builds while maintaining native
/// functionality for mobile platforms.

// Platform detection
import 'package:flutter/foundation.dart';

/// Conditional import for flutter_secure_storage.
///
/// Native-only (Android Keystore + iOS Keychain). On web, this stub provides
/// a no-op implementation that persists to localStorage for demo purposes.
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    if (dart.library.html) 'platform_stubs.dart';

/// Conditional import for flutter_local_notifications.
///
/// Native-only. On web, this stub provides no-op methods for demo purposes.
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    if (dart.library.html) 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Conditional import for webview_flutter.
///
/// Native-only. On web, this stub throws UnsupportedOperationException.
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter
    if (dart.library.html) 'webview_flutter_stub.dart';

/// Conditional import for flutter_stripe.
///
/// Native-only. On web, this stub throws NotImplementedError.
import 'package:flutter_stripe/flutter_stripe.dart' as stripe
    if (dart.library.html) 'flutter_stripe_stub.dart';

/// Conditional import for local_auth.
///
/// Native-only (biometrics). On web, this stub provides no-op methods.
import 'package:local_auth/local_auth.dart'
    if (dart.library.html) 'local_auth_stub.dart';

/// Conditional import for image_picker.
///
/// Native-only. On web, this stub throws NotImplementedError.
import 'package:image_picker/image_picker.dart'
    if (dart.library.html) 'image_picker_stub.dart';
