import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'crystal_stage_scaffold.dart';
import 'sticky_bottom_action_bar.dart';

/// Reusable Form Scaffold providing responsive keyboard avoidance,
/// dynamic scroll containment, and anchored bottom action placement.
///
/// Ensures:
/// - Primary submit actions remain visible, docked, and accessible above the soft keyboard.
/// - Scrollable form body dynamically resizes without clipping or `RenderFlex` overflow.
/// - Focused fields scroll into view on focus.
/// - Seamless interaction both inside [MainShellScreen] and as standalone surfaces.
class StickyFormScaffold extends StatelessWidget {
  /// Optional standard or custom app bar.
  final PreferredSizeWidget? appBar;

  /// Custom scrollable body widget. If provided, overrides [child].
  final Widget? body;

  /// Form content widget. Automatically wrapped in a [SingleChildScrollView].
  final Widget? child;

  /// Optional [GlobalKey<FormState>] wrapped around [child].
  final GlobalKey<FormState>? formKey;

  /// Content padding for the scrollable body (default: [AppTheme.space16]).
  final EdgeInsetsGeometry contentPadding;

  /// Scroll physics for the scrollable body.
  final ScrollPhysics? physics;

  /// Scroll controller for the scrollable body.
  final ScrollController? scrollController;

  /// Keyboard dismiss behavior for the scroll view (default: [ScrollViewKeyboardDismissBehavior.onDrag]).
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Custom bottom action bar widget. If null and [primaryActionLabel] is provided,
  /// a canonical [StickyBottomActionBar] is instantiated.
  final Widget? bottomActionBar;

  /// Label for the primary submit action button.
  final String? primaryActionLabel;

  /// Callback when primary submit action is tapped. When null, the action renders disabled.
  final VoidCallback? onPrimaryAction;

  /// Whether the primary submit action is currently processing.
  final bool isLoading;

  /// Optional leading icon for the primary submit action button.
  final IconData? primaryActionIcon;

  /// Optional accessibility semantic label for the primary action.
  final String? primarySemanticLabel;

  /// Optional secondary action widget placed to the left of the primary action.
  final Widget? secondaryAction;

  /// Optional disclaimer or helper text displayed above the action buttons.
  final String? disclaimerText;

  /// Scaffold background color (defaults to [AppTheme.background]).
  final Color? backgroundColor;

  /// Custom background color for the sticky bottom bar.
  final Color? bottomBarBackgroundColor;

  /// Custom border color for the sticky bottom bar top edge.
  final Color? bottomBarBorderColor;

  /// Whether the body should resize when the soft keyboard appears (default: true).
  final bool resizeToAvoidBottomInset;

  /// Functional stage domain for full-screen crystal-clear background.
  final ArmSphereStageDomain stageDomain;

  const StickyFormScaffold({
    super.key,
    this.appBar,
    this.body,
    this.child,
    this.formKey,
    this.contentPadding = const EdgeInsets.all(AppTheme.space16),
    this.physics,
    this.scrollController,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
    this.bottomActionBar,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.isLoading = false,
    this.primaryActionIcon,
    this.primarySemanticLabel,
    this.secondaryAction,
    this.disclaimerText,
    this.backgroundColor,
    this.bottomBarBackgroundColor,
    this.bottomBarBorderColor,
    this.resizeToAvoidBottomInset = true,
    this.stageDomain = ArmSphereStageDomain.arena,
  });

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    Widget? effectiveFooter = bottomActionBar;
    if (effectiveFooter == null && primaryActionLabel != null) {
      effectiveFooter = StickyBottomActionBar(
        primaryActionLabel: primaryActionLabel,
        onPrimaryAction: onPrimaryAction,
        isLoading: isLoading,
        primaryActionIcon: primaryActionIcon,
        primarySemanticLabel: primarySemanticLabel,
        secondaryAction: secondaryAction,
        disclaimerText: disclaimerText,
        backgroundColor: bottomBarBackgroundColor,
        borderColor: bottomBarBorderColor,
        isKeyboardOpen: isKeyboardOpen,
      );
    } else if (effectiveFooter is StickyBottomActionBar && effectiveFooter.isKeyboardOpen == null) {
      effectiveFooter = StickyBottomActionBar(
        primaryActionLabel: effectiveFooter.primaryActionLabel,
        onPrimaryAction: effectiveFooter.onPrimaryAction,
        isLoading: effectiveFooter.isLoading,
        primaryActionIcon: effectiveFooter.primaryActionIcon,
        primarySemanticLabel: effectiveFooter.primarySemanticLabel,
        secondaryAction: effectiveFooter.secondaryAction,
        disclaimerText: effectiveFooter.disclaimerText,
        padding: effectiveFooter.padding,
        backgroundColor: effectiveFooter.backgroundColor,
        borderColor: effectiveFooter.borderColor,
        maxWidth: effectiveFooter.maxWidth,
        isKeyboardOpen: isKeyboardOpen,
        child: effectiveFooter.child,
      );
    }

    Widget scrollableContent;
    if (body != null) {
      scrollableContent = body!;
    } else if (child != null) {
      Widget formContent = child!;
      if (formKey != null) {
        formContent = Form(key: formKey, child: formContent);
      }
      scrollableContent = SingleChildScrollView(
        controller: scrollController,
        physics: physics,
        padding: contentPadding,
        keyboardDismissBehavior: keyboardDismissBehavior,
        child: formContent,
      );
    } else {
      scrollableContent = const SizedBox.shrink();
    }

    Widget scaffoldBody = Column(
      children: [
        Expanded(
          child: scrollableContent,
        ),
        if (effectiveFooter != null) effectiveFooter,
      ],
    );

    if (appBar == null) {
      scaffoldBody = SafeArea(bottom: false, child: scaffoldBody);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.transparent,
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CrystalStageBackdrop(domain: stageDomain),
          ),
          scaffoldBody,
        ],
      ),
    );
  }
}
