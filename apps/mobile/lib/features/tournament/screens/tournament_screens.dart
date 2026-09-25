import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  Widget _buildFallbackHeroBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF070A11),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_kabaddi,
          size: 80,
          color: AppTheme.goldPrimary.withValues(alpha: 0.12),
        ),
      ),
    );
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
                      if (event['imageUrl'] != null && event['imageUrl'].toString().isNotEmpty)
                        Image.network(
                          event['imageUrl'].toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackHeroBackground(),
                        )
                      else
                        _buildFallbackHeroBackground(),

                      // 2. Canonical 4-Stop Hero Scrim Gradient (AppTheme.heroScrim)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppTheme.heroScrim(),
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
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Event Description Card (if available)
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
                    : (status == 'COMPLETED' ? 'View Final Results' : 'Registration Closed')),
            primaryActionIcon: canRegister
                ? Icons.how_to_reg
                : (status == 'ONGOING' ? Icons.sports_kabaddi : Icons.emoji_events_outlined),
            onPrimaryAction: canRegister
                ? () {
                    HapticFeedback.selectionClick();
                    context.push('/tournament/${widget.tournamentId}/register');
                  }
                : (status == 'ONGOING' || status == 'COMPLETED'
                    ? () {
                        HapticFeedback.selectionClick();
                        context.push('/tournament/${widget.tournamentId}/brackets');
                      }
                    : null),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
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
              color: isHighlighted ? AppTheme.goldPrimary : AppTheme.textPrimary,
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final bracketsAsync = ref.watch(eventBracketsProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Tournament Brackets',
          style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.w700),
        ),
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
