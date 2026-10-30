import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../utils/error_formatter.dart';
import 'tactile_press_wrapper.dart';

/// Standardized Contextual Error View & Recovery Component
///
/// Implements Canonical Stage 2 Specification (P1-03 / Task 36):
/// - Replaces raw exception leaks, stack dumps, and unformatted HTTP error envelopes.
/// - Contextual categorization: distinguishes Auth/Session Expired, Permission Denied,
///   Connection Offline/Timeout, and Server Unavailable.
/// - Two-way recovery navigation: primary recovery action (Retry / Sign In) alongside
///   a safe secondary escape route (Return to Home / Directory / Back) so users are never marooned.
/// - Smoked optical glass styling with Space Grotesk typography and tactile feedback.
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
      if (Navigator.of(context).canPop()) {
        secondaryLabel = 'Go Back';
        secondaryAction = () => Navigator.of(context).maybePop();
      } else {
        secondaryLabel = 'Return to Home';
        secondaryAction = () => context.go('/');
      }
    }

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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Emblem
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cardSurface,
                  border: Border.all(
                    color: isAuth || isPermission
                        ? AppTheme.goldPrimary.withValues(alpha: 0.6)
                        : AppTheme.borderSubtle,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    effectiveIcon,
                    size: 30,
                    color: isAuth
                        ? AppTheme.goldPrimary
                        : isPermission
                            ? AppTheme.warning
                            : isNetwork
                                ? AppTheme.goldLight
                                : AppTheme.goldPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                effectiveTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFamily: 'Space Grotesk',
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  effectiveMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons Row / Column
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  if (primaryLabel != null && primaryAction != null)
                    TactilePressWrapper(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        primaryAction!();
                      },
                      semanticLabel: primaryLabel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.elevatedSurface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          primaryLabel,
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            color: AppTheme.goldPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  if (secondaryLabel != null && secondaryAction != null)
                    TactilePressWrapper(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        secondaryAction!();
                      },
                      semanticLabel: secondaryLabel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(
                            color: AppTheme.borderSubtle,
                          ),
                        ),
                        child: Text(
                          secondaryLabel,
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
