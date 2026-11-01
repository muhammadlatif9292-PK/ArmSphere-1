// lib/core/routing/page_transitions.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// App-wide custom page transitions builder for push/pop navigation.
///
/// Engineered for Zero Header Bleed & Zero Double-Exposure Overlap:
/// - Outgoing screen (`secondaryAnimation`): rapidly fades `1.0 -> 0.0` in the first
///   42% of the transition (`Interval(0.0, 0.42)`) with a subtle `-4%` horizontal shift,
///   ensuring the outgoing header and action buttons dissolve completely before the
///   incoming header settles.
/// - Incoming screen (`primaryAnimation`): backed by a 100% opaque `#070A11` void
///   substrate (`ColoredBox(color: AppTheme.voidBackground)`) that seals the route
///   within the first 25% of the transition while the incoming screen glides from
///   `+6%` x-offset to `0.0` over `220ms` (`Curves.easeOutCubic`).
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AppCustomPageTransition(
      primaryAnimation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class AppCustomPageTransition extends StatelessWidget {
  final Animation<double> primaryAnimation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const AppCustomPageTransition({
    super.key,
    required this.primaryAnimation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Incoming content motion curve
    final CurvedAnimation primarySlideCurve = CurvedAnimation(
      parent: primaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Incoming content opacity: starts after outgoing header begins dissolving
    final Animation<double> primaryContentFade = CurvedAnimation(
      parent: primaryAnimation,
      curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0.0, 0.82, curve: Curves.easeInCubic),
    );

    // Fast opaque void substrate seal so underlying route never bleeds through
    final Animation<double> primaryBackdropFade = CurvedAnimation(
      parent: primaryAnimation,
      curve: const Interval(0.0, 0.28, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.28, curve: Curves.easeIn),
    );

    // Outgoing screen beneath new route: dissolves completely in first 42%
    final Animation<double> secondaryFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOut),
        reverseCurve: const Interval(0.0, 0.42, curve: Curves.easeIn),
      ),
    );

    final Animation<Offset> secondarySlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.04, 0.0),
    ).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    final Animation<Offset> primarySlide = Tween<Offset>(
      begin: const Offset(0.06, 0.0),
      end: Offset.zero,
    ).animate(primarySlideCurve);

    return SlideTransition(
      position: secondarySlide,
      child: FadeTransition(
        opacity: secondaryFade,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            FadeTransition(
              opacity: primaryBackdropFade,
              child: const ColoredBox(
                color: AppTheme.voidBackground,
                child: SizedBox.expand(),
              ),
            ),
            SlideTransition(
              position: primarySlide,
              child: FadeTransition(
                opacity: primaryContentFade,
                child: ColoredBox(
                  color: AppTheme.voidBackground,
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// App-wide custom GoRouter transition page.
///
/// Configures transitionDuration to 220ms (forward push) and
/// reverseTransitionDuration to 180ms (reverse pop) with [AppCustomPageTransition].
class AppTransitionPage extends CustomTransitionPage<void> {
  AppTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          opaque: true,
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AppCustomPageTransition(
              primaryAnimation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
        );
}
