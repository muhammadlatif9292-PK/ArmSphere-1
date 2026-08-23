import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App-wide custom page transitions builder for push/pop navigation.
///
/// Forward (push):
/// - Incoming screen: slides in from x-offset 30% of screen width to 0, opacity 0 -> 1,
///   over 300ms duration, Curves.easeOutCubic.
/// - Outgoing screen: slides to -10% offset, opacity 1 -> 0.85, scale 1.0 -> 0.98.
///
/// Reverse (pop):
/// - Same shape over 250ms reverseTransitionDuration.
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
    Key? key,
    required this.primaryAnimation,
    required this.secondaryAnimation,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CurvedAnimation primaryCurve = CurvedAnimation(
      parent: primaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );

    final CurvedAnimation secondaryCurve = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );

    // Primary (Incoming screen on push / Exiting screen on pop)
    final Animation<Offset> primarySlide = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(primaryCurve);

    final Animation<double> primaryFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(primaryCurve);

    // Secondary (Outgoing screen beneath new route)
    final Animation<Offset> secondarySlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.1, 0.0),
    ).animate(secondaryCurve);

    final Animation<double> secondaryFade = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(secondaryCurve);

    final Animation<double> secondaryScale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(secondaryCurve);

    return SlideTransition(
      position: secondarySlide,
      child: FadeTransition(
        opacity: secondaryFade,
        child: ScaleTransition(
          scale: secondaryScale,
          child: SlideTransition(
            position: primarySlide,
            child: FadeTransition(
              opacity: primaryFade,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// App-wide custom GoRouter transition page.
///
/// Configures transitionDuration to 300ms (forward push) and
/// reverseTransitionDuration to 250ms (reverse pop) with [AppCustomPageTransition].
class AppTransitionPage extends CustomTransitionPage<void> {
  AppTransitionPage({
    required Widget child,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) : super(
          key: key,
          name: name,
          arguments: arguments,
          restorationId: restorationId,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AppCustomPageTransition(
              primaryAnimation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
        );
}

