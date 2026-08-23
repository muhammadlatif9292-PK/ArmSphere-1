import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/count_up_text.dart';
import '../../../core/audio/sound_service.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../auth/providers/auth_provider.dart';

// ==========================================
// SCREEN 13: OFFICIAL SCOREPAD & MATCH CERTIFICATION (CONCEPT 2)
// ==========================================

enum MatchOperationalState {
  ready,
  running,
  paused,
  restart,
  officialReview,
  completed,
  certificationRequired,
  certified,
}

class OfficialScorepadScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? match;
  const OfficialScorepadScreen({Key? key, this.match}) : super(key: key);

  @override
  ConsumerState<OfficialScorepadScreen> createState() =>
      _OfficialScorepadScreenState();
}

class _OfficialScorepadScreenState
    extends ConsumerState<OfficialScorepadScreen> {
  // Operational Match State
  MatchOperationalState _matchState = MatchOperationalState.ready;
  bool _isAthletesVerified = true;
  bool _isOffline = false;
  bool _isTimerRunning = false;
  int _matchTimerSeconds = 0;
  bool _isSubmitting = false;
  bool _isCertified = false;
  bool _hasConcurrentConflict = false;
  String _certificationTimestamp = '';
  String _signatureHash = '';

  // Best of format configuration (3 or 5)
  int _maxRounds = 5; // Default Best of 5
  int _targetWins = 3; // First to 3

  // Score & Round tracking
  // round index -> winner ('A', 'B', or null if undecided)
  final Map<int, String?> _roundWinners = {
    1: 'A',
    2: 'B',
    3: 'A',
    4: null,
    5: null,
  };

  // Fouls list
  final List<Map<String, dynamic>> _fouls = [
    {
      'id': 'F-101',
      'athlete': 'Athlete A',
      'athleteName': 'Muhammad Ahmed',
      'type': 'Elbow Foul',
      'round': 2,
      'time': '09:42:48',
      'referee': 'Ahmed Ali',
    },
    {
      'id': 'F-102',
      'athlete': 'Athlete B',
      'athleteName': 'Tariq Khan',
      'type': 'False Start',
      'round': 3,
      'time': '09:44:12',
      'referee': 'Ahmed Ali',
    },
  ];

  // Restarts list
  final List<Map<String, dynamic>> _restarts = [
    {
      'id': 'R-201',
      'reason': 'Slip in Straps',
      'round': 2,
      'time': '09:43:02',
      'athlete': 'Both',
    },
  ];

  // Match Timeline
  final List<Map<String, dynamic>> _timelineEvents = [
    {'time': '09:40:00', 'event': 'Bout Assigned & Table 04 Prepped'},
    {'time': '09:41:15', 'event': 'Athletes Identity & Weight Verified'},
    {'time': '09:42:00', 'event': 'Round 1 Started — Athlete A Pinfall Win'},
    {'time': '09:42:48', 'event': 'Round 2 Elbow Foul — Athlete A'},
    {'time': '09:43:02', 'event': 'Ref Strap Applied (Restart)'},
    {'time': '09:43:30', 'event': 'Round 2 Won — Athlete B'},
    {'time': '09:44:12', 'event': 'Round 3 False Start — Athlete B'},
    {'time': '09:45:00', 'event': 'Round 3 Won — Athlete A'},
  ];

  // Evidence attachments
  final List<Map<String, dynamic>> _evidenceFiles = [
    {
      'title': 'High-Speed Camera Angle Table 04',
      'type': 'Video Recording',
      'time': '09:43:02',
      'status': 'Verified HD',
    },
  ];

  // Amendment request state
  bool _amendmentRequested = false;

  @override
  void initState() {
    super.initState();
    _loadMatchData();
  }

  void _loadMatchData() {
    if (widget.match != null) {
      final m = widget.match!;
      final format = m['format'] ?? m['matchFormat'] ?? 'Best of 5';
      if (format.toString().contains('3')) {
        _maxRounds = 3;
        _targetWins = 2;
      } else {
        _maxRounds = 5;
        _targetWins = 3;
      }
    }
  }

  // Calculated Scores
  int get _scoreA {
    return _roundWinners.values.where((w) => w == 'A').length;
  }

  int get _scoreB {
    return _roundWinners.values.where((w) => w == 'B').length;
  }

  String? get _calculatedWinner {
    if (_scoreA >= _targetWins) return 'Athlete A';
    if (_scoreB >= _targetWins) return 'Athlete B';
    return null;
  }

  bool get _isMatchComplete {
    return _scoreA >= _targetWins || _scoreB >= _targetWins;
  }

  List<String> get _validationErrors {
    final List<String> errors = [];
    if (!_isAthletesVerified) {
      errors.add('Athletes identity verification is incomplete');
    }
    if (!_isMatchComplete) {
      errors.add('Match score incomplete (First to $_targetWins wins required)');
    }
    if (_hasConcurrentConflict) {
      errors.add('Concurrent match record modification detected');
    }
    return errors;
  }

  bool get _canCertify => _validationErrors.isEmpty;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).userProfile ?? {};
    final match = widget.match ?? {};

    final athleteAName =
        match['athleteAName'] ?? match['athleteA'] ?? 'Muhammad Ahmed';
    final athleteBName =
        match['athleteBName'] ?? match['athleteB'] ?? 'Tariq Khan';

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.glassSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () async {
              if (await _handleWillPop()) {
                if (mounted) context.pop();
              }
            },
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OFFICIAL SCOREPAD',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'ArmSphere Official Certification Surface',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isOffline ? Icons.wifi_off : Icons.wifi,
                color: _isOffline ? AppTheme.warning : AppTheme.success,
                size: 20,
              ),
              tooltip: _isOffline ? 'Offline Mode' : 'Online Sync',
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _isOffline = !_isOffline);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isOffline
                        ? 'Switched to Encrypted Local Draft Mode'
                        : 'Switched to Authoritative Live Federation Sync'),
                    backgroundColor:
                        _isOffline ? AppTheme.warning : AppTheme.success,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.sync_problem,
                  color: AppTheme.textMuted, size: 20),
              tooltip: 'Simulate Conflict',
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(
                    () => _hasConcurrentConflict = !_hasConcurrentConflict);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // OFFLINE & CONCURRENT CONFLICT WARNING STRIPS
              _buildOperationalStatusBanner(),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PART 1 — OFFICIAL MATCH CONTEXT HEADER
                      _buildMatchContextHeader(match),

                      const SizedBox(height: 14),

                      // PART 2 — ATHLETE VERIFICATION STRIP
                      _buildAthleteVerificationStrip(
                          athleteAName, athleteBName),

                      const SizedBox(height: 14),

                      // PART 3 — MATCH STATE CONTROL
                      _buildMatchStateControl(),

                      const SizedBox(height: 16),

                      // PART 4 — ROUND SCOREPAD (MAIN INTERACTION)
                      _buildRoundScorepad(athleteAName, athleteBName),

                      const SizedBox(height: 16),

                      // PART 5 — FOUL RECORDING
                      _buildFoulRecordingSection(athleteAName, athleteBName),

                      const SizedBox(height: 16),

                      // PART 6 — RESTART RECORDING
                      _buildRestartRecordingSection(),

                      const SizedBox(height: 16),

                      // PART 8 — AUTHORITATIVE MATCH TIMER
                      _buildMatchTimerSection(),

                      const SizedBox(height: 16),

                      // PART 7 — ROUND TIMELINE
                      _buildMatchTimelineSection(),

                      const SizedBox(height: 16),

                      // PART 9 — FINAL RESULT CALCULATION
                      _buildFinalResultCard(athleteAName, athleteBName),

                      const SizedBox(height: 16),

                      // PART 12 — EVIDENCE ATTACHMENT
                      _buildEvidenceSection(),

                      const SizedBox(height: 16),

                      // PART 10 & 11 — RESULT VALIDATION & REVIEW STATE
                      _buildValidationAndReviewPanel(),

                      const SizedBox(height: 16),

                      // PART 13 — REFEREE CONFIRMATION / SIGNATURE IDENTITY
                      _buildRefereeIdentityCard(user),

                      const SizedBox(height: 16),

                      // PART 18 — AMENDMENT WORKFLOW (IF CERTIFIED)
                      if (_isCertified) _buildAmendmentSection(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // PART 15 — PRIMARY CERTIFICATION ACTION BAR
              _buildCertificationBottomBar(athleteAName, athleteBName),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // OPERATIONAL STATUS BANNER (OFFLINE / CONFLICT)
  // ==========================================
  Widget _buildOperationalStatusBanner() {
    if (!_isOffline && !_hasConcurrentConflict) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: AppTheme.surface,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.circle, color: AppTheme.success, size: 8),
                SizedBox(width: 8),
                Text(
                  'ONLINE • AUTHORITATIVE FEDERATION SYNC',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            Text(
              'PAF Engine v1.0',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_isOffline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppTheme.warning.withOpacity(0.2),
            child: const Row(
              children: [
                Icon(Icons.wifi_off, color: AppTheme.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OFFLINE • ENCRYPTED LOCAL DRAFT • PENDING SYNC',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_hasConcurrentConflict)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppTheme.error.withOpacity(0.25),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.error, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CONCURRENT RECORD MODIFICATION DETECTED',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _hasConcurrentConflict = false);
                  },
                  child: const Text('Resolve',
                      style:
                          TextStyle(color: AppTheme.textPrimary, fontSize: 10)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==========================================
  // PART 1: OFFICIAL MATCH CONTEXT HEADER
  // ==========================================
  Widget _buildMatchContextHeader(Map<String, dynamic> match) {
    final table = match['table'] ?? 'TABLE 04';
    final matchId = match['id'] ?? 'M-2026-01842';
    final arm = match['arm'] ?? 'RIGHT ARM';
    final weight = match['weight'] ?? '85 KG SENIOR';
    final stage = match['stage'] ?? 'QUARTER FINAL';
    final tournament =
        match['tournamentName'] ?? 'Pakistan National Championship 2026';

    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: AppTheme.goldPrimary.withOpacity(0.4),
      enableGlow: true,
      glowColor: AppTheme.goldPrimary.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppTheme.goldPrimary.withOpacity(0.5)),
                    ),
                    child: Text(
                      table.toString().toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.goldLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#$matchId',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontFamily: AppTheme.fontMono,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              _buildMatchStateChip(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tournament,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$stage • $arm • $weight',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontDisplay,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  'Best of $_maxRounds',
                  style: const TextStyle(
                    color: AppTheme.primaryAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchStateChip() {
    Color chipColor;
    String label;
    IconData icon;

    switch (_matchState) {
      case MatchOperationalState.ready:
        chipColor = AppTheme.info;
        label = 'READY';
        icon = Icons.play_circle_outline;
        break;
      case MatchOperationalState.running:
        chipColor = AppTheme.primaryAccent;
        label = 'LIVE';
        icon = Icons.bolt;
        break;
      case MatchOperationalState.paused:
        chipColor = AppTheme.warning;
        label = 'PAUSED';
        icon = Icons.pause_circle_outline;
        break;
      case MatchOperationalState.restart:
        chipColor = AppTheme.warning;
        label = 'RESTART';
        icon = Icons.restart_alt;
        break;
      case MatchOperationalState.officialReview:
        chipColor = AppTheme.secondaryAccent;
        label = 'REVIEW';
        icon = Icons.policy;
        break;
      case MatchOperationalState.completed:
        chipColor = AppTheme.success;
        label = 'COMPLETED';
        icon = Icons.check_circle_outline;
        break;
      case MatchOperationalState.certificationRequired:
        chipColor = AppTheme.goldPrimary;
        label = 'SIGNATURE REQ.';
        icon = Icons.assignment_turned_in;
        break;
      case MatchOperationalState.certified:
        chipColor = AppTheme.success;
        label = 'OFFICIALLY CERTIFIED';
        icon = Icons.verified;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: chipColor, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 2: ATHLETE VERIFICATION STRIP
  // ==========================================
  Widget _buildAthleteVerificationStrip(String nameA, String nameB) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isAthletesVerified
              ? AppTheme.border
              : AppTheme.warning.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'COMPETITOR VERIFICATION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textMuted,
                  fontFamily: AppTheme.fontDisplay,
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isAthletesVerified = !_isAthletesVerified);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (_isAthletesVerified
                            ? AppTheme.success
                            : AppTheme.warning)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (_isAthletesVerified
                              ? AppTheme.success
                              : AppTheme.warning)
                          .withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAthletesVerified
                            ? Icons.verified
                            : Icons.warning_amber_rounded,
                        color: _isAthletesVerified
                            ? AppTheme.success
                            : AppTheme.warning,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isAthletesVerified
                            ? 'ATHLETES VERIFIED ✓'
                            : 'IDENTITY REQ.',
                        style: TextStyle(
                          color: _isAthletesVerified
                              ? AppTheme.success
                              : AppTheme.warning,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // ATHLETE A
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.goldPrimary.withOpacity(0.2),
                      child: const Text('MA',
                          style: TextStyle(
                              color: AppTheme.goldPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  nameA,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified,
                                  color: AppTheme.goldPrimary, size: 12),
                            ],
                          ),
                          const Text(
                            'Lahore Titans • Punjab',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: AppTheme.goldPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: AppTheme.fontDisplay,
                  ),
                ),
              ),
              // ATHLETE B
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
                      child: const Text('TK',
                          style: TextStyle(
                              color: AppTheme.primaryAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  nameB,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified,
                                  color: AppTheme.primaryAccent, size: 12),
                            ],
                          ),
                          const Text(
                            'Karachi Warriors • Sindh',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 3: MATCH STATE CONTROL
  // ==========================================
  Widget _buildMatchStateControl() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MATCH OPERATIONAL STATE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppTheme.textMuted,
              fontFamily: AppTheme.fontDisplay,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _stateButton(MatchOperationalState.ready, 'READY', Icons.play_arrow),
                const SizedBox(width: 6),
                _stateButton(MatchOperationalState.running, 'LIVE BOUT', Icons.bolt),
                const SizedBox(width: 6),
                _stateButton(MatchOperationalState.paused, 'PAUSE', Icons.pause),
                const SizedBox(width: 6),
                _stateButton(MatchOperationalState.restart, 'RESTART', Icons.restart_alt),
                const SizedBox(width: 6),
                _stateButton(MatchOperationalState.officialReview, 'REVIEW', Icons.policy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stateButton(MatchOperationalState state, String label, IconData icon) {
    final isSelected = _matchState == state;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _matchState = state);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.goldPrimary
              : AppTheme.elevatedSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.goldPrimary : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppTheme.background : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.background : AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PART 4: ROUND SCOREPAD (MAIN INTERACTION)
  // ==========================================
  Widget _buildRoundScorepad(String nameA, String nameB) {
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
                'OFFICIAL ROUND SCOREPAD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.goldPrimary,
                  fontFamily: AppTheme.fontDisplay,
                ),
              ),
              Row(
                children: [
                  const Text('Format: ',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  DropdownButton<int>(
                    value: _maxRounds,
                    dropdownColor: AppTheme.surface,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                          value: 3,
                          child: Text('Best of 3',
                              style: TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 10))),
                      DropdownMenuItem(
                          value: 5,
                          child: Text('Best of 5',
                              style: TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 10))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _maxRounds = val;
                          _targetWins = val == 3 ? 2 : 3;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // LIVE SCORE DISPLAY
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.elevatedSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      nameA,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CountUpText(
                      value: _scoreA,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldPrimary,
                        fontFamily: AppTheme.fontMono,
                      ),
                    ),
                  ],
                ),
                const Text(
                  '—',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 24,
                      fontWeight: FontWeight.w300),
                ),
                Column(
                  children: [
                    Text(
                      nameB,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CountUpText(
                      value: _scoreB,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAccent,
                        fontFamily: AppTheme.fontMono,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ROUND BY ROUND CARDS
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _maxRounds,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final rNum = idx + 1;
              final winner = _roundWinners[rNum];

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: winner != null
                      ? AppTheme.elevatedSurface
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: winner == 'A'
                        ? AppTheme.goldPrimary.withOpacity(0.5)
                        : winner == 'B'
                            ? AppTheme.primaryAccent.withOpacity(0.5)
                            : AppTheme.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Center(
                        child: Text(
                          'R$rNum',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        winner == 'A'
                            ? '$nameA WINS (Pinfall)'
                            : winner == 'B'
                                ? '$nameB WINS (Pinfall)'
                                : 'Round $rNum Pending Decision',
                        style: TextStyle(
                          color: winner != null
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted,
                          fontWeight: winner != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _roundWinners[rNum] =
                                _roundWinners[rNum] == 'A' ? null : 'A');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: winner == 'A'
                                  ? AppTheme.goldPrimary
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: winner == 'A'
                                    ? AppTheme.goldPrimary
                                    : AppTheme.border,
                              ),
                            ),
                            child: Text(
                              'A WINS',
                              style: TextStyle(
                                color: winner == 'A'
                                    ? AppTheme.background
                                    : AppTheme.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _roundWinners[rNum] =
                                _roundWinners[rNum] == 'B' ? null : 'B');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: winner == 'B'
                                  ? AppTheme.primaryAccent
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: winner == 'B'
                                    ? AppTheme.primaryAccent
                                    : AppTheme.border,
                              ),
                            ),
                            child: Text(
                              'B WINS',
                              style: TextStyle(
                                color: winner == 'B'
                                    ? AppTheme.textPrimary
                                    : AppTheme.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
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
        ],
      ),
    );
  }

  // ==========================================
  // PART 5: FOUL RECORDING
  // ==========================================
  Widget _buildFoulRecordingSection(String nameA, String nameB) {
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
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warning, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'OFFICIAL FOUL RECORD',
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
                onTap: () => _showAddFoulDialog(context, nameA, nameB),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: AppTheme.warning, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'ADD FOUL',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_fouls.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'NO OFFICIAL FOULS LOGGED IN THIS MATCH',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _fouls.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                final f = _fouls[idx];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'R${f['round']}',
                          style: const TextStyle(
                            color: AppTheme.warning,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${f['athleteName']} — ${f['type']}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Logged by ${f['referee']} at ${f['time']}',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppTheme.textMuted, size: 14),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _fouls.removeAt(idx));
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddFoulDialog(BuildContext context, String nameA, String nameB) {
    String selectedAthlete = nameA;
    String foulType = 'Elbow Foul';
    int roundNum = 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECORD OFFICIAL FOUL',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: AppTheme.fontDisplay,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Select Athlete:',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(nameA,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 11)),
                          value: nameA,
                          groupValue: selectedAthlete,
                          onChanged: (val) =>
                              setModalState(() => selectedAthlete = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(nameB,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 11)),
                          value: nameB,
                          groupValue: selectedAthlete,
                          onChanged: (val) =>
                              setModalState(() => selectedAthlete = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Foul Type:',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  DropdownButton<String>(
                    value: foulType,
                    dropdownColor: AppTheme.surface,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 'Elbow Foul', child: Text('Elbow Foul')),
                      DropdownMenuItem(
                          value: 'False Start', child: Text('False Start')),
                      DropdownMenuItem(
                          value: 'Running Foul', child: Text('Running Foul')),
                      DropdownMenuItem(
                          value: 'Slip-Out', child: Text('Slip-Out')),
                      DropdownMenuItem(
                          value: 'Intentional Slip',
                          child: Text('Intentional Slip')),
                    ],
                    onChanged: (val) => setModalState(() => foulType = val!),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warning,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _fouls.add({
                            'id': 'F-${DateTime.now().millisecondsSinceEpoch}',
                            'athleteName': selectedAthlete,
                            'type': foulType,
                            'round': roundNum,
                            'time': 'Just now',
                            'referee': 'Ahmed Ali',
                          });
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Log Official Foul',
                          style: TextStyle(
                              color: AppTheme.background,
                              fontWeight: FontWeight.bold)),
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

  // ==========================================
  // PART 6: RESTART RECORDING
  // ==========================================
  Widget _buildRestartRecordingSection() {
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
                  Icon(Icons.restart_alt, color: AppTheme.info, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'OFFICIAL RESTARTS & STRAP LOG',
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
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _restarts.add({
                      'id': 'R-${DateTime.now().millisecondsSinceEpoch}',
                      'reason': 'Ref Strap Applied',
                      'round': 2,
                      'time': 'Just now',
                      'athlete': 'Both',
                    });
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.info.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: AppTheme.info, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'ADD RESTART',
                        style: TextStyle(
                          color: AppTheme.info,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_restarts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'NO RESTARTS RECORDED',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _restarts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                final r = _restarts[idx];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.elevatedSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'R${r['round']} • ${r['reason']} (${r['athlete']})',
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 10),
                      ),
                      Text(
                        r['time'] as String,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 9),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 8: AUTHORITATIVE MATCH TIMER
  // ==========================================
  Widget _buildMatchTimerSection() {
    final mins = (_matchTimerSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_matchTimerSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  color: AppTheme.goldPrimary, size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OFFICIAL BOUT TIMER',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$mins:$secs.00',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: AppTheme.fontMono,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isTimerRunning
                      ? Icons.pause_circle
                      : Icons.play_circle_fill,
                  color: AppTheme.goldPrimary,
                  size: 28,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isTimerRunning = !_isTimerRunning);
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh,
                    color: AppTheme.textMuted, size: 20),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isTimerRunning = false;
                    _matchTimerSeconds = 0;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 7: ROUND TIMELINE
  // ==========================================
  Widget _buildMatchTimelineSection() {
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
          const Text(
            'AUTHORITATIVE BOUT TIMELINE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppTheme.textMuted,
              fontFamily: AppTheme.fontDisplay,
            ),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _timelineEvents.length.clamp(0, 5),
            separatorBuilder: (_, __) =>
                const Divider(color: AppTheme.border, height: 10),
            itemBuilder: (context, idx) {
              final ev = _timelineEvents[idx];
              return Row(
                children: [
                  Text(
                    ev['time'] as String,
                    style: const TextStyle(
                      color: AppTheme.goldPrimary,
                      fontSize: 10,
                      fontFamily: AppTheme.fontMono,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ev['event'] as String,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
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
  // PART 9: FINAL RESULT CALCULATION
  // ==========================================
  Widget _buildFinalResultCard(String nameA, String nameB) {
    final winner = _calculatedWinner;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: winner != null
              ? AppTheme.goldPrimary.withOpacity(0.6)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DERIVED FINAL RESULT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppTheme.goldPrimary,
              fontFamily: AppTheme.fontDisplay,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    winner != null
                        ? '${winner == 'Athlete A' ? nameA : nameB} WINS BOUT'
                        : 'DECISION PENDING',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: AppTheme.fontDisplay,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Final Score: $_scoreA — $_scoreB • Best of $_maxRounds',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (winner != null
                          ? AppTheme.goldPrimary
                          : AppTheme.textMuted)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  winner != null ? 'OFFICIAL WIN' : 'INCOMPLETE',
                  style: TextStyle(
                    color: winner != null
                        ? AppTheme.goldLight
                        : AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 12: EVIDENCE ATTACHMENT
  // ==========================================
  Widget _buildEvidenceSection() {
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
                  Icon(Icons.videocam_outlined,
                      color: AppTheme.primaryAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'EVIDENCE ATTACHMENTS',
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
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _evidenceFiles.add({
                      'title': 'Referee Scorepad Audit Photo',
                      'type': 'Photo Attachment',
                      'time': 'Just now',
                      'status': 'Attached',
                    });
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppTheme.primaryAccent.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.camera_alt,
                          color: AppTheme.primaryAccent, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'ATTACH EVIDENCE',
                        style: TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _evidenceFiles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, idx) {
              final ev = _evidenceFiles[idx];
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attachment,
                        color: AppTheme.primaryAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ev['title'] as String,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${ev['type']} • ${ev['status']}',
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 10 & 11: VALIDATION & REVIEW PANEL
  // ==========================================
  Widget _buildValidationAndReviewPanel() {
    final errors = _validationErrors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: errors.isEmpty
              ? AppTheme.success.withOpacity(0.5)
              : AppTheme.warning.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    errors.isEmpty ? Icons.check_circle : Icons.error_outline,
                    color: errors.isEmpty
                        ? AppTheme.success
                        : AppTheme.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    errors.isEmpty
                        ? 'CERTIFICATION VALIDATION PASSED'
                        : 'CERTIFICATION CHECKLIST BLOCKED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: errors.isEmpty
                          ? AppTheme.success
                          : AppTheme.warning,
                      fontFamily: AppTheme.fontDisplay,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (errors.isEmpty)
            const Text(
              '✓ Match identity, competitors, scores, and official signature meet authoritative competition rules.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors
                  .map(
                    (err) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          const Icon(Icons.close,
                              color: AppTheme.warning, size: 12),
                          const SizedBox(width: 6),
                          Text(err,
                              style: const TextStyle(
                                  color: AppTheme.warning, fontSize: 11)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 13: REFEREE CONFIRMATION IDENTITY
  // ==========================================
  Widget _buildRefereeIdentityCard(Map<String, dynamic> user) {
    final refName = user['fullName'] ?? user['name'] ?? 'Ahmed Ali';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.goldPrimary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.gavel, color: AppTheme.goldLight, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      refName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Class A Chief Referee',
                        style: TextStyle(
                            color: AppTheme.goldLight, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'PAF Official • Digital Signature Ready',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 18: AMENDMENT SECTION
  // ==========================================
  Widget _buildAmendmentSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECORD CERTIFIED & LOCKED',
            style: TextStyle(
              color: AppTheme.success,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontDisplay,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Certified at: $_certificationTimestamp\nSignature Hash: $_signatureHash',
            style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontFamily: AppTheme.fontMono),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.warning),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _amendmentRequested = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Official Result Amendment Request Submitted to Technical Delegate'),
                    backgroundColor: AppTheme.warning,
                  ),
                );
              },
              child: Text(
                _amendmentRequested
                    ? 'AMENDMENT PENDING AUDIT'
                    : 'REQUEST RESULT AMENDMENT',
                style: const TextStyle(
                    color: AppTheme.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PART 14 & 15: CERTIFICATION BOTTOM BAR
  // ==========================================
  Widget _buildCertificationBottomBar(String nameA, String nameB) {
    if (_isCertified) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: AppTheme.glassSurface,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => context.pop(),
            icon: const Icon(Icons.check, color: AppTheme.textPrimary),
            label: const Text(
              'RETURN TO ASSIGNED MATCHES',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: AppTheme.fontDisplay,
              ),
            ),
          ),
        ),
      );
    }

    final canCertify = _canCertify;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        border: const Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: _isSubmitting
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canCertify ? AppTheme.goldPrimary : AppTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(
                    color: canCertify
                        ? AppTheme.goldPrimary
                        : AppTheme.border,
                  ),
                ),
                onPressed: canCertify
                    ? () => _openCertificationSheet(context, nameA, nameB)
                    : () {
                        HapticFeedback.vibrate();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_validationErrors.first),
                            backgroundColor: AppTheme.warning,
                          ),
                        );
                      },
                icon: Icon(
                  canCertify ? Icons.verified : Icons.lock,
                  color: canCertify
                      ? AppTheme.background
                      : AppTheme.textMuted,
                  size: 18,
                ),
                label: Text(
                  canCertify
                      ? 'CERTIFY & SUBMIT RESULT'
                      : 'CERTIFICATION BLOCKED',
                  style: TextStyle(
                    color: canCertify
                        ? AppTheme.background
                        : AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: AppTheme.fontDisplay,
                  ),
                ),
              ),
            ),
    );
  }

  // ==========================================
  // CERTIFICATION SHEET & SIGNING FLOW
  // ==========================================
  void _openCertificationSheet(
      BuildContext context, String nameA, String nameB) {
    bool confirmedStatement = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium,
                          color: AppTheme.goldPrimary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'CERTIFY OFFICIAL BOUT RESULT',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: AppTheme.fontDisplay,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MATCH: $nameA vs $nameB',
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                            'WINNER: ${_calculatedWinner == 'Athlete A' ? nameA : nameB}',
                            style: const TextStyle(
                                color: AppTheme.goldLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                        const SizedBox(height: 2),
                        Text('FINAL SCORE: $_scoreA — $_scoreB',
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    activeColor: AppTheme.goldPrimary,
                    checkColor: AppTheme.background,
                    title: const Text(
                      'I confirm that this scorepad accurately represents the official result of this match.',
                      style: TextStyle(
                          color: AppTheme.textPrimary, fontSize: 11),
                    ),
                    value: confirmedStatement,
                    onChanged: (val) =>
                        setSheetState(() => confirmedStatement = val ?? false),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmedStatement
                            ? AppTheme.goldPrimary
                            : AppTheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: confirmedStatement
                          ? () {
                              Navigator.pop(context);
                              _executeCertificationProcess();
                            }
                          : null,
                      icon: const Icon(Icons.draw,
                          color: AppTheme.background, size: 18),
                      label: const Text(
                        'SIGN & AUTHORIZE CERTIFICATION',
                        style: TextStyle(
                          color: AppTheme.background,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: AppTheme.fontDisplay,
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

  void _executeCertificationProcess() async {
    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 1200));

    final ts = DateTime.now().toIso8601String();
    final hash = 'PAF-CERT-2026-${DateTime.now().millisecondsSinceEpoch}';

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _isCertified = true;
        _matchState = MatchOperationalState.certified;
        _certificationTimestamp = ts;
        _signatureHash = hash;
      });

      await SoundService.instance.playMatchWon();
      if (mounted) {
        CelebrationOverlay.show(
          context,
          title: 'BOUT RESULT CERTIFIED!',
          subtitle:
              'Official record published to Pakistan Armwrestling Federation Registry.',
          score: _scoreA > _scoreB ? _scoreA : _scoreB,
          scoreSuffix: ' pts',
          decimalPlaces: 0,
        );
      }
    }
  }

  // ==========================================
  // BACK PRESS HANDLER (UNSAVED DATA)
  // ==========================================
  Future<bool> _handleWillPop() async {
    if (_isCertified) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.glassSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.goldPrimary),
        ),
        title: const Text(
          'UNSAVED OFFICIAL DATA',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontFamily: AppTheme.fontDisplay,
            fontSize: 14,
          ),
        ),
        content: const Text(
          'You have uncertified scorepad data recorded. Leaving now will retain the local draft status.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Editing',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldPrimary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save Draft & Exit',
                style: TextStyle(color: AppTheme.background)),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }
}
