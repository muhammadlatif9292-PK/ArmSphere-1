import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/radar_provider.dart';

/// Forged-Crystal Obsidian filter modal for toggling Radar pin layers and
/// filtering by weight class, arm preference, and distance radius.
class RadarFilterSheet extends StatefulWidget {
  final RadarFilterState initialFilter;

  const RadarFilterSheet({
    super.key,
    required this.initialFilter,
  });

  static Future<RadarFilterState?> show(
    BuildContext context, {
    required RadarFilterState initialFilter,
  }) {
    return showModalBottomSheet<RadarFilterState>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xCC030509),
      builder: (_) => RadarFilterSheet(initialFilter: initialFilter),
    );
  }

  @override
  State<RadarFilterSheet> createState() => _RadarFilterSheetState();
}

class _RadarFilterSheetState extends State<RadarFilterSheet> {
  static const List<String> _weights = [
    'ALL',
    '65kg',
    '75kg',
    '85kg',
    '95kg',
    '105kg',
    '105kg+',
  ];

  static const List<({String label, double? km})> _radii = [
    (label: 'Any', km: null),
    (label: '10 km', km: 10),
    (label: '25 km', km: 25),
    (label: '50 km', km: 50),
    (label: '100 km', km: 100),
    (label: '250 km', km: 250),
  ];

  late RadarFilterState _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppTheme.goldPrimary.withValues(alpha: 0.55),
            width: 1.3,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, safeBottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppTheme.goldPrimary, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'RADAR LAYERS & FILTERS',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: AppTheme.textPure,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _draft = const RadarFilterState());
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: AppTheme.goldPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Text(
              'MAP LAYERS',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LayerChip(
                  label: 'Events',
                  icon: Icons.emoji_events_rounded,
                  accent: AppTheme.goldPrimary,
                  selected: _draft.showEvents,
                  onTap: () => setState(
                    () => _draft = _draft.copyWith(showEvents: !_draft.showEvents),
                  ),
                ),
                _LayerChip(
                  label: 'Venues & Clubs',
                  icon: Icons.storefront_rounded,
                  accent: AppTheme.textSecondary,
                  selected: _draft.showVenues,
                  onTap: () => setState(
                    () => _draft = _draft.copyWith(showVenues: !_draft.showVenues),
                  ),
                ),
                _LayerChip(
                  label: 'Athletes',
                  icon: Icons.person_rounded,
                  accent: AppTheme.cyan,
                  selected: _draft.showAthletes,
                  onTap: () => setState(
                    () => _draft = _draft.copyWith(showAthletes: !_draft.showAthletes),
                  ),
                ),
                _LayerChip(
                  label: 'Beacons',
                  icon: Icons.local_fire_department_rounded,
                  accent: AppTheme.crimson,
                  selected: _draft.showBeacons,
                  onTap: () => setState(
                    () => _draft = _draft.copyWith(showBeacons: !_draft.showBeacons),
                  ),
                ),
                _LayerChip(
                  label: 'Meetups',
                  icon: Icons.sports_martial_arts_rounded,
                  accent: AppTheme.highlightPurple,
                  selected: _draft.showInformalEvents,
                  onTap: () => setState(
                    () => _draft =
                        _draft.copyWith(showInformalEvents: !_draft.showInformalEvents),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _draft.weightClass ?? 'ALL',
                    dropdownColor: AppTheme.titanium,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
                    decoration: const InputDecoration(
                      labelText: 'Weight Class',
                      filled: true,
                      fillColor: AppTheme.titanium,
                    ),
                    items: _weights
                        .map(
                          (w) => DropdownMenuItem(
                            value: w,
                            child: Text(w == 'ALL' ? 'All Divisions' : w),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        if (v == null || v == 'ALL') {
                          _draft = _draft.copyWith(clearWeightClass: true);
                        } else {
                          _draft = _draft.copyWith(weightClass: v);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _draft.armPreference ?? 'ALL',
                    dropdownColor: AppTheme.titanium,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
                    decoration: const InputDecoration(
                      labelText: 'Arm Preference',
                      filled: true,
                      fillColor: AppTheme.titanium,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('Any Arm')),
                      DropdownMenuItem(value: 'RIGHT', child: Text('Right Arm')),
                      DropdownMenuItem(value: 'LEFT', child: Text('Left Arm')),
                      DropdownMenuItem(value: 'BOTH', child: Text('Both')),
                    ],
                    onChanged: (v) {
                      setState(() {
                        if (v == null || v == 'ALL') {
                          _draft = _draft.copyWith(clearArmPreference: true);
                        } else {
                          _draft = _draft.copyWith(armPreference: v);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'DISTANCE RADIUS',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _radii.map((r) {
                final selected = _draft.maxDistanceKm == r.km;
                return ChoiceChip(
                  label: Text(r.label),
                  selected: selected,
                  selectedColor: AppTheme.goldPrimary.withValues(alpha: 0.22),
                  backgroundColor: AppTheme.titanium,
                  side: BorderSide(
                    color: selected ? AppTheme.goldPrimary : AppTheme.border,
                  ),
                  labelStyle: TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.goldLight : AppTheme.textSecondary,
                  ),
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (r.km == null) {
                        _draft = _draft.copyWith(clearMaxDistance: true);
                      } else {
                        _draft = _draft.copyWith(maxDistanceKm: r.km);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(_draft);
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('APPLY FILTERS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: AppTheme.voidBackground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                textStyle: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _LayerChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.18) : AppTheme.titanium,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: selected ? accent : AppTheme.border,
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? (accent == AppTheme.textSecondary ? AppTheme.textPure : accent)
                  : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.textPure : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
