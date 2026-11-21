import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/armsphere_location_picker.dart';
import '../../../core/widgets/crystal_toast.dart';

/// Output payload produced by the 2-step [DropBeaconSheet].
class DropBeaconSubmission {
  final String beaconType;
  final String title;
  final String? weightClass;
  final String armPreference;
  final int durationHours;
  final double latitude;
  final double longitude;

  const DropBeaconSubmission({
    required this.beaconType,
    required this.title,
    this.weightClass,
    required this.armPreference,
    required this.durationHours,
    required this.latitude,
    required this.longitude,
  });
}

/// Forged-Crystal Obsidian 2-step modal bottom sheet for dropping a live
/// Pickup Sparring or Traveling Puller beacon on ArmSphere Radar.
class DropBeaconSheet extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final String? initialWeightClass;
  final String? initialArmPreference;

  const DropBeaconSheet({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    this.initialWeightClass,
    this.initialArmPreference,
  });

  static Future<DropBeaconSubmission?> show(
    BuildContext context, {
    required double initialLatitude,
    required double initialLongitude,
    String? initialWeightClass,
    String? initialArmPreference,
  }) {
    return showModalBottomSheet<DropBeaconSubmission>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xCC030509),
      builder: (_) => DropBeaconSheet(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
        initialWeightClass: initialWeightClass,
        initialArmPreference: initialArmPreference,
      ),
    );
  }

  @override
  State<DropBeaconSheet> createState() => _DropBeaconSheetState();
}

class _DropBeaconSheetState extends State<DropBeaconSheet> {
  static const List<String> _weightClasses = [
    'Open',
    '65kg',
    '75kg',
    '85kg',
    '95kg',
    '105kg',
    '105kg+',
  ];

  static const List<({String label, int hours})> _sparringDurations = [
    (label: '6 Hours', hours: 6),
    (label: '24 Hours', hours: 24),
    (label: '48 Hours', hours: 48),
  ];

  static const List<({String label, int hours})> _travelDurations = [
    (label: '3 Days', hours: 72),
    (label: '7 Days', hours: 168),
    (label: '14 Days', hours: 336),
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();

  int _step = 0;
  String _beaconType = 'SPARRING';
  int _durationHours = 6;
  String _weightClass = '85kg';
  String _armPreference = 'RIGHT';
  late double _latitude;
  late double _longitude;
  String? _resolvedAddress;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    if (widget.initialWeightClass != null &&
        _weightClasses.contains(widget.initialWeightClass)) {
      _weightClass = widget.initialWeightClass!;
    }
    final initArm = (widget.initialArmPreference ?? '').toUpperCase();
    if (initArm == 'RIGHT' || initArm == 'LEFT' || initArm == 'BOTH') {
      _armPreference = initArm;
    } else if (initArm == 'AMBIDEXTROUS') {
      _armPreference = 'BOTH';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _selectBeaconType(String type) {
    HapticFeedback.selectionClick();
    setState(() {
      _beaconType = type;
      _durationHours = type == 'TRAVEL' ? 72 : 6;
    });
  }

  Future<void> _pickLocation() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await ArmSphereLocationPicker.show(
      context,
      title: 'Pin Beacon Coordinates',
      initialLatitude: _latitude,
      initialLongitude: _longitude,
      initialLabel: _resolvedAddress,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _latitude = picked.latitude;
      _longitude = picked.longitude;
      _resolvedAddress = picked.formattedAddress;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_titleCtrl.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: const Text('Enter a short title for your beacon.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop(
      DropBeaconSubmission(
        beaconType: _beaconType,
        title: _titleCtrl.text.trim(),
        weightClass: _weightClass == 'Open' ? null : _weightClass,
        armPreference: _armPreference,
        durationHours: _durationHours,
        latitude: _latitude,
        longitude: _longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final durations =
        _beaconType == 'TRAVEL' ? _travelDurations : _sparringDurations;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppTheme.crimson.withValues(alpha: 0.65),
            width: 1.4,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        bottomInset + safeBottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.crimson.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.crimson.withValues(alpha: 0.16),
                    border: Border.all(
                      color: AppTheme.crimson.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Icon(
                    Icons.podcasts_rounded,
                    color: AppTheme.crimson,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DROP RADAR BEACON',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: AppTheme.textPure,
                        ),
                      ),
                      Text(
                        _step == 0
                            ? 'Step 1 of 2 — Choose Beacon Signal & Duration'
                            : 'Step 2 of 2 — Match Specs & Map Pin',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontBody,
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_step == 0) ...[
              _BeaconTypeCard(
                icon: Icons.local_fire_department_rounded,
                title: 'Pickup Sparring Session',
                subtitle: 'Live table work, strap pulls, or open grip session nearby.',
                selected: _beaconType == 'SPARRING',
                onTap: () => _selectBeaconType('SPARRING'),
              ),
              const SizedBox(height: 10),
              _BeaconTypeCard(
                icon: Icons.flight_takeoff_rounded,
                title: 'Traveling Puller',
                subtitle: 'Visiting another city and looking for local clubs or pullers.',
                selected: _beaconType == 'TRAVEL',
                onTap: () => _selectBeaconType('TRAVEL'),
              ),
              const SizedBox(height: 18),
              const Text(
                'AUTO-EXPIRY WINDOW',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: durations.map((d) {
                  final active = _durationHours == d.hours;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _durationHours = d.hours);
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: active
                                ? AppTheme.crimson.withValues(alpha: 0.2)
                                : AppTheme.titanium,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: active ? AppTheme.crimson : AppTheme.border,
                              width: active ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            d.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: active ? AppTheme.textPure : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _step = 1);
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('CONTINUE TO DETAILS'),
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
            ] else ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Beacon Title *',
                        hintText: _beaconType == 'TRAVEL'
                            ? 'e.g. Visiting Islamabad — Looking for 85kg Sparring'
                            : 'e.g. Evening Toproll & Strap Table Open',
                        filled: true,
                        fillColor: AppTheme.titanium,
                      ),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Enter a title (at least 2 characters)'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _weightClass,
                            dropdownColor: AppTheme.titanium,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Target Weight Class',
                              filled: true,
                              fillColor: AppTheme.titanium,
                            ),
                            items: _weightClasses
                                .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _weightClass = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _armPreference,
                            dropdownColor: AppTheme.titanium,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Arm Discipline',
                              filled: true,
                              fillColor: AppTheme.titanium,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'RIGHT', child: Text('Right Arm')),
                              DropdownMenuItem(value: 'LEFT', child: Text('Left Arm')),
                              DropdownMenuItem(value: 'BOTH', child: Text('Both Arms')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _armPreference = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ArmSphereLocationFieldCard(
                      title: 'Beacon Map Location',
                      subtitle: 'Defaults to current map center — tap to adjust exact pin',
                      latitude: _latitude,
                      longitude: _longitude,
                      resolvedAddress: _resolvedAddress ??
                          '${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)}',
                      onPickLocation: _pickLocation,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _step = 0);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.border),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.podcasts_rounded, size: 18),
                            label: const Text('BROADCAST BEACON'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.crimson,
                              foregroundColor: AppTheme.textPure,
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BeaconTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _BeaconTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.crimson.withValues(alpha: 0.14)
              : AppTheme.titanium,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: selected ? AppTheme.crimson : AppTheme.border,
            width: selected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppTheme.crimson.withValues(alpha: 0.25)
                    : AppTheme.brushedSteel,
              ),
              child: Icon(
                icon,
                color: selected ? AppTheme.crimson : AppTheme.goldPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPure,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontBody,
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.crimson : AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
