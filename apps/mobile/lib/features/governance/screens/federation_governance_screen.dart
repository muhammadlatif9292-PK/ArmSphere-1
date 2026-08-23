import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/providers/referee_provider.dart';
import '../../../core/providers/dispute_provider.dart';
import '../../../core/providers/rankings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/audio/sound_service.dart';
import '../../../core/widgets/celebration_overlay.dart';

// ==========================================
// SCREEN 14: FEDERATION GOVERNANCE & COMPETITION OVERSIGHT
// ==========================================

class FederationGovernanceScreen extends ConsumerStatefulWidget {
  const FederationGovernanceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FederationGovernanceScreen> createState() =>
      _FederationGovernanceScreenState();
}

class _FederationGovernanceScreenState
    extends ConsumerState<FederationGovernanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final bool _isOnline = true;
  final String _lastSyncTime = 'Just now';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(tournamentProvider);
    final disputesAsync = ref.watch(disputeProvider);
    final refereesAsync = ref.watch(refereeProvider);
    final athletesAsync = ref.watch(rankingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.goldPrimary.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.goldPrimary, width: 1),
              ),
              child: const Icon(Icons.shield_outlined,
                  color: AppTheme.goldPrimary, size: 16),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FEDERATION GOVERNANCE',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 14,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Official Competition Oversight Surface',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.glassSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary, size: 20),
            tooltip: 'Sync Governance Data',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(tournamentProvider);
              ref.invalidate(disputeProvider);
              ref.invalidate(refereeProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.gavel, color: AppTheme.goldPrimary, size: 20),
            tooltip: 'Official Disputes Queue',
            onPressed: () => context.push('/governance/disputes'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tournamentProvider);
          ref.invalidate(disputeProvider);
          ref.invalidate(refereeProvider);
        },
        color: AppTheme.goldPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PART 18: OFFLINE / SYNCHRONIZATION STATUS STRIP
              _buildSyncStatusStrip(),

              const SizedBox(height: 12),

              // PART 1: FEDERATION IDENTITY HEADER
              _buildFederationHeader(),

              const SizedBox(height: 16),

              // PART 14: FEDERATION SEARCH BAR
              _buildFederationSearchField(),

              const SizedBox(height: 16),

              // PART 2: OFFICIAL OPERATIONS STATUS
              _buildOperationsStatusSurface(
                tournamentsAsync,
                disputesAsync,
                refereesAsync,
                athletesAsync,
              ),

              const SizedBox(height: 16),

              // PART 3: FEDERATION ACTION REQUIRED
              _buildActionRequiredSection(context, disputesAsync),

              const SizedBox(height: 20),

              // PART 13: QUICK ACCESS SHORTCUTS
              _buildQuickAccessSection(context),

              const SizedBox(height: 20),

              // PART 4 & 5: COMPETITION ECOSYSTEM & TOURNAMENT OVERSIGHT
              _buildTournamentOversightSection(context, tournamentsAsync),

              const SizedBox(height: 20),

              // PART 6 & 7: ATHLETE VERIFICATION & OFFICIALS CREDENTIALS
              _buildRegistryAndCredentialsSection(context, athletesAsync, refereesAsync),

              const SizedBox(height: 20),

              // PART 8 & 10: RESULTS CERTIFICATION & RANKINGS OVERSIGHT
              _buildCertificationAndRankingsCard(context),

              const SizedBox(height: 20),

              // PART 9: OFFICIAL RECORD REVIEW / DISPUTES
              _buildDisputesGovernanceCard(context, disputesAsync),

              const SizedBox(height: 20),

              // PART 11 & 20: AUDIT LOG & RECORD INTEGRITY
              _buildAuditTrailAndIntegrityCard(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SYNC STATUS STRIP
  // ==========================================
  Widget _buildSyncStatusStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isOnline ? AppTheme.success : AppTheme.warning,
                  boxShadow: [
                    BoxShadow(
                      color: (_isOnline ? AppTheme.success : AppTheme.warning)
                          .withOpacity(0.5),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isOnline
                    ? 'ONLINE • AUTHORITATIVE FEDERATION SYNC'
                    : 'OFFLINE • QUEUED PENDING GOVERNANCE SYNC',
                style: TextStyle(
                  color: _isOnline ? AppTheme.success : AppTheme.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Text(
            'Synced: $_lastSyncTime',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 1: FEDERATION IDENTITY HEADER
  // ==========================================
  Widget _buildFederationHeader() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppTheme.goldPrimary.withOpacity(0.4),
      enableGlow: true,
      glowColor: AppTheme.goldPrimary.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: AppTheme.goldPrimary, size: 12),
                    SizedBox(width: 6),
                    Text(
                      'FEDERATION VERIFIED • 2026 SEASON',
                      style: TextStyle(
                        color: AppTheme.goldLight,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  'EXECUTIVE COUNCIL',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Pakistan Armwrestling Federation (PAFF)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: AppTheme.fontDisplay,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'National Governing Body • Competition Oversight & Official Registry',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 14: FEDERATION SEARCH FIELD
  // ==========================================
  Widget _buildFederationSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: AppTheme.textMuted, size: 18),
          hintText: 'Search tournaments, athletes, referees, or records...',
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  // ==========================================
  // PART 2: OFFICIAL OPERATIONS STATUS
  // ==========================================
  Widget _buildOperationsStatusSurface(
    AsyncValue<List<Map<String, dynamic>>> tournamentsAsync,
    AsyncValue<List<Map<String, dynamic>>> disputesAsync,
    AsyncValue<List<Map<String, dynamic>>> refereesAsync,
    AsyncValue<List<Map<String, dynamic>>> athletesAsync,
  ) {
    int tournamentCount = 0;
    int disputeCount = 0;
    int refCount = 0;
    int athleteCount = 0;

    tournamentsAsync.whenData((data) => tournamentCount = data.length);
    disputesAsync.whenData((data) => disputeCount = data.length);
    refereesAsync.whenData((data) => refCount = data.length);
    athletesAsync.whenData((data) => athleteCount = data.length);

    final statusText = disputeCount > 0 ? 'ATTENTION REQUIRED' : 'NORMAL';
    final statusColor = disputeCount > 0 ? AppTheme.warning : AppTheme.success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FEDERATION ECOSYSTEM STATE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.goldPrimary,
                  fontFamily: AppTheme.fontDisplay,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: statusColor),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statusMetric('Sanctioned Tournaments', '$tournamentCount Active', AppTheme.primaryAccent),
              _statusMetric('Registered Athletes', '${athleteCount > 0 ? athleteCount : 128} Verified', AppTheme.textPrimary),
              _statusMetric('Federation Referees', '${refCount > 0 ? refCount : 6} Certified', AppTheme.success),
              _statusMetric('Pending Disputes', '$disputeCount Cases', disputeCount > 0 ? AppTheme.warning : AppTheme.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            fontFamily: AppTheme.fontMono,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  // ==========================================
  // PART 3: FEDERATION ACTION REQUIRED
  // ==========================================
  Widget _buildActionRequiredSection(
      BuildContext context, AsyncValue<List<Map<String, dynamic>>> disputesAsync) {
    final actions = [
      {
        'title': 'National Championship Sanction Request',
        'subtitle': 'Sindh Armwrestling Association submitted venue & rules checklist',
        'badge': 'Approval Required',
        'actionText': 'Review Request',
        'color': AppTheme.goldPrimary,
        'onTap': () => _showTournamentApprovalModal(context),
      },
      {
        'title': 'Senior Heavyweight Result Certification Review',
        'subtitle': '4 completed bout scorepads from Lahore Sports Complex awaiting sign-off',
        'badge': 'Certification Queue',
        'actionText': 'Certify Standings',
        'color': AppTheme.primaryAccent,
        'onTap': () => _showCertificationModal(context),
      },
      {
        'title': 'Chief Referee Credential Renewal',
        'subtitle': 'Master Referee Ref-104 (Ahmed Ali) certification renewal submitted',
        'badge': 'Credential Audit',
        'actionText': 'Review Credential',
        'color': AppTheme.info,
        'onTap': () => context.push('/referee/dashboard'),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.goldPrimary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'FEDERATION ACTION REQUIRED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.textPrimary,
                      fontFamily: AppTheme.fontDisplay,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
                ),
                child: const Text(
                  '3 Pending Items',
                  style: TextStyle(
                    color: AppTheme.goldLight,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppTheme.border, height: 16),
            itemBuilder: (context, idx) {
              final item = actions[idx];
              final color = item['color'] as Color;
              return Row(
                children: [
                  Container(
                    width: 6,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['subtitle'] as String,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      (item['onTap'] as VoidCallback)();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.5)),
                      ),
                      child: Text(
                        item['actionText'] as String,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 13: QUICK ACCESS SHORTCUTS
  // ==========================================
  Widget _buildQuickAccessSection(BuildContext context) {
    final shortcuts = [
      {
        'title': 'Tournament Hub',
        'icon': Icons.emoji_events_outlined,
        'route': '/tournaments',
      },
      {
        'title': 'Referee Dashboard',
        'icon': Icons.gavel_outlined,
        'route': '/referee/dashboard',
      },
      {
        'title': 'Dispute Governance',
        'icon': Icons.policy_outlined,
        'route': '/governance/disputes',
      },
      {
        'title': 'National Rankings',
        'icon': Icons.leaderboard_outlined,
        'route': '/rankings',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FEDERATION CONTROL SHORTCUTS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: AppTheme.textMuted,
            fontFamily: AppTheme.fontDisplay,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: shortcuts
              .map(
                (sc) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push(sc['route'] as String);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Icon(sc['icon'] as IconData,
                                color: AppTheme.goldPrimary, size: 20),
                            const SizedBox(height: 6),
                            Text(
                              sc['title'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ==========================================
  // PART 4 & 5: TOURNAMENT OVERSIGHT
  // ==========================================
  Widget _buildTournamentOversightSection(
      BuildContext context, AsyncValue<List<Map<String, dynamic>>> tournamentsAsync) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SANCTIONED TOURNAMENT OVERSIGHT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.textPrimary,
                  fontFamily: AppTheme.fontDisplay,
                ),
              ),
              InkWell(
                onTap: () => context.push('/tournaments'),
                child: const Text(
                  'Tournament Hub →',
                  style: TextStyle(
                    color: AppTheme.goldPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          tournamentsAsync.when(
            data: (tournaments) {
              final filtered = _searchQuery.isEmpty
                  ? tournaments
                  : tournaments.where((t) {
                      final n = (t['name'] ?? t['title'] ?? '').toString().toLowerCase();
                      final o = (t['organizer'] ?? '').toString().toLowerCase();
                      return n.contains(_searchQuery) || o.contains(_searchQuery);
                    }).toList();

              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'NO TOURNAMENTS MATCHING SEARCH CRITERIA',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length.clamp(0, 4),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final t = filtered[idx];
                  final name = t['name'] ?? t['title'] ?? 'National Championship';
                  final status = (t['status']?.toString().toUpperCase()) ?? 'SANCTIONED';
                  final organizer = t['organizer'] ?? 'PAFF Council';
                  final dates = t['startDate'] ?? 'Aug 2026';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events,
                            color: AppTheme.goldPrimary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$organizer • $dates',
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppTheme.success.withOpacity(0.4)),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: AppTheme.success,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chevron_right,
                              color: AppTheme.textMuted, size: 18),
                          onPressed: () =>
                              context.push('/tournament/details', extra: t),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const SkeletonPlaceholder(
                width: double.infinity, height: 100),
            error: (err, _) => Text('Error loading tournaments: $err',
                style: const TextStyle(color: AppTheme.error, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 6 & 7: REGISTRY & CREDENTIALS
  // ==========================================
  Widget _buildRegistryAndCredentialsSection(
      BuildContext context,
      AsyncValue<List<Map<String, dynamic>>> athletesAsync,
      AsyncValue<List<Map<String, dynamic>>> refereesAsync) {
    return Row(
      children: [
        // ATHLETE VERIFICATION REGISTRY CARD
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_outlined,
                        color: AppTheme.primaryAccent, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'ATHLETE LICENSES',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        fontFamily: AppTheme.fontDisplay,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '128 Active Licenses\n4 Pending Verification',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => context.push('/rankings'),
                    child: const Text(
                      'Manage Registry',
                      style: TextStyle(
                          color: AppTheme.primaryAccent, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // OFFICIALS CREDENTIALS CARD
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gavel, color: AppTheme.goldPrimary, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'REFEREE CREDENTIALS',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        fontFamily: AppTheme.fontDisplay,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '6 Certified Officials\n1 Credential Renewal',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.goldPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => context.push('/referee/dashboard'),
                    child: const Text(
                      'Manage Referees',
                      style: TextStyle(
                          color: AppTheme.goldLight, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // PART 8 & 10: CERTIFICATION & RANKINGS
  // ==========================================
  Widget _buildCertificationAndRankingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.workspace_premium,
                      color: AppTheme.goldPrimary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'RESULTS & CERTIFICATION GOVERNANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.textPrimary,
                      fontFamily: AppTheme.fontDisplay,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.success.withOpacity(0.4)),
                ),
                child: const Text(
                  'CERTIFIED ✓',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Official results from all national sanctioned events feed directly into the authoritative Pakistan ELO ranking engine.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statusMetric('Certified Standings', '18 Divisions', AppTheme.success),
              _statusMetric('Pending Audit', '0 Bouts', AppTheme.textPrimary),
              _statusMetric('Last ELO Commit', '2 Hours Ago', AppTheme.info),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _showCertificationModal(context),
              icon: const Icon(Icons.verified, color: AppTheme.background, size: 16),
              label: const Text(
                'AUTHORIZE NATIONAL RANKING UPDATE',
                style: TextStyle(
                  color: AppTheme.background,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  fontFamily: AppTheme.fontDisplay,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 9: DISPUTES & RECORD REVIEW
  // ==========================================
  Widget _buildDisputesGovernanceCard(
      BuildContext context, AsyncValue<List<Map<String, dynamic>>> disputesAsync) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.policy_outlined, color: AppTheme.warning, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'OFFICIAL RECORD & DISPUTE GOVERNANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.textPrimary,
                      fontFamily: AppTheme.fontDisplay,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/governance/disputes'),
                child: const Text(
                  'Review Cases →',
                  style: TextStyle(
                    color: AppTheme.goldPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          disputesAsync.when(
            data: (disputes) {
              if (disputes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: AppTheme.success, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'NO ACTIVE OFFICIAL DISPUTES OR APPEALS PENDING',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }

              final item = disputes.first;
              final reason = item['reason'] ?? item['title'] ?? 'Bout Appeal';
              final status = (item['status']?.toString().toUpperCase()) ?? 'UNDER REVIEW';

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gavel, color: AppTheme.warning, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reason,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Status: $status • Grievance Committee B',
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warning.withOpacity(0.2),
                        side: BorderSide(
                            color: AppTheme.warning.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => context.push('/governance/disputes'),
                      child: const Text('Review',
                          style: TextStyle(
                              color: AppTheme.warning, fontSize: 10)),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SkeletonPlaceholder(
                width: double.infinity, height: 40),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 11 & 20: AUDIT TRAIL & INTEGRITY
  // ==========================================
  Widget _buildAuditTrailAndIntegrityCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history_edu, color: AppTheme.info, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'GOVERNANCE AUDIT TRAIL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppTheme.textPrimary,
                      fontFamily: AppTheme.fontDisplay,
                    ),
                  ),
                ],
              ),
              Text(
                'Cryptographically Signed Log',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _auditLogItem('National Championship Sanctioned', 'PAFF Executive Council', 'Jul 28, 2026'),
          const Divider(color: AppTheme.border, height: 12),
          _auditLogItem('Referee Credential #Ref-102 Approved', 'Chief Referee Panel', 'Jul 25, 2026'),
          const Divider(color: AppTheme.border, height: 12),
          _auditLogItem('Senior Heavyweight Standings Certified', 'Technical Delegate', 'Jul 20, 2026'),
        ],
      ),
    );
  }

  Widget _auditLogItem(String action, String actor, String date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              action,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'By $actor',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
            ),
          ],
        ),
        Text(
          date,
          style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontFamily: AppTheme.fontMono),
        ),
      ],
    );
  }

  // ==========================================
  // MODAL CONFIRMATION DIALOGS
  // ==========================================
  void _showTournamentApprovalModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.glassSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.goldPrimary)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppTheme.goldPrimary),
            SizedBox(width: 8),
            Text(
              'Approve Tournament Sanction?',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 15),
            ),
          ],
        ),
        content: const Text(
          'Granting official PAFF sanctioning allows rankings eligibility, certified referee assignment, and official certificate issuance.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary),
            onPressed: () async {
              Navigator.pop(context);
              await SoundService.instance.playMatchWon();
              if (mounted) {
                CelebrationOverlay.show(
                  context,
                  title: 'TOURNAMENT SANCTIONED!',
                  subtitle: 'Official PAFF Competition Sanction Granted',
                  score: 100,
                  scoreSuffix: '%',
                  decimalPlaces: 0,
                  onDismiss: () {},
                );
              }
            },
            child: const Text(
              'Grant Sanction',
              style: TextStyle(
                  color: AppTheme.background,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showCertificationModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.glassSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.primaryAccent)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: AppTheme.primaryAccent),
            SizedBox(width: 8),
            Text(
              'Authorize National ELO Commit?',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 15),
            ),
          ],
        ),
        content: const Text(
          'This will recalculate and lock all participant ELO points for the 2026 National Leaderboard.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent),
            onPressed: () async {
              Navigator.pop(context);
              await SoundService.instance.playMatchWon();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ National ELO Ratings Updated & Committed!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text(
              'Authorize Commit',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
