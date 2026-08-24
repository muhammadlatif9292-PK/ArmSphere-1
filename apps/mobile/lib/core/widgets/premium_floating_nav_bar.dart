import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

enum PremiumNavAction { none, center }

class PremiumFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTapTab;
  final VoidCallback? onCenterActionTap;

  const PremiumFloatingNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTapTab,
    this.onCenterActionTap,
  }) : super(key: key);

  static const List<IconData> _icons = [
    Icons.explore_outlined,
    Icons.emoji_events_outlined,
    Icons.add_circle_outline,
    Icons.sports_outlined,
    Icons.person_outline,
  ];

  static const List<String> _labels = [
    'Discover',
    'Events',
    'Log',
    'Matches',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xCC121622),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.goldPrimary.withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_icons.length, (index) {
                final isCenter = index == 2;
                final isSelected = index == currentIndex;

                if (isCenter) {
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        if (onCenterActionTap != null) {
                          onCenterActionTap!();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.goldPrimary.withOpacity(0.15),
                                border: Border.all(
                                  color: AppTheme.goldPrimary.withOpacity(0.55),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                _icons[index],
                                size: 20,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _labels[index],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTapTab(index);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _icons[index],
                            size: 21,
                            color: isSelected
                                ? AppTheme.goldPrimary
                                : Colors.white70,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _labels[index],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.goldPrimary
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
