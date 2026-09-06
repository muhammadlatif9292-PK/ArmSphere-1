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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:local_auth/local_auth.dart';
import 'package:image_picker/image_picker.dart';
