import 'package:flutter/material.dart';
import '../constants/asset_paths.dart';

class VoidStageScaffold extends StatelessWidget {
  final String backgroundAsset;
  final Alignment focalAlignment;
  final Widget? child;
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool? resizeToAvoidBottomInset;
  final bool useSafeArea;

  const VoidStageScaffold({
    super.key,
    required this.backgroundAsset,
    this.child,
    this.body,
    this.focalAlignment = ArmSphereAssets.stageTopFocal,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.resizeToAvoidBottomInset,
    this.useSafeArea = true,
  }) : assert(child != null || body != null, 'Either child or body must be provided to VoidStageScaffold');

  @override
  Widget build(BuildContext context) {
    final Widget content = child ?? body ?? const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFF070A11),
      extendBodyBehindAppBar: true,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      drawer: drawer,
      endDrawer: endDrawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              alignment: focalAlignment,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Color(0xFF070A11),
              ),
            ),
          ),
          // Subtle gradient scrim protecting lower 65% UI controls & text
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35, 0.70, 1.0],
                  colors: [
                    Color(0x33070A11),
                    Color(0x1A070A11),
                    Color(0xCC070A11),
                    Color(0xFF070A11),
                  ],
                ),
              ),
            ),
          ),
          useSafeArea ? SafeArea(child: content) : content,
        ],
      ),
    );
  }
}
