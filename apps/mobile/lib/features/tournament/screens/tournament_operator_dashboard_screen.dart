import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';

/// Tournament Operator Landing Dashboard
///
/// Dedicated operational command center for event directors & arena operators:
/// - Active Tournament selector & Event War Room launcher.
/// - Live Arena Tables & Queue status monitoring (`match_tables` & `tournament_table_queue`).
/// - Official Weigh-In scale & rubber-stamp desk shortcut.
/// - Bracket generation & seeding progression overview.
/// - Podium ceremony & awards launcher.
class TournamentOperatorDashboardScreen extends ConsumerStatefulWidget {
  const TournamentOperatorDashboardScreen({super.key});

  @override
  ConsumerState<TournamentOperatorDashboardScreen> createState() =>
      _TournamentOperatorDashboardScreenState();
}

class _TournamentOperatorDashboardScreenState
    extends ConsumerState<TournamentOperatorDashboardScreen> {
  String? _selectedTournamentId;

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      final dt = DateTime.parse(dateVal.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateVal.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(tournamentProvider);
    final authState = ref.watch(authProvider);
    final profile = authState.userProfile ?? {};
    final operatorName = profile['displayName'] ?? profile['name'] ?? 'Operator';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.goldPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ARENA OPERATIONS COMMAND',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              operatorName,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.goldPrimary),
            tooltip: 'Refresh Arena Status',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(tournamentProvider);
              if (_selectedTournamentId != null) {
                ref.invalidate(eventDetailProvider(_selectedTournamentId!));
                ref.invalidate(eventMatchTablesProvider(_selectedTournamentId!));
                ref.invalidate(eventRegistrationsProvider(_selectedTournamentId!));
                ref.invalidate(eventBracketsProvider(_selectedTournamentId!));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppTheme.textSecondary),
            tooltip: 'Account Roles',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/settings/roles');
            },
          ),
        ],
      ),
      body: tournamentsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppTheme.space16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space16),
          itemBuilder: (_, __) => const SkeletonPlaceholder(
            height: 120,
            borderRadius: AppTheme.radiusMedium,
          ),
        ),
        error: (error, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Could not load tournaments',
          subtitle: error.toString(),
          ctaLabel: 'Retry',
          onCtaTap: () => ref.invalidate(tournamentProvider),
        ),
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return AppEmptyState(
              icon: Icons.table_chart_outlined,
              title: 'No Tournaments Available',
              subtitle:
                  'There are no active or sanctioned tournaments assigned for operations yet.',
              ctaLabel: 'Browse Competitions',
              onCtaTap: () => context.push('/tournaments'),
            );
          }

          final effectiveId = (_selectedTournamentId != null &&
                  tournaments.any((t) => t['id']?.toString() == _selectedTournamentId))
              ? _selectedTournamentId!
              : tournaments.first['id'].toString();

          final currentTournament = tournaments.firstWhere(
            (t) => t['id']?.toString() == effectiveId,
            orElse: () => tournaments.first,
          );

          final tablesAsync = ref.watch(eventMatchTablesProvider(effectiveId));
          final registrationsAsync = ref.watch(eventRegistrationsProvider(effectiveId));
          final bracketsAsync = ref.watch(eventBracketsProvider(effectiveId));

          return RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              ref.invalidate(tournamentProvider);
              ref.invalidate(eventDetailProvider(effectiveId));
              ref.invalidate(eventMatchTablesProvider(effectiveId));
              ref.invalidate(eventRegistrationsProvider(effectiveId));
              ref.invalidate(eventBracketsProvider(effectiveId));
            },
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.space16),
              children: [
                // 1. Tournament Selector & War Room Banner
                if (tournaments.length > 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SELECT ACTIVE TOURNAMENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.cardSurface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: effectiveId,
                            isDense: true,
                            dropdownColor: AppTheme.cardSurface,
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.goldPrimary),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            items: tournaments.map((t) {
                              return DropdownMenuItem<String>(
                                value: t['id'].toString(),
                                child: Text(
                                  t['name'] ?? 'Tournament',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (newId) {
                              if (newId != null) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedTournamentId = newId);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                ],

                // 2. Primary Event War Room Launcher Card
                ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space10),
                            decoration: BoxDecoration(
                              color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            child: const Icon(
                              Icons.stadium_outlined,
                              color: AppTheme.goldPrimary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        currentTournament['name'] ?? 'Tournament',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusChip(
                                      label: (currentTournament['status'] ?? 'ACTIVE').toString().toUpperCase(),
                                      type: StatusType.success,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        currentTournament['venue'] ?? currentTournament['city'] ?? 'Arena Venue',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (currentTournament['startDate'] != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_formatDate(currentTournament['startDate'])} - ${_formatDate(currentTournament['endDate'])}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space16),
                      const Divider(height: 1, color: AppTheme.cardBorder),
                      const SizedBox(height: AppTheme.space16),

                      // Primary Launch Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldPrimary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.dashboard_customize_outlined, size: 20),
                          label: const Text(
                            'LAUNCH EVENT OPERATIONS DESK',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            context.push('/tournament/$effectiveId/operations');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space20),

                // 3. Operational Quick Action Grids
                const Text(
                  'ARENA MANAGEMENT SUITE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),

                // Table & Queue Status Card
                tablesAsync.when(
                  loading: () => const SkeletonPlaceholder(height: 110, borderRadius: AppTheme.radiusMedium),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (tables) {
                    final activeCount = tables.where((t) => (t['status']?.toString().toUpperCase() == 'ACTIVE')).length;
                    final idleCount = tables.where((t) => (t['status']?.toString().toUpperCase() == 'IDLE')).length;

                    return ElevatedActionCard(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    ),
                                    child: const Icon(Icons.table_restaurant_outlined, color: Colors.blueAccent, size: 22),
                                  ),
                                  const SizedBox(width: AppTheme.space10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Match Tables & Arena Queue',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${tables.length} Arena ${tables.length == 1 ? "Table" : "Tables"} Active',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/tournament/$effectiveId/operations');
                                },
                                child: const Text('Manage'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space12),
                          Row(
                            children: [
                              _buildMetricPill('ACTIVE PULLING', '$activeCount', StatusType.success),
                              const SizedBox(width: AppTheme.space8),
                              _buildMetricPill('IDLE / READY', '$idleCount', StatusType.info),
                              const SizedBox(width: AppTheme.space8),
                              _buildMetricPill('TABLES TOTAL', '${tables.length}', StatusType.neutral),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.space12),

                // Weigh-In & Registrations Desk Card
                registrationsAsync.when(
                  loading: () => const SkeletonPlaceholder(height: 110, borderRadius: AppTheme.radiusMedium),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (regs) {
                    final approvedCount = regs.where((r) => r['status']?.toString().toUpperCase() == 'APPROVED').length;
                    final pendingCount = regs.where((r) => r['status']?.toString().toUpperCase() == 'PENDING').length;

                    return ElevatedActionCard(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    ),
                                    child: const Icon(Icons.scale_outlined, color: Colors.amber, size: 22),
                                  ),
                                  const SizedBox(width: AppTheme.space10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Official Weigh-In Desk',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${regs.length} Total Registered Competitors',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.goldPrimary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/tournament/$effectiveId/weigh-in');
                                },
                                child: const Text(
                                  'Open Scale',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space12),
                          Row(
                            children: [
                              _buildMetricPill('APPROVED PASSES', '$approvedCount', StatusType.success),
                              const SizedBox(width: AppTheme.space8),
                              _buildMetricPill('PENDING CHECK-IN', '$pendingCount', StatusType.warning),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.space12),

                // Brackets & Ceremony Quick Cards
                Row(
                  children: [
                    // Brackets Card
                    Expanded(
                      child: bracketsAsync.when(
                        loading: () => const SkeletonPlaceholder(height: 100, borderRadius: AppTheme.radiusMedium),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (brackets) {
                          return ElevatedActionCard(
                            padding: const EdgeInsets.all(AppTheme.space14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.account_tree_outlined, color: AppTheme.goldPrimary, size: 22),
                                    StatusChip(
                                      label: '${brackets.length}',
                                      type: StatusType.info,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Brackets',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Seeding & Trees',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 28),
                                      side: const BorderSide(color: AppTheme.cardBorder),
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      context.push('/tournament/$effectiveId/brackets');
                                    },
                                    child: const Text('View', style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),

                    // Awards Card
                    Expanded(
                      child: ElevatedActionCard(
                        padding: const EdgeInsets.all(AppTheme.space14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(Icons.emoji_events_outlined, color: AppTheme.goldPrimary, size: 22),
                                StatusChip(
                                  label: 'Podium',
                                  type: StatusType.success,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Awards Desk',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Medals & Citations',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 28),
                                  side: const BorderSide(color: AppTheme.cardBorder),
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/tournaments/$effectiveId/awards');
                                },
                                child: const Text('Ceremony', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space24),

                // 4. Quick Governance Escalation Link
                ElevatedActionCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
                  child: Row(
                    children: [
                      const Icon(Icons.gavel_outlined, color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: AppTheme.space12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Federation Arbitration & Protests',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textPrimary),
                            ),
                            Text(
                              'Review match disputes or official rule protests',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.push('/governance');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, StatusType type) {
    Color bg;
    Color fg;
    switch (type) {
      case StatusType.success:
        bg = AppTheme.success.withValues(alpha: 0.15);
        fg = AppTheme.success;
        break;
      case StatusType.warning:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber;
        break;
      case StatusType.info:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blueAccent;
        break;
      default:
        bg = AppTheme.cardSurface;
        fg = AppTheme.textSecondary;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.8),
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
