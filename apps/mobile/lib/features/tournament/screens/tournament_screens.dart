import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/sticky_bottom_action_bar.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../widgets/tournament_widgets.dart';

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
    final theme = Theme.of(context);
    final tournamentsAsync = ref.watch(tournamentProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
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
        ],
      ),
      body: tournamentsAsync.when(
        loading: () => const TournamentSkeletonLoadingWidget(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                'Could not load competitions',
                style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(tournamentProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (events) {
          // Drafts are not public product surfaces; hide them here.
          final visible = events
              .where((e) => (e['status']?.toString().toUpperCase() ?? '') != 'DRAFT')
              .toList();

          if (visible.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(tournamentProvider.future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.emoji_events_outlined, size: 56, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No competitions published yet',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Check back soon for upcoming sanctioned events',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(tournamentProvider.future),
            child: ListView.separated(
              key: const PageStorageKey<String>('tournaments_list_view'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                              color: AppTheme.elevatedSurface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(color: AppTheme.borderSubtle, width: 1),
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
  String _selectedCategory = 'ALL';
  static const _categories = ['ALL', '-75 KG', '-85 KG', '-95 KG', '+105 KG', 'OPEN RIGHT', 'OPEN LEFT'];

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
    final theme = Theme.of(context);
    final eventAsync = ref.watch(eventDetailProvider(widget.tournamentId));

    return eventAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.background,
        body: TournamentSkeletonLoadingWidget(),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Tournament Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                'Could not load tournament',
                style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(eventDetailProvider(widget.tournamentId)),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (event) {
        final status = (event['status']?.toString() ?? '').toUpperCase();
        final canRegister = status == 'PUBLISHED';
        final auth = ref.watch(authProvider);
        final role = auth.userProfile?['role']?.toString().toUpperCase();
        const operatorRoles = {'PROVINCIAL_DIRECTOR', 'NATIONAL_DIRECTOR', 'SYSTEM_ADMIN'};
        final canOperate = operatorRoles.contains(role) ||
            (event['organizerId'] != null &&
                event['organizerId'].toString() == auth.userProfile?['id']?.toString());
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
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260.0,
                pinned: true,
                backgroundColor: AppTheme.background,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.pop();
                      },
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      child: IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Clipboard.setData(ClipboardData(text: 'https://armsphere.app/tournament/${widget.tournamentId}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tournament link copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Background Image or Dynamic Arena Fallback
                      ArmSphereImage(
                        imageUrl: event['imageUrl']?.toString(),
                        fallbackAsset: ArmSphereAssets.defaultTournament,
                        fit: BoxFit.cover,
                        semanticLabel: event['name'] != null
                            ? 'Tournament banner for ${event['name']}'
                            : 'Tournament banner',
                      ),

                      // 2. Canonical 4-Stop Hero Scrim Gradient (AppTheme.heroScrim)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: AppTheme.heroScrim(),
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
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                      border: Border.all(
                                        color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                                        width: 1,
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

              // Body Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Overview Metrics Strip
                      ElevatedActionCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _metricColumn(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Dates',
                                    value: dates.isEmpty ? 'TBA' : dates,
                                  ),
                                ),
                                Container(height: 36, width: 1, color: AppTheme.borderSubtle),
                                Expanded(
                                  child: _metricColumn(
                                    icon: Icons.payments_outlined,
                                    label: 'Entry Fee',
                                    value: formatEventFee(event['registrationFeeCents']),
                                    isHighlighted: true,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: AppTheme.borderSubtle),
                            Row(
                              children: [
                                Expanded(
                                  child: _metricColumn(
                                    icon: Icons.groups_outlined,
                                    label: 'Capacity',
                                    value: '${event['registeredCount'] ?? 0} / ${event['capacity'] ?? '∞'} Athletes',
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

                      // 2. Weight & Division Tactical Filter Tray (Cat N)
                      _buildCategoryFilterTray(),
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

                      // 3. Organizer / Operations Console Access (if authorized)
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
                                  color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
                                  color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
                                event['venueName']?.toString() ?? 'Sanctioned Competition Facility',
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
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: StickyBottomActionBar(
            primaryActionLabel: canRegister
                ? 'Register for Event'
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
                    context.push('/tournament/${widget.tournamentId}/register');
                  }
                : (status == 'COMPLETED'
                    ? () {
                        HapticFeedback.selectionClick();
                        context.push('/tournament/${widget.tournamentId}/awards');
                      }
                    : (status == 'ONGOING'
                        ? () {
                            HapticFeedback.selectionClick();
                            context.push('/tournament/${widget.tournamentId}/brackets');
                          }
                        : null)),
            secondaryAction: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push('/tournament/${widget.tournamentId}/brackets');
              },
              icon: const Icon(Icons.account_tree_outlined, size: 16),
              label: const Text('Brackets & Schedule'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.borderSubtle),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
              ),
            ),
          ),
        );
      },
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
                    color: isSelected
                        ? AppTheme.goldPrimary.withValues(alpha: 0.18)
                        : AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: isSelected ? AppTheme.goldPrimary : AppTheme.borderSubtle,
                      width: isSelected ? 1.5 : 1.0,
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
                        color: isSelected ? AppTheme.goldPrimary : AppTheme.textSecondary,
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
                color: AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.borderSubtle),
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
                color: AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.borderSubtle),
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
                    color: AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: AppTheme.borderSubtle),
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
                    color: AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: AppTheme.borderSubtle),
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
    final badgeColor = hasActive ? const Color(0xFF10B981) : AppTheme.textMuted;

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
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.4),
              width: 1,
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
        return const Color(0xFF10B981); // Emerald
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
          color: AppTheme.elevatedSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isLive ? const Color(0xFF10B981).withValues(alpha: 0.6) : AppTheme.borderSubtle,
            width: isLive ? 1.5 : 1.0,
          ),
          boxShadow: isLive
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(color: AppTheme.borderSubtle, width: 1),
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
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLive) ...[
                        const Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
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
                          color: Color(0xFFEF4444),
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
                          color: Color(0xFF38BDF8),
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Tournament Brackets',
          style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSpatialView ? Icons.view_list_rounded : Icons.account_tree_rounded),
            tooltip: _isSpatialView ? 'Switch to List View' : 'Switch to Spatial Tree',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _isSpatialView = !_isSpatialView);
            },
          ),
          IconButton(
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
        ],
      ),
      body: bracketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary)),
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
              padding: const EdgeInsets.all(20),
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.account_tree_outlined, size: 48, color: AppTheme.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'No brackets published yet.',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Matchups will appear once tournament directors generate brackets.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
                color: AppTheme.cardSurface,
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
                              fontWeight: b['id']?.toString() == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: b['id']?.toString() == selected,
                          selectedColor: AppTheme.goldPrimary.withValues(alpha: 0.2),
                          side: BorderSide(
                            color: b['id']?.toString() == selected
                                ? AppTheme.goldPrimary
                                : AppTheme.borderSubtle,
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
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary)),
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
                      color: AppTheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.3)),
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
          const Divider(height: 16, color: AppTheme.borderSubtle),
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
