import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../utils/error_formatter.dart';
import 'crystal_glass_nav_controls.dart';
import 'main_shell_screen.dart';

/// Standardized Contextual Error View & Recovery Component
///
/// Upgraded to ArmSphere Crystal Glassmorphism Design System:
/// - Frosted Crystal Glass diagnostic panel with optical blur (`sigma: 16`)
///   and semantic crimson/gold specular rim.
/// - Replaces raw exception leaks, stack dumps, and unformatted HTTP error envelopes.
/// - Contextual categorization: distinguishes Auth/Session Expired, Permission Denied,
///   Connection Offline/Timeout, and Server Unavailable.
/// - Two-way recovery navigation with [CrystalActionButton] controls.
class AppErrorView extends StatefulWidget {
  final Object? error;
  final String? title;
  final String? message;
  final IconData? icon;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onRetry;

  /// When false, the automatic escape action (Go Back / Return to Home) is not
  /// added. Use on screens that already sit inside a navigation shell. An
  /// explicit [secondaryActionLabel] and [onSecondaryAction] are still honoured.
  final bool showSecondaryAction;

  /// Replaces the default Sign In Again action (`context.go('/login')`) for
  /// authentication errors. Leave null to keep the default.
  final VoidCallback? onSessionExpired;

  const AppErrorView({
    super.key,
    this.error,
    this.title,
    this.message,
    this.icon,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.onRetry,
    this.showSecondaryAction = true,
    this.onSessionExpired,
  });

  @override
  State<AppErrorView> createState() => _AppErrorViewState();
}

class _AppErrorViewState extends State<AppErrorView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<double>(begin: 10.0, end: 0.0).animate(curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = AppErrorFormatter.isAuthError(widget.error);
    final isPermission = AppErrorFormatter.isPermissionError(widget.error);
    final isNetwork = AppErrorFormatter.isNetworkError(widget.error);

    // 1. Determine Icon
    final effectiveIcon = widget.icon ??
        (isAuth
            ? Icons.lock_clock_outlined
            : isPermission
                ? Icons.gpp_bad_outlined
                : isNetwork
                    ? Icons.wifi_off_rounded
                    : Icons.cloud_off_rounded);

    // 2. Determine Title
    final effectiveTitle = widget.title ??
        (isAuth
            ? 'Session Expired'
            : isPermission
                ? 'Access Restricted'
                : isNetwork
                    ? 'Connection Lost'
                    : 'Service Unavailable');

    // 3. Determine Message
    final effectiveMessage = widget.message ??
        (isAuth
            ? 'Your session has expired. Please sign in again to access federation data.'
            : isPermission
                ? 'You do not have authorization to perform this action with your current role.'
                : isNetwork
                    ? 'Unable to connect to ArmSphere servers. Please check your internet connection and try again.'
                    : AppErrorFormatter.format(widget.error));

    // 4. Determine Primary Action
    String? primaryLabel = widget.primaryActionLabel;
    VoidCallback? primaryAction = widget.onPrimaryAction;

    if (primaryLabel == null && primaryAction == null) {
      if (isAuth) {
        primaryLabel = 'Sign In Again';
        primaryAction = widget.onSessionExpired ??
            () {
              if (context.mounted) {
                context.go('/login');
              }
            };
      } else if (widget.onRetry != null) {
        primaryLabel = 'Retry';
        primaryAction = widget.onRetry;
      }
    }

    // 5. Determine Secondary Action (Escape Route)
    String? secondaryLabel = widget.secondaryActionLabel;
    VoidCallback? secondaryAction = widget.onSecondaryAction;

    if (secondaryLabel == null &&
        secondaryAction == null &&
        widget.showSecondaryAction) {
      final router = GoRouter.maybeOf(context);
      if ((router != null && router.canPop()) ||
          Navigator.of(context).canPop()) {
        secondaryLabel = 'Go Back';
        secondaryAction = () {
          if (router != null && router.canPop()) {
            router.pop();
          } else {
            Navigator.of(context).maybePop();
          }
        };
      } else {
        secondaryLabel = 'Return to Home';
        secondaryAction = () {
          if (!MainShellScope.stepBackIfPossible(context)) {
            if (!MainShellScope.goToMainTabByPath(context, '/home')) {
              context.go('/');
            }
          }
        };
      }
    }

    final Color accentColor = isAuth
        ? AppTheme.goldPrimary
        : isPermission
            ? AppTheme.warning
            : isNetwork
                ? AppTheme.goldPrimary
                : AppTheme.crimson;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.52),
                    blurRadius: 26,
                    spreadRadius: -2,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.16),
                    blurRadius: 20,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 26,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xD90A0F1A),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.45),
                        width: 1.1,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.0, 0.48, 1.0],
                        colors: [
                          accentColor.withValues(alpha: 0.16),
                          const Color(0x14FFFFFF),
                          const Color(0x06FFFFFF),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Frosted Crystal Error Emblem
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(alpha: 0.14),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.52),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.24),
                                blurRadius: 14,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              effectiveIcon,
                              size: 30,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          effectiveTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textPure,
                            fontWeight: FontWeight.w700,
                            fontSize: 16.5,
                            fontFamily: AppTheme.fontDisplay,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          effectiveMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        if ((primaryLabel != null && primaryAction != null) ||
                            (secondaryLabel != null &&
                                secondaryAction != null)) ...[
                          const SizedBox(height: 22),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              if (primaryLabel != null && primaryAction != null)
                                CrystalActionButton(
                                  label: primaryLabel,
                                  icon: isAuth
                                      ? Icons.login_rounded
                                      : Icons.refresh_rounded,
                                  onTap: primaryAction,
                                  accentColor: AppTheme.goldPrimary,
                                  isPrimary: true,
                                ),
                              if (secondaryLabel != null &&
                                  secondaryAction != null)
                                CrystalActionButton(
                                  label: secondaryLabel,
                                  icon: secondaryLabel == 'Go Back'
                                      ? Icons.arrow_back_rounded
                                      : Icons.home_outlined,
                                  onTap: secondaryAction,
                                  isPrimary: false,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
