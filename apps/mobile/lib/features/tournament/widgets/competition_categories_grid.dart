import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class _CompetitionCategoriesGrid extends StatefulWidget {
  const _CompetitionCategoriesGrid({
    Key? key,
  }) : super(key: key);

  @override
  State<_CompetitionCategoriesGrid> createState() => _CompetitionCategoriesGridState();
}

class _CompetitionCategoriesGridState extends State<_CompetitionCategoriesGrid> {
  int _activeFilterIndex = 0; // 0: All, 1: Senior, 2: Junior, 3: Masters, 4: Right Arm, 5: Left Arm

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'cat_s_r_70',
      'division': 'Senior Men',
      'weightClass': '-70 kg',
      'arm': 'Right Arm',
      'armCode': 'R',
      'tag': 'Senior',
      'tagColor': Color(0xFF00E5FF),
      'registered': 14,
      'capacity': 16,
      'slotsRemaining': 2,
      'status': 'Almost Full',
      'statusColor': Color(0xFFFFB300),
      'weighInWindow': '08:00 AM - 10:00 AM',
      'tableAssignment': 'Table #1 • Arena Stage A',
    },
    {
      'id': 'cat_s_r_80',
      'division': 'Senior Men',
      'weightClass': '-80 kg',
      'arm': 'Right Arm',
      'armCode': 'R',
      'tag': 'Senior',
      'tagColor': Color(0xFF00E5FF),
      'registered': 16,
      'capacity': 16,
      'slotsRemaining': 0,
      'status': 'Full',
      'statusColor': Color(0xFFFF2A6D),
      'weighInWindow': '09:00 AM - 11:00 AM',
      'tableAssignment': 'Table #2 • Arena Stage B',
    },
    {
      'id': 'cat_s_l_80',
      'division': 'Senior Men',
      'weightClass': '-80 kg',
      'arm': 'Left Arm',
      'armCode': 'L',
      'tag': 'Senior',
      'tagColor': Color(0xFF00E5FF),
      'registered': 10,
      'capacity': 16,
      'slotsRemaining': 6,
      'status': 'Open',
      'statusColor': Color(0xFF00E676),
      'weighInWindow': '09:00 AM - 11:00 AM',
      'tableAssignment': 'Table #2 • Arena Stage B',
    },
    {
      'id': 'cat_s_r_90',
      'division': 'Senior Men',
      'weightClass': '-90 kg',
      'arm': 'Right Arm',
      'armCode': 'R',
      'tag': 'Senior',
      'tagColor': Color(0xFF00E5FF),
      'registered': 12,
      'capacity': 16,
      'slotsRemaining': 4,
      'status': 'Open',
      'statusColor': Color(0xFF00E676),
      'weighInWindow': '10:00 AM - 12:00 PM',
      'tableAssignment': 'Table #1 • Arena Stage A',
    },
    {
      'id': 'cat_j_r_75',
      'division': 'Junior Male U21',
      'weightClass': '-75 kg',
      'arm': 'Right Arm',
      'armCode': 'R',
      'tag': 'Junior',
      'tagColor': Color(0xFFFFB300),
      'registered': 8,
      'capacity': 16,
      'slotsRemaining': 8,
      'status': 'Open',
      'statusColor': Color(0xFF00E676),
      'weighInWindow': '08:00 AM - 09:30 AM',
      'tableAssignment': 'Table #3 • Stage C',
    },
    {
      'id': 'cat_m_r_85',
      'division': 'Masters Male 40+',
      'weightClass': '-85 kg',
      'arm': 'Right Arm',
      'armCode': 'R',
      'tag': 'Masters',
      'tagColor': Color(0xFFE040FB),
      'registered': 15,
      'capacity': 16,
      'slotsRemaining': 1,
      'status': 'Almost Full',
      'statusColor': Color(0xFFFFB300),
      'weighInWindow': '11:00 AM - 12:30 PM',
      'tableAssignment': 'Table #3 • Stage C',
    },
    {
      'id': 'cat_s_r_100',
      'division': 'Senior Men Heavyweight',
      'weightClass': '+100 kg',
      'arm': 'Right Arm',
      'armCode': 'R',
      'tag': 'Senior',
      'tagColor': Color(0xFF00E5FF),
      'registered': 6,
      'capacity': 16,
      'slotsRemaining': 10,
      'status': 'Open',
      'statusColor': Color(0xFF00E676),
      'weighInWindow': '12:00 PM - 01:30 PM',
      'tableAssignment': 'Main Arena Stage A',
    },
    {
      'id': 'cat_s_l_100',
      'division': 'Senior Men Heavyweight',
      'weightClass': '+100 kg',
      'arm': 'Left Arm',
      'armCode': 'L',
      'tag': 'Senior',
      'tagColor': Color(0xFF00E5FF),
      'registered': 4,
      'capacity': 16,
      'slotsRemaining': 12,
      'status': 'Open',
      'statusColor': Color(0xFF00E676),
      'weighInWindow': '12:00 PM - 01:30 PM',
      'tableAssignment': 'Main Arena Stage A',
    },
  ];

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
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: AppTheme.goldPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
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
    switch (_activeFilterIndex) {
      case 1:
        return _categories.where((c) => (c['tag'] as String) == 'Senior').toList();
      case 2:
        return _categories.where((c) => (c['tag'] as String) == 'Junior').toList();
      case 3:
        return _categories.where((c) => (c['tag'] as String) == 'Masters').toList();
      case 4:
        return _categories.where((c) => (c['armCode'] as String) == 'R').toList();
      case 5:
        return _categories.where((c) => (c['armCode'] as String) == 'L').toList();
      case 0:
      default:
        return _categories;
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
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFF0E1626).withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withOpacity(0.35),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
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
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tagColor.withOpacity(0.5), width: 0.8),
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
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    cat['arm'] as String,
                    style: TextStyle(
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
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cat['weightClass'] as String,
                  style: TextStyle(
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
                      style: TextStyle(
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
                            ? Color(0xFFFF2A6D)
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
              padding: EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withOpacity(0.5)),
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
      backgroundColor: Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(22.0),
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
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withOpacity(0.18),
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

