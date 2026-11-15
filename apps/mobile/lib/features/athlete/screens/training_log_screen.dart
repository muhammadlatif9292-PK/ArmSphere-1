import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/post_creation_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/crystal_slash_painter.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sensory_feedback_service.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../community/screens/video_player_modal.dart';

/// Canonical Arm-Wrestling Move descriptor used in the Top PR Carousel & Filter Strip.
class _CanonicalMoveSpec {
  final String id;
  final String label;
  final IconData icon;
  final Color accentColor;

  const _CanonicalMoveSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.accentColor,
  });
}

/// Resolved submitted PR telemetry for a move in the top horizontal carousel.
class _SubmittedMovePrCardData {
  final String moveId;
  final String moveLabel;
  final IconData icon;
  final Color accentColor;
  final num latestWeightKg;
  final num? previousWeightKg;
  final num peakWeightKg;
  final int? latestReps;
  final String latestCreatedAtIso;
  final DateTime latestCreatedAt;
  final bool hasVideoUrl;

  const _SubmittedMovePrCardData({
    required this.moveId,
    required this.moveLabel,
    required this.icon,
    required this.accentColor,
    required this.latestWeightKg,
    this.previousWeightKg,
    required this.peakWeightKg,
    this.latestReps,
    required this.latestCreatedAtIso,
    required this.latestCreatedAt,
    this.hasVideoUrl = false,
  });
}

/// Athlete Training Log & Personal Records (PR) Screen
class AthleteTrainingLogScreen extends ConsumerStatefulWidget {
  final String athleteId;

  const AthleteTrainingLogScreen({super.key, required this.athleteId});

  @override
  ConsumerState<AthleteTrainingLogScreen> createState() =>
      _AthleteTrainingLogScreenState();
}

class _AthleteTrainingLogScreenState
    extends ConsumerState<AthleteTrainingLogScreen> {
  /// The 9 canonical arm-wrestling moves requested by the user:
  /// Pronation, Riser, Back pressure, Side pressure, Cupping,
  /// Containment, Hammer curl, Curve biceps curl, Lat Drag.
  static const List<_CanonicalMoveSpec> _canonicalMoves = [
    _CanonicalMoveSpec(
      id: 'PRONATION',
      label: 'Pronation',
      icon: Icons.rotate_right_rounded,
      accentColor: AppTheme.cyanAccent,
    ),
    _CanonicalMoveSpec(
      id: 'RISER',
      label: 'Riser',
      icon: Icons.arrow_upward_rounded,
      accentColor: AppTheme.success,
    ),
    _CanonicalMoveSpec(
      id: 'BACK_PRESSURE',
      label: 'Back pressure',
      icon: Icons.fitness_center_rounded,
      accentColor: AppTheme.goldPrimary,
    ),
    _CanonicalMoveSpec(
      id: 'SIDE_PRESSURE',
      label: 'Side pressure',
      icon: Icons.sync_alt_rounded,
      accentColor: AppTheme.crimson,
    ),
    _CanonicalMoveSpec(
      id: 'CUPPING',
      label: 'Cupping',
      icon: Icons.pan_tool_alt_rounded,
      accentColor: AppTheme.goldPrimary,
    ),
    _CanonicalMoveSpec(
      id: 'CONTAINMENT',
      label: 'Containment',
      icon: Icons.back_hand_outlined,
      accentColor: AppTheme.cyanAccent,
    ),
    _CanonicalMoveSpec(
      id: 'HAMMER_CURL',
      label: 'Hammer curl',
      icon: Icons.sports_mma_outlined,
      accentColor: AppTheme.success,
    ),
    _CanonicalMoveSpec(
      id: 'CURVE_BICEPS_CURL',
      label: 'Curve biceps curl',
      icon: Icons.bolt_rounded,
      accentColor: AppTheme.goldPrimary,
    ),
    _CanonicalMoveSpec(
      id: 'LAT_DRAG',
      label: 'Lat Drag',
      icon: Icons.south_west_rounded,
      accentColor: AppTheme.crimson,
    ),
  ];

  static const List<({String id, String label})> _disciplines = [
    (id: 'ALL', label: 'All Lifts'),
    (id: 'PRONATION', label: 'Pronation'),
    (id: 'RISER', label: 'Riser'),
    (id: 'BACK_PRESSURE', label: 'Back pressure'),
    (id: 'SIDE_PRESSURE', label: 'Side pressure'),
    (id: 'CUPPING', label: 'Cupping'),
    (id: 'CONTAINMENT', label: 'Containment'),
    (id: 'HAMMER_CURL', label: 'Hammer curl'),
    (id: 'CURVE_BICEPS_CURL', label: 'Curve biceps curl'),
    (id: 'LAT_DRAG', label: 'Lat Drag'),
  ];

  String _selectedDiscipline = 'ALL';

  String get athleteId => widget.athleteId;

  /// Maps any raw `exerciseType` string to one of the 9 canonical move IDs
  /// (or returns a normalized uppercase fallback for legacy exercise types).
  static _CanonicalMoveSpec _resolveMoveSpec(String rawExercise) {
    final upper = rawExercise.trim().toUpperCase().replaceAll('-', '_');
    if (upper.contains('PRONAT')) {
      return _canonicalMoves[0]; // Pronation
    }
    if (upper.contains('RIS')) {
      return _canonicalMoves[1]; // Riser
    }
    if (upper.contains('BACK')) {
      return _canonicalMoves[2]; // Back pressure
    }
    if (upper.contains('SIDE')) {
      return _canonicalMoves[3]; // Side pressure
    }
    if (upper.contains('CONTAIN')) {
      return _canonicalMoves[5]; // Containment
    }
    if (upper.contains('CUP') || upper.contains('WRIST')) {
      return _canonicalMoves[4]; // Cupping
    }
    if (upper.contains('HAMMER')) {
      return _canonicalMoves[6]; // Hammer curl
    }
    if (upper.contains('CURVE') || upper.contains('BICEP')) {
      return _canonicalMoves[7]; // Curve biceps curl
    }
    if (upper.contains('LAT') || upper.contains('DRAG')) {
      return _canonicalMoves[8]; // Lat Drag
    }
    final cleanLabel = rawExercise.trim().isEmpty
        ? 'Lift'
        : rawExercise.trim().replaceAll('_', ' ');
    return _CanonicalMoveSpec(
      id: upper.isEmpty ? 'OTHER' : upper,
      label: cleanLabel,
      icon: _getExerciseIcon(rawExercise),
      accentColor: _getExerciseColor(rawExercise),
    );
  }

  bool _matchesDiscipline(String exerciseType) {
    if (_selectedDiscipline == 'ALL') return true;
    final resolved = _resolveMoveSpec(exerciseType);
    return resolved.id == _selectedDiscipline;
  }

  num? _parseWeight(dynamic raw) {
    if (raw is num) return raw;
    if (raw == null) return null;
    return num.tryParse(raw.toString().trim());
  }

  String _formatWeightValue(num value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  /// Builds the list of submitted PR cards for the top horizontal carousel:
  /// - Only moves with at least one submitted weight (> 0) are included.
  /// - Each move card shows its **latest submitted weight** (so if an athlete had
  ///   29 kg in Pronation and now submitted 35 kg in Pronation, 35 kg is shown!).
  /// - Cards are ordered by `latestCreatedAt DESC` so the most recently submitted
  ///   PR appears first on the left of the top horizontal carousel.
  List<_SubmittedMovePrCardData> _buildSubmittedMoveCards(
    List<Map<String, dynamic>> allLogs,
    List<Map<String, dynamic>> allPrs,
  ) {
    final Map<String, List<Map<String, dynamic>>> groupedByMove = {};

    // 1. Collect all weight-bearing entries from logs (which have full history + timestamps)
    for (final log in allLogs) {
      final rawEx =
          (log['exerciseType'] ?? log['exercise'])?.toString().trim() ?? '';
      final weight = _parseWeight(log['weightKg']);
      if (rawEx.isEmpty || weight == null || weight <= 0) continue;
      final spec = _resolveMoveSpec(rawEx);
      groupedByMove.putIfAbsent(spec.id, () => []).add(log);
    }

    // 2. Also incorporate any PR records from prsAsync that might not be in allLogs
    for (final pr in allPrs) {
      final rawEx =
          (pr['exerciseType'] ?? pr['exercise'])?.toString().trim() ?? '';
      final weight = _parseWeight(pr['weightKg']);
      if (rawEx.isEmpty || weight == null || weight <= 0) continue;
      final spec = _resolveMoveSpec(rawEx);
      final existingList = groupedByMove.putIfAbsent(spec.id, () => []);
      final prCreatedAt = pr['createdAt']?.toString() ?? '';
      final alreadyPresent = existingList.any((item) {
        final itemWeight = _parseWeight(item['weightKg']);
        final itemCreated = item['createdAt']?.toString() ?? '';
        return itemWeight == weight &&
            (itemCreated == prCreatedAt || prCreatedAt.isEmpty);
      });
      if (!alreadyPresent) {
        existingList.add(pr);
      }
    }

    final List<_SubmittedMovePrCardData> cards = [];

    for (final entry in groupedByMove.entries) {
      final entries = entry.value;
      if (entries.isEmpty) continue;

      // Sort newest first so index 0 is the latest submitted PR for this move
      entries.sort((a, b) {
        final dtA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dtB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return dtB.compareTo(dtA);
      });

      final latest = entries.first;
      final rawEx =
          (latest['exerciseType'] ?? latest['exercise'])?.toString() ??
              entry.key;
      final spec = _resolveMoveSpec(rawEx);
      final latestWeight = _parseWeight(latest['weightKg']) ?? 0;
      final previousWeight =
          entries.length > 1 ? _parseWeight(entries[1]['weightKg']) : null;

      num peak = latestWeight;
      for (final item in entries) {
        final w = _parseWeight(item['weightKg']) ?? 0;
        if (w > peak) peak = w;
      }

      final latestIso = latest['createdAt']?.toString() ?? '';
      final latestDt =
          DateTime.tryParse(latestIso) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final latestReps = (latest['reps'] is num)
          ? (latest['reps'] as num).toInt()
          : int.tryParse(latest['reps']?.toString() ?? '');
      final extUrl = latest['externalUrl']?.toString().trim() ?? '';

      cards.add(
        _SubmittedMovePrCardData(
          moveId: spec.id,
          moveLabel: spec.label,
          icon: spec.icon,
          accentColor: spec.accentColor,
          latestWeightKg: latestWeight,
          previousWeightKg: previousWeight,
          peakWeightKg: peak,
          latestReps: latestReps,
          latestCreatedAtIso: latestIso,
          latestCreatedAt: latestDt,
          hasVideoUrl: extUrl.isNotEmpty,
        ),
      );
    }

    // Order horizontally so the most recently submitted PR is first in the top carousel
    cards.sort((a, b) => b.latestCreatedAt.compareTo(a.latestCreatedAt));
    return cards;
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]}, $h:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _formatShortDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'LATEST';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  bool _isForbiddenError(Object e) {
    if (e is DioException && e.response?.statusCode == 403) {
      return true;
    }
    final msg = e.toString().toLowerCase();
    return msg.contains('403') ||
        msg.contains('forbidden') ||
        msg.contains('not authorized');
  }

  Future<void> _showQuickLogPrSheet(BuildContext context) async {
    final initialMove = _selectedDiscipline != 'ALL'
        ? _selectedDiscipline
        : _canonicalMoves.first.id;
    String selectedMoveId = initialMove;
    final weightCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: Color(0x59D4AF37), width: 1.0),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 16, 18, bottomInset + 20),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0x4DFFFFFF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0x73D4AF37),
                                  width: 1.0,
                                ),
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: AppTheme.goldPrimary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LOG PERSONAL RECORD (PR)',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Select move & weight. Video URL is optional (good to have).',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetCtx).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'ARM-WRESTLING MOVE',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _canonicalMoves.map((move) {
                            final isSelected = selectedMoveId == move.id;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setModalState(() {
                                  selectedMoveId = move.id;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0x24D4AF37)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.goldPrimary
                                        : const Color(0x38FFFFFF),
                                    width: isSelected ? 1.3 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      move.icon,
                                      size: 13,
                                      color: isSelected
                                          ? AppTheme.goldPrimary
                                          : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      move.label,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 11.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? AppTheme.goldPrimary
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: weightCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Weight (kg) *',
                                  hintText: 'e.g. 35',
                                  prefixIcon: Icon(
                                    Icons.fitness_center_rounded,
                                    color: AppTheme.goldPrimary,
                                    size: 18,
                                  ),
                                ),
                                validator: (v) {
                                  final text = v?.trim() ?? '';
                                  if (text.isEmpty) return 'Enter weight (kg)';
                                  final val = double.tryParse(text);
                                  if (val == null || val <= 0) {
                                    return 'Invalid weight';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: repsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Reps (Optional)',
                                  hintText: 'e.g. 1',
                                ),
                                validator: (v) {
                                  final text = v?.trim() ?? '';
                                  if (text.isEmpty) return null;
                                  if (int.tryParse(text) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: urlCtrl,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Video URL (Optional — good to have)',
                            hintText:
                                'Optional YouTube, TikTok, or Facebook link...',
                            helperText:
                                'Not compulsory — good to have a video URL for lift proof',
                            prefixIcon: Icon(
                              Icons.link_rounded,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                          ),
                          validator: (v) {
                            final text = v?.trim() ?? '';
                            if (text.isEmpty) return null;
                            final lower = text.toLowerCase();
                            final supported = lower.contains('youtube.com') ||
                                lower.contains('youtu.be') ||
                                lower.contains('tiktok.com') ||
                                lower.contains('facebook.com') ||
                                lower.contains('fb.watch');
                            if (!supported) {
                              return 'Use a YouTube, TikTok, or Facebook URL';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: notesCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            hintText: 'Strap setup, cable height, or hand feel...',
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    HapticFeedback.mediumImpact();
                                    setModalState(() => isSubmitting = true);
                                    try {
                                      final weightVal = double.parse(
                                        weightCtrl.text.trim(),
                                      );
                                      final repsVal =
                                          repsCtrl.text.trim().isNotEmpty
                                              ? int.tryParse(
                                                  repsCtrl.text.trim(),
                                                )
                                              : null;
                                      final notesVal =
                                          notesCtrl.text.trim().isNotEmpty
                                              ? notesCtrl.text.trim()
                                              : null;

                                      await ref
                                          .read(linkSubmissionProvider.notifier)
                                          .submitLink(
                                            externalUrl: urlCtrl.text.trim(),
                                            category: 'GYM',
                                            caption: notesVal,
                                            exerciseType: selectedMoveId,
                                            weightKg: weightVal,
                                            reps: repsVal,
                                            isTrainingLogEntry: true,
                                          );

                                      ref.invalidate(
                                          trainingLogProvider(athleteId));
                                      ref.invalidate(
                                          trainingLogPRsProvider(athleteId));

                                      if (sheetCtx.mounted) {
                                        Navigator.of(sheetCtx).pop();
                                      }
                                      if (mounted) {
                                        SensoryFeedbackService.instance
                                            .playSensoryCeremony(
                                          audioEvent:
                                              ArmSphereAudioEvent.prAchieved,
                                          hapticType: HapticFeedbackType.heavy,
                                        );
                                        final moveLabel = _resolveMoveSpec(
                                          selectedMoveId,
                                        ).label;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          CrystalSnackBar(
                                            content: Text(
                                              '$moveLabel PR (${_formatWeightValue(weightVal)} kg) updated in your top carousel!',
                                            ),
                                            backgroundColor: AppTheme.success,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } on ApiException catch (e) {
                                      setModalState(() => isSubmitting = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          CrystalSnackBar(
                                            content: Text(e.detail),
                                            backgroundColor: AppTheme.error,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(() => isSubmitting = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          CrystalSnackBar(
                                            content:
                                                Text('Could not log PR: $e'),
                                            backgroundColor: AppTheme.error,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(Icons.emoji_events_rounded),
                            label: Text(
                              isSubmitting
                                  ? 'SAVING PR...'
                                  : 'SAVE PR TO TOP CAROUSEL',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Renders the horizontal carousel of submitted PRs above the filters area.
  /// Only moves that have a submitted PR are shown in this carousel, with each
  /// move displaying its latest submitted weight (e.g., 35 kg in Pronation after
  /// upgrading from 29 kg).
  Widget _buildTopSubmittedPrsCarousel(
    BuildContext context,
    List<_SubmittedMovePrCardData> submittedCards,
    bool isSelf,
  ) {
    if (submittedCards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ElevatedActionCard(
          watermark: ForgedWatermarkType.pulleyAndStrap,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: isSelf ? () => _showQuickLogPrSheet(context) : null,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0x73D4AF37),
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: AppTheme.goldPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LATEST MOVE PR CAROUSEL',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isSelf
                          ? 'Submit your first lift (Pronation, Riser, Back pressure, Side pressure, Cupping, Containment, Hammer curl, Curve biceps curl, or Lat Drag) to populate your top PR carousel.'
                          : 'No move PRs have been submitted by this athlete yet.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelf) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppTheme.goldPrimary,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 15,
                    color: AppTheme.goldPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SUBMITTED MOVE PRs (${submittedCards.length})',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                ],
              ),
              if (isSelf)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showQuickLogPrSheet(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1FD4AF37),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0x73D4AF37),
                        width: 1.0,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 13,
                          color: AppTheme.goldPrimary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'LOG / UPDATE PR',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(submittedCards.length, (index) {
                final card = submittedCards[index];
                final isSelectedFilter = _selectedDiscipline == card.moveId;
                final weightText = '${_formatWeightValue(card.latestWeightKg)} kg';
                final hasPrev = card.previousWeightKg != null &&
                    card.previousWeightKg != card.latestWeightKg;
                final prevText = hasPrev
                    ? 'Prev ${_formatWeightValue(card.previousWeightKg!)} kg'
                    : _formatShortDate(card.latestCreatedAtIso);

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == submittedCards.length - 1 ? 0 : 10,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      SensoryFeedbackService.instance.playSensoryCeremony(
                        audioEvent: ArmSphereAudioEvent.prAchieved,
                        hapticType: HapticFeedbackType.light,
                      );
                      setState(() {
                        _selectedDiscipline =
                            _selectedDiscipline == card.moveId
                                ? 'ALL'
                                : card.moveId;
                      });
                    },
                    child: Container(
                      width: 166,
                      decoration: AppTheme.recessedObsidianWellDecoration(
                        radius: 16,
                        borderColor: isSelectedFilter
                            ? AppTheme.goldPrimary
                            : const Color(0x52D4AF37),
                      ),
                      child: CrystalSlashWrapper.crossedCard(
                        borderRadius: BorderRadius.circular(16),
                        accentColor: card.accentColor,
                        watermark: ForgedWatermarkType.pulleyAndStrap,
                        paintOpticalLens: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: card.accentColor
                                            .withValues(alpha: 0.55),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Icon(
                                      card.icon,
                                      size: 14,
                                      color: card.accentColor,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x1FD4AF37),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0x66D4AF37),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      index == 0 ? 'LATEST PR' : prevText,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: AppTheme.goldPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                weightText,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.goldPrimary,
                                  letterSpacing: -0.3,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                card.moveLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPure,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      hasPrev
                                          ? prevText
                                          : (card.latestReps != null
                                              ? '${card.latestReps} reps • ${_formatShortDate(card.latestCreatedAtIso)}'
                                              : _formatShortDate(
                                                  card.latestCreatedAtIso)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textMuted,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (card.hasVideoUrl)
                                    const Icon(
                                      Icons.play_circle_outline_rounded,
                                      size: 13,
                                      color: AppTheme.cyanAccent,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView(BuildContext context, WidgetRef ref, Object e) {
    if (_isForbiddenError(e)) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          155,
          20,
          MainShellScope.bottomClearance(context, additionalPadding: 44),
        ),
        children: [
          ElevatedActionCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0x73D4AF37),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 32,
                    color: AppTheme.goldPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PRIVATE TRAINING DOSSIER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Individual gym training logs and personal record telemetry are restricted to the athlete and authorized PAFF federation officials.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return AppErrorView(
      error: e,
      title: 'Could not load training log',
      onRetry: () {
        ref.invalidate(trainingLogProvider(athleteId));
        ref.invalidate(trainingLogPRsProvider(athleteId));
      },
      showSecondaryAction: false,
    );
  }

  bool _resolveIsSelf(
    String targetId,
    Map<String, dynamic>? myProfile,
    AuthState authState,
  ) {
    if (targetId.isEmpty || targetId == 'self' || targetId == 'me') {
      return true;
    }
    if (myProfile != null) {
      final myProfileId = myProfile['id']?.toString();
      final myUserId = myProfile['userId']?.toString();
      return (myProfileId != null && myProfileId == targetId) ||
          (myUserId != null && myUserId == targetId);
    }
    final authUser = authState.userProfile;
    if (authUser != null || authState.status == AuthStatus.authenticated) {
      final authUserId = authUser?['id']?.toString();
      final authAthleteId = authUser?['athleteId']?.toString();
      return (authUserId != null && authUserId == targetId) ||
          (authAthleteId != null && authAthleteId == targetId);
    }
    // Isolated widget test harness fallback when neither profile nor auth state is configured
    return authState.status == AuthStatus.unknown;
  }

  @override
  Widget build(BuildContext context) {
    final prsAsync = ref.watch(trainingLogPRsProvider(athleteId));
    final logsAsync = ref.watch(trainingLogProvider(athleteId));
    final myProfile = ref.watch(athleteProfileProvider).value;
    final authState = ref.watch(authProvider);
    final isSelf = _resolveIsSelf(athleteId, myProfile, authState);

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: const CrystalHeaderStageBar(
          domain: ArmSphereStageDomain.training,
        ),
        elevation: 0,
        leading: const CrystalBackButton(),
        title: const Text(
          'Training Log & PRs',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [
          CrystalHomeButton(),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(
              domain: ArmSphereStageDomain.training,
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(trainingLogPRsProvider(athleteId));
              ref.invalidate(trainingLogProvider(athleteId));
            },
            child: logsAsync.when(
              loading: () => const CrystalScreenLoadingView(
                itemCount: 4,
                cardHeight: 88,
              ),
              error: (e, _) => _errorView(context, ref, e),
              data: (allLogs) {
                final allPrs = prsAsync.value ?? const <Map<String, dynamic>>[];
                final submittedMoveCards =
                    _buildSubmittedMoveCards(allLogs, allPrs);

                final prsList = allPrs
                    .where((pr) => _matchesDiscipline(
                        (pr['exerciseType'] ?? pr['exercise'])?.toString() ??
                            ''))
                    .toList();
                final logs = allLogs
                    .where((l) => _matchesDiscipline(
                        (l['exerciseType'] ?? l['exercise'])?.toString() ?? ''))
                    .toList();

                num peakWeight = 0;
                for (final card in submittedMoveCards) {
                  if (_selectedDiscipline == 'ALL' ||
                      card.moveId == _selectedDiscipline) {
                    if (card.peakWeightKg > peakWeight) {
                      peakWeight = card.peakWeightKg;
                    }
                  }
                }
                for (final pr in prsList) {
                  final w = _parseWeight(pr['weightKg']) ?? 0;
                  if (w > peakWeight) peakWeight = w;
                }
                for (final l in logs) {
                  final w = _parseWeight(l['weightKg']) ?? 0;
                  if (w > peakWeight) peakWeight = w;
                }

                return ListView(
                  key: const PageStorageKey<String>('training_log_list_view'),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    MainShellScope.bottomClearance(context, additionalPadding: 80),
                  ),
                  children: [
                    // ========================================================
                    // 1. TOP HORIZONTAL CAROUSEL OF SUBMITTED MOVE PRs
                    //    (Only submitted moves appear here; latest submitted PR
                    //     weight is displayed on each move card)
                    // ========================================================
                    _buildTopSubmittedPrsCarousel(
                      context,
                      submittedMoveCards,
                      isSelf,
                    ),

                    // ========================================================
                    // 2. 9-MOVE STRENGTH DISCIPLINE FILTER BAR
                    //    (All Lifts, Pronation, Riser, Back pressure, Side pressure,
                    //     Cupping, Containment, Hammer curl, Curve biceps curl, Lat Drag)
                    // ========================================================
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _disciplines.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final d = _disciplines[idx];
                          final isSelected = _selectedDiscipline == d.id;
                          return ChoiceChip(
                            label: Text(
                              d.label,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppTheme.goldPrimary
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.transparent,
                            backgroundColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSmall),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0x73D4AF37)
                                    : const Color(0x2EFFFFFF),
                                width: isSelected ? 1.2 : 1.0,
                              ),
                            ),
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedDiscipline = d.id);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ========================================================
                    // 3. TITANIUM LUXE SUMMARY RIBBON
                    // ========================================================
                    ElevatedActionCard(
                      watermark: ForgedWatermarkType.pulleyAndStrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                        vertical: AppTheme.space14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LOGGED SESSIONS',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${logs.length}',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                              width: 1, height: 32, color: AppTheme.cardBorder),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'HEAVIEST PR',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  peakWeight > 0
                                      ? '${_formatWeightValue(peakWeight)} kg'
                                      : '—',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.goldPrimary,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                              width: 1, height: 32, color: AppTheme.cardBorder),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SUBMITTED MOVES',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${submittedMoveCards.length}',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'SESSION HISTORY',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (logs.isEmpty)
                      AppEmptyState(
                        icon: Icons.fitness_center,
                        title: 'No training logged yet',
                        subtitle: isSelf
                            ? 'Log your lift weight across any of the 9 arm-wrestling moves. Video URL is optional (good to have).'
                            : 'This athlete has not published any verified GYM training logs yet.',
                        ctaLabel: isSelf ? 'Log a Session / PR' : null,
                        onCtaTap: isSelf
                            ? () => _showQuickLogPrSheet(context)
                            : null,
                      )
                    else
                      Column(
                        children: List.generate(logs.length, (index) {
                          final log = logs[index];
                          final rawExercise =
                              (log['exerciseType'] ?? log['exercise'])
                                      ?.toString() ??
                                  'Session';
                          final spec = _resolveMoveSpec(rawExercise);
                          final exerciseLabel = spec.label;
                          final caption = log['caption']?.toString() ?? '';
                          final weight = _parseWeight(log['weightKg']);
                          final reps = log['reps'] as num?;
                          final details = [
                            if (weight != null)
                              '${_formatWeightValue(weight)} kg',
                            if (reps != null) '$reps reps',
                          ].join(' x ');
                          final time =
                              _formatDate(log['createdAt']?.toString() ?? '');
                          final thumbUrl = (log['thumbnailUrl'] ??
                                  log['mediaUrl'] ??
                                  log['imageUrl'])
                              ?.toString();
                          final extVideoUrl =
                              (log['externalUrl'] ?? log['videoUrl'] ?? '')
                                  .toString()
                                  .trim();
                          final hasLiftVideo = extVideoUrl.isNotEmpty;

                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: index == logs.length - 1 ? 0 : 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: hasLiftVideo
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      VideoPlayerModal.show(
                                        context,
                                        videoUrl: extVideoUrl,
                                        title: details.isNotEmpty
                                            ? '$exerciseLabel — $details'
                                            : exerciseLabel,
                                      );
                                    }
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: hasLiftVideo
                                        ? AppTheme.goldPrimary
                                            .withValues(alpha: 0.45)
                                        : const Color(0x38FFFFFF),
                                    width: 1.0,
                                  ),
                                  boxShadow: const [],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ArmSphereImage(
                                          imageUrl: (thumbUrl != null &&
                                                  thumbUrl.isNotEmpty)
                                              ? thumbUrl
                                              : null,
                                          assetPath: (thumbUrl == null ||
                                                  thumbUrl.isEmpty)
                                              ? ArmSphereAssets
                                                  .clipFallbackSparring
                                              : null,
                                          fallbackAsset: ArmSphereAssets
                                              .clipFallbackSparring,
                                          fit: BoxFit.cover,
                                          alignment: Alignment.centerRight,
                                          excludeFromSemantics: true,
                                        ),
                                      ),
                                      const Positioned.fill(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              stops: [0.0, 0.55, 1.0],
                                              colors: [
                                                Color(0x80000000),
                                                Color(0x00000000),
                                                Color(0x00000000),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: FractionallySizedBox(
                                          widthFactor: 0.65,
                                          alignment: Alignment.centerLeft,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                        color: spec.accentColor
                                                            .withValues(
                                                                alpha: 0.55),
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      spec.icon,
                                                      size: 14,
                                                      color: spec.accentColor,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      exerciseLabel,
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            'Space Grotesk',
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 14,
                                                        color: AppTheme
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (details.isNotEmpty ||
                                                  caption.isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  caption.isNotEmpty &&
                                                          details.isNotEmpty
                                                      ? '$caption ($details)'
                                                      : caption.isNotEmpty
                                                          ? caption
                                                          : details,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppTheme.textSecondary,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  if (time.isNotEmpty)
                                                    Flexible(
                                                      child: Text(
                                                        time,
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              'Space Grotesk',
                                                          fontSize: 11,
                                                          fontFeatures: [
                                                            FontFeature
                                                                .tabularFigures()
                                                          ],
                                                          color:
                                                              AppTheme.textMuted,
                                                        ),
                                                      ),
                                                    ),
                                                  if (hasLiftVideo) ...[
                                                    if (time.isNotEmpty)
                                                      const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 7,
                                                          vertical: 2.5),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0x22D4AF37),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                        border: Border.all(
                                                          color: const Color(
                                                              0x80D4AF37),
                                                        ),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .play_circle_fill_rounded,
                                                            size: 11,
                                                            color: AppTheme
                                                                .goldPrimary,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            'WATCH LIFT',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Space Grotesk',
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: AppTheme
                                                                  .goldPrimary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: MainShellScope.fabLocation(context),
      floatingActionButton: isSelf
          ? CrystalFloatingActionButton(
              heroTag: 'training_log_add',
              tooltip: 'Log a session or PR',
              icon: Icons.add,
              onPressed: () {
                _showQuickLogPrSheet(context);
              },
            )
          : null,
    );
  }
}

IconData _getExerciseIcon(String exercise) {
  final ex = exercise.toUpperCase();
  if (ex.contains('CONTAIN')) {
    return Icons.back_hand_outlined;
  } else if (ex.contains('CUP') || ex.contains('WRIST')) {
    return Icons.pan_tool_alt_rounded;
  } else if (ex.contains('PRONAT')) {
    return Icons.rotate_right_rounded;
  } else if (ex.contains('RIS')) {
    return Icons.arrow_upward_rounded;
  } else if (ex.contains('HAMMER')) {
    return Icons.sports_mma_outlined;
  } else if (ex.contains('CURVE') || ex.contains('BICEP')) {
    return Icons.bolt_rounded;
  } else if (ex.contains('LAT') || ex.contains('DRAG')) {
    return Icons.south_west_rounded;
  } else if (ex.contains('BACK')) {
    return Icons.fitness_center_rounded;
  } else if (ex.contains('SIDE')) {
    return Icons.sync_alt_rounded;
  }
  return Icons.sports_gymnastics_rounded;
}

Color _getExerciseColor(String exercise) {
  final ex = exercise.toUpperCase();
  if (ex.contains('CUP')) return AppTheme.goldPrimary;
  if (ex.contains('CONTAIN')) return AppTheme.cyanAccent;
  if (ex.contains('PRONAT')) return AppTheme.cyanAccent;
  if (ex.contains('RIS')) return AppTheme.success;
  if (ex.contains('BACK')) return AppTheme.goldPrimary;
  if (ex.contains('SIDE') || ex.contains('LAT')) return AppTheme.crimson;
  return AppTheme.goldPrimary;
}
