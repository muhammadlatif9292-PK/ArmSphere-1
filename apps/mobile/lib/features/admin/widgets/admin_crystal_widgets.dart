// lib/features/admin/widgets/admin_crystal_widgets.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/security/admin_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Top Authority Header for the 5 Native Admin Tabs.
///
/// Displays the workspace title, subtitle, active federation role badge,
/// optional Provincial Director jurisdiction pill, and a refresh trigger.
/// Per user directive: no mode-switching toggle is placed in the header
/// (switching between Athlete and Admin happens exclusively in Settings).
class AdminAuthorityHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String activeRole;
  final String? jurisdiction;
  final VoidCallback? onRefresh;
  final Widget? trailingAction;

  const AdminAuthorityHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.activeRole,
    this.jurisdiction,
    this.onRefresh,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final isProvincial = activeRole.toUpperCase() == 'PROVINCIAL_DIRECTOR';
    final badgeText = AdminPermissions.shortRoleBadge(activeRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0x73D4AF37),
                  width: 1.0,
                ),
                boxShadow: const [],
              ),
              child: Icon(
                AdminPermissions.roleIcon(activeRole),
                color: AppTheme.goldPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPure,
                          letterSpacing: -0.3,
                          shadows: AppTheme.crystalTextShadows,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0x80E23B3B),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: AppTheme.textPure,
                            shadows: AppTheme.crystalTextShadows,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailingAction != null) ...[
              const SizedBox(width: 8),
              trailingAction!,
            ],
            if (onRefresh != null) ...[
              const SizedBox(width: 8),
              CrystalIconPillButton(
                icon: Icons.refresh_rounded,
                iconColor: AppTheme.goldPrimary,
                tooltip: 'Synchronize Data',
                onPressed: () {
                  CrystalModalSheet.unfocusActiveInput(context);
                  onRefresh!();
                },
              ),
            ],
          ],
        ),
        if (isProvincial &&
            jurisdiction != null &&
            jurisdiction!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          AdminJurisdictionBanner(jurisdiction: jurisdiction!),
        ],
      ],
    );
  }
}

/// Gold Crystal Jurisdiction Badge shown when a Provincial Director is active.
class AdminJurisdictionBanner extends StatelessWidget {
  final String jurisdiction;

  const AdminJurisdictionBanner({
    super.key,
    required this.jurisdiction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('admin_locked_jurisdiction_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0x73D4AF37),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.place_rounded,
            size: 15,
            color: AppTheme.goldPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'JURISDICTION: ${jurisdiction.toUpperCase()}',
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.goldLight,
                letterSpacing: 0.3,
                shadows: AppTheme.crystalTextShadows,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Descriptor for a segment inside [AdminSegmentedDeck].
class AdminSegmentItem {
  final String label;
  final IconData icon;
  final int? count;

  const AdminSegmentItem({
    required this.label,
    required this.icon,
    this.count,
  });
}

/// Crystal Glass Segmented Control for switching sub-modules inside an Admin tab.
///
/// Automatically unfocuses active text inputs when tapped and provides tactile
/// selection feedback.
class AdminSegmentedDeck extends StatelessWidget {
  final List<AdminSegmentItem> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const AdminSegmentedDeck({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: AppTheme.recessedObsidianWellDecoration(radius: 16),
      child: Row(
        children: [
          for (int i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _buildSegment(context, i, segments[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegment(BuildContext context, int index, AdminSegmentItem item) {
    final bool isSelected = index == selectedIndex;
    final bool isDense = segments.length >= 4;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        CrystalModalSheet.unfocusActiveInput(context);
        if (index != selectedIndex) {
          HapticFeedback.selectionClick();
          onChanged(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 42),
        padding: EdgeInsets.symmetric(
          horizontal: isDense ? 4 : 6,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0x80E23B3B)
                : const Color(0x2EFFFFFF),
            width: isSelected ? 1.2 : 1.0,
          ),
          boxShadow: const [],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: isDense ? 13.5 : 15,
                color: isSelected ? AppTheme.crimson : const Color(0xFFCBD5E1),
              ),
              SizedBox(width: isDense ? 3.5 : 5),
              Text(
                item.label,
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: isDense ? 11.0 : 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppTheme.textPure : const Color(0xFFCBD5E1),
                  shadows: AppTheme.crystalTextShadows,
                ),
              ),
              if (item.count != null) ...[
                SizedBox(width: isDense ? 3.5 : 5),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDense ? 4 : 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0x80E23B3B)
                          : const Color(0x2EFFFFFF),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    '${item.count}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                      fontFeatures: const [FontFeature.tabularFigures()],
                      shadows: AppTheme.crystalTextShadows,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Search & Filter Chip Toolbar for Native Admin Lists.
class AdminCrystalSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final List<String> filterOptions;
  final String selectedFilter;
  final ValueChanged<String>? onFilterSelected;
  final String Function(String)? filterLabelBuilder;

  const AdminCrystalSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    this.filterOptions = const [],
    this.selectedFilter = '',
    this.onFilterSelected,
    this.filterLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          onTapOutside: (_) =>
              CrystalModalSheet.unfocusActiveInput(context),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13.5,
            shadows: AppTheme.crystalTextShadows,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              shadows: AppTheme.crystalTextShadows,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 19,
              color: AppTheme.goldPrimary,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      CrystalModalSheet.unfocusActiveInput(context);
                      onClear();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0x38FFFFFF), width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.goldPrimary,
                width: 1.3,
              ),
            ),
          ),
        ),
        if (filterOptions.isNotEmpty && onFilterSelected != null) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < filterOptions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _buildFilterChip(context, filterOptions[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _defaultFilterLabel(String value) {
    switch (value) {
      case '':
      case 'ALL':
        return 'ALL';
      case 'UNDER_REVIEW':
        return 'IN REVIEW';
      case 'RESOLVED_UPHELD':
        return 'UPHELD';
      case 'RESOLVED_OVERTURNED':
        return 'OVERTURNED';
      case 'IN_PROGRESS':
        return 'IN PROGRESS';
      case 'ATHLETE_REVIEW':
        return 'ATHLETE REVIEW';
      case 'MATCH_OVERRIDE':
        return 'MATCH OVERRIDE';
      case 'DISPUTE_RESOLVED':
        return 'DISPUTE RULING';
      case 'ROLE_GRANTED':
        return 'ROLE GRANT';
      case 'ATHLETE_SUSPENDED':
        return 'SUSPENSION';
      default:
        return value.replaceAll('_', ' ');
    }
  }

  Widget _buildFilterChip(BuildContext context, String value) {
    final bool isSelected = selectedFilter == value;
    final String label = filterLabelBuilder != null
        ? filterLabelBuilder!(value)
        : _defaultFilterLabel(value);

    return GestureDetector(
      onTap: () {
        CrystalModalSheet.unfocusActiveInput(context);
        HapticFeedback.selectionClick();
        onFilterSelected!(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0x73D4AF37)
                : const Color(0x2EFFFFFF),
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppTheme.goldPrimary : const Color(0xFFCBD5E1),
            letterSpacing: 0.35,
            shadows: AppTheme.crystalTextShadows,
          ),
        ),
      ),
    );
  }
}

/// Tabular KPI / Backlog Card for the Executive Command Deck.
class AdminKpiCrystalCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const AdminKpiCrystalCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactilePressWrapper(
      onTap: onTap,
      child: ElevatedActionCard(
        padding: const EdgeInsets.all(14),
        borderColor: accentColor.withValues(alpha: 0.45),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.35,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.55),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(icon, size: 14, color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPure,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: accentColor.withValues(alpha: 0.8),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
