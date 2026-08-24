import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'core/providers/dependency_providers.dart';
import 'core/storage/hive_storage.dart';
import 'core/notifications/push_notification_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe using environment configuration
  try {
    Stripe.publishableKey = const String.fromEnvironment(
      'STRIPE_PUBLISHABLE_KEY',
      defaultValue: 'pk_test_mock_publishable_key',
    );
  } catch (_) {
    // Safe guard against duplicate initialization errors
  }

  // Initialize Hive local cache storage
  final hiveStorage = HiveStorage();
  await hiveStorage.initialize();

  runApp(
    ProviderScope(
      overrides: [
        // Allow overriding values for mocks/testing if needed
        hiveStorageProvider.overrideWithValue(hiveStorage),
      ],
      child: const ArmSphereApp(),
    ),
  );
}

class ArmSphereApp extends ConsumerStatefulWidget {
  const ArmSphereApp({Key? key}) : super(key: key);

  @override
  ConsumerState<ArmSphereApp> createState() => _ArmSphereAppState();
}

class _ArmSphereAppState extends ConsumerState<ArmSphereApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationManagerProvider).initialize(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ArmSphere Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
