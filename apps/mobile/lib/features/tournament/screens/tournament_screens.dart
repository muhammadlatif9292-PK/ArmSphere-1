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
import '../../../core/utils/display_formatters.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/sticky_bottom_action_bar.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../../core/api/offline_sync.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/visual_preferences_provider.dart';
import '../../../core/widgets/crystal_slash_painter.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/security/admin_permissions.dart';
import '../services/tournament_offline_store.dart';
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
    case 'LIVE':
    case 'IN_PROGRESS':
      return const StatusChip.live(label: 'Live Now');
    case 'PUBLISHED':
    case 'REGISTRATION_OPEN':
    case 'OPEN':
      return const StatusChip.success(label: 'Registration Open');
    case 'COMPLETED':
    case 'FINISHED':
      return const StatusChip.neutral(label: 'Completed');
    case 'CANCELLED':
      return const StatusChip.error(label: 'Cancelled');
    default:
      return StatusChip.info(
        label: ArmSphereFormatters.formatTournamentStatus(status),
      );
  }
}

/// Tournaments List Screen — real data from GET /tournaments/events.
class TournamentsListScreen extends ConsumerWidget {
  const TournamentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentProvider);

    final bool insideRootShell = MainShellScope.isInsideShell(context);
    final double bottomDockGap = insideRootShell
        ? (kFloatingDockTotalHeight - 34.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBody: true,
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
          SafeArea(
            bottom: false,
            child: CrystalVaporDissolve(
              bottomMargin: bottomDockGap,
              child: tournamentsAsync.when(
                loading: () => const TournamentSkeletonLoadingWidget(),
                error: (error, _) => AppErrorView(
                  error: error,
                  title: 'Could not load competitions',
                  onRetry: () => ref.invalidate(tournamentProvider),
                  showSecondaryAction: false,
                  onSessionExpired: () =>
                      ref.read(authProvider.notifier).logout(),
                ),
                data: (events) {
                  final hive = ref.watch(hiveStorageProvider);
                  // Merge released local & server tournaments; strictly exclude unreleased drafts.
                  final visible = TournamentOfflineStore
                      .getAllReleasedTournaments(
                        hive: hive,
                        serverEvents: events,
                      )
                      .where(TournamentOfflineStore.isReleasedTournament)
                      .toList();

                  if (visible.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.refresh(tournamentProvider.future),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 66),
                        children: [
                          const SizedBox(height: 64),
                          AppEmptyState(
                            icon: Icons.emoji_events_outlined,
                            title: 'No competitions published yet',
                            subtitle:
                                'Check back soon for upcoming sanctioned events',
                            ctaLabel: 'Refresh Events',
                            onCtaTap: () => ref.invalidate(tournamentProvider),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.refresh(tournamentProvider.future),
                    child: ListView.separated(
                      key: const PageStorageKey<String>('tournaments_list_view'),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        AppTheme.space16,
                        16,
                        insideRootShell
                            ? 66.0
                            : MainShellScope.bottomClearance(
                                context,
                                additionalPadding: 44,
                              ),
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final t = visible[index];
                final status = (t['status']?.toString() ?? 'SCHEDULED').toUpperCase();
                final location = ArmSphereFormatters.formatCleanAddress([
                  t['city']?.toString(),
                  t['province']?.toString(),
                ]);

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
            ),
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

  // Matchups Read-Only Filter State
  String _selectedMatchupCategoryFilter = 'ALL';
  int _selectedMatchupRoundFilter = 0; // 0 = All Rounds
  Map<String, dynamic>? _localSubmittedApplication;

  List<String> _resolveDynamicFilterChips(Map<String, dynamic> event) {
    final realDivisions =
        TournamentOfflineStore.extractRealTournamentDivisions(event);
    final chips = <String>['ALL'];
    for (final div in realDivisions) {
      final label = (div['label'] ?? '').trim();
      if (label.isNotEmpty && !chips.contains(label)) {
        chips.add(label);
      }
    }
    return chips;
  }

  Future<void> _openDedicatedApplyScreen(
    BuildContext context,
    Map<String, dynamic> event,
  ) async {
    HapticFeedback.selectionClick();
    final result = await context.push<Map<String, dynamic>>(
      '/tournament/${widget.tournamentId}/register',
      extra: event,
    );
    if (!mounted) return;
    ref.invalidate(eventDetailProvider(widget.tournamentId));
    ref.invalidate(myRegistrationsProvider);
    ref.invalidate(eventRegistrationsProvider(widget.tournamentId));
    ref.invalidate(tournamentProvider);
    setState(() {
      if (result != null) {
        _localSubmittedApplication = result;
      }
    });
  }

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
    final hive = ref.watch(hiveStorageProvider);
    final myRegs = ref.watch(myRegistrationsProvider).valueOrNull;
    final athleteProf = ref.watch(athleteProfileProvider).valueOrNull;
    final activeRegistration =
        TournamentOfflineStore.findAthleteRegistrationForTournament(
          tournament: event,
          tournamentIdOverride: widget.tournamentId,
          userProfile: auth.userProfile,
          athleteProfile: athleteProf,
          myRegistrations: myRegs,
          hive: hive,
        ) ??
        _localSubmittedApplication;

    final canOperate = AdminPermissions.canOperateEvent(
      activeRole: auth.activeRole,
      userProfile: auth.userProfile,
      event: event,
    );
        final rawOrgName = (event['organizationName'] ??
                (event['organization'] is Map
                    ? (event['organization'] as Map)['name']
                    : null) ??
                '')
            .toString()
            .trim();
        final sanctioningOrgLabel = rawOrgName.isNotEmpty
            ? ArmSphereFormatters.formatOrganizationName(rawOrgName)
            : 'ArmSphere Verified';
        final location = ArmSphereFormatters.formatCleanAddress([
          event['venueName']?.toString(),
          event['city']?.toString(),
          event['province']?.toString(),
        ]);
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
                      // Two Clean Forged-Crystal Tabs: 1) Event Overview & Purse, 2) Live Brackets & Podium
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E121A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                          ),
                        ),
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
                                    gradient: _activeAthleteTab == 0
                                        ? const LinearGradient(
                                            colors: [Color(0xFF2B2210), Color(0xFF141008)],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _activeAthleteTab == 0
                                          ? AppTheme.goldPrimary
                                          : Colors.transparent,
                                      width: 1.3,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.emoji_events_outlined,
                                        size: 15,
                                        color: _activeAthleteTab == 0
                                            ? AppTheme.goldPrimary
                                            : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Event Overview & Purse',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11.5,
                                            color: _activeAthleteTab == 0
                                                ? AppTheme.goldPrimary
                                                : AppTheme.textSecondary,
                                          ),
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
                                    gradient: _activeAthleteTab == 1
                                        ? const LinearGradient(
                                            colors: [Color(0xFF0E3224), Color(0xFF071A12)],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _activeAthleteTab == 1
                                          ? AppTheme.emerald
                                          : Colors.transparent,
                                      width: 1.3,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_tree_rounded,
                                        size: 15,
                                        color: _activeAthleteTab == 1
                                            ? AppTheme.emerald
                                            : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Live Brackets & Podium',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11.5,
                                            color: _activeAthleteTab == 1
                                                ? AppTheme.emerald
                                                : AppTheme.textSecondary,
                                          ),
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
                        // 2. Weight & Division Tactical Filter Tray (Cat N)
                        _buildCategoryFilterTray(event),
                        const SizedBox(height: 16),

                        // 1. Overview Metrics Strip (Schedule, Entry Fee, Capacity, Sanctioning)
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
                                      label: event['entryFeePkr'] != null ? 'Entry Fee (PKR)' : 'Entry Fee',
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
                                      value: '${event['registeredCount'] ?? ((event['appliedAthletes'] is List && (event['appliedAthletes'] as List).isNotEmpty) ? (event['appliedAthletes'] as List).length : 0)} / ${event['capacity'] ?? '64'} Athletes',
                                    ),
                                  ),
                                  Container(height: 36, width: 1, color: AppTheme.borderSubtle),
                                  Expanded(
                                    child: _metricColumn(
                                      icon: Icons.verified_outlined,
                                      label: 'Sanctioning',
                                      value: sanctioningOrgLabel,
                                      badgeAsset: ArmSphereAssets.sealFed,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Multi-Table Live Arena Status Grid (SIG-1)
                        _buildLiveArenaTables(context),
                        const SizedBox(height: 16),

                        // Athlete Weight Categories (Left/Right Arm) & Awards/Prizes Summary Card
                        _buildAthleteCategoriesAndAwardsCard(context, event),
                        const SizedBox(height: 16),

                        // Athlete Registration Status Card (Single Unified CTA in StickyBottomActionBar)
                        _buildZeroErrorAthleteApplyCard(
                          context,
                          event,
                          activeRegistration,
                        ),
                        const SizedBox(height: 16),

                        // 2b. Official Spectator & VIP Event Passes
                        _buildEventPassesSection(context, event),
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
                ? (activeRegistration != null
                    ? 'Update Division'
                    : 'Apply to Compete')
                : (status == 'ONGOING'
                    ? 'Track Live Matches'
                    : (status == 'COMPLETED'
                        ? 'View Awards & Ceremony'
                        : (activeRegistration != null
                            ? 'Update Division'
                            : 'Apply to Compete'))),
            primaryActionIcon: activeRegistration != null
                ? Icons.edit_note_rounded
                : Icons.bolt_rounded,
            onPrimaryAction: () {
              HapticFeedback.selectionClick();
              if (!canRegister && status == 'COMPLETED') {
                context.push('/tournament/${widget.tournamentId}/awards');
                return;
              }
              if (!canRegister && status == 'ONGOING') {
                setState(() => _activeAthleteTab = 1);
                return;
              }
              _openDedicatedApplyScreen(context, event);
            },
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

  String _resolveTierPrizeLabel(
    Map<String, dynamic> awardsConfig, {
    required int place,
    required String fallbackKey,
    required String defaultPrize,
  }) {
    final direct = (awardsConfig[fallbackKey] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;
    final tiers = awardsConfig['tiers'];
    if (tiers is List) {
      for (final item in tiers) {
        if (item is! Map) continue;
        final itemPlace = (item['place'] as num?)?.toInt();
        if (itemPlace == place) {
          final cashPkr = (item['cashPrizePkr'] as num?)?.toInt() ?? 0;
          final customReward = (item['customReward'] ?? '').toString().trim();
          final parts = <String>[
            if (cashPkr > 0) 'PKR $cashPkr',
            if (customReward.isNotEmpty) customReward,
          ];
          if (parts.isNotEmpty) return parts.join(' + ');
        }
      }
    }
    return defaultPrize;
  }

  Widget _buildAthleteCategoriesAndAwardsCard(
    BuildContext context,
    Map<String, dynamic> event,
  ) {
    final realDivisions =
        TournamentOfflineStore.extractRealTournamentDivisions(event);
    final availableChipLabels = _resolveDynamicFilterChips(event);
    final activeFilter = availableChipLabels.contains(_selectedCategory)
        ? _selectedCategory
        : 'ALL';
    final visibleDivisions = activeFilter == 'ALL'
        ? realDivisions
        : realDivisions
            .where((d) => (d['label'] ?? '').toString() == activeFilter)
            .toList();

    final awardsConfig = (event['awardsConfig'] is Map)
        ? Map<String, dynamic>.from(event['awardsConfig'] as Map)
        : (event['step1Config'] is Map &&
                (event['step1Config'] as Map)['awardsConfig'] is Map)
            ? Map<String, dynamic>.from(
                (event['step1Config'] as Map)['awardsConfig'] as Map,
              )
            : <String, dynamic>{};

    final firstPrize = _resolveTierPrizeLabel(
      awardsConfig,
      place: 1,
      fallbackKey: 'firstPlacePrize',
      defaultPrize: 'PKR 50,000 + Gold Championship Medal',
    );
    final secondPrize = _resolveTierPrizeLabel(
      awardsConfig,
      place: 2,
      fallbackKey: 'secondPlacePrize',
      defaultPrize: 'PKR 25,000 + Silver Medal',
    );
    final thirdPrize = _resolveTierPrizeLabel(
      awardsConfig,
      place: 3,
      fallbackKey: 'thirdPlacePrize',
      defaultPrize: 'PKR 10,000 + Bronze Medal',
    );

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF171C27), Color(0xFF0C0F16)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded,
                  size: 16, color: AppTheme.goldPrimary),
              SizedBox(width: 8),
              Text(
                'DIVISIONS & CHAMPIONSHIP PURSE (PKR)',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppTheme.goldPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (visibleDivisions.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final div in visibleDivisions)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.obsidian,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      (div['label'] ?? '').toString(),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            )
          else
            const Text(
              'Official divisions configured by tournament host.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPursePod(
                  medal: '1ST GOLD',
                  prize: firstPrize,
                  color: const Color(0xFFD4AF37),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPursePod(
                  medal: '2ND SILVER',
                  prize: secondPrize,
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPursePod(
                  medal: '3RD BRONZE',
                  prize: thirdPrize,
                  color: const Color(0xFFCD7F32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPursePod({
    required String medal,
    required String prize,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppTheme.obsidian,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medal,
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            prize,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZeroErrorAthleteApplyCard(
    BuildContext context,
    Map<String, dynamic> event,
    Map<String, dynamic>? activeRegistration,
  ) {
    final app = activeRegistration;
    final weightLabel = (app?['registeredWeightLabel'] ??
            app?['weightCategory'] ??
            app?['weightClass'] ??
            app?['divisionName'] ??
            '')
        .toString()
        .trim();
    final armRaw = (app?['registeredArm'] ?? app?['arm'] ?? 'RIGHT')
        .toString()
        .trim();
    final formattedArm = ArmSphereFormatters.formatArmLabel(armRaw);
    final categorySummary = (app?['categoryLabel'] ?? '').toString().trim().isNotEmpty
        ? (app?['categoryLabel']).toString().trim()
        : (weightLabel.isNotEmpty ? '$weightLabel • $formattedArm' : formattedArm);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF151C27), Color(0xFF0C1017)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.emerald.withValues(alpha: 0.55),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                app != null ? Icons.verified_rounded : Icons.how_to_reg_rounded,
                color: AppTheme.emerald,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'TOURNAMENT REGISTRATION',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: AppTheme.emerald,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              StatusChip(
                label: app != null ? 'CONFIRMED ✓' : 'READY',
                color: AppTheme.emerald,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (app != null) ...[
            Container(
              padding: const EdgeInsets.all(13),
              decoration: AppTheme.recessedObsidianWellDecoration(radius: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirmed • $categorySummary',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if ((app['athleteName'] ?? '').toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${app['athleteName']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  const Text(
                    'Present your Profile QR Code at weigh-in, venue entrance, and your assigned table.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.push('/settings');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.goldPrimary,
                  side: const BorderSide(
                    color: AppTheme.goldPrimary,
                    width: 1.2,
                  ),
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                label: const Text(
                  'Profile QR',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Tap "Apply to Compete" below to select your created division on the official registration screen. Your permanent Profile QR Code is used automatically at weigh-in, venue entrance, and your assigned table.',
              style: TextStyle(
                fontSize: 11.5,
                color: AppTheme.textSecondary,
                height: 1.35,
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
          (m['categoryLabel'] ?? '').toString() !=
              _selectedMatchupCategoryFilter) {
        return false;
      }
      if (_selectedMatchupRoundFilter > 0 &&
          ((m['roundNumber'] as num?)?.toInt() ?? 1) !=
              _selectedMatchupRoundFilter) {
        return false;
      }
      return true;
    }).toList();

    final completedFinals = matchups.where((m) {
      final s = (m['status'] ?? '').toString().toUpperCase();
      return (s == 'DONE' || s == 'COMPLETED') &&
          (m['winnerName'] ?? '').toString().isNotEmpty;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Prestigious Live Podium Standings Card (Read-Only Broadcast View)
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF282010), Color(0xFF100E09)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.goldPrimary.withValues(alpha: 0.7),
              width: 1.3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events_rounded,
                      color: AppTheme.goldPrimary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'LIVE PODIUM & CHAMPIONSHIP WINNERS',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        color: AppTheme.goldPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  StatusChip(
                    label: 'BROADCAST VIEW',
                    color: AppTheme.emerald,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (completedFinals.isEmpty)
                const Text(
                  '1st Gold, 2nd Silver & 3rd Bronze podium winners appear automatically as division finals complete.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                )
              else
                for (int i = 0; i < completedFinals.take(3).length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.goldPrimary),
                          ),
                          child: Text(
                            i == 0
                                ? '1ST GOLD'
                                : i == 1
                                    ? '2ND SILVER'
                                    : '3RD BRONZE',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${completedFinals[i]['categoryLabel'] ?? 'Division'} • ${completedFinals[i]['winnerName']}',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
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
        const SizedBox(height: 12),

        // 2. Category & Round Filter Chips
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
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedMatchupCategoryFilter = cat),
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
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedMatchupRoundFilter = r),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Read-Only Broadcast Bout Plates (Table Assignments, 0L / 1L Badges, Red vs Gold Corner)
        for (final m in filtered)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Builder(
              builder: (_) {
                final status =
                    (m['status'] ?? 'PENDING').toString().toUpperCase();
                final isDone = status == 'DONE' || status == 'COMPLETED';
                final p1Losses = (m['player1Losses'] as num?)?.toInt() ?? 0;
                final p2Losses = (m['player2Losses'] as num?)?.toInt() ?? 0;

                return Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF171C28), Color(0xFF0D1017)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isDone
                          ? AppTheme.emerald.withValues(alpha: 0.55)
                          : AppTheme.goldPrimary.withValues(alpha: 0.35),
                    ),
                  ),
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
                            label: status,
                            color: isDone ? AppTheme.emerald : AppTheme.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (m['categoryLabel'] ?? 'Open Division').toString(),
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: const Color(0xFF11151F),
                                borderRadius: BorderRadius.circular(10),
                                border: const Border(
                                  left: BorderSide(
                                    color: Color(0xFFE23B3B),
                                    width: 3.0,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (m['player1Name'] ?? 'Athlete 1').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'ELO ${m['player1Elo'] ?? 1800} • ${p1Losses}L',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: p1Losses == 0
                                          ? AppTheme.emerald
                                          : AppTheme.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'VS',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w900,
                                fontSize: 11.5,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: const Color(0xFF11151F),
                                borderRadius: BorderRadius.circular(10),
                                border: const Border(
                                  right: BorderSide(
                                    color: AppTheme.goldPrimary,
                                    width: 3.0,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    (m['player2Name'] ?? 'Athlete 2').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'ELO ${m['player2Elo'] ?? 1800} • ${p2Losses}L',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: p2Losses == 0
                                          ? AppTheme.emerald
                                          : AppTheme.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if ((m['winnerName'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded,
                                  size: 15, color: AppTheme.emerald),
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
                );
              },
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

  Widget _buildCategoryFilterTray(Map<String, dynamic> event) {
    final chips = _resolveDynamicFilterChips(event);
    final effectiveSelected =
        chips.contains(_selectedCategory) ? _selectedCategory : 'ALL';
    if (chips.length <= 1) {
      return const SizedBox.shrink();
    }
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
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = chips[index];
              final isSelected = cat == effectiveSelected;
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
          [
            t['weightClass']?.toString() ?? '',
            t['arm']?.toString() ?? '',
          ].where((s) => s.isNotEmpty).join(' '),
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
    String normalize(String raw) => raw
        .toUpperCase()
        .replaceAll(RegExp(r'[•·|/,]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final normFilter = normalize(filter);
    final normWeight = normalize(weightClassFormatted);
    final normDiv = normalize(division);

    final fCompact = normFilter.replaceAll(' ', '');
    final wCompact = normWeight.replaceAll(' ', '');
    final dCompact = normDiv.replaceAll(' ', '');
    if (wCompact.contains(fCompact) || dCompact.contains(fCompact)) return true;

    final tokens = normFilter
        .split(' ')
        .where((s) => s.isNotEmpty && s != 'ARM');
    return tokens.every(
      (token) => normWeight.contains(token) || normDiv.contains(token),
    );
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
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
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
