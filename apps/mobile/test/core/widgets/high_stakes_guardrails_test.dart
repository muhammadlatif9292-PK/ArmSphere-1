import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/biometric_provider.dart';
import 'package:mobile/core/providers/session_provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/session/screens/session_screens.dart';
import 'package:mobile/features/settings/screens/settings_hub_screens.dart';

class MockBiometricEnabledNotifier extends StateNotifier<AsyncValue<bool>>
    implements BiometricEnabledNotifier {
  MockBiometricEnabledNotifier() : super(const AsyncValue.data(false));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSessionNotifier extends SessionNotifier {
  final List<Map<String, dynamic>> sessions;
  bool revokeSessionCalled = false;
  String? revokedId;
  bool revokeOthersCalled = false;

  FakeSessionNotifier(this.sessions);

  @override
  Future<List<Map<String, dynamic>>> build() async => sessions;

  @override
  Future<bool> revokeSession(String sessionId) async {
    revokeSessionCalled = true;
    revokedId = sessionId;
    return true;
  }

  @override
  Future<bool> revokeOthers() async {
    revokeOthersCalled = true;
    return true;
  }
}

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  bool deleteAccountCalled = false;

  FakeAuthNotifier()
      : super(AuthState(
          status: AuthStatus.authenticated,
          userProfile: {'id': 'user_test', 'role': 'ATHLETE'},
        ));

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleSessions = [
    {
      'id': 'sess_1',
      'device': 'Pixel 8 Pro',
      'browser': 'Chrome',
      'os': 'Android 14',
      'ipAddress': '192.168.1.10',
      'createdAt': '2026-10-01T12:00:00Z',
      'expiresAt': '2026-11-01T12:00:00Z',
    },
    {
      'id': 'sess_2',
      'device': 'MacBook Pro',
      'browser': 'Safari',
      'os': 'macOS 15',
      'ipAddress': '192.168.1.20',
      'createdAt': '2026-10-02T12:00:00Z',
      'expiresAt': '2026-11-02T12:00:00Z',
    },
  ];

  group('ISSUE-P1-05 / BTN-016: Security Vault Session Revocation Guardrails', () {
    testWidgets('ActiveSessionControlScreen: Revoke This Session requires confirmation', (tester) async {
      final fakeSessionNotifier = FakeSessionNotifier(sampleSessions);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith(() => fakeSessionNotifier),
          ],
          child: const MaterialApp(
            home: ActiveSessionControlScreen(sessionId: 'sess_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find 'Revoke This Session' button
      final revokeBtn = find.widgetWithText(ElevatedButton, 'Revoke This Session');
      expect(revokeBtn, findsOneWidget);

      // Tap 'Revoke This Session'
      await tester.tap(revokeBtn);
      await tester.pumpAndSettle();

      // Confirmation modal must be visible
      expect(find.text('Revoke This Session?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Revoke Session'), findsOneWidget);
      expect(fakeSessionNotifier.revokeSessionCalled, isFalse);

      // Tap Cancel -> dismissal without revocation
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Revoke This Session?'), findsNothing);
      expect(fakeSessionNotifier.revokeSessionCalled, isFalse);

      // Tap again and confirm
      await tester.tap(revokeBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revoke Session'));
      await tester.pumpAndSettle();

      expect(fakeSessionNotifier.revokeSessionCalled, isTrue);
      expect(fakeSessionNotifier.revokedId, equals('sess_1'));
    });

    testWidgets('ActiveSessionControlScreen: Revoke All Other Sessions requires confirmation', (tester) async {
      final fakeSessionNotifier = FakeSessionNotifier(sampleSessions);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith(() => fakeSessionNotifier),
          ],
          child: const MaterialApp(
            home: ActiveSessionControlScreen(sessionId: 'sess_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find 'Revoke All Other Sessions' button
      final revokeOthersBtn = find.widgetWithText(OutlinedButton, 'Revoke All Other Sessions');
      expect(revokeOthersBtn, findsOneWidget);

      // Tap 'Revoke All Other Sessions'
      await tester.tap(revokeOthersBtn);
      await tester.pumpAndSettle();

      // Confirmation modal must be visible
      expect(find.text('Revoke Other Sessions?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Revoke Other Sessions'), findsOneWidget);
      expect(fakeSessionNotifier.revokeOthersCalled, isFalse);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Revoke Other Sessions?'), findsNothing);
      expect(fakeSessionNotifier.revokeOthersCalled, isFalse);

      // Tap again and confirm
      await tester.tap(revokeOthersBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revoke Other Sessions'));
      await tester.pumpAndSettle();

      expect(fakeSessionNotifier.revokeOthersCalled, isTrue);
    });

    testWidgets('ActiveSessionsListScreen: shows Revoke All Other Sessions button when sessions > 1 with confirmation', (tester) async {
      final fakeSessionNotifier = FakeSessionNotifier(sampleSessions);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith(() => fakeSessionNotifier),
            biometricCapabilityProvider
                .overrideWith((ref) async => BiometricCapability.unsupported),
            biometricEnabledProvider
                .overrideWith((ref) => MockBiometricEnabledNotifier()),
          ],
          child: const MaterialApp(
            home: ActiveSessionsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify sessions are rendered
      expect(find.text('SIGNED-IN DEVICES'), findsOneWidget);

      // Verify bottom bulk revocation button is present
      final bulkRevokeBtn = find.widgetWithText(OutlinedButton, 'Revoke All Other Sessions');
      expect(bulkRevokeBtn, findsOneWidget);

      // Tap bulk revocation button
      await tester.tap(bulkRevokeBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Revoke Other Sessions?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(fakeSessionNotifier.revokeOthersCalled, isFalse);

      // Tap and confirm
      await tester.tap(bulkRevokeBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revoke Other Sessions'));
      await tester.pumpAndSettle();
      expect(fakeSessionNotifier.revokeOthersCalled, isTrue);
    });

    testWidgets('ActiveSessionsListScreen: does NOT show Revoke All Other Sessions button when only 1 session', (tester) async {
      final singleSessionNotifier = FakeSessionNotifier([sampleSessions.first]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith(() => singleSessionNotifier),
            biometricCapabilityProvider
                .overrideWith((ref) async => BiometricCapability.unsupported),
            biometricEnabledProvider
                .overrideWith((ref) => MockBiometricEnabledNotifier()),
          ],
          child: const MaterialApp(
            home: ActiveSessionsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Revoke All Other Sessions'), findsNothing);
    });
  });

  group('ISSUE-P1-05 / BTN-017: Account Deletion 2-Step Confirmation Guardrails', () {
    testWidgets('AccountDeletionScreen: requires checkbox then confirmation modal before deletion', (tester) async {
      final fakeAuthNotifier = FakeAuthNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => fakeAuthNotifier),
          ],
          child: const MaterialApp(
            home: AccountDeletionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'Permanently Delete My Account');
      expect(deleteBtnFinder, findsOneWidget);

      // Button is initially disabled
      final initialButton = tester.widget<ElevatedButton>(deleteBtnFinder);
      expect(initialButton.onPressed, isNull);

      // Tick the acknowledgment checkbox
      final checkboxFinder = find.byType(CheckboxListTile);
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Button should now be enabled
      final enabledButton = tester.widget<ElevatedButton>(deleteBtnFinder);
      expect(enabledButton.onPressed, isNotNull);

      // Tap delete button -> triggers confirmation dialog, NOT immediate deletion
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Confirm Account Deletion'), findsOneWidget);
      expect(find.text('Keep Account'), findsOneWidget);
      expect(find.text('Permanently Delete'), findsOneWidget);
      expect(fakeAuthNotifier.deleteAccountCalled, isFalse);

      // Tap 'Keep Account' -> dismisses dialog and preserves account
      await tester.tap(find.text('Keep Account'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Account Deletion'), findsNothing);
      expect(fakeAuthNotifier.deleteAccountCalled, isFalse);

      // Tap again and confirm permanent deletion
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Permanently Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeAuthNotifier.deleteAccountCalled, isTrue);
    });
  });
}
