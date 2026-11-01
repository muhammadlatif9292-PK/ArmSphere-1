import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Standardized Crystal Glassmorphic Modal Bottom Sheet Surface.
///
/// Enforces:
/// - Optical frosted glass (`BackdropFilter` sigma 24) with top specular rim highlight.
/// - Declarative tap-away unfocus: tapping anywhere on the sheet background or section
///   headers immediately unfocuses active typing inputs and clears selection.
/// - Interactive top grab-handle bar: tapping the top handle bar or close button
///   unfocuses any active input and toggles (closes) the modal sheet.
/// - Pinned bottom Crystal Action Bar: keeps the primary Save / Submit CTA 100%
///   visible above the system navigation bar and keyboard inset.
class CrystalModalSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? headerIcon;
  final Widget child;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final VoidCallback? onPrimaryAction;
  final bool isPrimaryLoading;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Key? primaryActionKey;
  final EdgeInsetsGeometry contentPadding;
  final double maxHeightFactor;

  const CrystalModalSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.headerIcon,
    required this.child,
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.onPrimaryAction,
    this.isPrimaryLoading = false,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.primaryActionKey,
    this.contentPadding = const EdgeInsets.fromLTRB(18, 12, 18, 18),
    this.maxHeightFactor = 0.88,
  });

  /// Unfocuses any active text field or selection in the current focus tree.
  static void unfocusActiveInput([BuildContext? context]) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (context != null) {
      try {
        final scope = FocusScope.of(context);
        if (scope.hasFocus) {
          scope.unfocus();
        }
      } catch (_) {}
    }
  }

  /// Helper to convert IconData or Widget into a standard input icon.
  static Widget? _resolveInputIcon(dynamic icon) {
    if (icon == null) return null;
    if (icon is Widget) return icon;
    if (icon is IconData) {
      return Icon(icon, size: 18, color: AppTheme.textSecondary);
    }
    return null;
  }

  /// Standardized frosted Crystal Glass input decoration for fields & dropdowns.
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    String? suffixText,
    dynamic prefixIcon,
    dynamic suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixText: suffixText,
      prefixIcon: _resolveInputIcon(prefixIcon),
      suffixIcon: _resolveInputIcon(suffixIcon),
      isDense: true,
      filled: true,
      fillColor: const Color(0x12FFFFFF),
      labelStyle: const TextStyle(
        fontFamily: AppTheme.fontBody,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
      floatingLabelStyle: const TextStyle(
        fontFamily: AppTheme.fontDisplay,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.goldPrimary,
      ),
      hintStyle: const TextStyle(
        fontSize: 12,
        color: AppTheme.textMuted,
      ),
      suffixStyle: const TextStyle(
        fontFamily: AppTheme.fontDisplay,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMuted,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x28FFFFFF), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final safeBottom = media.padding.bottom;
    final disableAnimations = media.disableAnimations;

    Widget surface = Container(
      constraints: BoxConstraints(
        maxHeight: media.size.height * maxHeightFactor,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xF00B101B),
            Color(0xF5080C14),
            Color(0xF8060910),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: const Color(0x33FFFFFF),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xB3000000),
            blurRadius: 32,
            spreadRadius: 2,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Specular Refraction Rim & Toggle Handle Bar
          // Tapping the top handle zone unfocuses active inputs and toggles (closes) the sheet.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              unfocusActiveInput(context);
              Navigator.of(context).maybePop();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grab handle pill
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (headerIcon != null) ...[
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            headerIcon,
                            size: 18,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.goldPrimary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            if (subtitle != null && subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Crystal Close Button Capsule
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          unfocusActiveInput(context);
                          Navigator.of(context).maybePop();
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0x28FFFFFF),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0x22FFFFFF)),

          // 2. Scrollable Form / Content Body
          Flexible(
            child: SingleChildScrollView(
              padding: contentPadding,
              child: child,
            ),
          ),

          // 3. Pinned Bottom Crystal Action Footer (Always Visible Above Dock & Keyboard)
          if (primaryActionLabel != null)
            Container(
              padding: EdgeInsets.fromLTRB(
                18,
                12,
                18,
                bottomInset > 0 ? 12 : (safeBottom > 0 ? safeBottom + 10 : 16),
              ),
              decoration: const BoxDecoration(
                color: Color(0xE6070B12),
                border: Border(
                  top: BorderSide(color: Color(0x26FFFFFF), width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  if (secondaryActionLabel != null) ...[
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            backgroundColor: const Color(0x10FFFFFF),
                            side: const BorderSide(color: Color(0x30FFFFFF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isPrimaryLoading
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  unfocusActiveInput(context);
                                  if (onSecondaryAction != null) {
                                    onSecondaryAction!();
                                  } else {
                                    Navigator.of(context).maybePop();
                                  }
                                },
                          child: Text(
                            secondaryActionLabel!,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        key: primaryActionKey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldPrimary,
                          foregroundColor: AppTheme.voidBackground,
                          disabledBackgroundColor:
                              AppTheme.goldPrimary.withValues(alpha: 0.45),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isPrimaryLoading
                            ? null
                            : () {
                                unfocusActiveInput(context);
                                onPrimaryAction?.call();
                              },
                        child: isPrimaryLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppTheme.voidBackground,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (primaryActionIcon != null) ...[
                                    Icon(primaryActionIcon, size: 18),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Text(
                                      primaryActionLabel!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        letterSpacing: 0.5,
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
            )
          else if (bottomInset == 0 && safeBottom > 0)
            SizedBox(height: safeBottom),
        ],
      ),
    );

    if (!disableAnimations) {
      surface = ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: surface,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => unfocusActiveInput(context),
        child: surface,
      ),
    );
  }
}
