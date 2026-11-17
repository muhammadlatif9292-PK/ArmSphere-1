import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/status_chip.dart';

// =============================================================================
// SHARED HOLD-TO-READ (LONG PRESS FULL TEXT PREVIEW) & WEIGHT/DIVISION HELPERS
// =============================================================================

void showHoldFullTextPopup(
  BuildContext context, {
  String? title,
  required String fullText,
}) {
  final cleaned = fullText.trim();
  if (cleaned.isEmpty) return;
  HapticFeedback.mediumImpact();
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF121722),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.goldPrimary, width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null && title.trim().isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.goldPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title.trim().toUpperCase(),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.6,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Text(
              cleaned,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'CLOSE',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class HoldToInspectText extends StatelessWidget {
  final String fullText;
  final String? title;
  final Widget child;

  const HoldToInspectText({
    super.key,
    required this.fullText,
    this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = fullText.trim();
    if (trimmed.isEmpty) return child;
    return Tooltip(
      message: trimmed,
      preferBelow: false,
      decoration: BoxDecoration(
        color: const Color(0xF5111622),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.goldPrimary, width: 1.2),
      ),
      textStyle: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () => showHoldFullTextPopup(
          context,
          title: title,
          fullText: trimmed,
        ),
        child: child,
      ),
    );
  }
}

double parseWeightClassCeilingKg(String? label) {
  if (label == null || label.trim().isEmpty) return 999.0;
  final upper = label.toUpperCase();
  if (upper.contains('OPEN') ||
      upper.contains('+') ||
      upper.contains('UNLIMITED')) {
    return 999.0;
  }
  final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(upper);
  if (match != null) {
    return double.tryParse(match.group(1)!) ?? 999.0;
  }
  return 999.0;
}

String resolveAthleteWeightLimitLabel(Map<String, dynamic> athlete) {
  final reg = (athlete['registeredWeightLabel'] ?? '').toString().trim();
  if (reg.isNotEmpty && reg.toLowerCase() != 'null') return reg;
  final wc = (athlete['weightClass'] ?? '').toString().trim();
  if (wc.isNotEmpty && wc.toLowerCase() != 'null') return wc;
  final cat = (athlete['categoryLabel'] ?? '').toString().trim();
  if (cat.isNotEmpty) {
    return cat.split('•').first.trim();
  }
  return '80 kg';
}

int resolveAthleteElo(Map<String, dynamic> athlete) {
  final v = athlete['eloRating'] ?? athlete['elo'];
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 1500;
}

String resolveAthleteClub(Map<String, dynamic> athlete) {
  final c = (athlete['clubName'] ?? athlete['club'] ?? '').toString().trim();
  if (c.isNotEmpty && c.toLowerCase() != 'null') return c;
  return 'ArmSphere Club';
}

String resolveAthleteQr(Map<String, dynamic> athlete) {
  final qr =
      (athlete['qrCode'] ?? athlete['qrCodePayload'] ?? athlete['id'] ?? '')
          .toString()
          .trim();
  return qr;
}

String eloTierBadgeForRating(int elo) {
  if (elo >= 1800) return 'GRANDMASTER';
  if (elo >= 1650) return 'MASTER';
  if (elo >= 1500) return 'ELITE CONTENDER';
  return 'PROSPECT';
}

String compactDivisionTag(String rawLabel) {
  final trimmed = rawLabel.trim();
  if (trimmed.isEmpty ||
      trimmed.toUpperCase() == 'ALL' ||
      trimmed == 'All Categories') {
    return 'All';
  }
  String weightPart = trimmed.split('•').first.trim();
  weightPart = weightPart.replaceAll(' ', '');
  final upper = trimmed.toUpperCase();
  if (upper.contains('RIGHT')) {
    return '$weightPart R';
  }
  if (upper.contains('LEFT')) {
    return '$weightPart L';
  }
  return trimmed;
}

// =============================================================================
// 1. CARD 2 — ATHLETE REGISTRY SCREEN (SCROLLABLE, TOP CAROUSEL & ROSTER)
// =============================================================================
class Card2AppliedAthletesView extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, String>> separatedDivisions;
  final List<Map<String, dynamic>> appliedAthletes;
  final String autoSaveBannerText;
  final ValueChanged<List<Map<String, dynamic>>> onUpdateAthletes;
  final ValueChanged<String> onOpenWeighInForAthlete;
  final VoidCallback onBackToHub;

  const Card2AppliedAthletesView({
    super.key,
    required this.tournament,
    required this.separatedDivisions,
    required this.appliedAthletes,
    required this.autoSaveBannerText,
    required this.onUpdateAthletes,
    required this.onOpenWeighInForAthlete,
    required this.onBackToHub,
  });

  static Future<void> showRegisterAthleteModal({
    required BuildContext context,
    required Map<String, dynamic> tournament,
    required List<Map<String, String>> separatedDivisions,
    required List<Map<String, dynamic>> appliedAthletes,
    required ValueChanged<List<Map<String, dynamic>>> onUpdateAthletes,
    WidgetRef? ref,
  }) async {
    final nameCtrl = TextEditingController();
    final clubCtrl = TextEditingController(text: 'ArmSphere Club');
    final eloCtrl = TextEditingController(text: '1600');
    final prCtrl = TextEditingController(text: '60 kg Max Lift');
    final maxLiftCtrl = TextEditingController(text: '60');
    String? selectedAthleteId;
    List<Map<String, dynamic>> searchMatches = [];
    bool isSearching = false;
    Timer? debounceTimer;

    final divisions = separatedDivisions.isNotEmpty
        ? separatedDivisions
        : [
            {
              'weightLabel': '80 kg',
              'arm': 'RIGHT',
              'label': '80 kg • Right Arm',
            }
          ];
    Map<String, String> selectedDiv = divisions.first;

    void onNameChanged(String val, void Function(void Function()) setModalState) {
      debounceTimer?.cancel();
      final q = val.trim();
      if (q.isEmpty || ref == null) {
        setModalState(() {
          searchMatches = [];
          isSearching = false;
        });
        return;
      }
      setModalState(() => isSearching = true);
      debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        try {
          final results = await ref.read(athleteRepositoryProvider).searchAthletes(q);
          setModalState(() {
            searchMatches = results;
            isSearching = false;
          });
        } catch (_) {
          setModalState(() => isSearching = false);
        }
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFA0B0F19),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0x38FFFFFF), width: 1.0),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.viewInsetsOf(ctx).bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.goldPrimary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.goldPrimary
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: AppTheme.goldPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'ADD ATHLETE TO REGISTRY',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Clean non-colliding Athlete Full Name Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ATHLETE FULL NAME',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: AppTheme.goldPrimary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameCtrl,
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'e.g. Tariq Mehmood',
                              prefixIcon: Icon(Icons.badge_outlined, size: 18),
                              isDense: true,
                            ),
                            onChanged: (val) => onNameChanged(val, setModalState),
                          ),
                        ],
                      ),

                      if (isSearching)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: const [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldPrimary),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Searching athlete database...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.goldPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (searchMatches.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          constraints: const BoxConstraints(maxHeight: 140),
                          decoration: BoxDecoration(
                            color: const Color(0x4D04060B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x38FFFFFF)),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(6),
                            itemCount: searchMatches.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                            itemBuilder: (ctx, idx) {
                              final athlete = searchMatches[idx];
                              final aName = (athlete['displayName'] ?? athlete['fullName'] ?? athlete['name'] ?? '').toString();
                              final aClub = (athlete['clubName'] ?? athlete['club'] ?? athlete['city'] ?? 'ArmSphere Club').toString();
                              final aElo = (athlete['eloRating'] ?? athlete['elo'] ?? 1600).toString();
                              return InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    nameCtrl.text = aName;
                                    clubCtrl.text = aClub;
                                    eloCtrl.text = aElo;
                                    selectedAthleteId = (athlete['id'] ?? athlete['userId'] ?? athlete['athleteId'] ?? '').toString();
                                    searchMatches = [];
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0x22FFFFFF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.goldPrimary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '$aName • $aClub',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                        ),
                                      ),
                                      Text('ELO $aElo', style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11, color: AppTheme.goldPrimary)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WEIGHT & ARM DIVISION',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: AppTheme.goldPrimary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: selectedDiv['label'],
                            dropdownColor: AppTheme.elevatedSurface,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              prefixIcon:
                                  Icon(Icons.fitness_center_rounded, size: 18),
                            ),
                            items: [
                              for (final d in divisions)
                                DropdownMenuItem(
                                  value: d['label'],
                                  child: Text(d['label'] ?? ''),
                                ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              final match = divisions.firstWhere(
                                (d) => d['label'] == v,
                                orElse: () => divisions.first,
                              );
                              setModalState(() => selectedDiv = match);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ELO RATING',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: eloCtrl,
                                  keyboardType: TextInputType.number,
                                  onTapOutside: (_) =>
                                      FocusManager.instance.primaryFocus?.unfocus(),
                                  style:
                                      const TextStyle(color: AppTheme.textPrimary),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    prefixIcon:
                                        Icon(Icons.leaderboard_rounded, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CLUB / CITY',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: clubCtrl,
                                  onTapOutside: (_) =>
                                      FocusManager.instance.primaryFocus?.unfocus(),
                                  style:
                                      const TextStyle(color: AppTheme.textPrimary),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    prefixIcon:
                                        Icon(Icons.shield_outlined, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'VERIFIED PR SUMMARY',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: prCtrl,
                                  onTapOutside: (_) =>
                                      FocusManager.instance.primaryFocus?.unfocus(),
                                  style:
                                      const TextStyle(color: AppTheme.textPrimary),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    prefixIcon: Icon(Icons.bolt_rounded, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MAX LIFT (KG)',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: maxLiftCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onTapOutside: (_) =>
                                      FocusManager.instance.primaryFocus?.unfocus(),
                                  style:
                                      const TextStyle(color: AppTheme.textPrimary),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          final elo = int.tryParse(eloCtrl.text.trim()) ?? 1550;
                          final maxLiftKg =
                              double.tryParse(maxLiftCtrl.text.trim()) ?? 62.0;
                          final prSummary = prCtrl.text.trim().isEmpty
                              ? '${maxLiftKg.toStringAsFixed(0)} kg Max Lift'
                              : prCtrl.text.trim();
                          final idx = appliedAthletes.length + 1;
                          final tId = (tournament['id'] ?? 'TRN').toString();
                          final rawDivLabel =
                              selectedDiv['label'] ?? '80 kg • Right Arm';
                          final weightPart =
                              selectedDiv['weightLabel'] ??
                                  rawDivLabel.split('•').first.trim();
                          final armPart = selectedDiv['arm'] ??
                              (rawDivLabel.toUpperCase().contains('LEFT')
                                  ? 'LEFT'
                                  : 'RIGHT');
                          final qrStr =
                              'ARMSPHERE-$tId-ATH-${idx.toString().padLeft(3, '0')}';
                          final effectiveAthleteId = selectedAthleteId ??
                              'ath-reg-${DateTime.now().millisecondsSinceEpoch}';
                          final newAthlete = <String, dynamic>{
                            'id': effectiveAthleteId,
                            'athleteId': effectiveAthleteId,
                            'athleteName': name,
                            'club': clubCtrl.text.trim().isEmpty
                                ? 'Independent'
                                : clubCtrl.text.trim(),
                            'clubName': clubCtrl.text.trim().isEmpty
                                ? 'Independent'
                                : clubCtrl.text.trim(),
                            'elo': elo,
                            'eloRating': elo,
                            'prSummary': prSummary,
                            'prKg': maxLiftKg,
                            'maxLiftKg': maxLiftKg,
                            'registeredWeightLabel': weightPart,
                            'weightClass': weightPart,
                            'registeredArm': armPart,
                            'arm': armPart,
                            'categoryLabel': rawDivLabel,
                            'qrCode': qrStr,
                            'qrCodePayload': qrStr,
                            'appliedAt': DateTime.now().toIso8601String(),
                            'weighInStatus': 'PENDING',
                            'measuredWeightKg': null,
                            'guestPassesAllowed':
                                (tournament['athleteGuestPassAllowance']
                                            as num?)
                                        ?.toInt() ??
                                    1,
                            'checkedInAtGate': false,
                          };
                          final next = [
                            newAthlete,
                            ...appliedAthletes,
                          ];
                          onUpdateAthletes(next);
                          Navigator.of(sheetCtx).pop();
                          CrystalToast.show(
                            context,
                            title: 'Athlete Added',
                            message: '$name registered in $rawDivLabel.',
                            type: CrystalToastType.success,
                          );
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2A2111), Color(0xFF141008)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.goldPrimary,
                              width: 1.3,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                color: AppTheme.goldPrimary,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'ADD ATHLETE & GENERATE QR PASS',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  State<Card2AppliedAthletesView> createState() =>
      _Card2AppliedAthletesViewState();
}

class _Card2AppliedAthletesViewState extends State<Card2AppliedAthletesView> {
  String _selectedCategoryFilter = 'ALL'; // 'ALL' or categoryLabel
  String _searchQuery = '';

  List<Map<String, String>> _buildCategoryChipsData() {
    final countsByLabel = <String, int>{};
    final orderedLabels = <String>[];

    for (final div in widget.separatedDivisions) {
      final lbl = (div['label'] ?? '').trim();
      if (lbl.isNotEmpty && !orderedLabels.contains(lbl)) {
        orderedLabels.add(lbl);
        countsByLabel[lbl] = 0;
      }
    }

    for (final a in widget.appliedAthletes) {
      final lbl = (a['categoryLabel'] ?? '').toString().trim();
      if (lbl.isEmpty) continue;
      if (!orderedLabels.contains(lbl)) {
        orderedLabels.add(lbl);
      }
      countsByLabel[lbl] = (countsByLabel[lbl] ?? 0) + 1;
    }

    return [
      {
        'key': 'ALL',
        'label': 'All',
        'fullLabel': 'All Divisions (${widget.appliedAthletes.length} Athletes)',
        'count': widget.appliedAthletes.length.toString(),
      },
      for (final lbl in orderedLabels)
        {
          'key': lbl,
          'label': compactDivisionTag(lbl),
          'fullLabel': '$lbl (${countsByLabel[lbl] ?? 0} Athletes)',
          'count': (countsByLabel[lbl] ?? 0).toString(),
        },
    ];
  }

  List<Map<String, dynamic>> _getFilteredAthletes() {
    final q = _searchQuery.trim().toLowerCase();
    return widget.appliedAthletes.where((a) {
      if (_selectedCategoryFilter != 'ALL') {
        final cat = (a['categoryLabel'] ?? '').toString().trim();
        if (cat != _selectedCategoryFilter) return false;
      }
      if (q.isNotEmpty) {
        final name = (a['athleteName'] ?? '').toString().toLowerCase();
        final qr = resolveAthleteQr(a).toLowerCase();
        final club = resolveAthleteClub(a).toLowerCase();
        final cat = (a['categoryLabel'] ?? '').toString().toLowerCase();
        return name.contains(q) ||
            qr.contains(q) ||
            club.contains(q) ||
            cat.contains(q);
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _getEloRankedAthletes() {
    final base = _selectedCategoryFilter == 'ALL'
        ? List<Map<String, dynamic>>.from(widget.appliedAthletes)
        : widget.appliedAthletes
            .where((a) =>
                (a['categoryLabel'] ?? '').toString().trim() ==
                _selectedCategoryFilter)
            .toList();

    base.sort((a, b) {
      final eloA = resolveAthleteElo(a);
      final eloB = resolveAthleteElo(b);
      return eloB.compareTo(eloA);
    });
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final chips = _buildCategoryChipsData();
    final eloRanked = _getEloRankedAthletes();
    final filteredAthletes = _getFilteredAthletes();

    final seedIndexById = <String, int>{};
    for (int i = 0; i < eloRanked.length; i++) {
      final id = (eloRanked[i]['id'] ?? '').toString();
      if (id.isNotEmpty) {
        seedIndexById[id] = i + 1;
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space16,
          8,
          AppTheme.space16,
          120,
        ),
        children: [
          // 1. Division Filter Bar (Horizontally Scrollable Forged-Crystal Chips with Live Counts)
          SingleChildScrollView(
            key: const ValueKey('card2_category_filter_bar'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (int i = 0; i < chips.length; i++) ...[
                  Builder(
                    builder: (_) {
                      final chip = chips[i];
                      final isSelected = _selectedCategoryFilter == chip['key'];
                      final isAll = chip['key'] == 'ALL';
                      final activeColor = isAll
                          ? const Color(0xFFE23B3B) // Competition Crimson
                          : AppTheme.goldPrimary; // 24k Gold
                      final fullChipText =
                          chip['fullLabel'] ?? '${chip['label']} (${chip['count']})';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: HoldToInspectText(
                          title: 'Division Filter',
                          fullText: fullChipText,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(11),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              FocusManager.instance.primaryFocus?.unfocus();
                              setState(() {
                                _selectedCategoryFilter = chip['key'] ?? 'ALL';
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isAll
                                            ? const [
                                                Color(0xFF3A1216),
                                                Color(0xFF1A090B),
                                              ]
                                            : const [
                                                Color(0xFF2B2210),
                                                Color(0xFF141008),
                                              ],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFF141821),
                                          Color(0xFF0C0F15),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                  color: isSelected
                                      ? activeColor
                                      : const Color(0x28FFFFFF),
                                  width: isSelected ? 1.3 : 1.0,
                                ),
                              ),
                              child: Text(
                                '${chip['label']} (${chip['count']})',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Top Seeded ELO Horizontal Carousel
          Container(
            key: const ValueKey('card2_elo_ranking_carousel'),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0x4D04060B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.goldPrimary.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppTheme.goldPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: HoldToInspectText(
                        title: 'Seeded ELO Rankings',
                        fullText: _selectedCategoryFilter == 'ALL'
                            ? 'Top Seeded ELO Rankings • All Divisions (${eloRanked.length} Seeds)'
                            : 'Top Seeded ELO • $_selectedCategoryFilter (${eloRanked.length} Seeds)',
                        child: Text(
                          _selectedCategoryFilter == 'ALL'
                              ? 'TOP SEEDED ELO RANKINGS • ALL DIVISIONS'
                              : 'TOP SEEDED ELO • ${compactDivisionTag(_selectedCategoryFilter).toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.7,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '${eloRanked.length} SEEDS',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (eloRanked.isEmpty)
                  const SizedBox(
                    height: 76,
                    child: Center(
                      child: Text(
                        'No athletes registered in this division yet.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 118,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: eloRanked.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final athlete = eloRanked[index];
                        final rank = index + 1;
                        final elo = resolveAthleteElo(athlete);
                        final clubName = resolveAthleteClub(athlete);
                        final athleteName =
                            (athlete['athleteName'] ?? 'Athlete').toString();
                        final fullCat =
                            (athlete['categoryLabel'] ?? '').toString();
                        final divCompact = compactDivisionTag(fullCat);

                        final Color seedColor = rank == 1
                            ? const Color(0xFFD4AF37) // #1 SEED 24k Gold
                            : rank == 2
                                ? const Color(0xFFE2E8F0) // #2 SEED Silver
                                : rank == 3
                                    ? const Color(0xFFCD7F32) // #3 SEED Bronze
                                    : const Color(0xFF94A3B8); // #4+ Titanium

                        return HoldToInspectText(
                          title: 'Seed #$rank Athlete Details',
                          fullText:
                              '$athleteName\nSeed #$rank • ELO $elo\nDivision: $fullCat\nClub: $clubName',
                          child: Container(
                            width: 196,
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: rank == 1
                                    ? const [
                                        Color(0xFF282010),
                                        Color(0xFF110E08),
                                      ]
                                    : const [
                                        Color(0xFF171C27),
                                        Color(0xFF0D1017),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: seedColor.withValues(
                                  alpha: rank <= 3 ? 0.8 : 0.35,
                                ),
                                width: rank == 1 ? 1.5 : 1.1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            seedColor.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color:
                                              seedColor.withValues(alpha: 0.65),
                                        ),
                                      ),
                                      child: Text(
                                        '#$rank SEED',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                          color: seedColor,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.obsidian,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppTheme.goldPrimary
                                              .withValues(alpha: 0.55),
                                        ),
                                      ),
                                      child: Text(
                                        'ELO $elo',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10.5,
                                          color: AppTheme.goldPrimary,
                                          fontFeatures: [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  athleteName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E2433),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        divCompact,
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        clubName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Compact Roster Search Bar (Unfocuses on tap outside)
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search athlete name, club, or division...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppTheme.goldPrimary,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() => _searchQuery = '');
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      icon: const Icon(Icons.clear_rounded, size: 16),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),

          // 4. Clean Division Roster List (ForgedCrystalRow Bars)
          if (filteredAthletes.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0x4D04060B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x38FFFFFF), width: 1.0),
              ),
              child: const Center(
                child: Text(
                  'No athletes match the selected division or search query.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
                ),
              ),
            )
          else
            for (int idx = 0; idx < filteredAthletes.length; idx++) ...[
              Builder(
                builder: (_) {
                  final athlete = filteredAthletes[idx];
                  final id = (athlete['id'] ?? '').toString();
                  final seedNum = seedIndexById[id] ?? (idx + 1);
                  final elo = resolveAthleteElo(athlete);
                  final clubName = resolveAthleteClub(athlete);
                  final maxLift =
                      (athlete['maxLiftKg'] as num?)?.toDouble() ?? 60.0;
                  final weighStatus =
                      (athlete['weighInStatus'] ?? 'PENDING').toString();
                  final isVerified = weighStatus == 'VERIFIED';
                  final isUnmatched = weighStatus == 'UNMATCHED' ||
                      weighStatus == 'UNMATCH';
                  final qrCode = resolveAthleteQr(athlete);
                  final fullCat =
                      (athlete['categoryLabel'] ?? '').toString();
                  final divTag = compactDivisionTag(fullCat);
                  final athleteName =
                      (athlete['athleteName'] ?? 'Athlete').toString();

                  final Color statusColor = isVerified
                      ? AppTheme.emerald
                      : isUnmatched
                          ? AppTheme.crimson
                          : AppTheme.warning;
                  final String statusLabel = isVerified
                      ? 'VERIFIED ✓'
                      : isUnmatched
                          ? 'UNMATCH ⚠'
                          : 'AWAITING SCALE';

                  return HoldToInspectText(
                    title: athleteName,
                    fullText:
                        'Seed #$seedNum • $athleteName\nDivision: $fullCat\nClub: $clubName\nELO: $elo • Max Lift PR: ${maxLift.toStringAsFixed(0)} kg\nWeigh-In Status: $statusLabel',
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x4D04060B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isVerified
                              ? AppTheme.emerald.withValues(alpha: 0.55)
                              : isUnmatched
                                  ? AppTheme.crimson.withValues(alpha: 0.65)
                                  : const Color(0x38FFFFFF),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Seed # Badge
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: seedNum <= 3
                                  ? AppTheme.goldPrimary.withValues(alpha: 0.16)
                                  : AppTheme.obsidian,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: seedNum <= 3
                                    ? AppTheme.goldPrimary
                                        .withValues(alpha: 0.65)
                                    : const Color(0x33FFFFFF),
                              ),
                            ),
                            child: Text(
                              '#$seedNum',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w900,
                                fontSize: 11.5,
                                color: seedNum <= 3
                                    ? AppTheme.goldPrimary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Athlete Name, Club/City, Weight & Arm tag, ELO + PR badge
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        athleteName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13.5,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF232938),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: AppTheme.goldPrimary
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        divTag,
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.goldPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      clubName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '• ELO $elo',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.goldPrimary,
                                      ),
                                    ),
                                    Text(
                                      '• PR ${maxLift.toStringAsFixed(0)}kg',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.cyan,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Weigh-In Status Pill (Tappable to jump to Card 4 Scale)
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => widget.onOpenWeighInForAthlete(
                              id.isNotEmpty ? id : qrCode,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.65),
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: statusColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
        ],
      ),
    );
  }
}

// =============================================================================
// 2. CARD 4 — WEIGH-IN VERIFICATION SCREEN (SCROLLABLE, CLEAN SCALE CONSOLE)
// =============================================================================
class Card4WeighInVerificationView extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, String>> separatedDivisions;
  final List<Map<String, dynamic>> appliedAthletes;
  final String autoSaveBannerText;
  final String? initialScannedQrCode;
  final String? initialSelectedAthleteId;
  final ValueChanged<List<Map<String, dynamic>>>? onUpdateAthletes;
  final Future<void> Function({
    required List<Map<String, dynamic>> updatedAthletes,
    required String actionType,
    required Map<String, dynamic> syncPayload,
    required String bannerMessage,
  })? onCommitWeighInAction;
  final void Function({
    required Map<String, dynamic> athlete,
    required String newWeightLabel,
    required String newArm,
    required String newCategoryLabel,
    required bool autoPairInNewCategory,
  })? onSwitchCategoryAndPairInMatchups;
  final VoidCallback onBackToHub;

  const Card4WeighInVerificationView({
    super.key,
    required this.tournament,
    required this.separatedDivisions,
    required this.appliedAthletes,
    required this.autoSaveBannerText,
    this.initialScannedQrCode,
    this.initialSelectedAthleteId,
    this.onUpdateAthletes,
    this.onCommitWeighInAction,
    this.onSwitchCategoryAndPairInMatchups,
    required this.onBackToHub,
  });

  @override
  State<Card4WeighInVerificationView> createState() =>
      _Card4WeighInVerificationViewState();
}

class _Card4WeighInVerificationViewState
    extends State<Card4WeighInVerificationView> {
  late final TextEditingController _qrScanController;
  late final TextEditingController _measuredWeightController;
  late List<Map<String, dynamic>> _athletesList;
  String _manualSearchQuery = '';
  String _statusFilter = 'ALL'; // ALL, PENDING, VERIFIED, UNMATCHED
  Map<String, dynamic>? _activeScannedAthlete;

  @override
  void initState() {
    super.initState();
    _athletesList = widget.appliedAthletes
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    _qrScanController =
        TextEditingController(text: widget.initialScannedQrCode ?? '');
    _measuredWeightController = TextEditingController();

    if (widget.initialScannedQrCode != null &&
        widget.initialScannedQrCode!.trim().isNotEmpty) {
      _resolveQrScan(widget.initialScannedQrCode!.trim(), showToast: false);
    } else if (widget.initialSelectedAthleteId != null &&
        widget.initialSelectedAthleteId!.trim().isNotEmpty) {
      final target = widget.initialSelectedAthleteId!.trim();
      final found = _athletesList
          .where((a) =>
              a['id']?.toString() == target ||
              a['athleteId']?.toString() == target ||
              resolveAthleteQr(a) == target)
          .firstOrNull;
      if (found != null) {
        _selectAthleteForWeighIn(found);
      } else if (_athletesList.isNotEmpty) {
        _selectAthleteForWeighIn(_athletesList.first);
      }
    } else if (_athletesList.isNotEmpty) {
      _selectAthleteForWeighIn(_athletesList.first);
    }
  }

  @override
  void didUpdateWidget(covariant Card4WeighInVerificationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _athletesList = widget.appliedAthletes
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (_activeScannedAthlete != null) {
      final activeId = _activeScannedAthlete!['id'];
      final updatedActive =
          _athletesList.where((a) => a['id'] == activeId).firstOrNull;
      if (updatedActive != null) {
        _activeScannedAthlete = updatedActive;
      }
    }
  }

  @override
  void dispose() {
    _qrScanController.dispose();
    _measuredWeightController.dispose();
    super.dispose();
  }

  void _emitAthletesUpdate(
    List<Map<String, dynamic>> updatedList, {
    required String actionType,
    required Map<String, dynamic> syncPayload,
    required String bannerMessage,
  }) {
    setState(() {
      _athletesList = updatedList;
    });
    if (widget.onUpdateAthletes != null) {
      widget.onUpdateAthletes!(updatedList);
    }
    if (widget.onCommitWeighInAction != null) {
      widget.onCommitWeighInAction!(
        updatedAthletes: updatedList,
        actionType: actionType,
        syncPayload: syncPayload,
        bannerMessage: bannerMessage,
      );
    }
  }

  void _selectAthleteForWeighIn(Map<String, dynamic> athlete) {
    final existingWeight = athlete['measuredWeightKg'];
    final weightLabel = resolveAthleteWeightLimitLabel(athlete);
    final ceiling = parseWeightClassCeilingKg(weightLabel);
    setState(() {
      _activeScannedAthlete = athlete;
      _qrScanController.text = resolveAthleteQr(athlete);
      if (existingWeight != null) {
        _measuredWeightController.text = existingWeight.toString();
      } else if (ceiling < 500) {
        _measuredWeightController.text = (ceiling - 1.2).toStringAsFixed(1);
      } else {
        _measuredWeightController.text = '98.5';
      }
    });
  }

  void _resolveQrScan(String rawInput, {bool showToast = true}) {
    FocusManager.instance.primaryFocus?.unfocus();
    final query = rawInput.trim().toLowerCase();
    if (query.isEmpty) return;

    Map<String, dynamic>? matched;
    for (final a in _athletesList) {
      final qr = resolveAthleteQr(a).toLowerCase();
      final id = (a['id'] ?? '').toString().toLowerCase();
      final name = (a['athleteName'] ?? '').toString().toLowerCase();
      if (qr == query ||
          id == query ||
          qr.contains(query) ||
          name.contains(query)) {
        matched = a;
        break;
      }
    }

    if (matched != null) {
      HapticFeedback.mediumImpact();
      _selectAthleteForWeighIn(matched);
      if (showToast && mounted) {
        CrystalToast.show(
          context,
          title: 'QR Verified on Scale',
          message:
              'Loaded ${matched['athleteName']} (${matched['categoryLabel']}) for scale verification.',
          type: CrystalToastType.success,
        );
      }
    } else if (showToast && mounted) {
      CrystalToast.show(
        context,
        title: 'Athlete Not Found',
        message: 'Select any athlete from the roster below to verify weight.',
        type: CrystalToastType.warning,
      );
    }
  }

  void _commitWeighInDecision({
    required Map<String, dynamic> athlete,
    required double measuredKg,
    required String targetStatus, // 'VERIFIED' or 'UNMATCHED'
    String? unmatchReason,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.heavyImpact();
    final id = athlete['id'];
    final weightLimitStr = resolveAthleteWeightLimitLabel(athlete);
    final updatedList = _athletesList.map((a) {
      if (a['id'] != id) return a;
      final copy = Map<String, dynamic>.from(a);
      copy['measuredWeightKg'] = measuredKg;
      copy['weighInStatus'] = targetStatus;
      copy['weighedInAt'] = DateTime.now().toIso8601String();
      if (targetStatus == 'UNMATCHED') {
        copy['unmatchReason'] = unmatchReason ??
            'Scale weight $measuredKg kg exceeds limit ($weightLimitStr)';
      } else {
        copy.remove('unmatchReason');
      }
      return copy;
    }).toList();

    final refreshed = updatedList.firstWhere(
      (a) => a['id'] == id,
      orElse: () => athlete,
    );
    setState(() {
      _activeScannedAthlete = refreshed;
    });

    _emitAthletesUpdate(
      updatedList,
      actionType: 'VERIFY_WEIGH_IN',
      syncPayload: {
        'eventId': widget.tournament['id'],
        'athleteId': id,
        'measuredWeightKg': measuredKg,
        'weighInStatus': targetStatus,
      },
      bannerMessage: targetStatus == 'VERIFIED'
          ? 'Weight Verified (${measuredKg.toStringAsFixed(1)} kg)'
          : 'Marked Unmatch (${measuredKg.toStringAsFixed(1)} kg)',
    );

    if (mounted) {
      CrystalToast.show(
        context,
        title: targetStatus == 'VERIFIED'
            ? 'Weight Verified ✓'
            : 'Marked Unmatch ⚠',
        message: targetStatus == 'VERIFIED'
            ? '${athlete['athleteName']} verified at ${measuredKg.toStringAsFixed(1)} kg.'
            : '${athlete['athleteName']} marked UNMATCH at ${measuredKg.toStringAsFixed(1)} kg.',
        type: targetStatus == 'VERIFIED'
            ? CrystalToastType.success
            : CrystalToastType.warning,
      );
    }
  }

  Map<String, String> _resolveRecommendedNextDivision(
      Map<String, dynamic> athlete) {
    final weightLimitStr = resolveAthleteWeightLimitLabel(athlete);
    final measured = (athlete['measuredWeightKg'] as num?)?.toDouble() ??
        (parseWeightClassCeilingKg(weightLimitStr) + 3.0);
    final currentArm =
        (athlete['registeredArm'] ?? athlete['arm'] ?? 'RIGHT').toString();
    final divisions = widget.separatedDivisions.isNotEmpty
        ? widget.separatedDivisions
        : <Map<String, String>>[
            {
              'weightLabel': '80 kg',
              'arm': currentArm,
              'label': '80 kg • $currentArm Arm',
            },
            {
              'weightLabel': '90 kg',
              'arm': currentArm,
              'label': '90 kg • $currentArm Arm',
            },
            {
              'weightLabel': 'Open',
              'arm': currentArm,
              'label': 'Open • $currentArm Arm',
            },
          ];

    for (final d in divisions) {
      final dLbl = (d['label'] ?? '').toString();
      final dWeight = d['weightLabel'] ?? dLbl.split('•').first.trim();
      final ceil = parseWeightClassCeilingKg(dWeight);
      if (ceil >= measured &&
          dLbl != (athlete['categoryLabel'] ?? '').toString()) {
        return {
          ...d,
          'weightLabel': dWeight,
        };
      }
    }
    for (final d in divisions) {
      final dLbl = (d['label'] ?? '').toString();
      final dWeight = d['weightLabel'] ?? dLbl.split('•').first.trim();
      if (dLbl != (athlete['categoryLabel'] ?? '').toString()) {
        return {
          ...d,
          'weightLabel': dWeight,
        };
      }
    }
    final first = divisions.first;
    final firstW =
        first['weightLabel'] ?? (first['label'] ?? '80 kg').split('•').first.trim();
    return {
      ...first,
      'weightLabel': firstW,
    };
  }

  void _quickMoveAndPairOneTap(
    Map<String, dynamic> athlete,
    Map<String, String> targetDiv,
  ) {
    HapticFeedback.heavyImpact();
    final newLbl = targetDiv['label'] ?? '80 kg • Right Arm';
    final newW = targetDiv['weightLabel'] ?? newLbl.split('•').first.trim();
    final newArm = targetDiv['arm'] ??
        (newLbl.toUpperCase().contains('LEFT') ? 'LEFT' : 'RIGHT');

    if (widget.onSwitchCategoryAndPairInMatchups != null) {
      widget.onSwitchCategoryAndPairInMatchups!(
        athlete: athlete,
        newWeightLabel: newW,
        newArm: newArm,
        newCategoryLabel: newLbl,
        autoPairInNewCategory: true,
      );
    } else {
      final id = athlete['id'];
      final next = _athletesList.map((a) {
        if (a['id'] != id) return a;
        return <String, dynamic>{
          ...a,
          'registeredWeightLabel': newW,
          'weightClass': newW,
          'registeredArm': newArm,
          'arm': newArm,
          'categoryLabel': newLbl,
          'weighInStatus': 'VERIFIED',
          'reassignedFromUnmatch': true,
        };
      }).toList();
      _emitAthletesUpdate(
        next,
        actionType: 'REASSIGN_UNMATCH_CATEGORY',
        syncPayload: {
          'eventId': widget.tournament['id'],
          'athleteId': id,
          'newCategoryLabel': newLbl,
        },
        bannerMessage: 'Moved to $newLbl & Verified',
      );
    }

    if (mounted) {
      CrystalToast.show(
        context,
        title: 'Moved to $newW & Paired ✓',
        message: '${athlete['athleteName']} moved to $newLbl & verified.',
        type: CrystalToastType.success,
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredWeighInRoster() {
    final q = _manualSearchQuery.trim().toLowerCase();
    return _athletesList.where((a) {
      final rawSt = (a['weighInStatus'] ?? 'PENDING').toString().toUpperCase();
      final st = rawSt == 'UNMATCH' ? 'UNMATCHED' : rawSt;
      if (_statusFilter != 'ALL' && st != _statusFilter) return false;
      if (q.isNotEmpty) {
        final name = (a['athleteName'] ?? '').toString().toLowerCase();
        final qr = resolveAthleteQr(a).toLowerCase();
        final cat = (a['categoryLabel'] ?? '').toString().toLowerCase();
        return name.contains(q) || qr.contains(q) || cat.contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final verifiedCount = _athletesList
        .where((a) => a['weighInStatus'] == 'VERIFIED')
        .length;
    final pendingCount = _athletesList
        .where((a) => (a['weighInStatus'] ?? 'PENDING') == 'PENDING')
        .length;
    final unmatchedCount = _athletesList
        .where((a) =>
            a['weighInStatus'] == 'UNMATCHED' ||
            a['weighInStatus'] == 'UNMATCH')
        .length;

    final active = _activeScannedAthlete;
    final double? activeMeasuredInput =
        double.tryParse(_measuredWeightController.text.trim());
    final String activeWeightLimitLabel = active != null
        ? resolveAthleteWeightLimitLabel(active)
        : '80 kg';
    final double activeCeiling = active != null
        ? parseWeightClassCeilingKg(activeWeightLimitLabel)
        : 999.0;
    final bool isOverweight = activeMeasuredInput != null &&
        activeCeiling < 500 &&
        activeMeasuredInput > activeCeiling;

    final roster = _getFilteredWeighInRoster();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space16,
          8,
          AppTheme.space16,
          120,
        ),
        children: [
          // 1. Top Ringside QR Scanner Console + Scale Verification Drawer
          Container(
            key: const ValueKey('card4_flow_a_qr_scan_panel'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF171D28), Color(0xFF0C0F16)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                width: 1.3,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Viewfinder Header + Full-Width QR Input + Full-Width Scan Button
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF090C11),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.goldPrimary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.goldPrimary,
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: AppTheme.goldPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'QR & SCALE VERIFICATION',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Scan athlete QR pass or select puller below',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_athletesList.isNotEmpty)
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                final idx = active == null
                                    ? 0
                                    : (_athletesList.indexWhere(
                                                (a) => a['id'] == active['id']) +
                                            1) %
                                        _athletesList.length;
                                final nextAth = _athletesList[idx];
                                _resolveQrScan(resolveAthleteQr(nextAth));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.cyan.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.cyan.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: const Text(
                                  'NEXT PULLER',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.cyan,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Full-width QR / Name input so text is never squished or cut off
                      TextField(
                        controller: _qrScanController,
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Athlete QR Code or Name',
                          hintText: 'Scan QR or type athlete name...',
                          prefixIcon: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 18,
                            color: AppTheme.goldPrimary,
                          ),
                          suffixIcon: _qrScanController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    setState(() => _qrScanController.clear());
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  },
                                  icon:
                                      const Icon(Icons.clear_rounded, size: 16),
                                )
                              : null,
                        ),
                        onSubmitted: (v) => _resolveQrScan(v),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        key: const ValueKey('card4_scan_qr_button'),
                        onTap: () => _resolveQrScan(_qrScanController.text),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2B2210), Color(0xFF141008)],
                            ),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: AppTheme.goldPrimary,
                              width: 1.3,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                size: 17,
                                color: AppTheme.goldPrimary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'SCAN ATHLETE QR PASS',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Active Scanned Athlete Scale Verification Drawer
                if (active != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111621),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isOverweight
                            ? AppTheme.crimson.withValues(alpha: 0.75)
                            : AppTheme.emerald.withValues(alpha: 0.55),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: HoldToInspectText(
                                title: 'Active Puller on Scale',
                                fullText:
                                    '${active['athleteName']}\nRegistered Division: ${active['categoryLabel']} ($activeWeightLimitLabel Limit)\nStatus: ${active['weighInStatus'] ?? 'PENDING'}',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (active['athleteName'] ?? 'Athlete')
                                          .toString(),
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Registered Division: ${compactDivisionTag((active['categoryLabel'] ?? '').toString())} ($activeWeightLimitLabel Limit)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.goldPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            StatusChip(
                              label: (active['weighInStatus'] ?? 'PENDING')
                                  .toString(),
                              color: active['weighInStatus'] == 'VERIFIED'
                                  ? AppTheme.emerald
                                  : (active['weighInStatus'] == 'UNMATCHED' ||
                                          active['weighInStatus'] == 'UNMATCH')
                                      ? AppTheme.crimson
                                      : AppTheme.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Full-width Scale Weight (kg) input so label and value are never squished
                        TextField(
                          key: const ValueKey('card4_measured_weight_input'),
                          controller: _measuredWeightController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Measured Scale Weight (kg)',
                            hintText: 'Enter weight in kg (e.g. 69.2)',
                            suffixText: 'kg',
                            prefixIcon: Icon(
                              Icons.monitor_weight_outlined,
                              size: 20,
                              color: isOverweight
                                  ? AppTheme.crimson
                                  : AppTheme.emerald,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Two spacious side-by-side action buttons below the weight input
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                key: const ValueKey('card4_verify_weight_button'),
                                onTap: () {
                                  final kg = double.tryParse(
                                        _measuredWeightController.text.trim(),
                                      ) ??
                                      (activeCeiling < 500
                                          ? activeCeiling - 0.5
                                          : 95.0);
                                  _commitWeighInDecision(
                                    athlete: active,
                                    measuredKg: kg,
                                    targetStatus: 'VERIFIED',
                                  );
                                },
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0E3325),
                                        Color(0xFF071B13),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: AppTheme.emerald,
                                      width: 1.3,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '✓ VERIFY WEIGHT',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: AppTheme.emerald,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                key: const ValueKey(
                                    'card4_flow_a_mark_unmatch_button'),
                                onTap: () {
                                  final kg = double.tryParse(
                                        _measuredWeightController.text.trim(),
                                      ) ??
                                      (activeCeiling < 500
                                          ? activeCeiling + 2.4
                                          : 105.0);
                                  _commitWeighInDecision(
                                    athlete: active,
                                    measuredKg: kg,
                                    targetStatus: 'UNMATCHED',
                                  );
                                },
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF381216),
                                        Color(0xFF1B080A),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: AppTheme.crimson,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '⚠ MARK UNMATCH',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: AppTheme.crimson,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (active['weighInStatus'] == 'UNMATCHED' ||
                            active['weighInStatus'] == 'UNMATCH') ...[
                          const SizedBox(height: 10),
                          Builder(
                            builder: (_) {
                              final nextDiv =
                                  _resolveRecommendedNextDivision(active);
                              final nextW = nextDiv['weightLabel'] ?? '80 kg';
                              return Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(9),
                                      onTap: () => _quickMoveAndPairOneTap(
                                          active, nextDiv),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 9,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.goldPrimary
                                              .withValues(alpha: 0.16),
                                          borderRadius:
                                              BorderRadius.circular(9),
                                          border: Border.all(
                                            color: AppTheme.goldPrimary,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '↗ Move to $nextW & Pair',
                                            style: const TextStyle(
                                              fontFamily: AppTheme.fontDisplay,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11.5,
                                              color: AppTheme.goldPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(9),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      CrystalToast.show(
                                        context,
                                        title: 'Kept Unmatched',
                                        message:
                                            '${active['athleteName']} remains in Unmatched status.',
                                        type: CrystalToastType.info,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.obsidian,
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(
                                          color: const Color(0x38FFFFFF),
                                        ),
                                      ),
                                      child: const Text(
                                        '✕ Keep Unmatched',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Searchable Athlete Weigh-In Roster + Status Filter Pills
          TextField(
            onChanged: (v) => setState(() => _manualSearchQuery = v),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search puller name, division, or QR...',
              prefixIcon: const Icon(
                Icons.person_search_rounded,
                size: 18,
                color: AppTheme.goldPrimary,
              ),
              suffixIcon: _manualSearchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() => _manualSearchQuery = '');
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      icon: const Icon(Icons.clear_rounded, size: 16),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final st in [
                  ('ALL', 'All (${_athletesList.length})'),
                  ('PENDING', 'Pending ($pendingCount)'),
                  ('VERIFIED', 'Verified ($verifiedCount)'),
                  ('UNMATCHED', 'Unmatch ($unmatchedCount)'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: _statusFilter == st.$1,
                      selectedColor:
                          AppTheme.goldPrimary.withValues(alpha: 0.22),
                      label: Text(
                        st.$2,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onSelected: (_) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() => _statusFilter = st.$1);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Roster Rows with One-Tap Verify / Unmatch & Instant 1-Tap Resolution Pills
          for (final athlete in roster)
            Builder(
              builder: (_) {
                final rawSt =
                    (athlete['weighInStatus'] ?? 'PENDING').toString();
                final isVerified = rawSt == 'VERIFIED';
                final isUnmatched =
                    rawSt == 'UNMATCHED' || rawSt == 'UNMATCH';
                final measured = athlete['measuredWeightKg'];
                final weightLimitStr = resolveAthleteWeightLimitLabel(athlete);
                final ceiling = parseWeightClassCeilingKg(weightLimitStr);
                final fullCat =
                    (athlete['categoryLabel'] ?? '').toString();
                final divCompact = compactDivisionTag(fullCat);
                final nextDiv = _resolveRecommendedNextDivision(athlete);
                final nextWeightLabel = nextDiv['weightLabel'] ?? '80 kg';
                final athleteName =
                    (athlete['athleteName'] ?? 'Athlete').toString();

                return HoldToInspectText(
                  title: athleteName,
                  fullText:
                      '$athleteName\nRegistered Division: $fullCat ($weightLimitStr Limit)\nScale Weight: ${measured != null ? "$measured kg" : "Awaiting Scale"}\nStatus: $rawSt',
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF161B26), Color(0xFF0E121A)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isVerified
                            ? AppTheme.emerald.withValues(alpha: 0.5)
                            : isUnmatched
                                ? AppTheme.crimson.withValues(alpha: 0.65)
                                : const Color(0x28FFFFFF),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectAthleteForWeighIn(athlete),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            athleteName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: AppTheme.fontDisplay,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13.5,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF222836),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            border: Border.all(
                                              color: AppTheme.goldPrimary
                                                  .withValues(alpha: 0.45),
                                            ),
                                          ),
                                          child: Text(
                                            divCompact,
                                            style: const TextStyle(
                                              fontFamily: AppTheme.fontDisplay,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.goldPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      measured != null
                                          ? 'Scale: $measured kg • $rawSt'
                                          : 'Registered: $weightLimitStr • Awaiting Scale',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isVerified
                                            ? AppTheme.emerald
                                            : isUnmatched
                                                ? AppTheme.crimson
                                                : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // [ ✓ Verify ] button
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                final targetKg =
                                    (measured as num?)?.toDouble() ??
                                        (ceiling < 500 ? ceiling - 1.0 : 96.0);
                                _commitWeighInDecision(
                                  athlete: athlete,
                                  measuredKg: targetKg,
                                  targetStatus: 'VERIFIED',
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isVerified
                                      ? AppTheme.emerald.withValues(alpha: 0.22)
                                      : AppTheme.obsidian,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.emerald.withValues(
                                      alpha: isVerified ? 0.9 : 0.5,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  isVerified ? '✓ VERIFIED' : '✓ Verify',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10.5,
                                    color: AppTheme.emerald,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // [ ⚠ Unmatch ] button
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                final overKg =
                                    ceiling < 500 ? ceiling + 2.5 : 108.0;
                                _commitWeighInDecision(
                                  athlete: athlete,
                                  measuredKg: overKg,
                                  targetStatus: 'UNMATCHED',
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isUnmatched
                                      ? AppTheme.crimson.withValues(alpha: 0.22)
                                      : AppTheme.obsidian,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.crimson.withValues(
                                      alpha: isUnmatched ? 0.9 : 0.45,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  '⚠ Unmatch',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10.5,
                                    color: AppTheme.crimson,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // One-Tap "Unmatch" Resolution Flow right on the card
                        if (isUnmatched) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F0C10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.crimson.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => _quickMoveAndPairOneTap(
                                        athlete, nextDiv),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF2B2210),
                                            Color(0xFF141008),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.goldPrimary,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '↗ Move to $nextWeightLabel & Pair',
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10.5,
                                            color: AppTheme.goldPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    CrystalToast.show(
                                      context,
                                      title: 'Kept Unmatched',
                                      message:
                                          '$athleteName remains in Unmatched status.',
                                      type: CrystalToastType.info,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.obsidian,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0x38FFFFFF),
                                      ),
                                    ),
                                    child: const Text(
                                      '✕ Keep Unmatched',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10.5,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. SPECTATOR & VENUE ENTRANCE QR GATE CONSOLE (SCROLLABLE, CLEAN LAYOUT)
// =============================================================================
class SpectatorEntranceQrGateView extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> appliedAthletes;
  final List<Map<String, dynamic>>? spectatorPasses;
  final String autoSaveBannerText;
  final void Function({
    required bool spectatorEnabled,
    required String spectatorMode,
    required int spectatorTicketPricePkr,
    required int athleteGuestPassAllowance,
  })? onUpdateSpectatorConfig;
  final ValueChanged<List<Map<String, dynamic>>>? onUpdateSpectatorPasses;
  final ValueChanged<List<Map<String, dynamic>>>? onUpdateAthletes;
  final Future<void> Function({
    required Map<String, dynamic> updatedSpectatorConfig,
    required List<Map<String, dynamic>> updatedAthletes,
    required String actionType,
    required Map<String, dynamic> syncPayload,
    required String bannerMessage,
  })? onCommitGateAction;
  final VoidCallback onBackToHub;

  const SpectatorEntranceQrGateView({
    super.key,
    required this.tournament,
    required this.appliedAthletes,
    this.spectatorPasses,
    required this.autoSaveBannerText,
    this.onUpdateSpectatorConfig,
    this.onUpdateSpectatorPasses,
    this.onUpdateAthletes,
    this.onCommitGateAction,
    required this.onBackToHub,
  });

  @override
  State<SpectatorEntranceQrGateView> createState() =>
      _SpectatorEntranceQrGateViewState();
}

class _SpectatorEntranceQrGateViewState
    extends State<SpectatorEntranceQrGateView> {
  late bool _spectatorEnabled;
  late String _spectatorMode; // 'FREE' or 'PAID'
  late final TextEditingController _ticketPricePkrController;
  late int _athleteGuestAllowance;
  late final TextEditingController _gateScanQrController;
  late List<Map<String, dynamic>> _passes;
  late List<Map<String, dynamic>> _athletes;

  Map<String, dynamic>? _lastVerifiedGateEntry;
  String? _gateScanStatus; // 'ALLOWED' or 'NOT_FOUND'

  @override
  void initState() {
    super.initState();
    final cfg = widget.tournament['spectatorGateConfig'] is Map
        ? Map<String, dynamic>.from(
            widget.tournament['spectatorGateConfig'] as Map)
        : <String, dynamic>{};
    _spectatorEnabled = widget.tournament['spectatorEnabled'] != false;
    _spectatorMode = (cfg['spectatorAccessMode'] ??
            widget.tournament['spectatorMode'] ??
            'FREE')
        .toString()
        .toUpperCase();
    final price = (cfg['spectatorFeePkr'] as num?)?.toInt() ??
        (widget.tournament['spectatorTicketPricePkr'] as num?)?.toInt() ??
        1000;
    _ticketPricePkrController = TextEditingController(text: price.toString());
    _athleteGuestAllowance =
        (cfg['allowedGuestsPerAthlete'] as num?)?.toInt() ??
            (widget.tournament['athleteGuestPassAllowance'] as num?)?.toInt() ??
            1;
    _gateScanQrController = TextEditingController();
    _athletes = widget.appliedAthletes
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final rawPasses = widget.spectatorPasses ??
        ((cfg['spectatorPasses'] is List)
            ? (cfg['spectatorPasses'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : <Map<String, dynamic>>[]);
    _passes = List<Map<String, dynamic>>.from(rawPasses);
  }

  @override
  void dispose() {
    _ticketPricePkrController.dispose();
    _gateScanQrController.dispose();
    super.dispose();
  }

  void _pushConfigUpdate({
    String actionType = 'UPDATE_SPECTATOR_GATE_CONFIG',
    String bannerMessage = 'Spectator Gate Policy Updated',
  }) {
    final price =
        int.tryParse(_ticketPricePkrController.text.trim()) ?? 1000;
    final fee = _spectatorMode == 'FREE' ? 0 : price;
    if (widget.onUpdateSpectatorConfig != null) {
      widget.onUpdateSpectatorConfig!(
        spectatorEnabled: _spectatorEnabled,
        spectatorMode: _spectatorMode,
        spectatorTicketPricePkr: fee,
        athleteGuestPassAllowance: _athleteGuestAllowance,
      );
    }
    if (widget.onCommitGateAction != null) {
      widget.onCommitGateAction!(
        updatedSpectatorConfig: {
          'spectatorEnabled': _spectatorEnabled,
          'spectatorAccessMode': _spectatorMode,
          'spectatorFeePkr': fee,
          'allowedGuestsPerAthlete': _athleteGuestAllowance,
          'spectatorPasses': _passes,
        },
        updatedAthletes: _athletes,
        actionType: actionType,
        syncPayload: {
          'eventId': widget.tournament['id'],
          'spectatorAccessMode': _spectatorMode,
          'spectatorFeePkr': fee,
          'allowedGuestsPerAthlete': _athleteGuestAllowance,
        },
        bannerMessage: bannerMessage,
      );
    }
  }

  void _verifyEntranceQr(String rawQr, {bool showToast = true}) {
    FocusManager.instance.primaryFocus?.unfocus();
    final q = rawQr.trim().toLowerCase();
    if (q.isEmpty) return;

    for (final pass in _passes) {
      final qr = (pass['qrCode'] ?? '').toString().toLowerCase();
      final name = (pass['holderName'] ?? '').toString().toLowerCase();
      if (qr == q || qr.contains(q) || name.contains(q)) {
        HapticFeedback.heavyImpact();
        final updatedPasses = _passes.map((p) {
          if (p['id'] != pass['id']) return p;
          return <String, dynamic>{
            ...p,
            'checkedInAtGate': true,
            'checkedInAt': DateTime.now().toIso8601String(),
          };
        }).toList();
        setState(() {
          _passes = updatedPasses;
          _gateScanStatus = 'ALLOWED';
          _lastVerifiedGateEntry = {
            'holderName': pass['holderName'],
            'roleBadge': pass['passType'] ?? 'SPECTATOR PASS',
            'qrCode': pass['qrCode'],
            'guestsIncluded': pass['guestsIncluded'] ?? 0,
            'feeStatus': _spectatorMode == 'FREE'
                ? 'FREE PASS'
                : 'PAID PKR ${pass['pricePaidPkr'] ?? _ticketPricePkrController.text}',
          };
        });
        if (widget.onUpdateSpectatorPasses != null) {
          widget.onUpdateSpectatorPasses!(updatedPasses);
        }
        _pushConfigUpdate(
          actionType: 'CHECK_IN_SPECTATOR_QR',
          bannerMessage: 'Spectator Pass Admitted at Gate',
        );
        if (showToast && mounted) {
          CrystalToast.show(
            context,
            title: 'VERIFIED — ALLOWED TO ENTER ✓',
            message: '${pass['holderName']} verified at Venue Gate.',
            type: CrystalToastType.success,
          );
        }
        return;
      }
    }

    for (final ath in _athletes) {
      final qr = resolveAthleteQr(ath).toLowerCase();
      final name = (ath['athleteName'] ?? '').toString().toLowerCase();
      if (qr == q || qr.contains(q) || name.contains(q)) {
        HapticFeedback.heavyImpact();
        final updatedAthletes = _athletes.map((a) {
          if (a['id'] != ath['id']) return a;
          return <String, dynamic>{
            ...a,
            'checkedInAtGate': true,
            'entranceCheckedIn': true,
            'gateCheckedInAt': DateTime.now().toIso8601String(),
          };
        }).toList();
        setState(() {
          _athletes = updatedAthletes;
          _gateScanStatus = 'ALLOWED';
          _lastVerifiedGateEntry = {
            'holderName': ath['athleteName'],
            'roleBadge': 'COMPETING ATHLETE (${ath['categoryLabel']})',
            'qrCode': resolveAthleteQr(ath),
            'guestsIncluded': _athleteGuestAllowance,
            'feeStatus':
                'REGISTERED ATHLETE + $_athleteGuestAllowance GUEST(S)',
          };
        });
        if (widget.onUpdateAthletes != null) {
          widget.onUpdateAthletes!(updatedAthletes);
        }
        _pushConfigUpdate(
          actionType: 'CHECK_IN_ATHLETE_GATE_QR',
          bannerMessage: 'Athlete Admitted at Gate',
        );
        if (showToast && mounted) {
          CrystalToast.show(
            context,
            title: 'VERIFIED — ALLOWED TO ENTER ✓',
            message:
                'Athlete ${ath['athleteName']} (+$_athleteGuestAllowance guest allowance) checked in.',
            type: CrystalToastType.success,
          );
        }
        return;
      }
    }

    setState(() {
      _gateScanStatus = 'NOT_FOUND';
      _lastVerifiedGateEntry = null;
    });
  }

  void _issueInstantSpectatorQrPass() {
    FocusManager.instance.primaryFocus?.unfocus();
    final idx = _passes.length + 1;
    final tId = (widget.tournament['id'] ?? 'TRN').toString();
    final price = _spectatorMode == 'FREE'
        ? 0
        : (int.tryParse(_ticketPricePkrController.text.trim()) ?? 1000);
    final newPass = <String, dynamic>{
      'id': 'spec-pass-${DateTime.now().millisecondsSinceEpoch}',
      'holderName': 'Arena Spectator #$idx',
      'passType': _spectatorMode == 'FREE'
          ? 'FREE SPECTATOR QR PASS'
          : 'PAID SPECTATOR TICKET',
      'pricePaidPkr': price,
      'guestsIncluded': 0,
      'qrCode': 'ARMSPHERE-$tId-SPEC-${idx.toString().padLeft(3, '0')}',
      'checkedInAtGate': false,
      'issuedAt': DateTime.now().toIso8601String(),
    };
    final next = [newPass, ..._passes];
    setState(() {
      _passes = next;
    });
    if (widget.onUpdateSpectatorPasses != null) {
      widget.onUpdateSpectatorPasses!(next);
    }
    _gateScanQrController.text = newPass['qrCode'] as String;
    _verifyEntranceQr(newPass['qrCode'] as String);
  }

  @override
  Widget build(BuildContext context) {
    final checkedInAthletes = _athletes
        .where((a) =>
            a['checkedInAtGate'] == true || a['entranceCheckedIn'] == true)
        .length;
    final checkedInSpectators =
        _passes.where((p) => p['checkedInAtGate'] == true).length;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space16,
          8,
          AppTheme.space16,
          120,
        ),
        children: [
          // 1. Top Ringside QR Scanner Console (Venue Gate)
          Container(
            key: const ValueKey('venue_entrance_qr_scanner_card'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF161C27), Color(0xFF0C0F16)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.emerald.withValues(alpha: 0.5),
                width: 1.3,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.emerald, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppTheme.emerald,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ARENA GATE QR VERIFICATION',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                              color: AppTheme.emerald,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$checkedInAthletes Athletes Checked In • $checkedInSpectators Spectators Entered',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _issueInstantSpectatorQrPass,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2B2210), Color(0xFF141008)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.goldPrimary,
                            width: 1.1,
                          ),
                        ),
                        child: const Text(
                          '+ ISSUE PASS',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('venue_entrance_qr_input'),
                  controller: _gateScanQrController,
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Spectator or Athlete QR Pass',
                    hintText: 'Scan QR Pass or type Holder Name...',
                    prefixIcon: const Icon(
                      Icons.qr_code_2_rounded,
                      size: 18,
                      color: AppTheme.emerald,
                    ),
                    suffixIcon: _gateScanQrController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState(() => _gateScanQrController.clear());
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            icon: const Icon(Icons.clear_rounded, size: 16),
                          )
                        : null,
                  ),
                  onSubmitted: (v) => _verifyEntranceQr(v),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  key: const ValueKey('venue_entrance_scan_submit_button'),
                  onTap: () => _verifyEntranceQr(_gateScanQrController.text),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0E3325), Color(0xFF071B13)],
                      ),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: AppTheme.emerald, width: 1.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: AppTheme.emerald,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'SCAN QR PASS',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: AppTheme.emerald,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_gateScanStatus == 'ALLOWED' &&
                    _lastVerifiedGateEntry != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    key: const ValueKey(
                        'venue_entrance_verified_allowed_banner'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.emerald, width: 1.3),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: AppTheme.emerald,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'VERIFIED — ALLOWED TO ENTER ✓',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: AppTheme.emerald,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_lastVerifiedGateEntry!['holderName']} • ${_lastVerifiedGateEntry!['roleBadge']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${_lastVerifiedGateEntry!['feeStatus']} • QR: ${_lastVerifiedGateEntry!['qrCode']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Compact Spectator Policy & Guest Allowance Controls
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF131722),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x28FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'SPECTATOR & ATHLETE GUEST PASS POLICY',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                          color: AppTheme.goldPrimary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _spectatorEnabled,
                      activeColor: AppTheme.emerald,
                      onChanged: (v) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() => _spectatorEnabled = v);
                        _pushConfigUpdate();
                      },
                    ),
                  ],
                ),
                if (_spectatorEnabled) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          key: const ValueKey('spectator_mode_free_chip'),
                          selected: _spectatorMode == 'FREE',
                          selectedColor:
                              AppTheme.emerald.withValues(alpha: 0.22),
                          label: const Text(
                            'Free Spectating',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onSelected: (_) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() => _spectatorMode = 'FREE');
                            _pushConfigUpdate();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          key: const ValueKey('spectator_mode_paid_chip'),
                          selected: _spectatorMode == 'PAID',
                          selectedColor:
                              AppTheme.goldPrimary.withValues(alpha: 0.22),
                          label: const Text(
                            'Paid Ticket (PKR)',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onSelected: (_) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() => _spectatorMode = 'PAID');
                            _pushConfigUpdate();
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_spectatorMode == 'PAID') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _ticketPricePkrController,
                      keyboardType: TextInputType.number,
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      onChanged: (_) => _pushConfigUpdate(),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Spectator Pass Price (PKR)',
                        prefixText: 'PKR ',
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Guests per Competing Athlete:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      for (final count in [0, 1, 2, 3])
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            key: ValueKey('athlete_guest_allowance_$count'),
                            selected: _athleteGuestAllowance == count,
                            selectedColor:
                                AppTheme.goldPrimary.withValues(alpha: 0.25),
                            label: Text(
                              '$count',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                            onSelected: (_) {
                              FocusManager.instance.primaryFocus?.unfocus();
                              setState(() => _athleteGuestAllowance = count);
                              _pushConfigUpdate();
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Quick-Tap Gate Pass Roster
          for (final pass in _passes)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF141822),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: pass['checkedInAtGate'] == true
                      ? AppTheme.emerald.withValues(alpha: 0.5)
                      : const Color(0x26FFFFFF),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (pass['holderName'] ?? 'Spectator').toString(),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${pass['passType']} • ${pass['qrCode']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () =>
                        _verifyEntranceQr((pass['qrCode'] ?? '').toString()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: pass['checkedInAtGate'] == true
                            ? AppTheme.emerald.withValues(alpha: 0.18)
                            : AppTheme.obsidian,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.emerald),
                      ),
                      child: Text(
                        pass['checkedInAtGate'] == true
                            ? 'ENTERED ✓'
                            : 'SCAN IN',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                          color: AppTheme.emerald,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
