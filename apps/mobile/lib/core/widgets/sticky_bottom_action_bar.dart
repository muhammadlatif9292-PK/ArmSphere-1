import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'tactile_press_wrapper.dart';

/// Sticky Bottom Action Bar with Responsive Constraints & Keyboard Avoidance
///
/// Grounded in:
/// - `docs/design/01_PRODUCT_EXPERIENCE_AUDIT.md` (§4.3)
/// - `docs/design/22_SCREEN_BY_SCREEN_SPEC.md` (Line 177: max-width 640dp on wide viewports)
/// - `docs/design/27_UI_UX_IMPLEMENTATION_BACKLOG.md` ([P0-02])
///
/// Prevents soft keyboards from obscuring primary form CTAs.
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
    final effectiveBgColor = backgroundColor ?? AppTheme.cardSurface;
    final effectiveBorderColor = borderColor ?? AppTheme.border;

    Widget content = child ?? _buildDefaultContent(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        border: Border(
          top: BorderSide(color: effectiveBorderColor, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding,
              child: content,
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
                        ? AppTheme.elevatedSurface
                        : AppTheme.primaryAccent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: onPrimaryAction == null
                        ? Border.all(color: AppTheme.border, width: 1.0)
                        : null,
                    boxShadow: onPrimaryAction != null
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                              blurRadius: 8,
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
                            color: AppTheme.textPrimary,
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
                                    : AppTheme.textPrimary,
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
                                    : AppTheme.textPrimary,
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
