import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_particle_background.dart';

/// Primary Navigation Shell for ArmSphere
///
/// Upgraded to ArmSphere Titanium Glass Master Design System:
/// - Floating smoked optical glass navigation dock with backdrop diffusion.
/// - Machined titanium rim borders and top specular reflection sheen.
/// - Tactile haptic feedback and competition crimson/cyan active states.
class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    if (index != navigationShell.currentIndex) {
      HapticFeedback.selectionClick();
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBody: true,
      body: Stack(
        children: [
          const AmbientParticleBackground(),
          SafeArea(
            bottom: false,
            child: navigationShell,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                AppTheme.glassDockShadow(),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurfaceHeavy,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.borderTitanium,
                      width: 1.0,
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.45, 1.0],
                      colors: [
                        Color(0x24FFFFFF), // Specular reflection sheen
                        Color(0xB3151B24),
                        Color(0x0A000000),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        context,
                        index: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Arena',
                      ),
                      _buildNavItem(
                        context,
                        index: 1,
                        icon: Icons.travel_explore_outlined,
                        activeIcon: Icons.travel_explore_rounded,
                        label: 'Discover',
                      ),
                      _buildNavItem(
                        context,
                        index: 2,
                        icon: Icons.emoji_events_outlined,
                        activeIcon: Icons.emoji_events_rounded,
                        label: 'Events',
                      ),
                      _buildNavItem(
                        context,
                        index: 3,
                        icon: Icons.forum_outlined,
                        activeIcon: Icons.forum_rounded,
                        label: 'Community',
                      ),
                      _buildNavItem(
                        context,
                        index: 4,
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Passport',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = navigationShell.currentIndex == index;
    final activeColor = index == 0 ? AppTheme.crimson : AppTheme.goldPrimary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(context, index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: isSelected
                  ? BoxDecoration(
                      color: activeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: activeColor.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    )
                  : null,
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected ? activeColor : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.3,
                color: isSelected ? activeColor : AppTheme.textMuted,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
