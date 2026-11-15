import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'main_shell_screen.dart';
import 'tactile_press_wrapper.dart';

/// Sticky Bottom Action Bar with Responsive Constraints & Keyboard Avoidance
///
/// Upgraded to ArmSphere Crystal Glassmorphism Design System:
/// - Optical BackdropFilter blur (`sigma: 16`) with deep smoked crystal glass substrate.
/// - Specular top rim reflection highlight.
/// - Frosted Crystal Glass primary action button with gold specular rim and glow.
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
  final bool? isKeyboardOpen;

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
    this.isKeyboardOpen,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? const Color(0x38FFFFFF);

    final Widget content = child ?? _buildDefaultContent(context);

    final isInsideShell = MainShellScope.isInsideShell(context);
    final keyboardOpen = isKeyboardOpen ??
        (MediaQuery.viewInsetsOf(context).bottom > 0 ||
            ((View.maybeOf(context)?.viewInsets.bottom ?? 0) > 0));
    final shellClearance =
        (isInsideShell && !keyboardOpen) ? kFloatingDockTotalHeight : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(color: effectiveBorderColor, width: 1.0),
        ),
        boxShadow: const [],
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
    );
  }

  Widget _buildDefaultContent(BuildContext context) {
    final bool isEnabled = !isLoading && onPrimaryAction != null;
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
              shadows: AppTheme.crystalTextShadows,
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
                onTap: !isEnabled
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onPrimaryAction!();
                      },
                semanticLabel: primarySemanticLabel ?? primaryActionLabel,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: onPrimaryAction == null
                          ? const Color(0x38FFFFFF)
                          : const Color(0x73D4AF37),
                      width: onPrimaryAction == null ? 1.0 : 1.2,
                    ),
                    boxShadow: const [],
                  ),
                  alignment: Alignment.center,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppTheme.goldPrimary,
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
                                    : AppTheme.goldPrimary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                primaryActionLabel ?? 'Submit',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: onPrimaryAction == null
                                      ? AppTheme.textMuted
                                      : AppTheme.textPure,
                                  letterSpacing: 0.5,
                                  shadows: AppTheme.crystalTextShadows,
                                ),
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
