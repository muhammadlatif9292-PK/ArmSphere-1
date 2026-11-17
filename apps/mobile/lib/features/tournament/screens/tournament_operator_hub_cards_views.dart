import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';

// =============================================================================
// SHARED HELPERS FOR APPLIED ATHLETES, WEIGH-IN & VENUE ENTRANCE GATE
// =============================================================================

double parseWeightClassCeilingKg(String? label) {
  if (label == null || label.trim().isEmpty) return 999.0;
  final upper = label.toUpperCase();
  if (upper.contains('OPEN') || upper.contains('+') || upper.contains('UNLIMITED')) {
    return 999.0;
  }
  final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(upper);
  if (match != null) {
    return double.tryParse(match.group(1)!) ?? 999.0;
  }
  return 999.0;
}

String eloTierBadgeForRating(int elo) {
  if (elo >= 1800) return 'GRANDMASTER';
  if (elo >= 1650) return 'MASTER';
  if (elo >= 1500) return 'ELITE CONTENDER';
  return 'PROSPECT';
}

String compactDivisionTag(String rawLabel) {
  final trimmed = rawLabel.trim();
  if (trimmed.isEmpty || trimmed.toUpperCase() == 'ALL' || trimmed == 'All Categories') {
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
// 1. CARD 2 — APPLIED / REGISTERED ATHLETES SCREEN (SEEDED CAROUSEL & ROSTER)
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
        'count': widget.appliedAthletes.length.toString(),
      },
      for (final lbl in orderedLabels)
        {
          'key': lbl,
          'label': compactDivisionTag(lbl),
          'fullLabel': lbl,
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
        final qr = (a['qrCode'] ?? '').toString().toLowerCase();
        final club = (a['club'] ?? '').toString().toLowerCase();
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
      final eloA = (a['elo'] as num?)?.toInt() ?? 1200;
      final eloB = (b['elo'] as num?)?.toInt() ?? 1200;
      return eloB.compareTo(eloA);
    });
    return base;
  }

  Future<void> _openRegisterWalkInAthleteModal() async {
    final nameCtrl = TextEditingController();
    final clubCtrl = TextEditingController(text: 'ArmSphere Pro Club');
    final eloCtrl = TextEditingController(text: '1620');
    final prCtrl = TextEditingController(text: '58 kg Pronation • 64 kg Cup');
    final maxLiftCtrl = TextEditingController(text: '64');
    final divisions = widget.separatedDivisions.isNotEmpty
        ? widget.separatedDivisions
        : [
            {
              'weightLabel': '80 kg',
              'arm': 'RIGHT',
              'label': '80 kg • RIGHT Arm',
            }
          ];
    Map<String, String> selectedDiv = divisions.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
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
                            color: AppTheme.goldPrimary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.goldPrimary.withValues(alpha: 0.45),
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
                            'REGISTER ATHLETE ENTRY',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const StatusChip(
                          label: 'OFFLINE-READY',
                          color: AppTheme.emerald,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Athlete Full Name',
                        hintText: 'e.g. Tariq Mehmood',
                        prefixIcon: Icon(Icons.badge_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDiv['label'],
                      dropdownColor: AppTheme.elevatedSurface,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Weight & Arm Division',
                        prefixIcon: Icon(Icons.fitness_center_rounded, size: 18),
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: eloCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'ELO Rating',
                              prefixIcon: Icon(Icons.leaderboard_rounded, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: clubCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Club / City',
                              prefixIcon: Icon(Icons.shield_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: prCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Verified PR Summary',
                              prefixIcon: Icon(Icons.bolt_rounded, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: maxLiftCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Max Lift (kg)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                        final idx = widget.appliedAthletes.length + 1;
                        final tId = (widget.tournament['id'] ?? 'TRN').toString();
                        final newAthlete = <String, dynamic>{
                          'id': 'ath-walkin-${DateTime.now().millisecondsSinceEpoch}',
                          'athleteName': name,
                          'club': clubCtrl.text.trim().isEmpty
                              ? 'Independent'
                              : clubCtrl.text.trim(),
                          'elo': elo,
                          'prSummary': prSummary,
                          'maxLiftKg': maxLiftKg,
                          'registeredWeightLabel':
                              selectedDiv['weightLabel'] ?? '80 kg',
                          'registeredArm': selectedDiv['arm'] ?? 'RIGHT',
                          'categoryLabel':
                              selectedDiv['label'] ?? '80 kg • RIGHT Arm',
                          'qrCode':
                              'ARMSPHERE-$tId-ATH-${idx.toString().padLeft(3, '0')}',
                          'appliedAt': DateTime.now().toIso8601String(),
                          'weighInStatus': 'PENDING',
                          'measuredWeightKg': null,
                          'guestPassesAllowed':
                              (widget.tournament['athleteGuestPassAllowance']
                                          as num?)
                                      ?.toInt() ??
                                  1,
                          'checkedInAtGate': false,
                        };
                        final next = [
                          newAthlete,
                          ...widget.appliedAthletes,
                        ];
                        widget.onUpdateAthletes(next);
                        Navigator.of(sheetCtx).pop();
                        CrystalToast.show(
                          context,
                          title: 'Athlete Added (Offline-Safe)',
                          message:
                              '$name added to ${selectedDiv['label']} with QR ${newAthlete['qrCode']}.',
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chips = _buildCategoryChipsData();
    final eloRanked = _getEloRankedAthletes();
    final filteredAthletes = _getFilteredAthletes();

    // Map athleteId -> overall seed # within the current selection
    final seedIndexById = <String, int>{};
    for (int i = 0; i < eloRanked.length; i++) {
      final id = (eloRanked[i]['id'] ?? '').toString();
      if (id.isNotEmpty) {
        seedIndexById[id] = i + 1;
      }
    }

    final verifiedCount = widget.appliedAthletes
        .where((a) => a['weighInStatus'] == 'VERIFIED')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Sleek Forged-Crystal Stage Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF171C26), Color(0xFF0C0F16)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.goldPrimary.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: widget.onBackToHub,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidian,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 12,
                        color: AppTheme.goldPrimary,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'HUB',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REGISTERED ATHLETES & ELO SEEDING',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.appliedAthletes.length} Registered • $verifiedCount Verified • ${widget.autoSaveBannerText}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.emerald,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openRegisterWalkInAthleteModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A2111), Color(0xFF141008)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.goldPrimary, width: 1.1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded,
                          size: 14, color: AppTheme.goldPrimary),
                      SizedBox(width: 5),
                      Text(
                        '+ ATHLETE',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Division Filter Bar (Horizontally Scrollable Forged-Crystal Chips with Live Counts)
        SingleChildScrollView(
          key: const ValueKey('card2_category_filter_bar'),
          scrollDirection: Axis.horizontal,
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
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(11),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCategoryFilter = chip['key'] ?? 'ALL';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${chip['label']} (${chip['count']})',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
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

        // 3. Top Seeded ELO Horizontal Carousel (height: 118px)
        Container(
          key: const ValueKey('card2_elo_ranking_carousel'),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF11151E),
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
                    itemCount: eloRanked.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final athlete = eloRanked[index];
                      final rank = index + 1;
                      final elo = (athlete['elo'] as num?)?.toInt() ?? 1500;
                      final Color seedColor = rank == 1
                          ? const Color(0xFFD4AF37) // #1 SEED 24k Gold
                          : rank == 2
                              ? const Color(0xFFE2E8F0) // #2 SEED Silver
                              : rank == 3
                                  ? const Color(0xFFCD7F32) // #3 SEED Bronze
                                  : const Color(0xFF94A3B8); // #4+ Titanium

                      final divCompact = compactDivisionTag(
                        (athlete['categoryLabel'] ?? '').toString(),
                      );

                      return Container(
                        width: 196,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: rank == 1
                                ? const [Color(0xFF282010), Color(0xFF110E08)]
                                : const [Color(0xFF171C27), Color(0xFF0D1017)],
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: seedColor.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: seedColor.withValues(alpha: 0.65),
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
                              (athlete['athleteName'] ?? 'Athlete').toString(),
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
                                    (athlete['club'] ?? '').toString(),
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
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4. Compact Roster Search Bar
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search athlete name, club, division, or QR pass...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppTheme.goldPrimary,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () => setState(() => _searchQuery = ''),
                    icon: const Icon(Icons.clear_rounded, size: 16),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),

        // 5. Clean Division Roster List (ForgedCrystalRow Bars)
        if (filteredAthletes.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF121620),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x26FFFFFF)),
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
                final elo = (athlete['elo'] as num?)?.toInt() ?? 1500;
                final maxLift =
                    (athlete['maxLiftKg'] as num?)?.toDouble() ?? 60.0;
                final weighStatus =
                    (athlete['weighInStatus'] ?? 'PENDING').toString();
                final isVerified = weighStatus == 'VERIFIED';
                final isUnmatched = weighStatus == 'UNMATCHED';
                final qrCode = (athlete['qrCode'] ?? '').toString();
                final divTag = compactDivisionTag(
                  (athlete['categoryLabel'] ?? '').toString(),
                );

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

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF161B26), Color(0xFF0E121A)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isVerified
                          ? AppTheme.emerald.withValues(alpha: 0.45)
                          : isUnmatched
                              ? AppTheme.crimson.withValues(alpha: 0.55)
                              : const Color(0x28FFFFFF),
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
                                ? AppTheme.goldPrimary.withValues(alpha: 0.65)
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
                                    (athlete['athleteName'] ?? 'Athlete')
                                        .toString(),
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
                                  (athlete['club'] ?? 'Club').toString(),
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
                        onTap: () => widget.onOpenWeighInForAthlete(qrCode),
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
                );
              },
            ),
          ],
      ],
    );
  }
}

// =============================================================================
// 2. CARD 4 — WEIGH-IN SCALE CONSOLE (QR SCANNER HERO + 1-TAP UNMATCH FLOW)
// =============================================================================
class Card4WeighInVerificationView extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, String>> separatedDivisions;
  final List<Map<String, dynamic>> appliedAthletes;
  final String autoSaveBannerText;
  final String? initialScannedQrCode;
  final String? initialSelectedAthleteId;
  final ValueChanged<List<Map<String, dynamic>>> onUpdateAthletes;
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
    required this.onUpdateAthletes,
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
  String _manualSearchQuery = '';
  String _statusFilter = 'ALL'; // ALL, PENDING, VERIFIED, UNMATCHED
  Map<String, dynamic>? _activeScannedAthlete;

  @override
  void initState() {
    super.initState();
    _qrScanController =
        TextEditingController(text: widget.initialScannedQrCode ?? '');
    _measuredWeightController = TextEditingController();

    if (widget.initialScannedQrCode != null &&
        widget.initialScannedQrCode!.trim().isNotEmpty) {
      _resolveQrScan(widget.initialScannedQrCode!.trim(), showToast: false);
    } else if (widget.initialSelectedAthleteId != null &&
        widget.initialSelectedAthleteId!.trim().isNotEmpty) {
      final found = widget.appliedAthletes.where((a) =>
          a['id']?.toString() == widget.initialSelectedAthleteId ||
          a['athleteId']?.toString() == widget.initialSelectedAthleteId).firstOrNull;
      if (found != null) {
        _selectAthleteForWeighIn(found);
      } else if (widget.appliedAthletes.isNotEmpty) {
        _selectAthleteForWeighIn(widget.appliedAthletes.first);
      }
    } else if (widget.appliedAthletes.isNotEmpty) {
      _selectAthleteForWeighIn(widget.appliedAthletes.first);
    }
  }

  @override
  void dispose() {
    _qrScanController.dispose();
    _measuredWeightController.dispose();
    super.dispose();
  }

  void _selectAthleteForWeighIn(Map<String, dynamic> athlete) {
    final existingWeight = athlete['measuredWeightKg'];
    final ceiling = parseWeightClassCeilingKg(
      (athlete['registeredWeightLabel'] ?? '').toString(),
    );
    setState(() {
      _activeScannedAthlete = athlete;
      _qrScanController.text = (athlete['qrCode'] ?? '').toString();
      if (existingWeight != null) {
        _measuredWeightController.text = existingWeight.toString();
      } else if (ceiling < 500) {
        _measuredWeightController.text =
            (ceiling - 1.2).toStringAsFixed(1);
      } else {
        _measuredWeightController.text = '98.5';
      }
    });
  }

  void _resolveQrScan(String rawInput, {bool showToast = true}) {
    final query = rawInput.trim().toLowerCase();
    if (query.isEmpty) return;

    Map<String, dynamic>? matched;
    for (final a in widget.appliedAthletes) {
      final qr = (a['qrCode'] ?? '').toString().toLowerCase();
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
        title: 'QR Code Not Found Locally',
        message: 'Select any athlete from the roster below to verify scale weight.',
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
    HapticFeedback.heavyImpact();
    final id = athlete['id'];
    final updatedList = widget.appliedAthletes.map((a) {
      if (a['id'] != id) return a;
      final copy = Map<String, dynamic>.from(a);
      copy['measuredWeightKg'] = measuredKg;
      copy['weighInStatus'] = targetStatus;
      copy['weighedInAt'] = DateTime.now().toIso8601String();
      if (targetStatus == 'UNMATCHED') {
        copy['unmatchReason'] = unmatchReason ??
            'Scale weight $measuredKg kg exceeds registered limit (${a['registeredWeightLabel']})';
      } else {
        copy.remove('unmatchReason');
      }
      return copy;
    }).toList();

    widget.onUpdateAthletes(updatedList);

    final refreshed = updatedList.firstWhere(
      (a) => a['id'] == id,
      orElse: () => athlete,
    );
    setState(() {
      _activeScannedAthlete = refreshed;
    });

    if (mounted) {
      CrystalToast.show(
        context,
        title: targetStatus == 'VERIFIED'
            ? 'Weight Verified ✓'
            : 'Marked Unmatch ⚠',
        message: targetStatus == 'VERIFIED'
            ? '${athlete['athleteName']} verified at ${measuredKg.toStringAsFixed(1)} kg.'
            : '${athlete['athleteName']} marked UNMATCH at ${measuredKg.toStringAsFixed(1)} kg. Tap 1-tap resolution pill below.',
        type: targetStatus == 'VERIFIED'
            ? CrystalToastType.success
            : CrystalToastType.warning,
      );
    }
  }

  Map<String, String> _resolveRecommendedNextDivision(
      Map<String, dynamic> athlete) {
    final measured = (athlete['measuredWeightKg'] as num?)?.toDouble() ??
        (parseWeightClassCeilingKg(
                (athlete['registeredWeightLabel'] ?? '').toString()) +
            3.0);
    final currentArm = (athlete['registeredArm'] ?? 'RIGHT').toString();
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
              'weightLabel': '+95 kg Open',
              'arm': currentArm,
              'label': '+95 kg Open • $currentArm Arm',
            },
          ];

    // Pick the first division with the same arm whose ceiling >= measured
    for (final d in divisions) {
      if ((d['arm'] ?? 'RIGHT') == currentArm) {
        final ceil = parseWeightClassCeilingKg(d['weightLabel']);
        if (ceil >= measured &&
            d['label'] != (athlete['categoryLabel'] ?? '').toString()) {
          return d;
        }
      }
    }
    // Otherwise pick any different division
    for (final d in divisions) {
      if (d['label'] != (athlete['categoryLabel'] ?? '').toString()) {
        return d;
      }
    }
    return divisions.first;
  }

  void _quickMoveAndPairOneTap(
    Map<String, dynamic> athlete,
    Map<String, String> targetDiv,
  ) {
    HapticFeedback.heavyImpact();
    final newW = targetDiv['weightLabel'] ?? '80 kg';
    final newArm = targetDiv['arm'] ?? 'RIGHT';
    final newLbl = targetDiv['label'] ?? '$newW • $newArm Arm';

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
      final next = widget.appliedAthletes.map((a) {
        if (a['id'] != id) return a;
        return <String, dynamic>{
          ...a,
          'registeredWeightLabel': newW,
          'registeredArm': newArm,
          'categoryLabel': newLbl,
          'weighInStatus': 'VERIFIED',
          'reassignedFromUnmatch': true,
        };
      }).toList();
      widget.onUpdateAthletes(next);
    }

    if (mounted) {
      CrystalToast.show(
        context,
        title: 'Moved to $newW & Paired ✓',
        message:
            '${athlete['athleteName']} moved to $newLbl, verified & paired in Card 3.',
        type: CrystalToastType.success,
      );
    }
  }

  Future<void> _openUnmatchCategorySwitchModal(
    Map<String, dynamic> athlete,
  ) async {
    final divisions = widget.separatedDivisions.isNotEmpty
        ? widget.separatedDivisions
        : <Map<String, String>>[
            {
              'weightLabel': '80 kg',
              'arm': 'RIGHT',
              'label': '80 kg • RIGHT Arm',
            },
            {
              'weightLabel': '90 kg',
              'arm': 'RIGHT',
              'label': '90 kg • RIGHT Arm',
            },
            {
              'weightLabel': '+95 kg Open',
              'arm': 'RIGHT',
              'label': '+95 kg Open • RIGHT Arm',
            },
          ];

    Map<String, String> selectedDiv = _resolveRecommendedNextDivision(athlete);
    bool autoPairInCard3 = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.viewInsetsOf(ctx).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.swap_horiz_rounded,
                        color: AppTheme.goldPrimary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'MOVE ${athlete['athleteName']} TO NEW DIVISION',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDiv['label'],
                    dropdownColor: AppTheme.elevatedSurface,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Target Weight & Arm Division',
                      prefixIcon: Icon(Icons.fitness_center_rounded, size: 18),
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
                      final found = divisions.firstWhere(
                        (d) => d['label'] == v,
                        orElse: () => divisions.first,
                      );
                      setModalState(() => selectedDiv = found);
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.emerald,
                    value: autoPairInCard3,
                    title: const Text(
                      'Auto-Pair in Card 3 Matchups',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    onChanged: (v) => setModalState(() => autoPairInCard3 = v),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      final newW = selectedDiv['weightLabel'] ?? '90 kg';
                      final newArm = selectedDiv['arm'] ?? 'RIGHT';
                      final newLbl =
                          selectedDiv['label'] ?? '$newW • $newArm Arm';
                      if (widget.onSwitchCategoryAndPairInMatchups != null) {
                        widget.onSwitchCategoryAndPairInMatchups!(
                          athlete: athlete,
                          newWeightLabel: newW,
                          newArm: newArm,
                          newCategoryLabel: newLbl,
                          autoPairInNewCategory: autoPairInCard3,
                        );
                      }
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0E2F23), Color(0xFF071A13)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.emerald, width: 1.3),
                      ),
                      child: const Center(
                        child: Text(
                          'CONFIRM DIVISION MOVE & PAIR',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: AppTheme.emerald,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredWeighInRoster() {
    final q = _manualSearchQuery.trim().toLowerCase();
    return widget.appliedAthletes.where((a) {
      final st = (a['weighInStatus'] ?? 'PENDING').toString();
      if (_statusFilter != 'ALL' && st != _statusFilter) return false;
      if (q.isNotEmpty) {
        final name = (a['athleteName'] ?? '').toString().toLowerCase();
        final qr = (a['qrCode'] ?? '').toString().toLowerCase();
        final cat = (a['categoryLabel'] ?? '').toString().toLowerCase();
        return name.contains(q) || qr.contains(q) || cat.contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final verifiedCount = widget.appliedAthletes
        .where((a) => a['weighInStatus'] == 'VERIFIED')
        .length;
    final pendingCount = widget.appliedAthletes
        .where((a) => (a['weighInStatus'] ?? 'PENDING') == 'PENDING')
        .length;
    final unmatchedCount = widget.appliedAthletes
        .where((a) => a['weighInStatus'] == 'UNMATCHED')
        .length;

    final active = _activeScannedAthlete;
    final double? activeMeasuredInput =
        double.tryParse(_measuredWeightController.text.trim());
    final double activeCeiling = active != null
        ? parseWeightClassCeilingKg(
            (active['registeredWeightLabel'] ?? '').toString(),
          )
        : 999.0;
    final bool isOverweight = activeMeasuredInput != null &&
        activeCeiling < 500 &&
        activeMeasuredInput > activeCeiling;

    final roster = _getFilteredWeighInRoster();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Compact Scale Console Stage Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF171C26), Color(0xFF0C0F16)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.goldPrimary.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: widget.onBackToHub,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidian,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 12,
                        color: AppTheme.goldPrimary,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'HUB',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WEIGH-IN SCALE CONSOLE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$verifiedCount Verified ✓ • $pendingCount Pending • $unmatchedCount Unmatch ⚠',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emerald,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusChip(
                label: 'OFFLINE SCALE',
                color: AppTheme.emerald,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Top Ringside QR Scanner Hero Console + Scale Verification Drawer
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
              // Glowing Viewfinder Frame + Large Thumb-Friendly Scan Button
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
                            color: AppTheme.goldPrimary.withValues(alpha: 0.14),
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
                                'RINGSIDE QR SCANNER CONSOLE',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: AppTheme.goldPrimary,
                                  letterSpacing: 0.6,
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
                        // Quick-Sim Button for testing scans
                        if (widget.appliedAthletes.isNotEmpty)
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              final idx = active == null
                                  ? 0
                                  : (widget.appliedAthletes.indexWhere(
                                              (a) => a['id'] == active['id']) +
                                          1) %
                                      widget.appliedAthletes.length;
                              final nextAth = widget.appliedAthletes[idx];
                              _resolveQrScan(
                                  (nextAth['qrCode'] ?? '').toString());
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
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
                                '⚡ QUICK-SIM SCAN',
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _qrScanController,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'ARMSPHERE-...-ATH-001 or Athlete Name',
                              prefixIcon: Icon(
                                Icons.qr_code_2_rounded,
                                size: 18,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                            onSubmitted: (v) => _resolveQrScan(v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          key: const ValueKey('card4_scan_qr_button'),
                          onTap: () => _resolveQrScan(_qrScanController.text),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: AppTheme.goldPrimary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '📷 SCAN ATHLETE QR PASS',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10.5,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Active Scanned Athlete Scale Verification Drawer
              if (active != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(13),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (active['athleteName'] ?? 'Athlete')
                                      .toString(),
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Registered Division: ${compactDivisionTag((active['categoryLabel'] ?? '').toString())} (${active['registeredWeightLabel']} Limit)',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.goldPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(
                            label:
                                (active['weighInStatus'] ?? 'PENDING').toString(),
                            color: active['weighInStatus'] == 'VERIFIED'
                                ? AppTheme.emerald
                                : active['weighInStatus'] == 'UNMATCHED'
                                    ? AppTheme.crimson
                                    : AppTheme.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: TextField(
                              key: const ValueKey('card4_measured_weight_input'),
                              controller: _measuredWeightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: 'Scale Weight (kg)',
                                suffixText: 'kg',
                                prefixIcon: Icon(
                                  Icons.monitor_weight_outlined,
                                  size: 18,
                                  color: isOverweight
                                      ? AppTheme.crimson
                                      : AppTheme.emerald,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
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
                                      fontSize: 11.5,
                                      color: AppTheme.emerald,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
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
                                    '⚠ UNMATCH',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      color: AppTheme.crimson,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (active['weighInStatus'] == 'UNMATCHED') ...[
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
                                    onTap: () =>
                                        _quickMoveAndPairOneTap(active, nextDiv),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.goldPrimary
                                            .withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(9),
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
                                            fontSize: 11,
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
                                  onTap: () =>
                                      _openUnmatchCategorySwitchModal(active),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
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

        // 3. Searchable Athlete Weigh-In Roster + Status Filter Pills
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _manualSearchQuery = v),
                style:
                    const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Search puller name, division, or QR...',
                  prefixIcon: Icon(
                    Icons.person_search_rounded,
                    size: 18,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final st in [
                ('ALL', 'All (${widget.appliedAthletes.length})'),
                ('PENDING', 'Pending ($pendingCount)'),
                ('VERIFIED', 'Verified ($verifiedCount)'),
                ('UNMATCHED', 'Unmatch ($unmatchedCount)'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _statusFilter == st.$1,
                    selectedColor: AppTheme.goldPrimary.withValues(alpha: 0.22),
                    label: Text(
                      st.$2,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onSelected: (_) => setState(() => _statusFilter = st.$1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 4. Roster Rows with One-Tap Verify / Unmatch & Instant 1-Tap Resolution Pills
        for (final athlete in roster)
          Builder(
            builder: (_) {
              final st = (athlete['weighInStatus'] ?? 'PENDING').toString();
              final isVerified = st == 'VERIFIED';
              final isUnmatched = st == 'UNMATCHED';
              final measured = athlete['measuredWeightKg'];
              final ceiling = parseWeightClassCeilingKg(
                (athlete['registeredWeightLabel'] ?? '').toString(),
              );
              final divCompact = compactDivisionTag(
                (athlete['categoryLabel'] ?? '').toString(),
              );
              final nextDiv = _resolveRecommendedNextDivision(athlete);
              final nextWeightLabel = nextDiv['weightLabel'] ?? '80 kg';

              return Container(
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
                                        (athlete['athleteName'] ?? 'Athlete')
                                            .toString(),
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
                                        borderRadius: BorderRadius.circular(5),
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
                                      ? 'Scale: $measured kg • $st'
                                      : 'Registered: ${athlete['registeredWeightLabel']} • Awaiting Scale',
                                  style: TextStyle(
                                    fontSize: 11,
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
                            final targetKg = (measured as num?)?.toDouble() ??
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
                                onTap: () =>
                                    _quickMoveAndPairOneTap(athlete, nextDiv),
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
                                      '${athlete['athleteName']} remains in Unmatched status.',
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
              );
            },
          ),
      ],
    );
  }
}

// =============================================================================
// 3. SPECTATOR & VENUE ENTRANCE QR GATE CONSOLE
// =============================================================================
class SpectatorEntranceQrGateView extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> appliedAthletes;
  final List<Map<String, dynamic>> spectatorPasses;
  final String autoSaveBannerText;
  final void Function({
    required bool spectatorEnabled,
    required String spectatorMode,
    required int spectatorTicketPricePkr,
    required int athleteGuestPassAllowance,
  }) onUpdateSpectatorConfig;
  final ValueChanged<List<Map<String, dynamic>>> onUpdateSpectatorPasses;
  final ValueChanged<List<Map<String, dynamic>>> onUpdateAthletes;
  final VoidCallback onBackToHub;

  const SpectatorEntranceQrGateView({
    super.key,
    required this.tournament,
    required this.appliedAthletes,
    required this.spectatorPasses,
    required this.autoSaveBannerText,
    required this.onUpdateSpectatorConfig,
    required this.onUpdateSpectatorPasses,
    required this.onUpdateAthletes,
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

  Map<String, dynamic>? _lastVerifiedGateEntry;
  String? _gateScanStatus; // 'ALLOWED' or 'NOT_FOUND'

  @override
  void initState() {
    super.initState();
    _spectatorEnabled = widget.tournament['spectatorEnabled'] != false;
    _spectatorMode =
        (widget.tournament['spectatorMode'] ?? 'PAID').toString().toUpperCase();
    final price =
        (widget.tournament['spectatorTicketPricePkr'] as num?)?.toInt() ?? 1000;
    _ticketPricePkrController = TextEditingController(text: price.toString());
    _athleteGuestAllowance =
        (widget.tournament['athleteGuestPassAllowance'] as num?)?.toInt() ?? 1;
    _gateScanQrController = TextEditingController();

    if (widget.spectatorPasses.isNotEmpty) {
      final firstPass = widget.spectatorPasses.first;
      _gateScanQrController.text = (firstPass['qrCode'] ?? '').toString();
      _verifyEntranceQr((firstPass['qrCode'] ?? '').toString(),
          showToast: false);
    }
  }

  @override
  void dispose() {
    _ticketPricePkrController.dispose();
    _gateScanQrController.dispose();
    super.dispose();
  }

  void _pushConfigUpdate() {
    final price =
        int.tryParse(_ticketPricePkrController.text.trim()) ?? 1000;
    widget.onUpdateSpectatorConfig(
      spectatorEnabled: _spectatorEnabled,
      spectatorMode: _spectatorMode,
      spectatorTicketPricePkr: _spectatorMode == 'FREE' ? 0 : price,
      athleteGuestPassAllowance: _athleteGuestAllowance,
    );
  }

  void _verifyEntranceQr(String rawQr, {bool showToast = true}) {
    final q = rawQr.trim().toLowerCase();
    if (q.isEmpty) return;

    for (final pass in widget.spectatorPasses) {
      final qr = (pass['qrCode'] ?? '').toString().toLowerCase();
      final name = (pass['holderName'] ?? '').toString().toLowerCase();
      if (qr == q || qr.contains(q) || name.contains(q)) {
        HapticFeedback.heavyImpact();
        final updatedPasses = widget.spectatorPasses.map((p) {
          if (p['id'] != pass['id']) return p;
          return <String, dynamic>{
            ...p,
            'checkedInAtGate': true,
            'checkedInAt': DateTime.now().toIso8601String(),
          };
        }).toList();
        widget.onUpdateSpectatorPasses(updatedPasses);
        setState(() {
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
        if (showToast && mounted) {
          CrystalToast.show(
            context,
            title: 'VERIFIED — ALLOWED TO ENTER ✓',
            message:
                '${pass['holderName']} verified at Venue Gate & saved offline.',
            type: CrystalToastType.success,
          );
        }
        return;
      }
    }

    for (final ath in widget.appliedAthletes) {
      final qr = (ath['qrCode'] ?? '').toString().toLowerCase();
      final name = (ath['athleteName'] ?? '').toString().toLowerCase();
      if (qr == q || qr.contains(q) || name.contains(q)) {
        HapticFeedback.heavyImpact();
        final updatedAthletes = widget.appliedAthletes.map((a) {
          if (a['id'] != ath['id']) return a;
          return <String, dynamic>{
            ...a,
            'checkedInAtGate': true,
            'gateCheckedInAt': DateTime.now().toIso8601String(),
          };
        }).toList();
        widget.onUpdateAthletes(updatedAthletes);
        setState(() {
          _gateScanStatus = 'ALLOWED';
          _lastVerifiedGateEntry = {
            'holderName': ath['athleteName'],
            'roleBadge': 'COMPETING ATHLETE (${ath['categoryLabel']})',
            'qrCode': ath['qrCode'],
            'guestsIncluded': _athleteGuestAllowance,
            'feeStatus': 'REGISTERED ATHLETE + $_athleteGuestAllowance GUEST(S)',
          };
        });
        if (showToast && mounted) {
          CrystalToast.show(
            context,
            title: 'VERIFIED — ALLOWED TO ENTER ✓',
            message:
                'Athlete ${ath['athleteName']} (+$_athleteGuestAllowance guest allowance) checked in at gate.',
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
    final idx = widget.spectatorPasses.length + 1;
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
    final next = [newPass, ...widget.spectatorPasses];
    widget.onUpdateSpectatorPasses(next);
    _gateScanQrController.text = newPass['qrCode'] as String;
    _verifyEntranceQr(newPass['qrCode'] as String);
  }

  @override
  Widget build(BuildContext context) {
    final checkedInAthletes = widget.appliedAthletes
        .where((a) => a['checkedInAtGate'] == true)
        .length;
    final checkedInSpectators = widget.spectatorPasses
        .where((p) => p['checkedInAtGate'] == true)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Sleek Gate Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF171C26), Color(0xFF0C0F16)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.goldPrimary.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: widget.onBackToHub,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidian,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 12,
                        color: AppTheme.goldPrimary,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'HUB',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SPECTATOR & VENUE GATE QR SCANNER',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$checkedInAthletes Athletes Checked In • $checkedInSpectators Spectators Entered',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emerald,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _issueInstantSpectatorQrPass,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2B2210), Color(0xFF141008)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.goldPrimary, width: 1.1),
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
        ),
        const SizedBox(height: 12),

        // 2. Top Ringside QR Scanner Console (Venue Gate)
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ARENA GATE QR VERIFICATION CONSOLE',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: AppTheme.emerald,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Verify Athlete Pass, Guest Allowance, or Spectator Ticket',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('venue_entrance_qr_input'),
                      controller: _gateScanQrController,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Scan QR Pass or type Holder Name...',
                        prefixIcon: Icon(
                          Icons.qr_code_2_rounded,
                          size: 18,
                          color: AppTheme.emerald,
                        ),
                      ),
                      onSubmitted: (v) => _verifyEntranceQr(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    key: const ValueKey('venue_entrance_scan_submit_button'),
                    onTap: () => _verifyEntranceQr(_gateScanQrController.text),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0E3325), Color(0xFF071B13)],
                        ),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppTheme.emerald, width: 1.3),
                      ),
                      child: const Center(
                        child: Text(
                          '📷 SCAN QR PASS',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: AppTheme.emerald,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_gateScanStatus == 'ALLOWED' &&
                  _lastVerifiedGateEntry != null) ...[
                const SizedBox(height: 12),
                Container(
                  key: const ValueKey('venue_entrance_verified_allowed_banner'),
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

        // 3. Compact Spectator Policy & Guest Allowance Controls
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
                        selectedColor: AppTheme.emerald.withValues(alpha: 0.22),
                        label: const Text(
                          'Free Spectating',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onSelected: (_) {
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

        // 4. Quick-Tap Gate Pass Roster
        for (final pass in widget.spectatorPasses)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    );
  }
}
