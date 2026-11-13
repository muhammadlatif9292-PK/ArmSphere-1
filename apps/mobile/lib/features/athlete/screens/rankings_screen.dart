import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/rankings_provider.dart';
import '../../../core/providers/visual_preferences_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/championship_name_marquee.dart';

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen> {
  static const _provinces = <String>[
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Gilgit-Baltistan',
    'Azad Kashmir',
    'Islamabad Capital Territory',
  ];

  static const _weightClasses = <String>[
    'ALL',
    '65kg',
    '75kg',
    '85kg',
    '95kg',
    '105kg',
    '105kg+',
  ];

  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(rankingsSearchQueryProvider);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(rankingsSearchQueryProvider.notifier).state = value.trim();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppTheme.goldPrimary;
      case 2:
        return const Color(0xFFCBD5E1); // Silver
      case 3:
        return const Color(0xFFD97706); // Bronze
      default:
        return AppTheme.textMuted;
    }
  }

  Widget _buildPodiumBadge(
    BuildContext context, {
    required int podiumSlot,
    required Map<String, dynamic>? athlete,
    required String arm,
  }) {
    final color = _rankColor(podiumSlot);
    final name = athlete?['displayName']?.toString() ?? 'Vacant #$podiumSlot';
    final elo = (athlete?['eloRating'] as num?)?.toInt() ?? 0;
    final athleteId = (athlete?['athleteId'] ?? athlete?['id'])?.toString() ?? '';
    final avatarUrl = (athlete?['avatarUrl'] ?? athlete?['profilePhoto'])?.toString();
    final isFirst = podiumSlot == 1;

    return Expanded(
      child: GestureDetector(
        onTap: athleteId.isEmpty
            ? null
            : () {
                HapticFeedback.lightImpact();
                context.push('/athlete/$athleteId');
              },
        child: Container(
          margin: EdgeInsets.only(top: isFirst ? 0 : 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: isFirst ? 0.65 : 0.45),
              width: isFirst ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: isFirst ? 14 : 12,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '#$podiumSlot',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.w900,
                      fontSize: isFirst ? 12 : 11,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: isFirst ? 44 : 38,
                height: isFirst ? 44 : 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: ArmSphereImage.avatar(
                  imageUrl: avatarUrl,
                  initial: name,
                  size: isFirst ? 44 : 38,
                  fallbackAsset: ArmSphereAssets.avatarNeutralDark,
                  semanticLabel: 'Podium #$podiumSlot Avatar for $name',
                ),
              ),
              const SizedBox(height: 6),
              ChampionshipNameMarquee(
                name: name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w700,
                  fontSize: isFirst ? 12 : 11,
                  color: AppTheme.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                elo > 0 ? '$elo ELO' : arm,
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFiltersBar({
    required String arm,
    required String province,
    required String selectedWeightClass,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search athletes by ring or real name...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _searchController.clear();
                      _debounce?.cancel();
                      ref.read(rankingsSearchQueryProvider.notifier).state = '';
                      setState(() {});
                    },
                  )
                : null,
            isDense: true,
          ),
        ),
        const SizedBox(height: AppTheme.space10),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'RIGHT', label: Text('Right Arm')),
                  ButtonSegment(value: 'LEFT', label: Text('Left Arm')),
                ],
                selected: {arm},
                onSelectionChanged: (selection) {
                  HapticFeedback.lightImpact();
                  ref.read(rankingsArmProvider.notifier).state = selection.first;
                },
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.transparent,
                  selectedBackgroundColor: Colors.transparent,
                  selectedForegroundColor: AppTheme.goldPrimary,
                  foregroundColor: const Color(0xFFCBD5E1),
                  textStyle: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space10),
        // Weight Class Filter Strip
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _weightClasses.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.space8),
            itemBuilder: (context, idx) {
              final wc = _weightClasses[idx];
              final isSelected = selectedWeightClass == wc ||
                  (wc == 'ALL' && selectedWeightClass.isEmpty);
              final label = (wc.isEmpty || wc == 'ALL')
                  ? 'ALL DIVISIONS'
                  : wc.toUpperCase();
              return ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isSelected ? AppTheme.goldPrimary : const Color(0xFFCBD5E1),
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
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0x73D4AF37)
                        : const Color(0x2EFFFFFF),
                    width: isSelected ? 1.2 : 1.0,
                  ),
                ),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  ref.read(rankingsWeightClassProvider.notifier).state = wc;
                },
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12, vertical: AppTheme.space6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: const Color(0x38FFFFFF), width: 1.0),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: province.isEmpty ? null : province,
                  hint: const Text('All Provinces',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  isDense: true,
                  dropdownColor: AppTheme.cardSurface,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All Provinces', style: TextStyle(fontSize: 12)),
                    ),
                    for (final p in _provinces)
                      DropdownMenuItem(
                          value: p,
                          child: Text(p, style: const TextStyle(fontSize: 12))),
                  ],
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    ref.read(rankingsProvinceProvider.notifier).state = value ?? '';
                  },
                ),
              ),
            ),
            if (province.isNotEmpty) ...[
              const SizedBox(width: AppTheme.space8),
              InputChip(
                label: Text(province,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                onDeleted: () {
                  HapticFeedback.lightImpact();
                  ref.read(rankingsProvinceProvider.notifier).state = '';
                },
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                deleteIconColor: AppTheme.primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  side: const BorderSide(color: Color(0x80E23B3B), width: 1.0),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rankingsAsync = ref.watch(rankingsProvider);
    final arm = ref.watch(rankingsArmProvider);
    final province = ref.watch(rankingsProvinceProvider);
    final selectedWeightClass = ref.watch(rankingsWeightClassProvider);
    final myProfileId =
        ref.watch(athleteProfileProvider).value?['id']?.toString();

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const CrystalHeaderStageBar(
          domain: ArmSphereStageDomain.rankings,
        ),
        leading: const CrystalBackButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ArmSphereImage(
              assetPath: ArmSphereAssets.sealFed,
              width: 24,
              height: 24,
              semanticLabel: 'Official Federation Seal',
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Leaderboard & Rankings'),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tale of the Tape (Compare)',
            icon: const Icon(Icons.compare_arrows_rounded, color: AppTheme.goldPrimary),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/matches/head-to-head');
            },
          ),
          const CrystalHomeButton(),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.rankings),
          ),
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(rankingsProvider),
            child: rankingsAsync.when(
              data: (rawRankings) {
                final rankings = (selectedWeightClass.isEmpty ||
                        selectedWeightClass == 'ALL')
                    ? rawRankings
                    : rawRankings.where((r) {
                        final wc =
                            r['weightClass']?.toString().toLowerCase() ?? '';
                        return wc == selectedWeightClass.toLowerCase();
                      }).toList();

                final rank1 = rankings.isNotEmpty ? rankings[0] : null;
                final rank2 = rankings.length > 1 ? rankings[1] : null;
                final rank3 = rankings.length > 2 ? rankings[2] : null;

                return ListView(
                  key: const PageStorageKey<String>('rankings_list_view'),
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    160,
                    AppTheme.space16,
                    MainShellScope.bottomClearance(context, additionalPadding: 44),
                  ),
                  children: [
                    // Top-3 Medalist Badges aligned beneath the #2 (left), #1 (center), and #3 (right) 3D podium tiers
                    if (rankings.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPodiumBadge(
                            context,
                            podiumSlot: 2,
                            athlete: rank2,
                            arm: arm,
                          ),
                          const SizedBox(width: 8),
                          _buildPodiumBadge(
                            context,
                            podiumSlot: 1,
                            athlete: rank1,
                            arm: arm,
                          ),
                          const SizedBox(width: 8),
                          _buildPodiumBadge(
                            context,
                            podiumSlot: 3,
                            athlete: rank3,
                            arm: arm,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space14),
                    ],

                    // Search Bar, Arm Toggle, Weight-Class & Province Filters (below 160px podium + Top-3 badges)
                    _buildSearchAndFiltersBar(
                      arm: arm,
                      province: province,
                      selectedWeightClass: selectedWeightClass,
                    ),
                    const SizedBox(height: AppTheme.space12),

                    if (rankings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.emoji_events_outlined,
                                  size: 48, color: AppTheme.textMuted),
                              SizedBox(height: 12),
                              Text(
                                'No ranked athletes match these filters',
                                style: TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(rankings.length, (index) {
                        final athlete = rankings[index];
                        final rank = athlete['rank'] as int? ?? (index + 1);
                        final name =
                            athlete['displayName'] as String? ?? 'Unknown Athlete';
                        final eloRating = athlete['eloRating'] as int? ?? 0;
                        final provinceValue = athlete['province'] as String?;
                        final weightClass = athlete['weightClass'] as String?;
                        final athleteId =
                            (athlete['athleteId'] ?? athlete['id'])?.toString() ?? '';
                        final color = _rankColor(rank);

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == rankings.length - 1
                                ? 0
                                : AppTheme.space10,
                          ),
                          child: RepaintBoundary(
                            child: ElevatedActionCard(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                if (athleteId.isNotEmpty) {
                                  context.push('/athlete/$athleteId');
                                }
                              },
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space14,
                                  vertical: AppTheme.space12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: color.withValues(
                                            alpha: rank <= 3 ? 0.55 : 0.30),
                                        width: rank <= 3 ? 1.2 : 1.0,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$rank',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: color,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.space12),
                                  ArmSphereImage.avatar(
                                    imageUrl: (athlete['avatarUrl'] ??
                                            athlete['profilePhoto'])
                                        ?.toString(),
                                    initial: name,
                                    size: 40,
                                    cacheWidth: 80,
                                    cacheHeight: 80,
                                    fallbackAsset:
                                        ArmSphereAssets.avatarNeutralDark,
                                    semanticLabel: 'Athlete Avatar for $name',
                                  ),
                                  const SizedBox(width: AppTheme.space12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ChampionshipNameMarquee(
                                          name: name,
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: AppTheme.space4),
                                        Text(
                                          [
                                            if (weightClass != null &&
                                                weightClass.isNotEmpty &&
                                                weightClass != 'OPEN')
                                              weightClass,
                                            if (provinceValue != null &&
                                                provinceValue.isNotEmpty)
                                              provinceValue,
                                          ].join(' • '),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.space8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$eloRating',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.goldPrimary,
                                          fontFeatures: [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '$arm ELO',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textMuted,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (athleteId.isNotEmpty &&
                                      athleteId != myProfileId) ...[
                                    const SizedBox(width: AppTheme.space8),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      tooltip: 'Compare with $name',
                                      icon: const Icon(
                                        Icons.compare_arrows_rounded,
                                        size: 18,
                                        color: AppTheme.textMuted,
                                      ),
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        final query = myProfileId != null &&
                                                myProfileId.isNotEmpty
                                            ? 'athleteId1=$myProfileId&athleteId2=$athleteId'
                                            : 'athleteId2=$athleteId';
                                        context.push(
                                            '/matches/head-to-head?$query');
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
              error: (err, stack) => ListView(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.space16,
                  160,
                  AppTheme.space16,
                  MainShellScope.bottomClearance(context, additionalPadding: 44),
                ),
                children: [
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 44, color: AppTheme.error),
                        const SizedBox(height: 12),
                        Text('Error loading rankings: $err',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.error)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.invalidate(rankingsProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              loading: () => const CrystalScreenLoadingView(
                itemCount: 5,
                cardHeight: 78,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
