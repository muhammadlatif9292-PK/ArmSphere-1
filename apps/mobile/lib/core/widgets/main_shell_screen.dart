import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_particle_background.dart';

/// Primary Navigation Shell for ArmSphere
///
/// Upgraded to Canonical Stage 2 Specification (Slice 10 / [P1-03]):
/// - Static ambient background substrate with 0 idle GPU/CPU cycles.
/// - Tactile haptic feedback on tab changes.
/// - Normalized AppTheme tokens (cardSurface, borderSubtle, goldPrimary).
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
      body: Stack(
        children: [
          const AmbientParticleBackground(),
          SafeArea(
            child: navigationShell,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardSurface,
          border: Border(
            top: BorderSide(
              color: AppTheme.borderSubtle,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => _onTap(context, index),
          elevation: 0,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.goldPrimary,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
          // Order mirrors the shell branches declared in app_router.dart:
          // /home, /discover, /tournaments, /community/feed, /athlete/profile.
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.travel_explore_outlined),
              activeIcon: Icon(Icons.travel_explore),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Competitions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
