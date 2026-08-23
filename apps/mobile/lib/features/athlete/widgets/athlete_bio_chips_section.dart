import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Data model for an individual Bio Chip item
class BioChipData {
  final String label;
  final IconData? icon;
  final String? emoji;
  final Color accentColor;

  const BioChipData({
    required this.label,
    this.icon,
    this.emoji,
    this.accentColor = AppTheme.goldLight,
  });
}

/// Glassmorphic Rounded Bio Chips Grid/Wrap Widget
class AthleteBioChipsSection extends StatelessWidget {
  final String countryFlag;
  final String country;
  final String province;
  final String club;
  final String weightClass;
  final String preferredArm;
  final String age;
  final String height;

  const AthleteBioChipsSection({
    Key? key,
    this.countryFlag = '🇵🇰',
    this.country = 'Pakistan',
    this.province = 'Islamabad',
    this.club = 'Islamabad Club',
    this.weightClass = '90 kg',
    this.preferredArm = 'Right Arm',
    this.age = '24 Years',
    this.height = '182 cm',
  }) : super(key: key);

  List<BioChipData> get _chips => [
        BioChipData(
          emoji: countryFlag,
          label: country,
          accentColor: AppTheme.info,
        ),
        BioChipData(
          icon: Icons.location_city_rounded,
          label: province,
          accentColor: AppTheme.success.withOpacity(0.2),
        ),
        BioChipData(
          icon: Icons.fitness_center_rounded,
          label: club,
          accentColor: AppTheme.goldLight,
        ),
        BioChipData(
          icon: Icons.scale_rounded,
          label: weightClass,
          accentColor: AppTheme.primaryAccent.withOpacity(0.3),
        ),
        BioChipData(
          icon: Icons.back_hand_outlined,
          label: preferredArm,
          accentColor: AppTheme.highlightPurple,
        ),
        BioChipData(
          icon: Icons.cake_outlined,
          label: age,
          accentColor: AppTheme.goldLight,
        ),
        BioChipData(
          icon: Icons.height_rounded,
          label: height,
          accentColor: AppTheme.success,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.background.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.0,
            runSpacing: 8.0,
            children: _chips.map((chip) => _buildGlassChip(chip)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassChip(BioChipData chip) {
    return TactilePressWrapper(
      onTap: () => HapticFeedback.selectionClick(),
      enableLift: true,
      liftDistance: -2,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.67),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: chip.accentColor.withOpacity(0.35),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: chip.accentColor.withOpacity(0.12),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chip.emoji != null) ...[
              Text(
                chip.emoji!,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 6),
            ] else if (chip.icon != null) ...[
              Icon(
                chip.icon,
                size: 13,
                color: chip.accentColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              chip.label,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
