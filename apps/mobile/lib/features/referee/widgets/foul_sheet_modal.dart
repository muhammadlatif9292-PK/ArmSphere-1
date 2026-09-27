import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Official Foul Classification Entry
class OfficialFoulRule {
  final String id;
  final String category;
  final String title;
  final String description;
  final bool isDisqualification;

  const OfficialFoulRule({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.isDisqualification = false,
  });
}

/// Domain 3 (Item 2) / Stage 6 Convergence: Official Table Foul Sheet Modal
///
/// Implements Canonical Referee Precision Mode (Mode 3) & Material 1 (Knurled Steel):
/// - DraggableScrollableSheet with 16dp rounded top chamfer and knurled steel grip handle.
/// - Red Corner vs Blue/White Corner designation with 48dp tactile hit targets.
/// - Official WAF / IFA Categorized Foul Taxonomy:
///     1. Elbow Fouls (Lift, Slip, Tricep)
///     2. Technical & Position Fouls (Intentional Slip, False Start, Loss of Peg Grip)
///     3. Conduct & Disciplinary Fouls (Disobeying Official, Intentional Table Slam)
/// - 48dp minimum hit rows with high-contrast tactical styling.
/// - Tabular monospace timing readouts (`FontFeature.tabularFigures()`).
/// - Heavy haptic feedback on official foul confirmation.
class FoulSheetModal extends StatefulWidget {
  final String athleteAName;
  final String athleteBName;
  final int currentRound;
  final String? initialCorner; // 'RED' or 'BLUE' / athlete name
  final void Function(Map<String, dynamic> foulData) onFoulConfirmed;

  const FoulSheetModal({
    super.key,
    required this.athleteAName,
    required this.athleteBName,
    this.currentRound = 1,
    this.initialCorner,
    required this.onFoulConfirmed,
  });

  /// Static launcher for clean bottom sheet invocation
  static Future<void> show(
    BuildContext context, {
    required String athleteAName,
    required String athleteBName,
    int currentRound = 1,
    String? initialCorner,
    required void Function(Map<String, dynamic> foulData) onFoulConfirmed,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FoulSheetModal(
        athleteAName: athleteAName,
        athleteBName: athleteBName,
        currentRound: currentRound,
        initialCorner: initialCorner,
        onFoulConfirmed: onFoulConfirmed,
      ),
    );
  }

  @override
  State<FoulSheetModal> createState() => _FoulSheetModalState();
}

class _FoulSheetModalState extends State<FoulSheetModal> {
  late String _selectedAthlete;
  String _selectedCategory = 'ELBOW';
  OfficialFoulRule? _selectedRule;

  static const _foulRules = <OfficialFoulRule>[
    // ── ELBOW FOULS ──────────────────────────────────────────────────────────
    OfficialFoulRule(
      id: 'elbow_lift',
      category: 'ELBOW',
      title: 'Elbow Lift (Off Pad)',
      description: 'Elbow completely leaves the contact surface of the elbow pad.',
    ),
    OfficialFoulRule(
      id: 'elbow_slip',
      category: 'ELBOW',
      title: 'Elbow Slip (Over Edge)',
      description: 'Elbow slides off the front, back, or side boundary of the pad.',
    ),
    OfficialFoulRule(
      id: 'tricep_touch',
      category: 'ELBOW',
      title: 'Tricep Touch on Table',
      description: 'Upper arm or tricep makes illegal contact with the table surface.',
    ),

    // ── TECHNICAL & POSITION FOULS ───────────────────────────────────────────
    OfficialFoulRule(
      id: 'intentional_slip',
      category: 'TECHNICAL',
      title: 'Intentional Slip-Out',
      description: 'Deliberately opening hand in a losing position to force straps.',
    ),
    OfficialFoulRule(
      id: 'false_start',
      category: 'TECHNICAL',
      title: 'False Start / Early Hit',
      description: 'Initiating forward movement before the referee calls READY... GO!',
    ),
    OfficialFoulRule(
      id: 'loss_of_peg',
      category: 'TECHNICAL',
      title: 'Loss of Peg Grip',
      description: 'Non-competing hand completely breaks physical contact with peg.',
    ),
    OfficialFoulRule(
      id: 'shoulder_centerline',
      category: 'TECHNICAL',
      title: 'Shoulder Across Centerline',
      description: 'Shoulder extends past the central line of the table in neutral.',
    ),

    // ── CONDUCT & DISCIPLINARY FOULS ─────────────────────────────────────────
    OfficialFoulRule(
      id: 'disobey_command',
      category: 'CONDUCT',
      title: 'Disobeying Official Command',
      description: 'Refusal to comply during referee grip setup or strap placement.',
    ),
    OfficialFoulRule(
      id: 'table_slam',
      category: 'CONDUCT',
      title: 'Intentional Table Slam',
      description: 'Excessive violent equipment abuse threatening table structural integrity.',
    ),
    OfficialFoulRule(
      id: 'unsportsmanlike',
      category: 'CONDUCT',
      title: 'Unsportsmanlike Conduct',
      description: 'Verbal profanity, threatening gestures, or hostile behavior.',
      isDisqualification: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCorner == 'BLUE' || widget.initialCorner == widget.athleteBName) {
      _selectedAthlete = widget.athleteBName;
    } else {
      _selectedAthlete = widget.athleteAName;
    }
    _selectedRule = _foulRules.first;
  }

  List<OfficialFoulRule> get _currentGroupRules {
    return _foulRules.where((r) => r.category == _selectedCategory).toList();
  }

  void _confirmFoul() {
    if (_selectedRule == null) return;
    HapticFeedback.heavyImpact();

    final foulData = {
      'id': 'F-${DateTime.now().millisecondsSinceEpoch}',
      'athleteName': _selectedAthlete,
      'corner': _selectedAthlete == widget.athleteAName ? 'RED' : 'BLUE',
      'ruleId': _selectedRule!.id,
      'type': _selectedRule!.title,
      'category': _selectedRule!.category,
      'description': _selectedRule!.description,
      'isDisqualification': _selectedRule!.isDisqualification,
      'round': widget.currentRound,
      'timestamp': DateTime.now().toIso8601String(),
    };

    widget.onFoulConfirmed(foulData);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isAthleteASelected = _selectedAthlete == widget.athleteAName;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.50,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1523),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: AppTheme.borderSubtle, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Knurled Steel Grip Handle (Material 1) ──────────────────────
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // ── Modal Header: Title & Round Telemetry ───────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEF4444),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x88EF4444),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'OFFICIAL TABLE FOUL CALL',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.elevatedSurface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                      ),
                      child: Text(
                        'ROUND ${widget.currentRound}',
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppTheme.borderSubtle, height: 12),

              // ── Corner Selection (48dp Touch Targets) ──────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    // Red Corner
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedAthlete = widget.athleteAName);
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isAthleteASelected
                                ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                : AppTheme.cardSurface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: isAthleteASelected
                                  ? const Color(0xFFEF4444)
                                  : AppTheme.borderSubtle,
                              width: isAthleteASelected ? 1.5 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'RED CORNER',
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                    Text(
                                      widget.athleteAName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontSize: 12,
                                        fontWeight: isAthleteASelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isAthleteASelected
                                            ? AppTheme.textPrimary
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Blue Corner
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedAthlete = widget.athleteBName);
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: !isAthleteASelected
                                ? const Color(0xFF38BDF8).withValues(alpha: 0.2)
                                : AppTheme.cardSurface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: !isAthleteASelected
                                  ? const Color(0xFF38BDF8)
                                  : AppTheme.borderSubtle,
                              width: !isAthleteASelected ? 1.5 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'BLUE CORNER',
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF38BDF8),
                                      ),
                                    ),
                                    Text(
                                      widget.athleteBName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontSize: 12,
                                        fontWeight: !isAthleteASelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: !isAthleteASelected
                                            ? AppTheme.textPrimary
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Category Filter Tray (Elbow, Technical, Conduct) ────────────
              Container(
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                ),
                child: Row(
                  children: [
                    _buildCategoryTab('ELBOW', 'ELBOW FOULS'),
                    _buildCategoryTab('TECHNICAL', 'SLIP & POSITION'),
                    _buildCategoryTab('CONDUCT', 'CONDUCT'),
                  ],
                ),
              ),

              // ── Scrollable Foul Rules List ──────────────────────────────────
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _currentGroupRules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final rule = _currentGroupRules[index];
                    final isSelected = _selectedRule?.id == rule.id;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedRule = rule);
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 52),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                              : AppTheme.cardSurface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFEF4444)
                                : AppTheme.borderSubtle,
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 18,
                              color: isSelected
                                  ? const Color(0xFFEF4444)
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          rule.title,
                                          style: TextStyle(
                                            fontFamily: 'Space Grotesk',
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? AppTheme.textPrimary
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      if (rule.isDisqualification)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444)
                                                .withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: const Text(
                                            'DQ WARNING',
                                            style: TextStyle(
                                              fontFamily: 'Space Grotesk',
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    rule.description,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Action Footer: 52dp Confirm Button ──────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selectedRule == null ? null : _confirmFoul,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.gavel, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'LOG FOUL: ${_selectedRule?.title ?? 'SELECT FOUL'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryTab(String catKey, String label) {
    final isSelected = _selectedCategory == catKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedCategory = catKey;
            _selectedRule = _currentGroupRules.isNotEmpty ? _currentGroupRules.first : null;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.elevatedSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: isSelected
                ? Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.5), width: 1.0)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppTheme.goldPrimary : AppTheme.textMuted,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
