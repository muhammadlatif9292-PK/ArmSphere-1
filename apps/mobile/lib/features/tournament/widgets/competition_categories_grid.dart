import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class CompetitionCategoriesGrid extends StatefulWidget {
  final Map<String, dynamic>? tournament;

  const CompetitionCategoriesGrid({
    super.key,
    this.tournament,
  });

  @override
  State<CompetitionCategoriesGrid> createState() => _CompetitionCategoriesGridState();
}

class _CompetitionCategoriesGridState extends State<CompetitionCategoriesGrid> {
  int _activeFilterIndex = 0; // 0: All, 1: Senior, 2: Junior, 3: Masters, 4: Right Arm, 5: Left Arm

  List<Map<String, dynamic>> _resolveCategories() {
    final raw = widget.tournament?['categories'] ?? widget.tournament?['divisions'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map<Map<String, dynamic>>((c) {
        if (c is! Map<String, dynamic>) return <String, dynamic>{};
        final division = c['division'] ?? c['name'] ?? 'Open';
        final weightClass = c['weightClass'] ?? 'Open';
        final arm = c['arm'] ?? 'Right Arm';
        final armCode = (c['arm'] ?? 'R').toString().toUpperCase().startsWith('L') ? 'L' : 'R';
        final tag = c['tag'] ?? division;
        final registered = (c['registered'] is num)
            ? (c['registered'] as num).toInt()
            : ((c['participantCount'] is num) ? (c['participantCount'] as num).toInt() : 0);
        final capacity = (c['capacity'] is num)
            ? (c['capacity'] as num).toInt()
            : ((c['maxParticipants'] is num) ? (c['maxParticipants'] as num).toInt() : 16);
        final slotsRemaining = capacity - registered;
        final status = slotsRemaining <= 0 ? 'Full' : (slotsRemaining <= 2 ? 'Almost Full' : 'Open');
        final statusColor = slotsRemaining <= 0
            ? const Color(0xFFFF2A6D)
            : (slotsRemaining <= 2 ? const Color(0xFFFFB300) : const Color(0xFF00E676));

        return {
          'id': c['id']?.toString() ?? 'cat_${division}_${weightClass}_$armCode',
          'division': division.toString(),
          'weightClass': weightClass.toString(),
          'arm': arm.toString(),
          'armCode': armCode,
          'tag': tag.toString(),
          'tagColor': _resolveTagColor(tag.toString()),
          'registered': registered,
          'capacity': capacity,
          'slotsRemaining': slotsRemaining > 0 ? slotsRemaining : 0,
          'status': status,
          'statusColor': statusColor,
          'weighInWindow': c['weighInWindow'] ?? 'Check schedule',
          'tableAssignment': c['tableAssignment'] ?? 'Main Arena Stage',
        };
      }).where((element) => element.isNotEmpty).toList();
    }
    return [];
  }

  Color _resolveTagColor(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('junior')) return const Color(0xFFFFB300);
    if (lower.contains('master')) return const Color(0xFFE040FB);
    return const Color(0xFF00E5FF);
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _getFilteredCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: AppTheme.goldPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPETITION CATEGORIES',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Male Armwrestling Divisions & Weight Brackets',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF162032),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                '${filteredCategories.length} DIVISIONS',
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.goldPrimary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Filter Pills Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterPill(0, 'ALL DIVISIONS'),
              const SizedBox(width: 6),
              _buildFilterPill(1, 'SENIOR MEN'),
              const SizedBox(width: 6),
              _buildFilterPill(2, 'JUNIOR U21'),
              const SizedBox(width: 6),
              _buildFilterPill(3, 'MASTERS 40+'),
              const SizedBox(width: 6),
              _buildFilterPill(4, 'RIGHT ARM'),
              const SizedBox(width: 6),
              _buildFilterPill(5, 'LEFT ARM'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Grid of Categories (Responsive 2-column layout)
        LayoutBuilder(
          builder: (context, constraints) {
            if (filteredCategories.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1527).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.category_outlined, size: 36, color: AppTheme.textMuted),
                    SizedBox(height: 8),
                    Text(
                      'No competition categories available for this selection.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }

            final isWide = constraints.maxWidth > 550;
            final crossAxisCount = isWide ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final cat = filteredCategories[index];
                return _buildCategoryCard(context, cat);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final isSelected = _activeFilterIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activeFilterIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.goldPrimary : const Color(0xFF101728),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.goldPrimary : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? Colors.black : AppTheme.textMuted,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredCategories() {
    final categories = _resolveCategories();
    switch (_activeFilterIndex) {
      case 1:
        return categories.where((c) => (c['tag'] as String).toLowerCase().contains('senior')).toList();
      case 2:
        return categories.where((c) => (c['tag'] as String).toLowerCase().contains('junior')).toList();
      case 3:
        return categories.where((c) => (c['tag'] as String).toLowerCase().contains('master')).toList();
      case 4:
        return categories.where((c) => (c['armCode'] as String) == 'R').toList();
      case 5:
        return categories.where((c) => (c['armCode'] as String) == 'L').toList();
      case 0:
      default:
        return categories;
    }
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> cat) {
    final statusColor = cat['statusColor'] as Color;
    final tagColor = cat['tagColor'] as Color;

    return TactilePressWrapper(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showCategoryDetailModal(context, cat);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1626).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.35),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Tag (Senior/Junior/Masters) & Arm Badge (R/L)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tagColor.withValues(alpha: 0.5), width: 0.8),
                  ),
                  child: Text(
                    (cat['tag'] as String).toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: tagColor,
                    ),
                  ),
                ),

                // Arm Indicator Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    cat['arm'] as String,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Division & Weight Class Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat['division'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cat['weightClass'] as String,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Registration Count & Slots Remaining
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${cat['registered']}/${cat['capacity']} Athletes',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 9,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    Text(
                      '${cat['slotsRemaining']} left',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: cat['slotsRemaining'] == 0
                            ? const Color(0xFFFF2A6D)
                            : AppTheme.goldPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Linear Capacity Indicator Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (cat['registered'] as int) / (cat['capacity'] as int),
                    minHeight: 4,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Bottom Status Badge (Open / Almost Full / Full)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(
                  (cat['status'] as String).toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDetailModal(BuildContext context, Map<String, dynamic> cat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sports_mma_rounded, color: AppTheme.goldPrimary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cat['division']} ${cat['weightClass']}',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cat['arm']} Category • ${cat['tag']} Division',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 16),

            _buildModalDetailRow(
              icon: Icons.scale_rounded,
              label: 'WEIGHT CLASS LIMIT',
              value: '${cat['weightClass']} (Strict Scale Calibration)',
            ),
            const SizedBox(height: 10),
            _buildModalDetailRow(
              icon: Icons.access_time_rounded,
              label: 'WEIGH-IN WINDOW',
              value: cat['weighInWindow'] as String,
            ),
            const SizedBox(height: 10),
            _buildModalDetailRow(
              icon: Icons.tab_unselected_rounded,
              label: 'ARENA TABLE',
              value: cat['tableAssignment'] as String,
            ),
            const SizedBox(height: 10),
            _buildModalDetailRow(
              icon: Icons.people_rounded,
              label: 'SLOTS CAPACITY',
              value: '${cat['registered']} / ${cat['capacity']} Athletes Registered (${cat['slotsRemaining']} remaining)',
            ),

            const SizedBox(height: 22),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cat['slotsRemaining'] > 0 ? AppTheme.goldPrimary : Colors.grey[700],
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: cat['slotsRemaining'] > 0
                  ? () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Category ${cat['division']} ${cat['weightClass']} selected for registration.'),
                          backgroundColor: AppTheme.goldPrimary,
                        ),
                      );
                    }
                  : null,
              child: Text(
                cat['slotsRemaining'] > 0 ? 'REGISTER FOR THIS CATEGORY' : 'CATEGORY FULL',
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.goldPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PART 7 — REGISTRATION PANEL (Adaptive Registration & Verified Pass Section)
// ============================================================================

