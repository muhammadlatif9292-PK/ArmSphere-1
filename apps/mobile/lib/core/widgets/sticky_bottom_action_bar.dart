import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'main_shell_screen.dart';
import 'tactile_press_wrapper.dart';

/// Sticky Bottom Action Bar with Responsive Constraints & Keyboard Avoidance
///
/// Upgraded to Smoked Optical Glass:
/// - Backdrop filter blur (sigma 16) with heavy smoked glass substrate.
/// - Machined titanium top rim border with upper specular highlight line.
/// - Tactile CTA button with championship gradient.
/// - Safe area & MainShell dynamic dock clearance.
class StickyBottomActionBar extends StatelessWidget {
  final Widget? child;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final bool isLoading;
  final IconData? primaryActionIcon;
  final String? primarySemanticLabel;
  final Widget? secondaryAction;
  final String? disclaimerText;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double maxWidth;

  const StickyBottomActionBar({
    super.key,
    this.child,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.isLoading = false,
    this.primaryActionIcon,
    this.primarySemanticLabel,
    this.secondaryAction,
    this.disclaimerText,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppTheme.space16,
      vertical: AppTheme.space12,
    ),
    this.backgroundColor,
    this.borderColor,
    this.maxWidth = 640.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? AppTheme.glassSurfaceHeavy;
    final effectiveBorderColor = borderColor ?? AppTheme.borderTitanium;

    Widget content = child ?? _buildDefaultContent(context);

    final isInsideShell = MainShellScope.isInsideShell(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final shellClearance = (isInsideShell && !keyboardOpen) ? kFloatingDockTotalHeight : 0.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: effectiveBgColor,
            border: Border(
              top: BorderSide(color: effectiveBorderColor, width: 1.0),
            ),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x1AFFFFFF), // Fine specular highlight edge at top
                Colors.transparent,
              ],
              stops: [0.0, 0.25],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: shellClearance),
              child: Align(
                alignment: Alignment.center,
                heightFactor: 1.0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: padding,
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (disclaimerText != null) ...[
          Text(
            disclaimerText!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.fontBody,
              fontSize: 11.5,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            if (secondaryAction != null) ...[
              Expanded(flex: 1, child: secondaryAction!),
              const SizedBox(width: AppTheme.space12),
            ],
            Expanded(
              flex: secondaryAction != null ? 2 : 1,
              child: TactilePressWrapper(
                onTap: isLoading || onPrimaryAction == null
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onPrimaryAction!();
                      },
                semanticLabel: primarySemanticLabel ?? primaryActionLabel,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: onPrimaryAction == null
                        ? AppTheme.recessedSurface
                        : null,
                    gradient: onPrimaryAction != null
                        ? AppTheme.championshipGoldGradient
                        : null,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: onPrimaryAction == null
                        ? Border.all(color: AppTheme.borderTitanium, width: 1.0)
                        : Border.all(color: AppTheme.glassBorderSpecular, width: 1.0),
                    boxShadow: onPrimaryAction != null
                        ? [
                            BoxShadow(
                              color: AppTheme.goldGlow,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.black,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (primaryActionIcon != null) ...[
                              Icon(
                                primaryActionIcon,
                                color: onPrimaryAction == null
                                    ? AppTheme.textMuted
                                    : Colors.black,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              primaryActionLabel ?? 'Submit',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: onPrimaryAction == null
                                    ? AppTheme.textMuted
                                    : Colors.black,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
