import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../providers/state_providers.dart';
import '../routing/app_router.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services here, make sure to initialize Firebase first.
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationManager {
  static final PushNotificationManager _instance = PushNotificationManager._internal();
  factory PushNotificationManager() => _instance;
  PushNotificationManager._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _cachedToken;
  String? _deviceId;
  dynamic _widgetRef;

  Future<void> initialize(dynamic ref) async {
    if (_initialized) return;
    _widgetRef = ref;

    if (kIsWeb) {
      // FCM web push requires its own Firebase Web app config (apiKey/appId/
      // messagingSenderId), a VAPID key, and a firebase-messaging-sw.js
      // service worker under web/ — none of which exist in this repo yet
      // (there is no google-services.json/firebase_options.dart for any
      // platform in this checkout). Rather than half-initialize FCM against
      // absent config, the web build cleanly skips push registration; every
      // other feature (auth, navigation, tournaments, community, etc.) is
      // unaffected. In-app/local notification UI still works normally.
      debugPrint(
        "PushNotificationManager: skipping FCM/device registration on web preview (no Firebase Web config present).",
      );
      _initialized = true;
      return;
    }

    try {
      // Initialize Firebase App
      await Firebase.initializeApp();
      
      // Set the background messaging handler early on, as a top-level function
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize local notifications for foreground display
      await _initializeLocalNotifications();

      // Request permissions
      await requestPermissions();

      // Configure foreground message presentation options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Foreground message received: ${message.notification?.title}");
        _showLocalNotification(message);
      });

      // Handle notification taps when app is in background or terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("Notification tapped (opened app): ${message.data}");
        _handleNotificationTap(message.data);
      });

      // Check if app was opened from a terminated state via a notification
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint("App opened from terminated state via notification: ${initialMessage.data}");
        _handleNotificationTap(initialMessage.data);
      }

      // Automatically register device if token changes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint("FCM Token refreshed: $newToken");
        _cachedToken = newToken;
        _registerDeviceWithServer(newToken);
      });

      _initialized = true;
      debugPrint("PushNotificationManager initialized successfully.");
    } catch (e) {
      debugPrint("PushNotificationManager initialization failed: $e");
      debugPrint("Ensure you have placed google-services.json (Android) and GoogleService-Info.plist (iOS) in respective platform folders.");
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            // Decode the payload and route
            final data = Uri.splitQueryString(payload);
            _handleNotificationTap(data);
          } catch (e) {
            debugPrint("Error parsing local notification tap payload: $e");
          }
        }
      },
    );
  }

  Future<void> requestPermissions() async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // FCM request permissions
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint("Notification authorization status: ${settings.authorizationStatus}");

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Request FCM Token
        final token = await messaging.getToken();
        _cachedToken = token;
        debugPrint("FCM Token: $token");
        if (token != null) {
          await _registerDeviceWithServer(token);
        }
      }
    } catch (e) {
      debugPrint("Error requesting notification permissions: $e");
    }
  }

  Future<void> registerCurrentDevice() async {
    if (_cachedToken != null) {
      await _registerDeviceWithServer(_cachedToken!);
    } else {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        _cachedToken = token;
        if (token != null) {
          await _registerDeviceWithServer(token);
        }
      } catch (e) {
        debugPrint("FCM getToken failed: $e");
      }
    }
  }

  Future<void> deregisterCurrentDevice() async {
    try {
      final deviceId = await _getUniqueDeviceId();
      if (_widgetRef != null) {
        final repository = _widgetRef!.read(notificationRepositoryProvider);
        await repository.deregisterDevice(deviceId);
        debugPrint("Successfully deregistered device: $deviceId");
      }
    } catch (e) {
      debugPrint("Failed to deregister device: $e");
    }
  }

  Future<void> _registerDeviceWithServer(String token) async {
    if (_widgetRef == null) return;

    try {
      final deviceId = await _getUniqueDeviceId();
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      final locale = PlatformDispatcher.instance.locale.toLanguageTag();
      final timezone = DateTime.now().timeZoneName;
      final platform = defaultTargetPlatform == TargetPlatform.android
          ? 'android'
          : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'unknown');

      final repository = _widgetRef!.read(notificationRepositoryProvider);
      
      debugPrint("Registering device: $deviceId with server. Token: $token");
      await repository.registerDevice(
        deviceId: deviceId,
        platform: platform,
        fcmToken: token,
        appVersion: appVersion,
        locale: locale,
        timezone: timezone,
        pushEnabled: true,
      );
    } catch (e) {
      debugPrint("Failed to register device token with server: $e");
    }
  }

  Future<String> _getUniqueDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    final deviceInfo = DeviceInfoPlugin();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id; // Unique ID on Android
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor ?? const Uuid().v4();
      } else {
        _deviceId = const Uuid().v4();
      }
    } catch (_) {
      _deviceId = const Uuid().v4();
    }
    return _deviceId!;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'armsphere_channel',
      'ArmSphere Notifications',
      channelDescription: 'General notifications for matches, events, and messages.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // Convert Map<String, dynamic> data to URI query string for simple payload serialization
    final data = message.data;
    final payloadString = Uri(queryParameters: data.map((k, v) => MapEntry(k, v.toString()))).query;

    await _localNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: payloadString,
    );
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    if (_widgetRef == null) return;

    final router = _widgetRef!.read(routerProvider);

    // Parse notification type or specific fields to deep-link
    final conversationId = data['conversationId']?.toString();
    final eventId = data['eventId']?.toString();
    final venueId = data['venueId']?.toString();
    final postId = data['postId']?.toString();
    final category = data['category']?.toString() ?? data['type']?.toString();

    debugPrint("Routing notification tap: conversationId=$conversationId, eventId=$eventId, venueId=$venueId, postId=$postId, category=$category");

    try {
      if (conversationId != null && conversationId.isNotEmpty) {
        router.push('/messages/$conversationId');
      } else if (eventId != null && eventId.isNotEmpty) {
        if (category == 'INFORMAL_EVENT') {
          router.push('/informal-events/detail/$eventId');
        } else {
          router.push('/events/$eventId/register');
        }
      } else if (venueId != null && venueId.isNotEmpty) {
        router.push('/venues/detail/$venueId');
      } else if (postId != null && postId.isNotEmpty) {
        router.push('/community/posts/$postId/comments');
      } else {
        // Fallback or generic routes
        if (category == 'ANNOUNCEMENT') {
          router.push('/announcements');
        } else if (category == 'TICKET') {
          router.push('/settings/tickets');
        } else {
          router.push('/notifications');
        }
      }
    } catch (e) {
      debugPrint("Deep-linking navigation failed: $e");
    }
  }
}

// State provider for PushNotificationManager
final pushNotificationManagerProvider = Provider<PushNotificationManager>((ref) {
  return PushNotificationManager();
});
