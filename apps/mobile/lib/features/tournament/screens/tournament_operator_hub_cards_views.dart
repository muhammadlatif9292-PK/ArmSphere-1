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

// =============================================================================
// 1. CARD 2 — APPLIED / REGISTERED ATHLETES SCREEN
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
        'label': 'All Categories',
        'count': widget.appliedAthletes.length.toString(),
      },
      for (final lbl in orderedLabels)
        {
          'key': lbl,
          'label': lbl,
          'count': (countsByLabel[lbl] ?? 0).toString(),
        },
    ];
  }

  Future<void> _showAddWalkInApplicantDialog() async {
    final nameCtrl = TextEditingController();
    final clubCtrl = TextEditingController(text: 'Lahore Armwrestling Club');
    final eloCtrl = TextEditingController(text: '1560');
    final availableCategories = widget.separatedDivisions.isNotEmpty
        ? widget.separatedDivisions
            .map((d) => d['label'] ?? '70 kg • Right Arm')
            .toList()
        : <String>[
            '70 kg • Right Arm',
            '70 kg • Left Arm',
            '80 kg • Right Arm',
            '80 kg • Left Arm',
            '90 kg • Right Arm',
            'Open • Right Arm',
          ];
    String chosenCategory = availableCategories.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.titanium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            side: const BorderSide(color: AppTheme.goldPrimary),
          ),
          title: const Text(
            'Add Applied / Walk-In Athlete (Offline-Ready)',
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Athlete Full Name *',
                    hintText: 'e.g. Usman Tariq',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: clubCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Club / City',
                    hintText: 'e.g. Islamabad Titans • Islamabad',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: eloCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Official Elo Rating',
                    hintText: '1500',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: chosenCategory,
                  isExpanded: true,
                  items: [
                    for (final c in availableCategories)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => chosenCategory = v);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Weight Category & Arm *',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'SAVE & QUEUE SYNC',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final regId = 'reg-offline-$nowMs';
    final athId = 'ath-offline-$nowMs';
    final elo = int.tryParse(eloCtrl.text.trim()) ?? 1500;
    final parts = chosenCategory.split('•');
    final weightPart = parts.first.trim();
    final armPart = parts.length > 1 ? parts.last.trim() : 'Right Arm';

    final newAthlete = <String, dynamic>{
      'id': regId,
      'registrationId': regId,
      'athleteId': athId,
      'athleteName': name,
      'clubName': clubCtrl.text.trim().isEmpty
          ? 'Independent Competitor'
          : clubCtrl.text.trim(),
      'categoryLabel': chosenCategory,
      'weightClass': weightPart,
      'arm': armPart,
      'eloRating': elo,
      'qrCodePayload': 'ARMSPHERE-QR:$regId:$athId:$chosenCategory',
      'applicationStatus': 'APPLIED',
      'weighInStatus': 'PENDING',
      'measuredWeightKg': null,
      'unmatchResolution': 'NONE',
      'assignedOpponentId': null,
      'assignedOpponentName': null,
      'checkedInGuestsCount': 0,
      'entranceCheckedIn': false,
      'offlineQueued': true,
    };

    final updated = <Map<String, dynamic>>[
      newAthlete,
      ...widget.appliedAthletes,
    ];
    widget.onUpdateAthletes(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          'Saved / Done: $name added to $chosenCategory (Cached locally & queued for auto-sync).',
        ),
        backgroundColor: AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chips = _buildCategoryChipsData();
    final categoryFiltered = widget.appliedAthletes.where((a) {
      if (_selectedCategoryFilter == 'ALL') return true;
      return (a['categoryLabel'] ?? '').toString().trim() ==
          _selectedCategoryFilter;
    }).toList();

    // Sort by Elo descending for the Horizontal Elo Ranking Carousel
    final rankedByElo = List<Map<String, dynamic>>.from(categoryFiltered)
      ..sort((a, b) {
        final eloA = (a['eloRating'] as num?)?.toInt() ?? 1200;
        final eloB = (b['eloRating'] as num?)?.toInt() ?? 1200;
        return eloB.compareTo(eloA);
      });

    final searchFiltered = rankedByElo.where((a) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final name = (a['athleteName'] ?? '').toString().toLowerCase();
      final club = (a['clubName'] ?? '').toString().toLowerCase();
      final cat = (a['categoryLabel'] ?? '').toString().toLowerCase();
      final id = (a['id'] ?? '').toString().toLowerCase();
      return name.contains(q) || club.contains(q) || cat.contains(q) || id.contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        12,
        AppTheme.space16,
        40,
      ),
      children: [
        // Offline-First Status Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              const Icon(Icons.offline_pin_rounded,
                  size: 16, color: AppTheme.emerald),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CARD 2 • OFFLINE-CACHED ROSTER (${widget.appliedAthletes.length} ATHLETES) • ${widget.autoSaveBannerText}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.emerald,
                  ),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.goldPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _showAddWalkInApplicantDialog,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                label: const Text(
                  '+ WALK-IN',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // =====================================================================
        // 1. CATEGORY FILTER BAR (Horizontal Scrollable Chips with Exact Counts)
        // =====================================================================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'WEIGHT CATEGORY & ARM FILTER BAR',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: AppTheme.goldPrimary,
              ),
            ),
            Text(
              '${chips.length - 1} Divisions',
              style: const TextStyle(
                fontFamily: AppTheme.fontMono,
                fontSize: 10.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          key: const ValueKey('card2_category_filter_bar'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final chip in chips)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryCountChip(
                    keyId: chip['key']!,
                    label: chip['label']!,
                    countText: chip['count']!,
                    selected: _selectedCategoryFilter == chip['key'],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategoryFilter = chip['key']!;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // =====================================================================
        // 2. HORIZONTAL ELO RANKING CAROUSEL
        // =====================================================================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.leaderboard_rounded,
                    size: 16, color: AppTheme.goldPrimary),
                SizedBox(width: 6),
                Text(
                  'ELO RANKING CAROUSEL (REGISTERED ATHLETES)',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ],
            ),
            StatusChip(
              label: 'TOP ${rankedByElo.length} SEEDED',
              type: StatusType.info,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Swipe horizontally to inspect registered athletes ranked by official ArmSphere Elo rating.',
          style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 10),
        SizedBox(
          key: const ValueKey('card2_elo_ranking_carousel'),
          height: 158,
          child: rankedByElo.isEmpty
              ? ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: const Center(
                    child: Text(
                      'No applied athletes in this weight category yet.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: rankedByElo.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final athlete = rankedByElo[index];
                    final rank = index + 1;
                    return _buildEloCarouselCard(athlete, rank);
                  },
                ),
        ),
        const SizedBox(height: 20),

        // =====================================================================
        // 3. APPLIED / REGISTERED ATHLETES LIST
        // =====================================================================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCategoryFilter == 'ALL'
                  ? 'ALL APPLIED ATHLETES (${searchFiltered.length})'
                  : '${_selectedCategoryFilter.toUpperCase()} (${searchFiltered.length})',
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: widget.onBackToHub,
              icon: const Icon(Icons.dashboard_customize_outlined,
                  size: 14, color: AppTheme.goldPrimary),
              label: const Text(
                'Tournament Hub',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.goldPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: const InputDecoration(
            hintText: 'Search applied athletes by name, club, or category...',
            prefixIcon: Icon(Icons.search_rounded, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),

        if (searchFiltered.isEmpty)
          ElevatedActionCard(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: const Text(
              'No athletes match the current category or search filter.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          )
        else
          for (int i = 0; i < searchFiltered.length; i++) ...[
            _buildAppliedAthleteRowCard(
              athlete: searchFiltered[i],
              eloRank: rankedByElo.indexOf(searchFiltered[i]) + 1,
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildCategoryCountChip({
    required String keyId,
    required String label,
    required String countText,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isLeft = label.toUpperCase().contains('LEFT');
    final accentColor = selected
        ? AppTheme.goldPrimary
        : (isLeft ? AppTheme.cyan : AppTheme.textPrimary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.goldPrimary.withValues(alpha: 0.18)
              : const Color(0x16FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppTheme.goldPrimary
                : const Color(0x38FFFFFF),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: selected ? AppTheme.goldPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.goldPrimary
                    : accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                countText,
                style: TextStyle(
                  fontFamily: AppTheme.fontMono,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.black : accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEloCarouselCard(Map<String, dynamic> athlete, int rank) {
    final name = (athlete['athleteName'] ?? 'Athlete').toString();
    final club = (athlete['clubName'] ?? 'Federation Club').toString();
    final categoryLabel =
        (athlete['categoryLabel'] ?? '70 kg • Right Arm').toString();
    final elo = (athlete['eloRating'] as num?)?.toInt() ?? 1500;
    final tier = eloTierBadgeForRating(elo);
    final isTop3 = rank <= 3;
    final rankColor = rank == 1
        ? AppTheme.goldPrimary
        : (rank == 2
            ? const Color(0xFFE2E8F0)
            : (rank == 3 ? const Color(0xFFD97706) : AppTheme.cyan));

    return Container(
      width: 228,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.titanium.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTop3
              ? rankColor.withValues(alpha: 0.75)
              : AppTheme.borderTitanium,
          width: isTop3 ? 1.5 : 1.0,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: rankColor.withValues(alpha: 0.65)),
                ),
                child: Text(
                  'RANK #$rank',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: rankColor,
                  ),
                ),
              ),
              Text(
                tier,
                style: const TextStyle(
                  fontFamily: AppTheme.fontMono,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                club,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  categoryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.cyan,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.55)),
                ),
                child: Text(
                  '$elo ELO',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.goldPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedAthleteRowCard({
    required Map<String, dynamic> athlete,
    required int eloRank,
  }) {
    final id = (athlete['id'] ?? '').toString();
    final name = (athlete['athleteName'] ?? 'Athlete').toString();
    final club = (athlete['clubName'] ?? 'Federation Club').toString();
    final categoryLabel =
        (athlete['categoryLabel'] ?? '70 kg • Right Arm').toString();
    final elo = (athlete['eloRating'] as num?)?.toInt() ?? 1500;
    final weighInStatus =
        (athlete['weighInStatus'] ?? 'PENDING').toString().toUpperCase();
    final measured = (athlete['measuredWeightKg'] as num?)?.toDouble();
    final assignedOpponent = athlete['assignedOpponentName']?.toString();

    Color badgeColor = AppTheme.textSecondary;
    String badgeText = 'WEIGH-IN PENDING';
    if (weighInStatus == 'VERIFIED') {
      badgeColor = AppTheme.emerald;
      badgeText = measured != null
          ? 'VERIFIED ✓ (${measured.toStringAsFixed(1)} kg)'
          : 'VERIFIED ✓';
    } else if (weighInStatus == 'UNMATCH') {
      badgeColor = AppTheme.warning;
      badgeText = '⚠ UNMATCH (WEIGHT MISMATCH)';
    } else if (weighInStatus == 'UNMATCHED_OUT') {
      badgeColor = AppTheme.crimson;
      badgeText = 'LEFT UNMATCHED / OUT';
    }

    return ElevatedActionCard(
      padding: const EdgeInsets.all(14),
      borderColor: weighInStatus == 'UNMATCH'
          ? AppTheme.warning.withValues(alpha: 0.65)
          : (weighInStatus == 'VERIFIED'
              ? AppTheme.emerald.withValues(alpha: 0.55)
              : AppTheme.border),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.goldPrimary, width: 1.5),
                  color: AppTheme.titanium,
                ),
                child: Center(
                  child: Text(
                    '#$eloRank',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontMono,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$club • QR ID: $id',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.55)),
                ),
                child: Text(
                  '$elo ELO',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.5)),
                ),
                child: Text(
                  categoryLabel,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.cyan,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.55)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
              if (assignedOpponent != null && assignedOpponent.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'OPPONENT: vs. $assignedOpponent',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontMono,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.emerald,
                side: BorderSide(color: AppTheme.emerald.withValues(alpha: 0.6)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 34),
              ),
              onPressed: () => widget.onOpenWeighInForAthlete(id),
              icon: const Icon(Icons.scale_outlined, size: 15),
              label: const Text(
                'OPEN IN WEIGH-IN DESK (CARD 4) →',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. CARD 4 — WEIGH-IN VERIFICATION SCREEN (QR Scan Flow A + Quick Unmatch Flow B)
// =============================================================================
class Card4WeighInVerificationView extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, String>> separatedDivisions;
  final List<Map<String, dynamic>> appliedAthletes;
  final String? initialSelectedAthleteId;
  final String autoSaveBannerText;
  final Future<void> Function({
    required List<Map<String, dynamic>> updatedAthletes,
    required String actionType,
    required Map<String, dynamic> syncPayload,
    required String bannerMessage,
  }) onCommitWeighInAction;
  final VoidCallback onBackToHub;

  const Card4WeighInVerificationView({
    super.key,
    required this.tournament,
    required this.separatedDivisions,
    required this.appliedAthletes,
    this.initialSelectedAthleteId,
    required this.autoSaveBannerText,
    required this.onCommitWeighInAction,
    required this.onBackToHub,
  });

  @override
  State<Card4WeighInVerificationView> createState() =>
      _Card4WeighInVerificationViewState();
}

class _Card4WeighInVerificationViewState
    extends State<Card4WeighInVerificationView> {
  String? _scannedOrSelectedId;
  final TextEditingController _qrInputCtrl = TextEditingController();
  final TextEditingController _measuredWeightCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // ALL, PENDING, VERIFIED, UNMATCH, UNMATCHED_OUT
  String _categoryFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _scannedOrSelectedId = widget.initialSelectedAthleteId ??
        (widget.appliedAthletes.isNotEmpty
            ? widget.appliedAthletes.first['id']?.toString()
            : null);
    _syncWeightFieldWithSelected();
  }

  @override
  void dispose() {
    _qrInputCtrl.dispose();
    _measuredWeightCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _activeAthlete {
    if (widget.appliedAthletes.isEmpty) return null;
    if (_scannedOrSelectedId == null) return widget.appliedAthletes.first;
    return widget.appliedAthletes
            .where((a) => a['id']?.toString() == _scannedOrSelectedId)
            .firstOrNull ??
        widget.appliedAthletes.first;
  }

  void _syncWeightFieldWithSelected() {
    final active = _activeAthlete;
    if (active == null) return;
    final w = active['measuredWeightKg'];
    if (w != null) {
      _measuredWeightCtrl.text = (w as num).toDouble().toStringAsFixed(1);
    } else {
      final ceiling = parseWeightClassCeilingKg(
        active['categoryLabel']?.toString(),
      );
      _measuredWeightCtrl.text =
          ceiling < 999.0 ? (ceiling - 0.6).toStringAsFixed(1) : '102.5';
    }
  }

  void _recognizeAthleteByQr(String rawQr) {
    final cleaned = rawQr.trim();
    if (cleaned.isEmpty) return;

    final matched = widget.appliedAthletes.where((a) {
      final id = (a['id'] ?? '').toString().toLowerCase();
      final athId = (a['athleteId'] ?? '').toString().toLowerCase();
      final qr = (a['qrCodePayload'] ?? '').toString().toLowerCase();
      final name = (a['athleteName'] ?? '').toString().toLowerCase();
      final q = cleaned.toLowerCase();
      return qr == q ||
          id == q ||
          athId == q ||
          q.contains(id) ||
          name.contains(q);
    }).firstOrNull;

    if (matched == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: Text(
            'QR Code "$cleaned" not found in local roster. Try selecting from the athlete QR tray.',
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _scannedOrSelectedId = matched['id'].toString();
      _syncWeightFieldWithSelected();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          'QR Recognized (Offline-Ready): ${matched['athleteName']} • ${matched['categoryLabel']}',
        ),
        backgroundColor: AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openQrScannerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.titanium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_scanner_rounded,
                      color: AppTheme.goldPrimary, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'SCAN ATHLETE QR PASSPORT (ONLINE & OFFLINE)',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Scan the QR code from the athlete\'s mobile app, saved card, or printed player card/page. Works 100% offline against the cached tournament roster.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qrInputCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Scan or Enter Athlete QR Code / ID',
                        hintText: 'e.g. ARMSPHERE-QR:reg-pk-101 or Athlete Name',
                        prefixIcon: Icon(Icons.qr_code_2_rounded, size: 18),
                      ),
                      onSubmitted: (v) {
                        Navigator.of(ctx).pop();
                        _recognizeAthleteByQr(v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      final text = _qrInputCtrl.text;
                      Navigator.of(ctx).pop();
                      _recognizeAthleteByQr(text);
                    },
                    child: const Text(
                      'RECOGNIZE',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'TAP AN ATHLETE QR CARD BELOW TO SIMULATE CAMERA SCAN:',
                style: TextStyle(
                  fontFamily: AppTheme.fontMono,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.appliedAthletes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, idx) {
                    final a = widget.appliedAthletes[idx];
                    return ListTile(
                      dense: true,
                      tileColor: const Color(0x14FFFFFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                      leading: const Icon(Icons.qr_code_rounded,
                          color: AppTheme.goldPrimary),
                      title: Text(
                        a['athleteName']?.toString() ?? 'Athlete',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${a['categoryLabel']} • ${a['qrCodePayload']}',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontMono,
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      trailing: const Text(
                        'SCAN →',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.emerald,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _recognizeAthleteByQr(a['id'].toString());
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _verifyAthleteWeight(
    Map<String, dynamic> athlete,
    double measuredKg,
  ) async {
    final ceiling = parseWeightClassCeilingKg(
      athlete['categoryLabel']?.toString(),
    );
    if (ceiling < 999.0 && measuredKg > ceiling) {
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: Text(
            'Measured weight (${measuredKg.toStringAsFixed(1)} kg) exceeds ${ceiling.toStringAsFixed(1)} kg limit for ${athlete['categoryLabel']}. Mark as "Unmatch" to move category or leave out.',
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    final id = athlete['id'].toString();
    final updatedList = widget.appliedAthletes.map((a) {
      if (a['id']?.toString() != id) return a;
      return <String, dynamic>{
        ...a,
        'measuredWeightKg': measuredKg,
        'weighInStatus': 'VERIFIED',
        'unmatchResolution': 'NONE',
        'weighedInAt': DateTime.now().toIso8601String(),
      };
    }).toList();

    await widget.onCommitWeighInAction(
      updatedAthletes: updatedList,
      actionType: 'VERIFY_WEIGH_IN',
      syncPayload: {
        'eventId': widget.tournament['id'],
        'registrationId': id,
        'athleteId': athlete['athleteId'],
        'athleteName': athlete['athleteName'],
        'measuredWeightKg': measuredKg,
        'categoryLabel': athlete['categoryLabel'],
        'status': 'VERIFIED',
      },
      bannerMessage:
          'Saved / Done • ${athlete['athleteName']} Verified (${measuredKg.toStringAsFixed(1)} kg)',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          'Saved / Done: ${athlete['athleteName']} verified at ${measuredKg.toStringAsFixed(1)} kg (${athlete['categoryLabel']}).',
        ),
        backgroundColor: AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _markAthleteUnmatch(
    Map<String, dynamic> athlete, {
    double? measuredKg,
  }) async {
    HapticFeedback.mediumImpact();
    final id = athlete['id'].toString();
    final updatedList = widget.appliedAthletes.map((a) {
      if (a['id']?.toString() != id) return a;
      return <String, dynamic>{
        ...a,
        if (measuredKg != null) 'measuredWeightKg': measuredKg,
        'weighInStatus': 'UNMATCH',
        'unmatchResolution': 'PENDING_RESOLUTION',
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }).toList();

    await widget.onCommitWeighInAction(
      updatedAthletes: updatedList,
      actionType: 'MARK_WEIGH_IN_UNMATCH',
      syncPayload: {
        'eventId': widget.tournament['id'],
        'registrationId': id,
        'athleteId': athlete['athleteId'],
        'athleteName': athlete['athleteName'],
        'measuredWeightKg': measuredKg ?? athlete['measuredWeightKg'],
        'categoryLabel': athlete['categoryLabel'],
        'status': 'UNMATCH',
      },
      bannerMessage:
          'Saved / Done • ${athlete['athleteName']} marked UNMATCH (Choose Category Move or Leave Out)',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          'Saved / Done: ${athlete['athleteName']} marked as UNMATCH. Use one-tap options below to move category & assign opponent or leave out.',
        ),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _leaveUnmatchAthleteOut(Map<String, dynamic> athlete) async {
    HapticFeedback.mediumImpact();
    final id = athlete['id'].toString();
    final updatedList = widget.appliedAthletes.map((a) {
      if (a['id']?.toString() != id) return a;
      return <String, dynamic>{
        ...a,
        'weighInStatus': 'UNMATCHED_OUT',
        'unmatchResolution': 'LEFT_OUT',
        'assignedOpponentId': null,
        'assignedOpponentName': null,
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }).toList();

    await widget.onCommitWeighInAction(
      updatedAthletes: updatedList,
      actionType: 'RESOLVE_UNMATCH_ATHLETE',
      syncPayload: {
        'eventId': widget.tournament['id'],
        'registrationId': id,
        'athleteId': athlete['athleteId'],
        'resolutionMode': 'LEAVE_OUT',
        'status': 'UNMATCHED_OUT',
      },
      bannerMessage:
          'Saved / Done • ${athlete['athleteName']} marked Left Unmatched / Out',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          'Saved / Done: ${athlete['athleteName']} left unmatched / out.',
        ),
        backgroundColor: AppTheme.textSecondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openMoveCategoryAndAssignOpponentModal(
    Map<String, dynamic> athlete,
  ) async {
    final currentCat = (athlete['categoryLabel'] ?? '').toString();
    final allDivisionLabels = <String>{
      for (final d in widget.separatedDivisions)
        if ((d['label'] ?? '').trim().isNotEmpty) d['label']!.trim(),
      '70 kg • Right Arm',
      '70 kg • Left Arm',
      '80 kg • Right Arm',
      '80 kg • Left Arm',
      '90 kg • Right Arm',
      '90 kg • Left Arm',
      'Open • Right Arm',
      'Open • Left Arm',
    }.where((lbl) => lbl != currentCat).toList();

    String targetCategory = allDivisionLabels.isNotEmpty
        ? allDivisionLabels.first
        : 'Open • Right Arm';

    // Measure weight suggestion
    final measured = (athlete['measuredWeightKg'] as num?)?.toDouble();
    if (measured != null) {
      final fitting = allDivisionLabels.where((lbl) {
        final c = parseWeightClassCeilingKg(lbl);
        return measured <= c;
      }).firstOrNull;
      if (fitting != null) {
        targetCategory = fitting;
      }
    }

    List<Map<String, dynamic>> opponentsForCategory(String catLabel) {
      return widget.appliedAthletes
          .where((other) =>
              other['id']?.toString() != athlete['id']?.toString() &&
              (other['categoryLabel'] ?? '').toString().trim() == catLabel &&
              other['weighInStatus'] != 'UNMATCHED_OUT')
          .toList();
    }

    String? selectedOpponentId;
    final initialOpponents = opponentsForCategory(targetCategory);
    if (initialOpponents.isNotEmpty) {
      selectedOpponentId = initialOpponents.first['id']?.toString();
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final candidates = opponentsForCategory(targetCategory);
          if (selectedOpponentId != null &&
              !candidates.any((c) => c['id']?.toString() == selectedOpponentId)) {
            selectedOpponentId =
                candidates.isNotEmpty ? candidates.first['id']?.toString() : null;
          }

          return AlertDialog(
            backgroundColor: AppTheme.titanium,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              side: const BorderSide(color: AppTheme.goldPrimary),
            ),
            title: Text(
              'Move Category & Assign Opponent — ${athlete['athleteName']}',
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Previous Category: $currentCat${measured != null ? " • Measured: ${measured.toStringAsFixed(1)} kg" : ""}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: targetCategory,
                    isExpanded: true,
                    items: [
                      for (final c in allDivisionLabels)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() {
                          targetCategory = v;
                          final nextOpps = opponentsForCategory(v);
                          selectedOpponentId = nextOpps.isNotEmpty
                              ? nextOpps.first['id']?.toString()
                              : null;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: '1. Select New Weight Category & Arm *',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '2. FIND / ASSIGN OPPONENT IN NEW CATEGORY',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (candidates.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: const Text(
                        'No other athletes currently in this category — athlete will be seeded #1 in this category awaiting next contender.',
                        style: TextStyle(
                            fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedOpponentId,
                      isExpanded: true,
                      items: [
                        for (final opp in candidates)
                          DropdownMenuItem(
                            value: opp['id'].toString(),
                            child: Text(
                              '${opp['athleteName']} (${opp['eloRating']} ELO)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => selectedOpponentId = v),
                      decoration: const InputDecoration(
                        labelText: 'Assign Opponent from Category',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          final myElo =
                              (athlete['eloRating'] as num?)?.toInt() ?? 1500;
                          final sortedByClosestElo =
                              List<Map<String, dynamic>>.from(candidates)
                                ..sort((a, b) {
                                  final da = (((a['eloRating'] as num?)?.toInt() ??
                                              1500) -
                                          myElo)
                                      .abs();
                                  final db = (((b['eloRating'] as num?)?.toInt() ??
                                              1500) -
                                          myElo)
                                      .abs();
                                  return da.compareTo(db);
                                });
                          setDialogState(() {
                            selectedOpponentId =
                                sortedByClosestElo.first['id'].toString();
                          });
                        },
                        icon: const Icon(Icons.auto_fix_high_rounded,
                            size: 14, color: AppTheme.cyan),
                        label: const Text(
                          'Auto-Pick Closest Elo Opponent',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.cyan,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text(
                  'MOVE & ASSIGN OPPONENT',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;
    HapticFeedback.heavyImpact();

    final chosenOpponent = widget.appliedAthletes
        .where((a) => a['id']?.toString() == selectedOpponentId)
        .firstOrNull;
    final opponentName = chosenOpponent?['athleteName']?.toString() ??
        'Category Bracket Seed';
    final parts = targetCategory.split('•');
    final weightPart = parts.first.trim();
    final armPart = parts.length > 1 ? parts.last.trim() : 'Right Arm';
    final id = athlete['id'].toString();

    final updatedList = widget.appliedAthletes.map((a) {
      if (a['id']?.toString() == id) {
        return <String, dynamic>{
          ...a,
          'movedFromCategoryLabel': currentCat,
          'categoryLabel': targetCategory,
          'weightClass': weightPart,
          'arm': armPart,
          'weighInStatus': 'VERIFIED',
          'unmatchResolution': 'MOVED_AND_MATCHED',
          'assignedOpponentId': selectedOpponentId,
          'assignedOpponentName': opponentName,
          'updatedAt': DateTime.now().toIso8601String(),
        };
      }
      if (selectedOpponentId != null &&
          a['id']?.toString() == selectedOpponentId) {
        return <String, dynamic>{
          ...a,
          'assignedOpponentId': id,
          'assignedOpponentName': athlete['athleteName'],
        };
      }
      return a;
    }).toList();

    await widget.onCommitWeighInAction(
      updatedAthletes: updatedList,
      actionType: 'RESOLVE_UNMATCH_ATHLETE',
      syncPayload: {
        'eventId': widget.tournament['id'],
        'registrationId': id,
        'athleteId': athlete['athleteId'],
        'resolutionMode': 'MOVE_CATEGORY',
        'previousCategoryKey': currentCat,
        'targetCategoryKey': targetCategory,
        'newWeightClass': weightPart,
        'newArm': armPart,
        'assignedOpponentId': selectedOpponentId,
        'assignedOpponentName': opponentName,
        'status': 'VERIFIED',
      },
      bannerMessage:
          'Saved / Done • Moved ${athlete['athleteName']} to $targetCategory vs. $opponentName',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          'Saved / Done: ${athlete['athleteName']} moved to $targetCategory and matched vs. $opponentName.',
        ),
        backgroundColor: AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = widget.appliedAthletes.length;
    final verifiedCount = widget.appliedAthletes
        .where((a) => a['weighInStatus'] == 'VERIFIED')
        .length;
    final unmatchCount = widget.appliedAthletes
        .where((a) => a['weighInStatus'] == 'UNMATCH')
        .length;
    final leftOutCount = widget.appliedAthletes
        .where((a) => a['weighInStatus'] == 'UNMATCHED_OUT')
        .length;
    final pendingCount =
        totalCount - verifiedCount - unmatchCount - leftOutCount;

    final active = _activeAthlete;
    final activeCeiling =
        parseWeightClassCeilingKg(active?['categoryLabel']?.toString());
    final enteredWeight = double.tryParse(_measuredWeightCtrl.text.trim());
    final fitsActiveCategory = enteredWeight != null &&
        enteredWeight > 0 &&
        (activeCeiling >= 999.0 || enteredWeight <= activeCeiling);

    final filteredList = widget.appliedAthletes.where((a) {
      if (_statusFilter != 'ALL') {
        final st = (a['weighInStatus'] ?? 'PENDING').toString().toUpperCase();
        if (st != _statusFilter) return false;
      }
      if (_categoryFilter != 'ALL') {
        if ((a['categoryLabel'] ?? '').toString() != _categoryFilter) {
          return false;
        }
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final name = (a['athleteName'] ?? '').toString().toLowerCase();
        final cat = (a['categoryLabel'] ?? '').toString().toLowerCase();
        final id = (a['id'] ?? '').toString().toLowerCase();
        return name.contains(q) || cat.contains(q) || id.contains(q);
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        12,
        AppTheme.space16,
        40,
      ),
      children: [
        // Offline-First Status Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              const Icon(Icons.offline_bolt_rounded,
                  size: 16, color: AppTheme.emerald),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CARD 4 WEIGH-IN • OFFLINE-FIRST SYNC • ${widget.autoSaveBannerText}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.emerald,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Weigh-In Live Telemetry Summary Bar
        Row(
          children: [
            _buildStatPill('VERIFIED ✓', '$verifiedCount/$totalCount',
                AppTheme.emerald),
            const SizedBox(width: 8),
            _buildStatPill('UNMATCH ⚠', '$unmatchCount', AppTheme.warning),
            const SizedBox(width: 8),
            _buildStatPill('PENDING', '$pendingCount', AppTheme.cyan),
            const SizedBox(width: 8),
            _buildStatPill('LEFT OUT', '$leftOutCount', AppTheme.textMuted),
          ],
        ),
        const SizedBox(height: 16),

        // =====================================================================
        // FLOW A — QR SCAN VERIFICATION (WORKS ONLINE & OFFLINE)
        // =====================================================================
        ElevatedActionCard(
          key: const ValueKey('card4_flow_a_qr_scan_panel'),
          padding: const EdgeInsets.all(AppTheme.space16),
          borderColor: AppTheme.goldPrimary.withValues(alpha: 0.65),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_scanner_rounded,
                      color: AppTheme.goldPrimary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'FLOW A • QR SCAN VERIFICATION (ONLINE & OFFLINE)',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    key: const ValueKey('card4_scan_qr_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onPressed: _openQrScannerSheet,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                    label: const Text(
                      'SCAN ATHLETE QR',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Scan the athlete\'s QR code (from mobile app, saved card, or printed player card/page), enter their measured scale weight, and mark Verified if it fits their registered category.',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
              if (active != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: fitsActiveCategory
                          ? AppTheme.emerald.withValues(alpha: 0.6)
                          : AppTheme.warning.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RECOGNIZED ATHLETE: ${active['athleteName']}',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Registered Category: ${active['categoryLabel']} • Limit: ${activeCeiling < 999.0 ? "Max ${activeCeiling.toStringAsFixed(1)} kg" : "Open Weight"}',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontMono,
                                    fontSize: 11,
                                    color: AppTheme.cyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(
                            label: (active['weighInStatus'] ?? 'PENDING')
                                .toString(),
                            type: active['weighInStatus'] == 'VERIFIED'
                                ? StatusType.success
                                : (active['weighInStatus'] == 'UNMATCH'
                                    ? StatusType.warning
                                    : StatusType.neutral),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const ValueKey(
                                  'card4_measured_weight_input'),
                              controller: _measuredWeightCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Measured Scale Weight (kg) *',
                                suffixText: 'kg',
                                helperText: fitsActiveCategory
                                    ? '✓ Fits ${active['categoryLabel']} limit'
                                    : '⚠ Exceeds ${active['categoryLabel']} limit — Mark Unmatch or adjust',
                                helperStyle: TextStyle(
                                  color: fitsActiveCategory
                                      ? AppTheme.emerald
                                      : AppTheme.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(52, 32),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: () {
                                  final cur = double.tryParse(
                                          _measuredWeightCtrl.text) ??
                                      70.0;
                                  setState(() {
                                    _measuredWeightCtrl.text =
                                        (cur + 0.5).toStringAsFixed(1);
                                  });
                                },
                                child: const Text('+0.5'),
                              ),
                              const SizedBox(height: 4),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(52, 32),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: () {
                                  final cur = double.tryParse(
                                          _measuredWeightCtrl.text) ??
                                      70.0;
                                  setState(() {
                                    _measuredWeightCtrl.text = (cur - 0.5)
                                        .clamp(30.0, 250.0)
                                        .toStringAsFixed(1);
                                  });
                                },
                                child: const Text('-0.5'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              key: const ValueKey('card4_verify_weight_button'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: fitsActiveCategory
                                    ? AppTheme.emerald
                                    : const Color(0x33FFFFFF),
                                foregroundColor: fitsActiveCategory
                                    ? Colors.black
                                    : AppTheme.textSecondary,
                              ),
                              onPressed: () {
                                final w = double.tryParse(
                                    _measuredWeightCtrl.text.trim());
                                if (w == null || w <= 0) return;
                                _verifyAthleteWeight(active, w);
                              },
                              icon: const Icon(Icons.verified_rounded, size: 17),
                              label: const Text(
                                'MARK VERIFIED ✓',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const ValueKey(
                                  'card4_flow_a_mark_unmatch_button'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.warning,
                                side: const BorderSide(color: AppTheme.warning),
                              ),
                              onPressed: () => _markAthleteUnmatch(
                                active,
                                measuredKg: double.tryParse(
                                    _measuredWeightCtrl.text.trim()),
                              ),
                              icon: const Icon(Icons.warning_amber_rounded,
                                  size: 16),
                              label: const Text(
                                'UNMATCH',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5,
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
        const SizedBox(height: 18),

        // =====================================================================
        // FLOW B — QUICK "UNMATCH" MARKING & DIRECT ROSTER BROWSE / SEARCH
        // =====================================================================
        const Text(
          'FLOW B • BROWSE / SEARCH ATHLETE LIST & QUICK "UNMATCH" MARKING',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
            color: AppTheme.goldPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Browse or search athletes directly without scanning one-by-one. Mark any weight mismatch as "Unmatch" and resolve with one tap.',
          style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 10),
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: const InputDecoration(
            hintText: 'Search athlete name, QR code, or weight category...',
            prefixIcon: Icon(Icons.search_rounded, size: 18),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final st in const [
                ('ALL', 'All Statuses'),
                ('PENDING', 'Pending'),
                ('VERIFIED', 'Verified ✓'),
                ('UNMATCH', 'Unmatch ⚠'),
                ('UNMATCHED_OUT', 'Left Out'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(st.$2, style: const TextStyle(fontSize: 11)),
                    selected: _statusFilter == st.$1,
                    onSelected: (_) => setState(() => _statusFilter = st.$1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        for (final athlete in filteredList) ...[
          _buildWeighInAthleteRowCard(athlete),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontMono,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeighInAthleteRowCard(Map<String, dynamic> athlete) {
    final id = (athlete['id'] ?? '').toString();
    final name = (athlete['athleteName'] ?? 'Athlete').toString();
    final categoryLabel =
        (athlete['categoryLabel'] ?? '70 kg • Right Arm').toString();
    final status =
        (athlete['weighInStatus'] ?? 'PENDING').toString().toUpperCase();
    final measured = (athlete['measuredWeightKg'] as num?)?.toDouble();
    final ceiling = parseWeightClassCeilingKg(categoryLabel);
    final movedFrom = athlete['movedFromCategoryLabel']?.toString();
    final assignedOpponent = athlete['assignedOpponentName']?.toString();
    final isSelected = id == _scannedOrSelectedId;

    return ElevatedActionCard(
      padding: const EdgeInsets.all(14),
      borderColor: status == 'UNMATCH'
          ? AppTheme.warning
          : (status == 'VERIFIED'
              ? AppTheme.emerald.withValues(alpha: 0.65)
              : (isSelected
                  ? AppTheme.goldPrimary.withValues(alpha: 0.65)
                  : AppTheme.border)),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _scannedOrSelectedId = id;
          _syncWeightFieldWithSelected();
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$categoryLabel • Ceiling: ${ceiling < 999.0 ? "${ceiling.toStringAsFixed(1)} kg" : "Open"}${measured != null ? " • Measured: ${measured.toStringAsFixed(1)} kg" : ""}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (movedFrom != null && movedFrom.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'Moved from $movedFrom → Paired vs. ${assignedOpponent ?? "Bracket Seed"}',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontMono,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status / Warning Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'VERIFIED'
                      ? AppTheme.emerald.withValues(alpha: 0.16)
                      : (status == 'UNMATCH'
                          ? AppTheme.warning.withValues(alpha: 0.2)
                          : (status == 'UNMATCHED_OUT'
                              ? AppTheme.crimson.withValues(alpha: 0.16)
                              : const Color(0x18FFFFFF))),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: status == 'VERIFIED'
                        ? AppTheme.emerald
                        : (status == 'UNMATCH'
                            ? AppTheme.warning
                            : (status == 'UNMATCHED_OUT'
                                ? AppTheme.crimson
                                : const Color(0x38FFFFFF))),
                  ),
                ),
                child: Text(
                  status == 'VERIFIED'
                      ? 'VERIFIED ✓'
                      : (status == 'UNMATCH'
                          ? '⚠ UNMATCH'
                          : (status == 'UNMATCHED_OUT'
                              ? 'LEFT OUT'
                              : 'PENDING')),
                  style: TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: status == 'VERIFIED'
                        ? AppTheme.emerald
                        : (status == 'UNMATCH'
                            ? AppTheme.warning
                            : (status == 'UNMATCHED_OUT'
                                ? AppTheme.crimson
                                : AppTheme.textSecondary)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Actions Row (Flow B: Quick Verify or Quick "Unmatch" without scanning)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.emerald,
                    side: BorderSide(
                        color: AppTheme.emerald.withValues(alpha: 0.6)),
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: () {
                    final defaultFitWeight =
                        ceiling < 999.0 ? (ceiling - 0.5) : 102.0;
                    _verifyAthleteWeight(athlete, measured ?? defaultFitWeight);
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                  label: Text(
                    status == 'VERIFIED' ? 'RE-VERIFY ✓' : 'QUICK VERIFY ✓',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warning,
                    side: BorderSide(
                        color: AppTheme.warning.withValues(alpha: 0.75)),
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: () => _markAthleteUnmatch(athlete),
                  icon: const Icon(Icons.warning_amber_rounded, size: 15),
                  label: const Text(
                    'MARK "UNMATCH"',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // =================================================================
          // HANDLING "UNMATCH" ATHLETES — ONE-TAP RESOLUTION OPTIONS
          // =================================================================
          if (status == 'UNMATCH') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning, width: 1.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 16, color: AppTheme.warning),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'UNMATCH RESOLUTION — ONE-TAP OPERATOR ACTION',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This athlete\'s weight does not fit their registered category. Choose one of the two resolution options below:',
                    style:
                        TextStyle(fontSize: 11.5, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () =>
                          _openMoveCategoryAndAssignOpponentModal(athlete),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text(
                        '1) MOVE TO ANOTHER WEIGHT CATEGORY & ASSIGN OPPONENT',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.crimson,
                        side: const BorderSide(color: AppTheme.crimson),
                      ),
                      onPressed: () => _leaveUnmatchAthleteOut(athlete),
                      icon: const Icon(Icons.person_off_outlined, size: 16),
                      label: const Text(
                        '2) LEAVE UNMATCHED / OUT',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
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
  }
}

// =============================================================================
// 3. OPTIONAL FEATURE AREA — SPECTATOR ACCESS & VENUE ENTRANCE QR GATE
// =============================================================================
class SpectatorEntranceQrGateView extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> appliedAthletes;
  final String autoSaveBannerText;
  final Future<void> Function({
    required Map<String, dynamic> updatedSpectatorConfig,
    required List<Map<String, dynamic>> updatedAthletes,
    required String actionType,
    required Map<String, dynamic> syncPayload,
    required String bannerMessage,
  }) onCommitGateAction;
  final VoidCallback onBackToHub;

  const SpectatorEntranceQrGateView({
    super.key,
    required this.tournament,
    required this.appliedAthletes,
    required this.autoSaveBannerText,
    required this.onCommitGateAction,
    required this.onBackToHub,
  });

  @override
  State<SpectatorEntranceQrGateView> createState() =>
      _SpectatorEntranceQrGateViewState();
}

class _SpectatorEntranceQrGateViewState
    extends State<SpectatorEntranceQrGateView> {
  late String _spectatorAccessMode; // 'FREE' | 'PAID'
  late int _spectatorFeePkr;
  late int _allowedGuestsPerAthlete; // 0, 2, 3, 4
  late List<Map<String, dynamic>> _entranceLog;
  late final TextEditingController _feeCtrl;
  late final TextEditingController _qrScanCtrl;
  Map<String, dynamic>? _lastVerifiedGateBanner;

  @override
  void initState() {
    super.initState();
    final cfg = widget.tournament['spectatorGateConfig'] is Map
        ? Map<String, dynamic>.from(
            widget.tournament['spectatorGateConfig'] as Map)
        : <String, dynamic>{};
    _spectatorAccessMode = (cfg['spectatorAccessMode'] ?? 'FREE').toString();
    _spectatorFeePkr = (cfg['spectatorFeePkr'] as num?)?.toInt() ?? 500;
    _allowedGuestsPerAthlete =
        (cfg['allowedGuestsPerAthlete'] as num?)?.toInt() ?? 2;
    _entranceLog = (cfg['entranceCheckInLog'] is List)
        ? (cfg['entranceCheckInLog'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    _feeCtrl = TextEditingController(text: _spectatorFeePkr.toString());
    _qrScanCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _feeCtrl.dispose();
    _qrScanCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildConfigMap() {
    return <String, dynamic>{
      'spectatorAccessMode': _spectatorAccessMode,
      'spectatorFeePkr': _spectatorAccessMode == 'FREE' ? 0 : _spectatorFeePkr,
      'allowedGuestsPerAthlete': _allowedGuestsPerAthlete,
      'entranceCheckInLog': _entranceLog,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _saveSettingsOnly() async {
    HapticFeedback.selectionClick();
    final cfg = _buildConfigMap();
    await widget.onCommitGateAction(
      updatedSpectatorConfig: cfg,
      updatedAthletes: widget.appliedAthletes,
      actionType: 'UPDATE_SPECTATOR_GATE_CONFIG',
      syncPayload: {
        'eventId': widget.tournament['id'],
        ...cfg,
      },
      bannerMessage:
          'Saved / Done • Spectator (${_spectatorAccessMode == "FREE" ? "Free" : "PKR $_spectatorFeePkr"}) & $_allowedGuestsPerAthlete Athlete Friends Saved',
    );
  }

  Future<void> _processEntranceQrScan({
    required String passType, // 'ATHLETE' | 'ATHLETE_GUEST' | 'SPECTATOR'
    required String holderName,
    required String passId,
    String? athleteId,
  }) async {
    HapticFeedback.heavyImpact();
    final nowIso = DateTime.now().toIso8601String();
    var updatedAthletes = List<Map<String, dynamic>>.from(widget.appliedAthletes);

    String detailNote = '';
    if (passType == 'ATHLETE' && athleteId != null) {
      updatedAthletes = updatedAthletes.map((a) {
        if (a['id']?.toString() != athleteId) return a;
        return <String, dynamic>{
          ...a,
          'entranceCheckedIn': true,
          'entranceCheckedInAt': nowIso,
        };
      }).toList();
      detailNote =
          'Competing Athlete • Up to $_allowedGuestsPerAthlete Friends Allowed';
    } else if (passType == 'ATHLETE_GUEST' && athleteId != null) {
      final host = updatedAthletes
          .where((a) => a['id']?.toString() == athleteId)
          .firstOrNull;
      final used = (host?['checkedInGuestsCount'] as num?)?.toInt() ?? 0;
      if (used >= _allowedGuestsPerAthlete) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text(
              'Guest Limit Reached: ${host?['athleteName']} has already used $used/$_allowedGuestsPerAthlete allowed guest passes.',
            ),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final nextUsed = used + 1;
      updatedAthletes = updatedAthletes.map((a) {
        if (a['id']?.toString() != athleteId) return a;
        return <String, dynamic>{
          ...a,
          'checkedInGuestsCount': nextUsed,
        };
      }).toList();
      detailNote =
          'Athlete Guest ($nextUsed/$_allowedGuestsPerAthlete Friends Checked In)';
    } else {
      detailNote = _spectatorAccessMode == 'FREE'
          ? 'Spectator Pass • FREE Admission'
          : 'Spectator Pass • PAID (PKR $_spectatorFeePkr)';
    }

    final logEntry = <String, dynamic>{
      'passId': passId,
      'passType': passType,
      'holderName': holderName,
      'detailNote': detailNote,
      'status': 'VERIFIED / ALLOWED',
      'checkedInAt': nowIso,
    };

    setState(() {
      _entranceLog = [logEntry, ..._entranceLog];
      _lastVerifiedGateBanner = logEntry;
    });

    final cfg = _buildConfigMap();
    await widget.onCommitGateAction(
      updatedSpectatorConfig: cfg,
      updatedAthletes: updatedAthletes,
      actionType: 'SCAN_VENUE_ENTRANCE_QR',
      syncPayload: {
        'eventId': widget.tournament['id'],
        ...logEntry,
      },
      bannerMessage:
          'VERIFIED / ALLOWED ✓ • $holderName Checked In at Venue Entrance',
    );
  }

  void _handleRawQrInputScan(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return;

    // Check if matches a competing athlete in the local roster
    final matchedAthlete = widget.appliedAthletes.where((a) {
      final id = (a['id'] ?? '').toString().toLowerCase();
      final name = (a['athleteName'] ?? '').toString().toLowerCase();
      final qr = (a['qrCodePayload'] ?? '').toString().toLowerCase();
      final q = cleaned.toLowerCase();
      return qr == q || id == q || q.contains(id) || name.contains(q);
    }).firstOrNull;

    if (matchedAthlete != null) {
      _processEntranceQrScan(
        passType: 'ATHLETE',
        holderName: matchedAthlete['athleteName'].toString(),
        passId: matchedAthlete['id'].toString(),
        athleteId: matchedAthlete['id'].toString(),
      );
      _qrScanCtrl.clear();
      return;
    }

    // Otherwise treat as Spectator QR Pass
    _processEntranceQrScan(
      passType: 'SPECTATOR',
      holderName: 'Spectator Pass ($cleaned)',
      passId: cleaned,
    );
    _qrScanCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        12,
        AppTheme.space16,
        40,
      ),
      children: [
        // Non-mandatory optional badge banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              const Icon(Icons.qr_code_2_rounded,
                  size: 17, color: AppTheme.cyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OPTIONAL FEATURE • SPECTATOR & VENUE ENTRANCE QR GATE • ${widget.autoSaveBannerText}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.cyan,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // =====================================================================
        // 1. SPECTATOR & ATHLETE GUEST SETTINGS
        // =====================================================================
        ElevatedActionCard(
          padding: const EdgeInsets.all(AppTheme.space16),
          borderColor: AppTheme.goldPrimary.withValues(alpha: 0.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. SPECTATOR & ATHLETE GUEST SETTINGS',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.goldPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Configure whether spectating is Free of cost or Paid (in PKR), and select how many friends/guests each competing athlete can bring.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),

              const Text(
                'SPECTATOR ADMISSION MODE',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    key: const ValueKey('spectator_mode_free_chip'),
                    label: const Text('Free of Cost (0 PKR for Anyone)'),
                    selected: _spectatorAccessMode == 'FREE',
                    onSelected: (_) {
                      setState(() => _spectatorAccessMode = 'FREE');
                      _saveSettingsOnly();
                    },
                  ),
                  ChoiceChip(
                    key: const ValueKey('spectator_mode_paid_chip'),
                    label: const Text('Paid Spectator Ticket (PKR)'),
                    selected: _spectatorAccessMode == 'PAID',
                    onSelected: (_) {
                      setState(() => _spectatorAccessMode = 'PAID');
                      _saveSettingsOnly();
                    },
                  ),
                ],
              ),
              if (_spectatorAccessMode == 'PAID') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _feeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Spectator Entrance Fee (PKR)',
                    prefixIcon: Icon(Icons.payments_outlined, size: 18),
                    suffixText: 'PKR',
                  ),
                  onChanged: (v) {
                    setState(() {
                      _spectatorFeePkr = int.tryParse(v.trim()) ?? 500;
                    });
                    _saveSettingsOnly();
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final preset in const [300, 500, 1000, 2000])
                      ActionChip(
                        label: Text('PKR $preset'),
                        onPressed: () {
                          setState(() {
                            _spectatorFeePkr = preset;
                            _feeCtrl.text = preset.toString();
                          });
                          _saveSettingsOnly();
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              const Text(
                'COMPETING ATHLETE FRIENDS / GUESTS ALLOWANCE',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select how many friends/guests each competing athlete is allowed to bring through the venue entrance gate:',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final count in const [0, 2, 3, 4])
                    ChoiceChip(
                      key: ValueKey('athlete_guest_allowance_$count'),
                      label: Text(
                        count == 0 ? '0 Friends' : '$count Friends',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      selected: _allowedGuestsPerAthlete == count,
                      onSelected: (_) {
                        setState(() => _allowedGuestsPerAthlete = count);
                        _saveSettingsOnly();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // =====================================================================
        // 2. VENUE ENTRANCE QR SCANNER (INSTANT OFFLINE VERIFICATION)
        // =====================================================================
        ElevatedActionCard(
          key: const ValueKey('venue_entrance_qr_scanner_card'),
          padding: const EdgeInsets.all(AppTheme.space16),
          borderColor: AppTheme.emerald.withValues(alpha: 0.65),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      color: AppTheme.emerald, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '2. VENUE ENTRANCE QR SCANNER (ATHLETES & SPECTATORS)',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.emerald,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Scan QR codes of competing athletes, athlete guests, or spectators at the entrance gate. Checks the local synced roster and immediately shows "Verified / Allowed" with zero network error even if internet flickers.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),

              // Instant "VERIFIED / ALLOWED" Result Banner
              if (_lastVerifiedGateBanner != null) ...[
                Container(
                  key: const ValueKey('venue_entrance_verified_allowed_banner'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.emerald, width: 1.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          color: AppTheme.emerald, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VERIFIED / ALLOWED — ENTRANCE GRANTED ✓',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.emerald,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_lastVerifiedGateBanner!['holderName']} • ${_lastVerifiedGateBanner!['detailNote']}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Text(
                              'Saved Locally & Queued for Automatic Database Sync (Zero Network Delay)',
                              style: TextStyle(
                                fontFamily: AppTheme.fontMono,
                                fontSize: 10,
                                color: AppTheme.emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('venue_entrance_qr_input'),
                      controller: _qrScanCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Scan / Enter Athlete or Spectator QR Code',
                        hintText: 'e.g. ARMSPHERE-QR:reg-pk-101 or SPEC-PASS-01',
                        prefixIcon: Icon(Icons.qr_code_scanner_rounded, size: 18),
                      ),
                      onSubmitted: _handleRawQrInputScan,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    key: const ValueKey('venue_entrance_scan_submit_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                    onPressed: () => _handleRawQrInputScan(
                      _qrScanCtrl.text.trim().isEmpty
                          ? 'SPECTATOR-QR-${DateTime.now().millisecondsSinceEpoch % 10000}'
                          : _qrScanCtrl.text,
                    ),
                    icon: const Icon(Icons.verified_rounded, size: 17),
                    label: const Text(
                      'SCAN QR',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick One-Tap Entrance Check-In for Competing Athletes & Their Friends
              const Text(
                'LOCAL ROSTER QUICK-SCAN (ATHLETES & GUEST QUOTA):',
                style: TextStyle(
                  fontFamily: AppTheme.fontMono,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.goldPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (final a in widget.appliedAthletes.take(6)) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: a['entranceCheckedIn'] == true
                          ? AppTheme.emerald.withValues(alpha: 0.6)
                          : const Color(0x33FFFFFF),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a['athleteName']?.toString() ?? 'Athlete',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${a['categoryLabel']} • Friends Checked In: ${(a['checkedInGuestsCount'] as num?)?.toInt() ?? 0}/$_allowedGuestsPerAthlete',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontMono,
                                fontSize: 10.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.emerald,
                          side: const BorderSide(color: AppTheme.emerald),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 32),
                        ),
                        onPressed: () => _processEntranceQrScan(
                          passType: 'ATHLETE',
                          holderName: a['athleteName'].toString(),
                          passId: a['id'].toString(),
                          athleteId: a['id'].toString(),
                        ),
                        child: Text(
                          a['entranceCheckedIn'] == true
                              ? 'ALLOWED ✓'
                              : 'SCAN ATHLETE QR',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (_allowedGuestsPerAthlete > 0) ...[
                        const SizedBox(width: 6),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.cyan,
                            side: const BorderSide(color: AppTheme.cyan),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 32),
                          ),
                          onPressed: () => _processEntranceQrScan(
                            passType: 'ATHLETE_GUEST',
                            holderName: 'Guest of ${a['athleteName']}',
                            passId: 'GUEST-${a['id']}',
                            athleteId: a['id'].toString(),
                          ),
                          child: const Text(
                            '+1 FRIEND QR',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
