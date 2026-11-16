import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/sticky_bottom_action_bar.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/visual_preferences_provider.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/security/admin_permissions.dart';
import '../services/tournament_offline_store.dart';
import 'event_qr_passport_screen.dart';
import '../widgets/tournament_widgets.dart';
import '../../../core/widgets/crystal_toast.dart';

/// Shared formatting helpers for event data (used by list, detail and
/// registration screens so every surface renders the same real values).
String formatEventDate(dynamic iso) {
  if (iso == null) return 'TBA';
  final d = DateTime.tryParse(iso.toString());
  if (d == null) return iso.toString();
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String formatEventFee(dynamic registrationFeeCents) {
  final cents = (registrationFeeCents is num)
      ? registrationFeeCents.toInt()
      : int.tryParse('${registrationFeeCents ?? ''}') ?? 0;
  if (cents <= 0) return 'Free entry';
  return 'CAD \$${(cents / 100).toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';
}

Color eventStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PUBLISHED':
      return AppTheme.success;
    case 'ONGOING':
      return AppTheme.goldPrimary;
    case 'COMPLETED':
      return AppTheme.textMuted;
    case 'CANCELLED':
      return AppTheme.error;
    default:
      return AppTheme.info;
  }
}

Widget _buildStatusChip(String status) {
  switch (status.toUpperCase()) {
    case 'ONGOING':
      return const StatusChip.live(label: 'LIVE NOW');
    case 'PUBLISHED':
      return const StatusChip.success(label: 'REGISTRATION OPEN');
    case 'COMPLETED':
      return const StatusChip.neutral(label: 'COMPLETED');
    case 'CANCELLED':
      return const StatusChip.error(label: 'CANCELLED');
    default:
      return StatusChip.info(label: status.isEmpty ? 'UPCOMING' : status);
  }
}

/// Tournaments List Screen — real data from GET /tournaments/events.
class TournamentsListScreen extends ConsumerWidget {
  const TournamentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentProvider);

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const CrystalHeaderStageBar(
          domain: ArmSphereStageDomain.events,
        ),
        leading: CrystalBackButton.maybeForInnerScreen(context),
        title: const Text(
          'Competitions',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            tooltip: 'Refresh Tournaments',
            onPressed: () => ref.invalidate(tournamentProvider),
          ),
          if (!MainShellScope.isInsideShell(context)) const CrystalHomeButton(),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.events),
          ),
          tournamentsAsync.when(
            loading: () => const TournamentSkeletonLoadingWidget(),
            error: (error, _) => AppErrorView(
              error: error,
              title: 'Could not load competitions',
              onRetry: () => ref.invalidate(tournamentProvider),
              showSecondaryAction: false,
              onSessionExpired: () => ref.read(authProvider.notifier).logout(),
            ),
            data: (events) {
          final hive = ref.watch(hiveStorageProvider);
          // Merge released local & server tournaments; strictly exclude unreleased drafts.
          final visible = TournamentOfflineStore.getAllReleasedTournaments(
            hive: hive,
            serverEvents: events,
          ).where(TournamentOfflineStore.isReleasedTournament).toList();

          if (visible.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(tournamentProvider.future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 20, 16, MainShellScope.bottomClearance(context)),
                children: [
                  const SizedBox(height: 64),
                  AppEmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'No competitions published yet',
                    subtitle: 'Check back soon for upcoming sanctioned events',
                    ctaLabel: 'Refresh Events',
                    onCtaTap: () => ref.invalidate(tournamentProvider),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(tournamentProvider.future),
            child: ListView.separated(
              key: const PageStorageKey<String>('tournaments_list_view'),
              padding: EdgeInsets.fromLTRB(
                16,
                155,
                16,
                MainShellScope.bottomClearance(context, additionalPadding: 44),
              ),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final t = visible[index];
                final status = (t['status']?.toString() ?? 'UNKNOWN').toUpperCase();
                final location = [
                  t['city']?.toString(),
                  t['province']?.toString(),
                ].where((part) => part != null && part.isNotEmpty).join(', ');

                return ElevatedActionCard(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/tournament/${t['id']}');
                  },
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusChip(status),
                          if (t['startDate'] != null)
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  formatEventDate(t['startDate']),
                                  style: const TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t['name']?.toString() ?? t['title']?.toString() ?? 'Untitled competition',
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.goldPrimary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location.isEmpty ? 'Location TBA' : location,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(color: const Color(0x73D4AF37), width: 1.0),
                            ),
                            child: Text(
                              formatEventFee(t['registrationFeeCents']),
                              style: const TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.goldPrimary,
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
          );
            },
          ),
        ],
      ),
    );
  }
}

/// Tournament Detail Screen — real data from GET /tournaments/events/:id.
/// Upgraded to Canonical Stage 2 Specification:
/// - Collapsing SliverAppBar with 4-stop heroScrim gradient.
/// - Live 1-second countdown ticker badge.
/// - StatusChip normalization.
/// - Integrated ImportantDatesTimelineWidget and RulebookAccordionWidget.
/// - Persistent StickyBottomActionBar with responsive constraints & action switching.
class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen> {
  Timer? _countdownTimer;
  int _activeAthleteTab = 0; // 0 = Details Tab, 1 = Matchups Tab
  String _selectedCategory = 'ALL';
  static const _categories = ['ALL', '-75 KG', '-85 KG', '-95 KG', '+105 KG', 'OPEN RIGHT', 'OPEN LEFT'];

  // Matchups Read-Only Filter State
  String _selectedMatchupCategoryFilter = 'ALL';
  int _selectedMatchupRoundFilter = 0; // 0 = All Rounds
  Map<String, dynamic>? _localSubmittedApplication;
  Map<String, dynamic>? _localIssuedSpectatorPass;
  Map<String, dynamic>? _entranceVerifyResult;
  final TextEditingController _entranceVerifyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Live countdown update ticker
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _entranceVerifyCtrl.dispose();
    super.dispose();
  }

  String _calculateCountdown(dynamic startDateIso) {
    if (startDateIso == null) return '';
    final start = DateTime.tryParse(startDateIso.toString());
    if (start == null) return '';
    final now = DateTime.now();
    final diff = start.difference(now);
    if (diff.isNegative) {
      return 'Event in progress';
    }
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m left';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s left';
    } else {
      return '${minutes}m ${seconds}s left';
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.tournamentId));
    final hive = ref.watch(hiveStorageProvider);
    final offlineFallback = TournamentOfflineStore.getReleasedTournamentById(
      hive: hive,
      tournamentId: widget.tournamentId,
    );

    Widget buildWithResolvedEvent(Map<String, dynamic> rawEvent) {
      final mergedEvent = TournamentOfflineStore.getReleasedTournamentById(
            hive: hive,
            tournamentId: widget.tournamentId,
            serverEvents: [rawEvent],
          ) ??
          rawEvent;
      return _buildTournamentDetailScaffold(context, mergedEvent);
    }

    return eventAsync.when(
      loading: () => offlineFallback != null
          ? buildWithResolvedEvent(offlineFallback)
          : const Scaffold(
              backgroundColor: AppTheme.background,
              body: TournamentSkeletonLoadingWidget(),
            ),
      error: (error, _) => offlineFallback != null
          ? buildWithResolvedEvent(offlineFallback)
          : Scaffold(
              backgroundColor: AppTheme.background,
              appBar: AppBar(
                leading: const CrystalBackButton(fallbackRoute: '/tournaments'),
                title: const Text('Tournament Details'),
                actions: const [CrystalHomeButton()],
              ),
              body: AppErrorView(
                error: error,
                title: 'Could not load tournament',
                onRetry: () => ref.invalidate(eventDetailProvider(widget.tournamentId)),
                secondaryActionLabel: 'Return to Tournaments',
                onSecondaryAction: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/tournaments');
                  }
                },
              ),
            ),
      data: (event) => buildWithResolvedEvent(event),
    );
  }

  Widget _buildTournamentDetailScaffold(BuildContext context, Map<String, dynamic> event) {
    final status = (event['status']?.toString() ?? 'REGISTRATION_OPEN').toUpperCase();
    final canRegister = status == 'PUBLISHED' ||
        status == 'REGISTRATION_OPEN' ||
        status == 'UPCOMING' ||
        event['isReleased'] == true;
    final auth = ref.watch(authProvider);
    final canOperate = AdminPermissions.canOperateEvent(
      activeRole: auth.activeRole,
      userProfile: auth.userProfile,
      event: event,
    );
        final rawOrgId = event['organizationId']?.toString() ?? '';
        final isIndependentPromotion = rawOrgId.isEmpty;
        final hostOrgId = isIndependentPromotion ? 'org_paff_national' : rawOrgId;
        final hostOrgName = (event['organizationName'] ??
                (isIndependentPromotion
                    ? 'Independent Promotion · Verified Organizer'
                    : 'Pakistan Armwrestling Federation (PAFF)'))
            .toString();
        final location = [
          event['venueName']?.toString(),
          event['city']?.toString(),
          event['province']?.toString(),
        ].where((part) => part != null && part.isNotEmpty).join(', ');
        final dates = {
          formatEventDate(event['startDate']),
          formatEventDate(event['endDate']),
        }.join(' → ');

        final countdownText = _calculateCountdown(event['startDate']);

        return Scaffold(
          backgroundColor: AppTheme.voidBackground,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(
                child: CrystalStageBackdrop(domain: ArmSphereStageDomain.events),
              ),
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 260.0,
                    pinned: true,
                    backgroundColor: AppTheme.voidBackground,
                    leading: const CrystalBackButton(fallbackRoute: '/tournaments'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
                        tooltip: 'Share Tournament',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Clipboard.setData(ClipboardData(text: 'https://armsphere.app/tournament/${widget.tournamentId}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            CrystalSnackBar(
                              content: Text('Tournament link copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const CrystalHomeButton(),
                    ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Background Image or Dynamic Arena Fallback (`tournament_poster.webp` at 100% opacity)
                      ArmSphereImage(
                        imageUrl: event['imageUrl']?.toString(),
                        assetPath: (event['imageUrl'] == null ||
                                event['imageUrl'].toString().isEmpty)
                            ? ArmSphereAssets.tournamentPoster
                            : null,
                        fallbackAsset: ArmSphereAssets.tournamentPoster,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0.0, -0.20),
                        semanticLabel: event['name'] != null
                            ? 'Tournament banner for ${event['name']}'
                            : 'Tournament banner',
                      ),

                      // 2. Bottom-Only Pure-Black Gradient (y: 0.55 to 1.0) preserving 100% clarity of the 3D Grand Prix stage, table, and trophies
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.0, 0.55, 1.0],
                              colors: [
                                Color(0x00000000),
                                Color(0x00000000),
                                Color(0x99000000),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 3. Bottom pinned Information Overlay
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                _buildStatusChip(status),
                                if (countdownText.isNotEmpty && status == 'PUBLISHED') ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                      border: Border.all(
                                        color: const Color(0x73D4AF37),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 12, color: AppTheme.goldPrimary),
                                        const SizedBox(width: 4),
                                        Text(
                                          countdownText,
                                          style: const TextStyle(
                                            fontFamily: 'Space Grotesk',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                            color: AppTheme.goldPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event['name']?.toString() ?? 'Untitled Competition',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                            if (location.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: AppTheme.goldPrimary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Body Content with 2 Clean Athlete-Adapted Tabs (1: Details Tab, 2: Matchups Tab)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Two Clean Athlete-Adapted Tabs Selector: 1) Details Tab, 2) Matchups Tab
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: AppTheme.recessedObsidianWellDecoration(radius: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                key: const ValueKey('athlete_tournament_details_tab_btn'),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _activeAthleteTab = 0);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    color: _activeAthleteTab == 0
                                        ? AppTheme.goldPrimary.withValues(alpha: 0.18)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _activeAthleteTab == 0
                                          ? AppTheme.goldPrimary
                                          : Colors.transparent,
                                      width: 1.4,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event_note_rounded,
                                        size: 16,
                                        color: _activeAthleteTab == 0
                                            ? AppTheme.goldPrimary
                                            : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '1) DETAILS TAB',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          letterSpacing: 0.6,
                                          color: _activeAthleteTab == 0
                                              ? AppTheme.goldPrimary
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: GestureDetector(
                                key: const ValueKey('athlete_tournament_matchups_tab_btn'),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _activeAthleteTab = 1);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    color: _activeAthleteTab == 1
                                        ? AppTheme.emerald.withValues(alpha: 0.18)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _activeAthleteTab == 1
                                          ? AppTheme.emerald
                                          : Colors.transparent,
                                      width: 1.4,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_tree_rounded,
                                        size: 16,
                                        color: _activeAthleteTab == 1
                                            ? AppTheme.emerald
                                            : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '2) MATCHUPS TAB',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          letterSpacing: 0.6,
                                          color: _activeAthleteTab == 1
                                              ? AppTheme.emerald
                                              : AppTheme.textSecondary,
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
                      const SizedBox(height: 16),

                      if (_activeAthleteTab == 1) ...[
                        _buildAthleteReadOnlyMatchupsAndPodiumTab(context, event),
                        const SizedBox(height: 96),
                      ] else ...[
                        // 1. Overview Metrics Strip (Schedule, Entry Fee in PKR, Capacity, Sanctioning)
                        ElevatedActionCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _metricColumn(
                                      icon: Icons.calendar_today_outlined,
                                      label: 'Schedule & Dates',
                                      value: dates.isEmpty ? 'TBA' : dates,
                                    ),
                                  ),
                                  Container(height: 36, width: 1, color: AppTheme.borderSubtle),
                                  Expanded(
                                    child: _metricColumn(
                                      icon: Icons.payments_outlined,
                                      label: 'Entry Fee (PKR)',
                                      value: _formatPkrEntryFee(event),
                                      isHighlighted: true,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 1, color: Color(0x22FFFFFF)),
                              Row(
                                children: [
                                  Expanded(
                                    child: _metricColumn(
                                      icon: Icons.groups_outlined,
                                      label: 'Capacity',
                                      value: '${(event['appliedAthletes'] is List) ? (event['appliedAthletes'] as List).length : (event['registeredCount'] ?? 0)} / ${event['capacity'] ?? '64'} Athletes',
                                    ),
                                  ),
                                  Container(height: 36, width: 1, color: AppTheme.borderSubtle),
                                  Expanded(
                                    child: _metricColumn(
                                      icon: Icons.verified_outlined,
                                      label: 'Sanctioning',
                                      value: 'IFA / WAF Certified',
                                      badgeAsset: ArmSphereAssets.sealFed,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Athlete Weight Categories (Left/Right Arm) & Awards/Prizes Summary Card
                        _buildAthleteCategoriesAndAwardsCard(context, event),
                        const SizedBox(height: 16),

                        // Zero-Error Optimistic Apply / Register Card (with Local Tournament QR Generation)
                        _buildZeroErrorAthleteApplyCard(context, event),
                        const SizedBox(height: 16),

                        // Buying / Clicking for Spectating & Verification by QR or Name
                        _buildOfflineSpectatorPassAndVerificationCard(context, event),
                        const SizedBox(height: 16),

                        // 2. Weight & Division Tactical Filter Tray (Cat N)
                        _buildCategoryFilterTray(),
                        const SizedBox(height: 16),

                        // 2b. Official Spectator & VIP Event Passes
                        _buildEventPassesSection(context, event),
                        const SizedBox(height: 16),

                        // 3. Multi-Table Live Arena Status Grid (SIG-1)
                        _buildLiveArenaTables(context),
                        const SizedBox(height: 16),

                        // 4. Event Description Card (if available)
                        if ((event['description']?.toString() ?? '').isNotEmpty) ...[
                          ElevatedActionCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: AppTheme.goldPrimary),
                                    SizedBox(width: 8),
                                    Text(
                                      'Event Overview',
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  event['description'].toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.6,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Host Sanctioning Organization / Independent Promotion Pill
                        ElevatedActionCard(
                          borderColor: AppTheme.goldPrimary.withValues(alpha: 0.35),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.push(
                              isIndependentPromotion
                                  ? '/organizations'
                                  : '/organizations/$hostOrgId',
                            );
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shield_rounded,
                                color: AppTheme.goldPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isIndependentPromotion
                                          ? 'INDEPENDENT PROMOTION'
                                          : 'HOST SANCTIONING ORGANIZATION',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: AppTheme.goldPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hostOrgName,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusChip(
                                label: isIndependentPromotion
                                    ? 'INDEPENDENT PROMOTION'
                                    : 'SANCTIONED',
                                color: isIndependentPromotion
                                    ? AppTheme.cyan
                                    : AppTheme.goldPrimary,
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                color: AppTheme.textMuted,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Athlete Event QR Passport Quick-Access Card
                        ElevatedActionCard(
                          borderColor: AppTheme.emerald.withValues(alpha: 0.45),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.push('/tournament/${widget.tournamentId}/qr');
                          },
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.emerald.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  color: AppTheme.emerald,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'My Event QR Passport',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Present your cryptographic QR pass at the weigh-in scale',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const StatusChip(
                                label: 'SHOW QR',
                                color: AppTheme.emerald,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Organizer / Operations Console Access (strictly gated by Invariant 1 & 2)
                        if (canOperate) ...[
                          ElevatedActionCard(
                            borderColor: AppTheme.goldPrimary.withValues(alpha: 0.4),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.push('/tournament/${widget.tournamentId}/operations');
                            },
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0x73D4AF37), width: 1.0),
                                  ),
                                  child: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.goldPrimary, size: 22),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Event Operations Console',
                                        style: TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Weigh-ins, bracket seeds & scorekeeping',
                                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Championship Awards Ceremony Card (Canary 10)
                        if (status == 'COMPLETED') ...[
                          ElevatedActionCard(
                            borderColor: AppTheme.goldPrimary,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.push('/tournament/${widget.tournamentId}/awards');
                            },
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0x73D4AF37), width: 1.0),
                                  ),
                                  child: const Icon(Icons.workspace_premium_rounded, color: AppTheme.goldPrimary, size: 24),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Championship Awards & Podium',
                                        style: TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Official gold, silver & bronze medalist ceremony',
                                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppTheme.goldPrimary, size: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 4. Important Dates Timeline Widget
                        ImportantDatesTimelineWidget(tournament: event),
                        const SizedBox(height: 16),

                        // 5. Rulebook Accordion Widget
                        RulebookAccordionWidget(tournament: event),
                        const SizedBox(height: 16),

                        // 6. Venue & Location Details
                        if (location.isNotEmpty) ...[
                          ElevatedActionCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.stadium_outlined, size: 16, color: AppTheme.goldPrimary),
                                    SizedBox(width: 8),
                                    Text(
                                      'Venue & Arena Information',
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  (event['venue'] ?? event['venueName'] ?? 'Sanctioned Competition Facility').toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  location,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                if (event['venueAddress'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    event['venueAddress'].toString(),
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Extra bottom padding to avoid sticky bar occlusion
                        const SizedBox(height: 96),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
            ],
          ),
          bottomNavigationBar: StickyBottomActionBar(
            primaryActionLabel: canRegister
                ? 'Apply / Register to Compete'
                : (status == 'ONGOING'
                    ? 'Track Live Matches'
                    : (status == 'COMPLETED' ? 'View Awards & Ceremony' : 'Registration Closed')),
            primaryActionIcon: canRegister
                ? Icons.how_to_reg
                : (status == 'COMPLETED'
                    ? Icons.workspace_premium_rounded
                    : (status == 'ONGOING' ? Icons.sports_kabaddi : Icons.emoji_events_outlined)),
            onPrimaryAction: canRegister
                ? () {
                    HapticFeedback.selectionClick();
                    _openOptimisticApplyModal(context, event);
                  }
                : (status == 'COMPLETED'
                    ? () {
                        HapticFeedback.selectionClick();
                        context.push('/tournament/${widget.tournamentId}/awards');
                      }
                    : (status == 'ONGOING'
                        ? () {
                            HapticFeedback.selectionClick();
                            setState(() => _activeAthleteTab = 1);
                          }
                        : null)),
            secondaryAction: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _activeAthleteTab = _activeAthleteTab == 0 ? 1 : 0);
              },
              icon: Icon(
                _activeAthleteTab == 0 ? Icons.account_tree_outlined : Icons.event_note_rounded,
                size: 16,
              ),
              label: Text(_activeAthleteTab == 0 ? 'Matchups & Podium' : 'Back to Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.borderSubtle),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
              ),
            ),
          ),
        );
  }

  String _formatPkrEntryFee(Map<String, dynamic> event) {
    final feePkr = (event['entryFeePkr'] as num?)?.toInt();
    if (feePkr != null) {
      return feePkr <= 0 ? 'FREE (0 PKR)' : 'PKR $feePkr';
    }
    return formatEventFee(event['registrationFeeCents']);
  }

  Widget _buildAthleteCategoriesAndAwardsCard(
    BuildContext context,
    Map<String, dynamic> event,
  ) {
    final weightCategories = (event['weightCategories'] is List)
        ? (event['weightCategories'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[
            {'weightLabel': '70 kg', 'arm': 'BOTH'},
            {'weightLabel': '80 kg', 'arm': 'BOTH'},
            {'weightLabel': '90 kg', 'arm': 'RIGHT'},
            {'weightLabel': 'Open', 'arm': 'BOTH'},
          ];
    final awardsConfig = (event['awardsConfig'] is Map)
        ? Map<String, dynamic>.from(event['awardsConfig'] as Map)
        : <String, dynamic>{
            'firstPlacePrize': 'PKR 50,000 + Gold Championship Medal & Certificate',
            'secondPlacePrize': 'PKR 25,000 + Silver Medal & Certificate',
            'thirdPlacePrize': 'PKR 10,000 + Bronze Medal & Certificate',
            'championOfChampionsPrize': 'Custom ArmSphere Championship Title Belt',
          };

    return ElevatedActionCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppTheme.goldPrimary.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fitness_center_rounded, size: 16, color: AppTheme.goldPrimary),
              SizedBox(width: 8),
              Text(
                'WEIGHT CATEGORIES (LEFT / RIGHT ARM) & PRIZES',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppTheme.goldPrimary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in weightCategories)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidian,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    '${cat['weightLabel'] ?? 'Open'} • ${(cat['arm'] ?? 'BOTH') == 'BOTH' ? 'Left & Right Arm' : '${cat['arm']} Arm'}',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0x22FFFFFF)),
          const SizedBox(height: 12),
          const Text(
            'OFFICIAL AWARDS & PRIZES:',
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.emerald,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '• 1st Place: ${awardsConfig['firstPlacePrize'] ?? 'Gold Medal & Cash Prize'}\n'
            '• 2nd Place: ${awardsConfig['secondPlacePrize'] ?? 'Silver Medal & Cash Prize'}\n'
            '• 3rd Place: ${awardsConfig['thirdPlacePrize'] ?? 'Bronze Medal & Cash Prize'}\n'
            '• Overall Champion: ${awardsConfig['championOfChampionsPrize'] ?? 'Championship Belt'}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openOptimisticApplyModal(
    BuildContext context,
    Map<String, dynamic> event,
  ) async {
    final weightCategories = (event['weightCategories'] is List &&
            (event['weightCategories'] as List).isNotEmpty)
        ? (event['weightCategories'] as List)
            .whereType<Map>()
            .map((e) => (e['weightLabel'] ?? '80 kg').toString())
            .toSet()
            .toList()
        : <String>['70 kg', '80 kg', '90 kg', 'Open'];

    String selectedWeight = weightCategories.first;
    String selectedArm = 'RIGHT';
    int guestCount = 0;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.viewInsetsOf(ctx).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.how_to_reg_rounded, color: AppTheme.goldPrimary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'APPLY / REGISTER TO COMPETE',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const StatusChip(
                        label: 'OFFLINE-SAFE',
                        color: AppTheme.emerald,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Entry Fee: ${_formatPkrEntryFee(event)} • Instant local save & QR generation even if offline.',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedWeight,
                    decoration: const InputDecoration(
                      labelText: 'Select Weight Category',
                      prefixIcon: Icon(Icons.scale_outlined, size: 18),
                    ),
                    items: [
                      for (final w in weightCategories)
                        DropdownMenuItem(value: w, child: Text(w)),
                    ],
                    onChanged: (v) => setSheetState(() => selectedWeight = v ?? selectedWeight),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedArm,
                    decoration: const InputDecoration(
                      labelText: 'Select Competition Arm / Hand',
                      prefixIcon: Icon(Icons.front_hand_outlined, size: 18),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'RIGHT', child: Text('Right Arm Division')),
                      DropdownMenuItem(value: 'LEFT', child: Text('Left Arm Division')),
                      DropdownMenuItem(value: 'BOTH', child: Text('Both Arms (Left & Right)')),
                    ],
                    onChanged: (v) => setSheetState(() => selectedArm = v ?? 'RIGHT'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Additional Spectator Guests (Optional)',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textPrimary),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: guestCount > 0
                                ? () => setSheetState(() => guestCount--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$guestCount',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                          IconButton(
                            onPressed: guestCount < 5
                                ? () => setSheetState(() => guestCount++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      key: const ValueKey('athlete_optimistic_submit_apply_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        HapticFeedback.heavyImpact();
                        final auth = ref.read(authProvider);
                        final profile = auth.userProfile ?? {};
                        final athleteId =
                            (profile['id'] ?? profile['userId'] ?? 'ath-pk-local').toString();
                        final athleteName = (profile['displayName'] ??
                                profile['name'] ??
                                'ArmSphere Athlete')
                            .toString();
                        final hive = ref.read(hiveStorageProvider);
                        OfflineSyncManager? syncManager;
                        try {
                          syncManager = ref.read(offlineSyncManagerProvider);
                        } catch (_) {}

                        final submitted =
                            await TournamentOfflineStore.submitAthleteApplicationOfflineSafe(
                          hive: hive,
                          syncManager: syncManager,
                          tournamentId: widget.tournamentId,
                          athleteId: athleteId,
                          athleteName: athleteName,
                          weightCategory: selectedWeight,
                          arm: selectedArm,
                          guestCount: guestCount,
                          elo: (profile['elo'] as num?)?.toInt() ?? 1820,
                        );
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (mounted) {
                          setState(() {
                            _localSubmittedApplication = submitted;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            CrystalSnackBar(
                              content: Text(
                                'Submitted / Done ✓ • Registered for $selectedWeight ($selectedArm Arm). Local Tournament QR generated & queued for auto-sync!',
                              ),
                              backgroundColor: AppTheme.emerald,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text(
                        'SUBMIT APPLICATION (INSTANT OFFLINE-SAFE)',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
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

  Widget _buildZeroErrorAthleteApplyCard(
    BuildContext context,
    Map<String, dynamic> event,
  ) {
    final app = _localSubmittedApplication;
    return ElevatedActionCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppTheme.emerald.withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppTheme.emerald, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ATHLETE REGISTRATION & TOURNAMENT QR PASS',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: AppTheme.emerald,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              StatusChip(
                label: app != null ? 'SUBMITTED / DONE ✓' : 'OPEN',
                color: AppTheme.emerald,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (app != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.recessedObsidianWellDecoration(radius: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ArmSphereQrMatrixView(
                      data: (app['qrCode'] ?? 'ARMSPHERE-QR').toString(),
                      size: 86,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SUBMITTED / DONE ✓',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            color: AppTheme.emerald,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${app['athleteName']} • ${app['registeredWeightLabel']} (${app['registeredArm']} Arm)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'QR: ${app['qrCode']}\nSaved locally & auto-syncing in background.',
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
            const SizedBox(height: 10),
          ] else
            const Text(
              'Select your Weight Category and Arm/Hand to apply. Works 100% offline — immediately saves locally and generates your Tournament QR Code.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldPrimary,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _openOptimisticApplyModal(context, event),
                  icon: const Icon(Icons.how_to_reg_rounded, size: 17),
                  label: Text(
                    app != null ? 'UPDATE / ADD CATEGORY' : 'APPLY / REGISTER NOW',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/tournament/${widget.tournamentId}/register'),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text(
                  'FULL FORM',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineSpectatorPassAndVerificationCard(
    BuildContext context,
    Map<String, dynamic> event,
  ) {
    final spectatorEnabled = event['spectatorEnabled'] != false;
    if (!spectatorEnabled) return const SizedBox.shrink();

    final passPricePkr = (event['spectatorTicketPricePkr'] as num?)?.toInt() ?? 0;
    final pass = _localIssuedSpectatorPass;

    return ElevatedActionCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppTheme.cyan.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number_rounded, color: AppTheme.cyan, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'SPECTATING & ENTRANCE VERIFICATION (QR OR NAME)',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.5,
                    color: AppTheme.cyan,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              StatusChip(
                label: passPricePkr <= 0 ? 'FREE SPECTATING' : 'PKR $passPricePkr PASS',
                color: AppTheme.cyan,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (pass != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.recessedObsidianWellDecoration(radius: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ArmSphereQrMatrixView(
                      data: (pass['qrCode'] ?? 'ARMSPHERE-SPEC').toString(),
                      size: 72,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SPECTATOR PASS ISSUED ✓',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: AppTheme.emerald,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Holder: ${pass['holderName']} • ${pass['qrCode']}',
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final auth = ref.read(authProvider);
              final profile = auth.userProfile ?? {};
              final userId = (profile['id'] ?? 'spec-local-01').toString();
              final userName =
                  (profile['displayName'] ?? profile['name'] ?? 'Arena Spectator').toString();
              final hive = ref.read(hiveStorageProvider);
              OfflineSyncManager? syncManager;
              try {
                syncManager = ref.read(offlineSyncManagerProvider);
              } catch (_) {}

              final issued = await TournamentOfflineStore.claimOrPurchaseSpectatorPassOfflineSafe(
                hive: hive,
                syncManager: syncManager,
                tournamentId: widget.tournamentId,
                userId: userId,
                userName: userName,
                pricePkr: passPricePkr,
              );
              if (mounted) {
                setState(() => _localIssuedSpectatorPass = issued);
                ScaffoldMessenger.of(context).showSnackBar(
                  CrystalSnackBar(
                    content: Text(
                      'Submitted / Done ✓ • Spectator Pass (${issued['qrCode']}) saved locally & synced!',
                    ),
                    backgroundColor: AppTheme.emerald,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.qr_code_2_rounded, size: 18),
            label: Text(
              passPricePkr <= 0
                  ? 'GET FREE SPECTATOR QR PASS (OFFLINE-SAFE)'
                  : 'BUY SPECTATOR PASS (PKR $passPricePkr • OFFLINE-SAFE)',
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _entranceVerifyCtrl,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Verify Athlete / Spectator by QR Code or Name',
              hintText: 'Scan/paste QR code or type name (e.g. Malik Sherbaz)...',
              prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.cyan),
              suffixIcon: IconButton(
                icon: const Icon(Icons.verified_rounded, color: AppTheme.emerald),
                onPressed: () async {
                  final hive = ref.read(hiveStorageProvider);
                  OfflineSyncManager? syncManager;
                  try {
                    syncManager = ref.read(offlineSyncManagerProvider);
                  } catch (_) {}
                  final res = await TournamentOfflineStore.verifyEntranceByQrOrNameOfflineSafe(
                    hive: hive,
                    syncManager: syncManager,
                    tournamentId: widget.tournamentId,
                    query: _entranceVerifyCtrl.text,
                  );
                  if (mounted) {
                    setState(() => _entranceVerifyResult = res);
                  }
                },
              ),
            ),
          ),
          if (_entranceVerifyResult != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (_entranceVerifyResult!['verified'] == true)
                    ? AppTheme.emerald.withValues(alpha: 0.15)
                    : AppTheme.crimson.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (_entranceVerifyResult!['verified'] == true)
                      ? AppTheme.emerald
                      : AppTheme.crimson,
                ),
              ),
              child: Text(
                (_entranceVerifyResult!['message'] ?? '').toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: (_entranceVerifyResult!['verified'] == true)
                      ? AppTheme.emerald
                      : AppTheme.crimson,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAthleteReadOnlyMatchupsAndPodiumTab(
    BuildContext context,
    Map<String, dynamic> event,
  ) {
    final matchups = (event['matchups'] is List)
        ? (event['matchups'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    final categories = <String>{
      'ALL',
      for (final m in matchups)
        if ((m['categoryLabel'] ?? '').toString().trim().isNotEmpty)
          (m['categoryLabel'] ?? '').toString(),
    }.toList();

    final rounds = <int>{
      0,
      for (final m in matchups) (m['roundNumber'] as num?)?.toInt() ?? 1,
    }.toList()
      ..sort();

    final filtered = matchups.where((m) {
      if (_selectedMatchupCategoryFilter != 'ALL' &&
          (m['categoryLabel'] ?? '').toString() != _selectedMatchupCategoryFilter) {
        return false;
      }
      if (_selectedMatchupRoundFilter > 0 &&
          ((m['roundNumber'] as num?)?.toInt() ?? 1) != _selectedMatchupRoundFilter) {
        return false;
      }
      return true;
    }).toList();

    final completedFinals = matchups.where((m) {
      final s = (m['status'] ?? '').toString().toUpperCase();
      return (s == 'DONE' || s == 'COMPLETED') && (m['winnerName'] ?? '').toString().isNotEmpty;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Final Podium Winners Summary Card (Read-Only for Athletes)
        ElevatedActionCard(
          padding: const EdgeInsets.all(16),
          borderColor: AppTheme.goldPrimary.withValues(alpha: 0.55),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: AppTheme.goldPrimary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'FINAL PODIUM & LIVE WINNERS STANDINGS',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        color: AppTheme.goldPrimary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  StatusChip(
                    label: 'READ-ONLY LIVE VIEW',
                    color: AppTheme.emerald,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (completedFinals.isEmpty)
                const Text(
                  'Podium standings (1st Gold, 2nd Silver, 3rd Bronze) update automatically as category rounds and finals are completed.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                )
              else
                for (final done in completedFinals.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded,
                            color: AppTheme.goldPrimary, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${done['categoryLabel'] ?? 'Category'} • Winner: ${done['winnerName']} (vs ${done['winnerId'] == done['player1Id'] ? done['player2Name'] : done['player1Name']})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Category & Round Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final cat in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _selectedMatchupCategoryFilter == cat,
                    selectedColor: AppTheme.goldPrimary.withValues(alpha: 0.22),
                    label: Text(
                      cat,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                    onSelected: (_) => setState(() => _selectedMatchupCategoryFilter = cat),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final r in rounds)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _selectedMatchupRoundFilter == r,
                    selectedColor: AppTheme.emerald.withValues(alpha: 0.22),
                    label: Text(
                      r == 0 ? 'All Rounds' : 'Round $r',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    onSelected: (_) => setState(() => _selectedMatchupRoundFilter = r),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Read-Only Matchup Cards with Table Badges, Rounds, Loss Badges, and Live Results
        for (final m in filtered)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ElevatedActionCard(
              padding: const EdgeInsets.all(14),
              borderColor: ((m['status'] ?? '').toString().toUpperCase() == 'DONE')
                  ? AppTheme.emerald.withValues(alpha: 0.5)
                  : AppTheme.goldPrimary.withValues(alpha: 0.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusChip(
                        label: 'TABLE ${m['tableNumber'] ?? 1}',
                        color: AppTheme.goldPrimary,
                        icon: Icons.table_restaurant_rounded,
                      ),
                      const SizedBox(width: 6),
                      StatusChip(
                        label: 'ROUND ${m['roundNumber'] ?? 1}',
                        color: AppTheme.cyan,
                      ),
                      const Spacer(),
                      StatusChip(
                        label: (m['status'] ?? 'PENDING').toString().toUpperCase(),
                        color: ((m['status'] ?? '').toString().toUpperCase() == 'DONE')
                            ? AppTheme.emerald
                            : AppTheme.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (m['categoryLabel'] ?? 'Open Division').toString(),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (m['player1Name'] ?? 'Athlete 1').toString(),
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Elo ${m['player1Elo'] ?? 1800} • ${m['player1Losses'] ?? 0} Loss(es)',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              (m['player2Name'] ?? 'Athlete 2').toString(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Elo ${m['player2Elo'] ?? 1800} • ${m['player2Losses'] ?? 0} Loss(es)',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if ((m['winnerName'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded, size: 15, color: AppTheme.emerald),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Winner: ${m['winnerName']} (${m['scoreLine'] ?? 'Official Result'})',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.emerald,
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
          ),
      ],
    );
  }

  Widget _metricColumn({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
    String? badgeAsset,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (badgeAsset != null) ...[
                ArmSphereImage(
                  assetPath: badgeAsset,
                  width: 14,
                  height: 14,
                  semanticLabel: '$label official seal',
                ),
                const SizedBox(width: 4),
              ] else ...[
                Icon(icon, size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isHighlighted ? AppTheme.goldPrimary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterTray() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.tune, size: 14, color: AppTheme.goldPrimary),
            SizedBox(width: 6),
            Text(
              'Weight & Division Filter',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = cat == _selectedCategory;
              return TactilePressWrapper(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = cat);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: isSelected ? const Color(0x73D4AF37) : const Color(0x2EFFFFFF),
                      width: isSelected ? 1.2 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: isSelected ? AppTheme.goldPrimary : const Color(0xFFCBD5E1),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventPassesSection(BuildContext context, Map<String, dynamic> event) {
    final ticketTypesAsync = ref.watch(ticketTypesProvider(widget.tournamentId));

    return ticketTypesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (rawTiers) {
        final List<Map<String, dynamic>> tiers = rawTiers.isNotEmpty
            ? rawTiers
            : [
                {
                  'id': 'spectator-${widget.tournamentId}',
                  'name': 'General Arena Spectator Pass',
                  'priceCents': 2500,
                  'remainingQuantity': 120,
                  'quantityAvailable': 150,
                  'isFallback': true,
                },
                {
                  'id': 'vip-${widget.tournamentId}',
                  'name': 'VIP Ringside & Pit Access Pass',
                  'priceCents': 7500,
                  'remainingQuantity': 24,
                  'quantityAvailable': 30,
                  'isFallback': true,
                },
              ];

        return ElevatedActionCard(
          padding: const EdgeInsets.all(16),
          borderColor: AppTheme.goldPrimary.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: 16, color: AppTheme.goldPrimary),
                      SizedBox(width: 8),
                      Text(
                        'Spectator & VIP Arena Passes',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.push('/settings/tickets');
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 14, color: AppTheme.goldPrimary),
                    label: const Text(
                      'My Passes',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < tiers.length; i++) ...[
                if (i > 0) const Divider(height: 18, thickness: 1, color: Color(0x22FFFFFF)),
                Builder(
                  builder: (context) {
                    final tier = tiers[i];
                    final tierId = tier['id']?.toString() ?? '';
                    final tierName = tier['name']?.toString() ?? 'Event Pass';
                    final priceCents = (tier['priceCents'] is num)
                        ? (tier['priceCents'] as num).toInt()
                        : int.tryParse('${tier['priceCents'] ?? 0}') ?? 0;
                    final remaining = (tier['remainingQuantity'] is num)
                        ? (tier['remainingQuantity'] as num).toInt()
                        : ((tier['quantityAvailable'] is num) ? (tier['quantityAvailable'] as num).toInt() : 50);
                    final isSoldOut = remaining <= 0;
                    final isFallback = tier['isFallback'] == true;

                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tierName,
                                style: const TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${formatEventFee(priceCents)} • ${isSoldOut ? 'SOLD OUT' : '$remaining passes remaining'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSoldOut ? AppTheme.error : AppTheme.textSecondary,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isSoldOut
                              ? null
                              : () async {
                                  HapticFeedback.mediumImpact();
                                  try {
                                    if (!isFallback && tierId.isNotEmpty) {
                                      await ref.read(tournamentRepositoryProvider).purchaseTicket(
                                            ticketTypeId: tierId,
                                          );
                                    }
                                    ref.invalidate(ticketTypesProvider(widget.tournamentId));
                                    ref.invalidate(myTicketsProvider);
                                    if (context.mounted) {
                                      CrystalToast.show(
                                        context,
                                        title: 'Pass Issued',
                                        message: '$tierName added to your Official Passes wallet.',
                                        type: CrystalToastType.success,
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      CrystalToast.show(
                                        context,
                                        title: 'Pass Reservation Queued',
                                        message: 'Unable to complete live pass checkout: $e',
                                        type: CrystalToastType.warning,
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppTheme.goldPrimary,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            side: const BorderSide(color: Color(0x73D4AF37), width: 1.0),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: const Size(88, 34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                          ),
                          child: Text(
                            isSoldOut ? 'SOLD OUT' : 'GET PASS',
                            style: const TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.5,
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
        );
      },
    );
  }

  Widget _buildLiveArenaTables(BuildContext context) {
    final liveTablesAsync = ref.watch(eventLiveArenaTablesProvider(widget.tournamentId));

    return liveTablesAsync.when(
      loading: () => RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildArenaTableHeader(activeCount: null, isLoading: true),
            const SizedBox(height: 12),
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x38FFFFFF), width: 1.0),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildArenaTableHeader(activeCount: 0, isLoading: false),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x38FFFFFF), width: 1.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Could not load live arena tables',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(eventLiveArenaTablesProvider(widget.tournamentId)),
                    child: const Text('Retry', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      data: (tables) {
        final filteredTables = tables.where((t) => _matchesCategory(
          _selectedCategory,
          t['weightClass']?.toString() ?? '',
          t['division']?.toString() ?? '',
        )).toList();

        final activeCount = tables.length;

        return RepaintBoundary(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArenaTableHeader(activeCount: activeCount, isLoading: false),
              const SizedBox(height: 12),
              if (tables.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x38FFFFFF), width: 1.0),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.sports_kabaddi, size: 36, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 10),
                      const Text(
                        'No Live Arena Tables Active',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Arena tables will appear here once matches are called to the table.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ] else if (filteredTables.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x38FFFFFF), width: 1.0),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.tune, size: 32, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 10),
                      Text(
                        'No Live Tables in $_selectedCategory',
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select "ALL" to view active tables across all divisions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                for (int i = 0; i < filteredTables.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _buildArenaTableCard(
                    context: context,
                    tableNumber: filteredTables[i]['tableNumber']?.toString() ?? 'TABLE ${i + 1}',
                    stageName: filteredTables[i]['stageName']?.toString() ?? 'Main Stage',
                    status: filteredTables[i]['status']?.toString() ?? 'IN BOUT',
                    statusColor: _resolveArenaStatusColor(filteredTables[i]['status']?.toString() ?? ''),
                    weightClass: filteredTables[i]['weightClass']?.toString() ?? '',
                    redCornerName: filteredTables[i]['redCornerName']?.toString() ?? 'TBD',
                    redCornerCountry: filteredTables[i]['redCornerCountry']?.toString() ?? '',
                    blueCornerName: filteredTables[i]['blueCornerName']?.toString() ?? 'TBD',
                    blueCornerCountry: filteredTables[i]['blueCornerCountry']?.toString() ?? '',
                    isLive: filteredTables[i]['isLive'] == true,
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildArenaTableHeader({required int? activeCount, bool isLoading = false}) {
    final hasActive = (activeCount ?? 0) > 0;
    final badgeColor = hasActive ? AppTheme.verifiedEmerald : AppTheme.textMuted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.sports_kabaddi, size: 16, color: AppTheme.goldPrimary),
            SizedBox(width: 8),
            Text(
              'Live Arena Tables',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: badgeColor),
              const SizedBox(width: 5),
              Text(
                isLoading
                    ? 'SYNCING TABLES'
                    : (hasActive
                        ? '$activeCount TABLE${activeCount == 1 ? '' : 'S'} ACTIVE'
                        : '0 TABLES ACTIVE'),
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _matchesCategory(String filter, String weightClassFormatted, String division) {
    if (filter == 'ALL') return true;
    final f = filter.toUpperCase().replaceAll(' ', '');
    final w = weightClassFormatted.toUpperCase().replaceAll(' ', '');
    final d = division.toUpperCase().replaceAll(' ', '');
    if (w.contains(f) || d.contains(f)) return true;

    final tokens = filter.toUpperCase().split(' ').where((s) => s.isNotEmpty);
    return tokens.every((token) =>
        weightClassFormatted.toUpperCase().contains(token) ||
        division.toUpperCase().contains(token));
  }

  Color _resolveArenaStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'IN BOUT':
        return AppTheme.verifiedEmerald;
      case 'ON DECK':
        return const Color(0xFFF59E0B); // Amber
      case 'READY':
        return AppTheme.goldPrimary; // Gold
      default:
        return AppTheme.textMuted;
    }
  }

  Widget _buildArenaTableCard({
    required BuildContext context,
    required String tableNumber,
    required String stageName,
    required String status,
    required Color statusColor,
    required String weightClass,
    required String redCornerName,
    required String redCornerCountry,
    required String blueCornerName,
    required String blueCornerCountry,
    required bool isLive,
  }) {
    final semanticLabel = '$tableNumber, $stageName, $status, $weightClass. Red corner: $redCornerName. Blue corner: $blueCornerName.';
    return Semantics(
      label: semanticLabel,
      button: true,
      child: TactilePressWrapper(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/tournament/${widget.tournamentId}/brackets');
        },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLive ? const Color(0x6610B981) : const Color(0x38FFFFFF),
            width: isLive ? 1.2 : 1.0,
          ),
          boxShadow: const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(color: const Color(0x73D4AF37), width: 1.0),
                      ),
                      child: Text(
                        tableNumber,
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.goldPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      stageName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: statusColor.withValues(alpha: 0.55), width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLive) ...[
                        const Icon(Icons.circle, size: 6, color: AppTheme.verifiedEmerald),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        status,
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              weightClass,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.competitionCrimson,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          redCornerCountry.isNotEmpty
                              ? '$redCornerName ($redCornerCountry)'
                              : redCornerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.electricCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          blueCornerCountry.isNotEmpty
                              ? '$blueCornerName ($blueCornerCountry)'
                              : blueCornerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Tournament Brackets Screen — real data from GET /tournaments/events/:id/brackets.
class TournamentBracketsScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentBracketsScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentBracketsScreen> createState() => _TournamentBracketsScreenState();
}

class _TournamentBracketsScreenState extends ConsumerState<TournamentBracketsScreen> {
  String? _selectedBracketId;
  bool _isSpatialView = true;

  @override
  Widget build(BuildContext context) {
    final effectiveTournamentId = widget.tournamentId.isNotEmpty
        ? widget.tournamentId
        : (ref.watch(tournamentProvider).valueOrNull?.firstOrNull?['id']?.toString() ?? '');

    final bracketsAsync = effectiveTournamentId.isNotEmpty
        ? ref.watch(eventBracketsProvider(effectiveTournamentId))
        : const AsyncValue<List<dynamic>>.loading();

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 4,
        flexibleSpace: const CrystalHeaderStageBar(domain: ArmSphereStageDomain.events),
        leading: const CrystalBackButton(fallbackRoute: '/tournaments'),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Tournament Brackets',
            style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700),
          ),
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(_isSpatialView ? Icons.view_list_rounded : Icons.account_tree_rounded),
            tooltip: _isSpatialView ? 'Switch to List View' : 'Switch to Spatial Tree',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _isSpatialView = !_isSpatialView);
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            tooltip: 'Refresh Brackets',
            onPressed: () {
              HapticFeedback.selectionClick();
              if (effectiveTournamentId.isNotEmpty) {
                ref.invalidate(eventBracketsProvider(effectiveTournamentId));
              }
              if (_selectedBracketId != null) {
                ref.invalidate(bracketDetailsProvider(_selectedBracketId!));
              }
            },
          ),
          const CrystalHomeButton(),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.events),
          ),
          bracketsAsync.when(
            loading: () => const CrystalScreenLoadingView(itemCount: 3, cardHeight: 112),
            error: (e, _) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 80),
                const Center(child: Icon(Icons.error_outline, size: 44, color: AppTheme.error)),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Could not load brackets',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.textPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => ref.invalidate(eventBracketsProvider(widget.tournamentId)),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                ),
              ],
            ),
            data: (brackets) {
              if (brackets.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 140, 20, 32),
                  children: [
                    ElevatedActionCard(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.account_tree_outlined,
                              size: 38,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No brackets published yet.',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Matchups will appear once tournament directors generate brackets.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              if (effectiveTournamentId.isNotEmpty) {
                                ref.invalidate(eventBracketsProvider(effectiveTournamentId));
                              }
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.goldPrimary),
                            label: const Text(
                              'SYNC BRACKETS',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                color: AppTheme.goldPrimary,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              final selected = _selectedBracketId != null &&
                      brackets.any((b) => b['id']?.toString() == _selectedBracketId)
                  ? _selectedBracketId!
                  : brackets.first['id']?.toString();

              return Column(
                children: [
                  // Bracket selector — one chip per category bracket.
                  Container(
                    height: 52,
                    color: Colors.transparent,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        for (final b in brackets)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                '${b['division'] ?? ''} ${b['weightClass'] ?? ''} ${b['arm'] ?? ''}'.trim(),
                                style: TextStyle(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 12,
                                  color: b['id']?.toString() == selected
                                      ? AppTheme.goldPrimary
                                      : const Color(0xFFCBD5E1),
                                  fontWeight: b['id']?.toString() == selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              selected: b['id']?.toString() == selected,
                              backgroundColor: Colors.transparent,
                              selectedColor: Colors.transparent,
                              surfaceTintColor: Colors.transparent,
                              side: BorderSide(
                                color: b['id']?.toString() == selected
                                    ? const Color(0x73D4AF37)
                                    : const Color(0x2EFFFFFF),
                                width: b['id']?.toString() == selected ? 1.2 : 1.0,
                              ),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedBracketId = b['id']?.toString());
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildBracketMatches(selected)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBracketMatches(String? bracketId) {
    if (bracketId == null || bracketId.isEmpty) {
      return const Center(child: Text('Select a bracket.', style: TextStyle(color: AppTheme.textMuted)));
    }
    final detailAsync = ref.watch(bracketDetailsProvider(bracketId));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(bracketDetailsProvider(bracketId)),
      child: detailAsync.when(
        loading: () => const CrystalScreenLoadingView(itemCount: 3, cardHeight: 112),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Could not load bracket: $e', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => ref.invalidate(bracketDetailsProvider(bracketId)),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
        data: (bracket) {
          final status = (bracket['status']?.toString() ?? '').toUpperCase();
          final matches = (bracket['matches'] as List?) ?? const [];
          if (matches.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ElevatedActionCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_empty, color: AppTheme.goldPrimary, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.isEmpty ? 'Bracket Pending' : 'Status: $status',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Matchups appear once the organizer generates them.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          if (_isSpatialView) {
            final matchesList = matches
                .map((m) => Map<String, dynamic>.from(m as Map))
                .toList();
            final format = bracket['format']?.toString().toUpperCase() ?? '';
            final prefix = format == 'DOUBLE_ELIMINATION' ? 'WINNERS' : 'BRACKET';
            return BracketTreeWidget(
              matches: matchesList,
              titlePrefix: prefix,
            );
          }

          // Group by round for honest round-by-round rendering.
          final rounds = <int, List<Map<String, dynamic>>>{};
          for (final raw in matches) {
            final m = Map<String, dynamic>.from(raw);
            final round = (m['round'] as num?)?.toInt() ?? 0;
            rounds.putIfAbsent(round, () => []).add(m);
          }
          final sortedRounds = rounds.keys.toList()..sort();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedRounds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final round = sortedRounds[index];
              final roundMatches = rounds[round]!
                ..sort((a, b) => ((a['matchIndex'] as num?)?.toInt() ?? 0)
                    .compareTo((b['matchIndex'] as num?)?.toInt() ?? 0));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(color: const Color(0x73D4AF37), width: 1.0),
                    ),
                    child: Text(
                      bracket['format']?.toString() == 'DOUBLE_ELIMINATION'
                          ? 'Round $round (${_bracketTypeLabel(roundMatches.first)})'
                          : 'Round $round',
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final m in roundMatches)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _matchCard(m),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _bracketTypeLabel(Map<String, dynamic> m) {
    switch ((m['bracketType']?.toString() ?? '').toUpperCase()) {
      case 'WINNERS':
        return 'Winners Bracket';
      case 'LOSERS':
        return 'Elimination Bracket';
      case 'GRAND_FINAL':
        return 'Grand Championship Final';
      default:
        return m['bracketType']?.toString() ?? '';
    }
  }

  Widget _matchCard(Map<String, dynamic> m) {
    final aName = m['athleteAName']?.toString() ?? 'TBD';
    final bName = m['athleteBName']?.toString() ?? 'TBD';
    final winnerId = m['winnerId']?.toString() ?? '';
    final aWins = winnerId.isNotEmpty && winnerId == (m['athleteAId']?.toString() ?? '');
    final bWins = winnerId.isNotEmpty && winnerId == (m['athleteBId']?.toString() ?? '');
    final scoreLine = m['scoreLine']?.toString() ?? '';
    final isCompleted = (m['status']?.toString().toUpperCase()) == 'COMPLETED';

    return ElevatedActionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  aName,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: aWins ? FontWeight.w800 : FontWeight.w500,
                    color: aWins ? AppTheme.goldPrimary : AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('vs', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ),
              Expanded(
                child: Text(
                  bName,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: bWins ? FontWeight.w800 : FontWeight.w500,
                    color: bWins ? AppTheme.goldPrimary : AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (m['athleteAElo'] != null || m['athleteBElo'] != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ELO ${(m['athleteAElo'] as num?)?.toInt() ?? '—'}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: 'Space Grotesk'),
                ),
                Text(
                  'ELO ${(m['athleteBElo'] as num?)?.toInt() ?? '—'}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: 'Space Grotesk'),
                ),
              ],
            ),
          ],
          const Divider(height: 16, thickness: 1, color: Color(0x22FFFFFF)),
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle_outline : Icons.schedule,
                size: 14,
                color: isCompleted ? AppTheme.success : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  scoreLine.isNotEmpty
                      ? '${m['status'] ?? ''} • $scoreLine'
                      : '${m['status'] ?? 'SCHEDULED'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isCompleted ? AppTheme.success : AppTheme.textMuted,
                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
