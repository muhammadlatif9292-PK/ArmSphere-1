import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

import '../../../core/constants/asset_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/widgets/void_stage_scaffold.dart';
import '../../../core/widgets/championship_name_marquee.dart';
import '../../community/screens/video_player_modal.dart';
import '../../../core/providers/state_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/live_matches_provider.dart';
import '../../../core/providers/discover_provider.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/admin_provider.dart';


class MatchDetailScreen extends ConsumerStatefulWidget {
  final String matchId;
  final Map<String, dynamic>? initialMatchData;

  const MatchDetailScreen({
    super.key,
    required this.matchId,
    this.initialMatchData,
  });

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  bool _isActionLoading = false;

  Future<void> _refreshMatch() async {
    try {
      await ref.read(matchRepositoryProvider).getMatchById(
            widget.matchId,
            forceRefresh: true,
          );
    } catch (_) {}
    ref.invalidate(matchDetailProvider(widget.matchId));
    ref.invalidate(discoverFeedProvider);
    ref.invalidate(liveMatchesProvider);
  }

  String _formatDateTime(dynamic rawDate) {
    if (rawDate == null) return 'Official Federation Record';
    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return rawDate.toString();
    final local = parsed.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[local.month - 1];
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$month ${local.day}, ${local.year} • $hour12:$minute $period';
  }

  Map<String, int> _parseScores(Map<String, dynamic> data) {
    final scoreAVal = data['scoreA'];
    final scoreBVal = data['scoreB'];
    if (scoreAVal is num && scoreBVal is num) {
      return {'a': scoreAVal.toInt(), 'b': scoreBVal.toInt()};
    }
    final rawScore = (data['scoreLine'] ?? data['score'] ?? '0-0').toString();
    final parts = rawScore.split(RegExp(r'[\s\-:]+'));
    final a = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
    final b = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return {'a': a, 'b': b};
  }

  Future<void> _handleVerifyMatch(Map<String, dynamic> matchData) async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);
    try {
      await ref.read(matchRepositoryProvider).verifyMatch(widget.matchId);
      ref.invalidate(matchDetailProvider(widget.matchId));
      ref.invalidate(discoverFeedProvider);
      ref.invalidate(liveMatchesProvider);
      ref.invalidate(adminMatchesProvider);
      ref.invalidate(athleteProfileProvider);

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match officially verified and ELO ratings updated.'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: AppTheme.crimson,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _showDisputeSheet(Map<String, dynamic> matchData) async {
    final controller = TextEditingController();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF10151F),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: const Color(0xFFE5A93C).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5A93C).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.security_update_warning_rounded,
                        color: const Color(0xFFE5A93C),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'File Official Match Dispute',
                        style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Provide technical grounds for challenging this bout result (e.g. missed elbow foul, false start, or scoreline discrepancy).',
                  style: TextStyle(fontFamily: AppTheme.fontBody, 
                    color: AppTheme.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  style: TextStyle(fontFamily: AppTheme.fontBody, color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Describe the official reason for dispute (minimum 5 characters)...',
                    hintStyle: TextStyle(fontFamily: AppTheme.fontBody, color: AppTheme.textMuted, fontSize: 12.5),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: const Color(0xFFE5A93C)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (controller.text.trim().length < 5) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter at least 5 characters explaining the dispute.'),
                            backgroundColor: AppTheme.crimson,
                          ),
                        );
                        return;
                      }
                      Navigator.of(ctx).pop(true);
                    },
                    icon: const Icon(Icons.flag_rounded, size: 16),
                    label: Text(
                      'SUBMIT TO GOVERNANCE BOARD',
                      style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5A93C),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (submitted == true && controller.text.trim().length >= 5) {
      setState(() => _isActionLoading = true);
      try {
        await ref.read(matchRepositoryProvider).disputeMatch(
              widget.matchId,
              controller.text.trim(),
            );
        ref.invalidate(matchDetailProvider(widget.matchId));
        ref.invalidate(discoverFeedProvider);
        ref.invalidate(liveMatchesProvider);
        ref.invalidate(adminMatchesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Official match dispute submitted for Federation review.'),
              backgroundColor: const Color(0xFFE5A93C),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.crimson,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isActionLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(matchDetailProvider(widget.matchId));
    final authState = ref.watch(authProvider);
    final activeRole = (authState.activeRole ??
            authState.userProfile?['role']?.toString() ??
            'ATHLETE')
        .toUpperCase();
    final allRoles = <String>{
      ...authState.verifiedRoles.map((r) => r.toUpperCase()),
      activeRole,
    };
    final canVerifyOrOfficiate = allRoles.any(
      (r) =>
          r == 'REFEREE' ||
          r == 'SYSTEM_ADMIN' ||
          r == 'NATIONAL_DIRECTOR' ||
          r == 'PROVINCIAL_DIRECTOR',
    );

    final Map<String, dynamic> matchData = {
      ...?widget.initialMatchData,
      ...(detailAsync.valueOrNull ?? const <String, dynamic>{}),
    };

    final isInitialLoading = detailAsync.isLoading && matchData.isEmpty;
    final hasFatalError = detailAsync.hasError && matchData.isEmpty;

    return VoidStageScaffold(
      stageAsset: ArmSphereAssets.stageArena9x16,
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OFFICIAL BOUT DOSSIER',
              style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'REF #${widget.matchId.length > 8 ? widget.matchId.substring(0, 8).toUpperCase() : widget.matchId.toUpperCase()}',
              style: TextStyle(fontFamily: AppTheme.fontDisplay, fontFeatures: const [FontFeature.tabularFigures()], 
                color: AppTheme.goldPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Bout Telemetry',
            onPressed: _refreshMatch,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldPrimary),
            )
          : hasFatalError
              ? _buildErrorState(detailAsync.error)
              : RefreshIndicator(
                  color: AppTheme.goldPrimary,
                  backgroundColor: const Color(0x4704060B),
                  onRefresh: _refreshMatch,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    children: [
                      _buildEventOrSanctionBanner(matchData),
                      const SizedBox(height: 14),
                      _buildFaceOffHeroCard(matchData),
                      const SizedBox(height: 16),
                      _buildBoutMomentumBar(matchData),
                      const SizedBox(height: 16),
                      _buildOfficialTelemetryGrid(matchData),
                      if ((matchData['evidenceUrl']?.toString() ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildEvidenceVideoCard(matchData),
                      ],
                      const SizedBox(height: 18),
                      _buildConnectedActionsSection(
                        matchData,
                        canVerifyOrOfficiate: canVerifyOrOfficiate,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0x4704060B).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.crimson.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.crimson, size: 36),
              const SizedBox(height: 12),
              Text(
                'Unable to Load Match Dossier',
                style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString().replaceAll('Exception: ', '') ??
                    'The requested match record could not be retrieved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: AppTheme.fontBody, 
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _refreshMatch,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventOrSanctionBanner(Map<String, dynamic> data) {
    final eventName = (data['eventName'] ?? data['tournamentName'])?.toString().trim();
    final eventId = data['eventId']?.toString().trim();
    final isEventMatch = data['isEventMatch'] == true || (eventName != null && eventName.isNotEmpty);
    final round = data['round'];
    final tableName = data['tableName']?.toString().trim();
    final province = (data['province'] ?? data['challengerProvince'] ?? 'National').toString();

    return GestureDetector(
      onTap: isEventMatch && eventId != null && eventId.isNotEmpty
          ? () => context.push('/tournament/$eventId')
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEventMatch
                ? [
                    AppTheme.goldPrimary.withValues(alpha: 0.22),
                    const Color(0xFF131926).withValues(alpha: 0.92),
                  ]
                : [
                    AppTheme.cyan.withValues(alpha: 0.16),
                    const Color(0xFF131926).withValues(alpha: 0.92),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEventMatch
                ? AppTheme.goldPrimary.withValues(alpha: 0.45)
                : AppTheme.cyan.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: (isEventMatch ? AppTheme.goldPrimary : AppTheme.cyan)
                    .withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isEventMatch ? Icons.emoji_events_rounded : Icons.verified_user_rounded,
                color: isEventMatch ? AppTheme.goldPrimary : AppTheme.cyan,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEventMatch ? 'OFFICIAL TOURNAMENT BOUT' : 'SANCTIONED FEDERATION BOUT',
                    style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                      color: isEventMatch ? AppTheme.goldPrimary : AppTheme.cyan,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEventMatch
                        ? eventName!
                        : 'Official Ranked Match • $province Jurisdiction',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (isEventMatch && (round != null || (tableName != null && tableName.isNotEmpty))) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (round != null) 'Round $round',
                        if (tableName != null && tableName.isNotEmpty) tableName,
                      ].join(' • '),
                      style: TextStyle(fontFamily: AppTheme.fontBody, 
                        color: AppTheme.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isEventMatch && eventId != null && eventId.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EVENT',
                      style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                        color: AppTheme.goldPrimary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.goldPrimary,
                      size: 14,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceOffHeroCard(Map<String, dynamic> data) {
    final athleteAId = (data['athleteAId'] ?? data['challengerId'] ?? '').toString();
    final athleteBId = (data['athleteBId'] ?? data['opponentId'] ?? '').toString();

    final rawNameA = (data['athleteAName'] ?? data['challengerName'] ?? '').toString().trim();
    final rawNameB = (data['athleteBName'] ?? data['opponentName'] ?? '').toString().trim();
    final athleteAName = rawNameA.isNotEmpty ? rawNameA : 'Challenger';
    final athleteBName = rawNameB.isNotEmpty ? rawNameB : 'Opponent';

    final avatarA = (data['athleteAAvatar'] ?? data['challengerAvatar'])?.toString();
    final avatarB = (data['athleteBAvatar'] ?? data['opponentAvatar'])?.toString();

    final teamA = (data['athleteATeamName'] ?? data['challengerTeamName'] ?? data['athleteAClubName'])
        ?.toString()
        .trim();
    final teamB = (data['athleteBTeamName'] ?? data['opponentTeamName'] ?? data['athleteBClubName'])
        ?.toString()
        .trim();

    final weightA = (data['athleteAWeightClass'] ?? data['challengerWeightClass'] ?? data['weightClass'])
        ?.toString()
        .trim();
    final weightB = (data['athleteBWeightClass'] ?? data['opponentWeightClass'] ?? data['weightClass'])
        ?.toString()
        .trim();

    final scores = _parseScores(data);
    final scoreA = scores['a'] ?? 0;
    final scoreB = scores['b'] ?? 0;

    final winnerId = data['winnerId']?.toString();
    final isAWinner = (winnerId != null && winnerId.isNotEmpty && winnerId == athleteAId) ||
        ((winnerId == null || winnerId.isEmpty) && scoreA > scoreB);
    final isBWinner = (winnerId != null && winnerId.isNotEmpty && winnerId == athleteBId) ||
        ((winnerId == null || winnerId.isEmpty) && scoreB > scoreA);

    final status = (data['status'] ?? 'VERIFIED').toString().toUpperCase();
    final arm = (data['arm'] ?? 'RIGHT').toString().toUpperCase();
    final division = (data['division'] ?? data['weightClass'] ?? weightA ?? weightB ?? 'Open').toString();

    final eloA = data['challengerNewElo'] ?? data['challengerElo'];
    final eloB = data['opponentNewElo'] ?? data['opponentElo'];
    final deltaA = data['challengerEloDelta'] as num?;
    final deltaB = data['opponentEloDelta'] as num?;

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'VERIFIED':
      case 'COMPLETED':
        statusColor = AppTheme.emerald;
        statusLabel = 'FINAL • VERIFIED';
        break;
      case 'LIVE':
      case 'IN_PROGRESS':
        statusColor = AppTheme.crimson;
        statusLabel = 'LIVE ON TABLE';
        break;
      case 'DISPUTED':
        statusColor = const Color(0xFFE5A93C);
        statusLabel = 'UNDER DISPUTE';
        break;
      case 'VOID':
        statusColor = AppTheme.textMuted;
        statusLabel = 'VOIDED';
        break;
      default:
        statusColor = const Color(0xFFE5A93C);
        statusLabel = 'PENDING VERIFICATION';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E131D).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: 0.32),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Status & Arm / Weight Class Bar
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                        color: statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      ArmSphereFormatters.formatArmLabel(arm, uppercase: true),
                      style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                        color: AppTheme.goldPrimary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    child: Text(
                      division.toUpperCase(),
                      style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                        color: Colors.white70,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Red Corner vs Scoreboard vs Blue Corner
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildAthleteCornerColumn(
                  athleteId: athleteAId,
                  name: athleteAName,
                  avatarUrl: avatarA,
                  teamName: teamA,
                  weightClass: weightA,
                  cornerLabel: 'RED CORNER',
                  cornerColor: AppTheme.crimson,
                  isWinner: isAWinner,
                  elo: eloA,
                  eloDelta: deltaA,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1A2234),
                            const Color(0xFF0E131D),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$scoreA',
                            style: TextStyle(fontFamily: AppTheme.fontDisplay, fontFeatures: const [FontFeature.tabularFigures()], 
                              color: isAWinner ? AppTheme.goldPrimary : Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              ':',
                              style: TextStyle(fontFamily: AppTheme.fontDisplay, fontFeatures: const [FontFeature.tabularFigures()], 
                                color: AppTheme.textMuted,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '$scoreB',
                            style: TextStyle(fontFamily: AppTheme.fontDisplay, fontFeatures: const [FontFeature.tabularFigures()], 
                              color: isBWinner ? AppTheme.goldPrimary : Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SCORELINE',
                      style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                        color: AppTheme.textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildAthleteCornerColumn(
                  athleteId: athleteBId,
                  name: athleteBName,
                  avatarUrl: avatarB,
                  teamName: teamB,
                  weightClass: weightB,
                  cornerLabel: 'BLUE CORNER',
                  cornerColor: AppTheme.cyan,
                  isWinner: isBWinner,
                  elo: eloB,
                  eloDelta: deltaB,
                ),
              ),
            ],
          ),

          if (isAWinner || isBWinner) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.goldPrimary.withValues(alpha: 0.18),
                    AppTheme.goldPrimary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.38),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.military_tech_rounded,
                    color: AppTheme.goldPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'OFFICIAL WINNER: ${(isAWinner ? athleteAName : athleteBName).toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                        color: AppTheme.goldPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
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

  Widget _buildAthleteCornerColumn({
    required String athleteId,
    required String name,
    required String? avatarUrl,
    required String? teamName,
    required String? weightClass,
    required String cornerLabel,
    required Color cornerColor,
    required bool isWinner,
    required dynamic elo,
    required num? eloDelta,
  }) {
    final hasTeam = teamName != null && teamName.isNotEmpty;
    final affiliationText = hasTeam
        ? teamName
        : (weightClass != null && weightClass.isNotEmpty
            ? 'Independent • $weightClass'
            : 'Independent • Open');

    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join()
        : 'A';

    return GestureDetector(
      onTap: athleteId.isNotEmpty ? () => context.push('/athlete/$athleteId') : null,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cornerColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cornerColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              cornerLabel,
              style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                color: cornerColor,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isWinner
                        ? [AppTheme.goldPrimary, const Color(0xFFB8860B)]
                        : [cornerColor.withValues(alpha: 0.65), Colors.white12],
                  ),
                  boxShadow: isWinner
                      ? [
                          BoxShadow(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                padding: const EdgeInsets.all(2.5),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF151C28),
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Text(
                          initials,
                          style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
              ),
              if (isWinner)
                Positioned(
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      size: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ChampionshipNameMarquee(
            text: name,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: AppTheme.fontDisplay, 
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: hasTeam
                  ? AppTheme.goldPrimary.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasTeam
                    ? AppTheme.goldPrimary.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasTeam ? Icons.shield_outlined : Icons.how_to_reg_rounded,
                  size: 11,
                  color: hasTeam ? AppTheme.goldPrimary : AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    affiliationText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: AppTheme.fontBody, 
                      color: hasTeam ? AppTheme.goldPrimary : AppTheme.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (elo != null || eloDelta != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (elo != null)
                  Text(
                    '$elo ELO',
                    style: TextStyle(fontFamily: AppTheme.fontDisplay, fontFeatures: const [FontFeature.tabularFigures()], 
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (eloDelta != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: (eloDelta >= 0
                              ? AppTheme.emerald
                              : AppTheme.crimson)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${eloDelta >= 0 ? '+' : ''}$eloDelta',
                      style: TextStyle(fontFamily: AppTheme.fontDisplay, fontFeatures: const [FontFeature.tabularFigures()], 
                        color: eloDelta >= 0
                            ? AppTheme.emerald
                            : AppTheme.crimson,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBoutMomentumBar(Map<String, dynamic> data) {
    final scores = _parseScores(data);
    final scoreA = scores['a'] ?? 0;
    final scoreB = scores['b'] ?? 0;
    final total = (scoreA + scoreB) > 0 ? (scoreA + scoreB) : 1;
    final ratioA = (scoreA + scoreB) > 0 ? scoreA / total : 0.5;

    final rawNameA = (data['athleteAName'] ?? data['challengerName'] ?? 'Red Corner').toString();
    final rawNameB = (data['athleteBName'] ?? data['opponentName'] ?? 'Blue Corner').toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E131D).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$rawNameA ($scoreA Pins)',
                style: TextStyle(fontFamily: AppTheme.fontBody, 
                  color: AppTheme.crimson,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'PIN DOMINANCE',
                style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '$rawNameB ($scoreB Pins)',
                style: TextStyle(fontFamily: AppTheme.fontBody, 
                  color: AppTheme.cyan,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (ratioA * 100).round().clamp(10, 90),
                    child: Container(color: AppTheme.crimson),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: ((1 - ratioA) * 100).round().clamp(10, 90),
                    child: Container(color: AppTheme.cyan),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialTelemetryGrid(Map<String, dynamic> data) {
    final dateStr = _formatDateTime(data['verifiedAt'] ?? data['createdAt']);
    final venueName = (data['venueName'] ?? 'Sanctioned Championship Arena').toString();
    final city = (data['city'] ?? data['province'] ?? 'Pakistan').toString();
    final refereeName = (data['refereeName'] ?? 'Certified Official').toString();
    final refereeRole = (data['refereeRole'] ?? 'REFEREE').toString().replaceAll('_', ' ');
    final eventName = (data['eventName'] ?? data['tournamentName'])?.toString().trim();
    final tableName = data['tableName']?.toString().trim();
    final round = data['round'];

    final eventDisplay = (eventName != null && eventName.isNotEmpty)
        ? [
            eventName,
            if (round != null) 'Round $round',
            if (tableName != null && tableName.isNotEmpty) tableName,
          ].join(' • ')
        : 'Sanctioned Open / Independent Match';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E131D).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.goldPrimary, size: 16),
              const SizedBox(width: 8),
              Text(
                'OFFICIAL BOUT TELEMETRY & DOSSIER',
                style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTelemetryRow(
            icon: Icons.calendar_today_rounded,
            iconColor: AppTheme.goldPrimary,
            label: 'DATE & OFFICIAL TIMESTAMP',
            value: dateStr,
          ),
          const Divider(color: Colors.white10, height: 20),
          _buildTelemetryRow(
            icon: Icons.location_on_rounded,
            iconColor: AppTheme.cyan,
            label: 'ARENA VENUE & LOCATION',
            value: '$venueName • $city',
          ),
          const Divider(color: Colors.white10, height: 20),
          _buildTelemetryRow(
            icon: Icons.gavel_rounded,
            iconColor: AppTheme.emerald,
            label: 'OFFICIATING HEAD REFEREE',
            value: '$refereeName ($refereeRole)',
          ),
          const Divider(color: Colors.white10, height: 20),
          _buildTelemetryRow(
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFFE5A93C),
            label: 'EVENT / TOURNAMENT CLASSIFICATION',
            value: eventDisplay,
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(fontFamily: AppTheme.fontBody, 
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceVideoCard(Map<String, dynamic> data) {
    final evidenceUrl = data['evidenceUrl']!.toString().trim();
    final nameA = (data['athleteAName'] ?? data['challengerName'] ?? 'Athlete A').toString();
    final nameB = (data['athleteBName'] ?? data['opponentName'] ?? 'Athlete B').toString();

    return GestureDetector(
      onTap: () {
        VideoPlayerModal.show(
          context,
          videoUrl: evidenceUrl,
          title: '$nameA vs $nameB — Official Bout Footage',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF131B2A).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_circle_fill_rounded, color: AppTheme.cyan, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OFFICIAL BOUT VIDEO EVIDENCE',
                    style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                      color: AppTheme.cyan,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Watch verified table recording in ArmSphere Player',
                    style: TextStyle(fontFamily: AppTheme.fontBody, 
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: AppTheme.cyan, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedActionsSection(
    Map<String, dynamic> data, {
    required bool canVerifyOrOfficiate,
  }) {
    final athleteAId = (data['athleteAId'] ?? data['challengerId'] ?? '').toString();
    final athleteBId = (data['athleteBId'] ?? data['opponentId'] ?? '').toString();
    final status = (data['status'] ?? 'VERIFIED').toString().toUpperCase();
    final isPending = status == 'PENDING_VERIFICATION';
    final canDispute = status == 'VERIFIED' || status == 'PENDING_VERIFICATION';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tale of the Tape (Head-to-Head Compare)
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              final query = Uri(
                queryParameters: {
                  'matchId': widget.matchId,
                  if (athleteAId.isNotEmpty) 'athleteId1': athleteAId,
                  if (athleteBId.isNotEmpty) 'athleteId2': athleteBId,
                },
              ).query;
              context.push('/matches/head-to-head?$query', extra: data);
            },
            icon: const Icon(Icons.sports_kabaddi_rounded, size: 18),
            label: Text(
              'TALE OF THE TAPE (HEAD-TO-HEAD)',
              style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: 0.8,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldPrimary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        if (isPending && canVerifyOrOfficiate) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isActionLoading ? null : () => _handleVerifyMatch(data),
              icon: _isActionLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                'VERIFY RESULT & COMMIT ELO',
                style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  letterSpacing: 0.8,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emerald,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],

        if (canDispute) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _isActionLoading ? null : () => _showDisputeSheet(data),
              icon: const Icon(Icons.flag_rounded, size: 16),
              label: Text(
                'CHALLENGE / DISPUTE MATCH RESULT',
                style: TextStyle(fontFamily: AppTheme.fontDisplay, 
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.7,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE5A93C),
                side: BorderSide(color: const Color(0xFFE5A93C).withValues(alpha: 0.45)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
