import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/dio_client.dart';
import 'package:mobile/core/widgets/app_error_view.dart';

void main() {
  group('AppErrorView Widget Tests', () {
    testWidgets('Renders session expired state for 401 error without leaking raw status codes', (tester) async {
      final apiEx = ApiException(
        type: 'auth:session-expired',
        title: 'Session Expired',
        status: 401,
        detail: 'Please log in again.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              error: apiEx,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Dignified copy must be displayed
      expect(find.text('Session Expired'), findsOneWidget);
      expect(find.text('Your session has expired. Please sign in again to access federation data.'), findsOneWidget);
      expect(find.text('Sign In Again'), findsOneWidget);

      // Raw HTTP status codes must NEVER appear
      expect(find.textContaining('[401]'), findsNothing);
      expect(find.textContaining('ApiException'), findsNothing);
      expect(find.textContaining('Exception:'), findsNothing);
    });

    testWidgets('Offers Retry action for network errors and invokes callback on tap', (tester) async {
      var retried = false;
      final offlineEx = OfflineException('Network unreachable.');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              error: offlineEx,
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Connection Lost'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('Renders Access Restricted for 403 permission error without unauthorized action', (tester) async {
      final apiEx = ApiException(
        type: 'auth:forbidden',
        title: 'Forbidden',
        status: 403,
        detail: 'Unauthorized role.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              error: apiEx,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('You do not have authorization to perform this action with your current role.'), findsOneWidget);
      // Must not display "Sign In Again" or "Retry" when unauthorized
      expect(find.text('Sign In Again'), findsNothing);
      expect(find.text('Retry'), findsNothing);
      // Must provide secondary escape route
      expect(find.text('Return to Home'), findsOneWidget);
    });

    testWidgets('Provides secondary escape route ensuring user is never marooned', (tester) async {
      var secondaryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              title: 'Custom Error',
              message: 'Something went wrong.',
              primaryActionLabel: 'Retry Action',
              onPrimaryAction: () {},
              secondaryActionLabel: 'Back to Safety',
              onSecondaryAction: () {
                secondaryTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Custom Error'), findsOneWidget);
      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.text('Retry Action'), findsOneWidget);
      expect(find.text('Back to Safety'), findsOneWidget);

      await tester.tap(find.text('Back to Safety'));
      await tester.pump();

      expect(secondaryTapped, isTrue);
    });

    testWidgets('Cleanses raw exception strings containing [401] and stack traces', (tester) async {
      final rawException = Exception('[401] Session Expired: Please log in again.');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              error: rawException,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Session Expired'), findsOneWidget);
      expect(find.textContaining('[401]'), findsNothing);
      expect(find.textContaining('Exception:'), findsNothing);
    });
  });
}
