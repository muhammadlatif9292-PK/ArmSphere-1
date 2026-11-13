import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import 'foul_sheet_modal.dart';
import '../../../core/widgets/crystal_toast.dart';

/// Table-Side Live Referee Scorepad Controller
///
/// Designed specifically for live table operations per `docs/design/30_PREMIUM_EXPERIENCE_PATTERN_LIBRARY.md`
/// Category 2, `docs/design/31_ACTION_CHOREOGRAPHY.md` Surfaces 1 & 2, and `docs/design/32_HAPTIC_AND_AUDIO_UX.md`.
///
/// Features:
/// - Pre-Match Format Selector: Best of 1, Best of 3, Best of 5 (default), Best of 7.
/// - Atomic Touch Locking: Prevents simultaneous multi-touch / chalk-hand cross-button collisions.
/// - Strict Match Completion Locking (Win-Lock): Immediately locks scoring buttons once target wins are reached,
///   displaying a Prominent Crystal Victory Banner with "UNDO LAST POINT" and "PROCEED TO OFFICIAL CERTIFICATION".
/// - Symmetrical Corner Red vs Corner White/Cyan layout.
/// - Minimum 64×64dp point and foul hit targets for chalk/sweat tolerance.
/// - 400ms long-press PIN lock with radial progress ring and haptic crescendo.
/// - WAF Foul & Warning Escalation Integrity (2 Warnings = 1 Foul, 2 Fouls = 1 Opponent Point).
class LiveScorepadController extends StatefulWidget {
  final String challengerName;
  final String opponentName;
  final String arm;
  final int maxPoints; // Default 3 for best-of-5, 2 for best-of-3, 1 for best-of-1, 4 for best-of-7
  final int? initialFormatRounds; // Optional explicit Best-of-N (1, 3, 5, 7)
  final ValueChanged<int>? onFormatChanged;
  final void Function({
    required int challengerScore,
    required int opponentScore,
    required String winnerSide,
    required String scoreLine,
  }) onMatchFinished;

  const LiveScorepadController({
    super.key,
    required this.challengerName,
    required this.opponentName,
    this.arm = 'RIGHT',
    this.maxPoints = 3,
    this.initialFormatRounds,
    this.onFormatChanged,
    required this.onMatchFinished,
  });

  @override
  State<LiveScorepadController> createState() => _LiveScorepadControllerState();
}

class _LiveScorepadControllerState extends State<LiveScorepadController> {
  static const List<int> _kSupportedFormats = [1, 3, 5, 7, 99];

  late int _formatRounds;
  int _scoreRed = 0;
  int _scoreWhite = 0;
  int _foulsRed = 0;
  int _foulsWhite = 0;
  int _warningsRed = 0;
  int _warningsWhite = 0;
  bool _inStraps = false;

  // Match Win-Lock state & point history stack (true = Red, false = White)
  bool _isMatchDecided = false;
  String? _matchWinner;
  final List<bool> _pointHistory = <bool>[];

  // Atomic Touch Lock state (prevents simultaneous multi-touch / cross-corner collisions)
  int _activePointers = 0;
  bool _isProcessingTap = false;
  bool _isActionLocked = false;
  bool _sameFrameLocked = false;
  String? _lastActionKey;
  Timer? _actionLockTimer;

  // Running bout timer
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _timerRunning = false;

  // SIG-8: Table Foul Flash state
  bool _isFoulFlashing = false;
  String? _foulFlashSide;
  Timer? _foulFlashTimer;
  Timer? _foulHapticTimer;

  int get _targetWins => _formatRounds >= 99 ? 999 : (_formatRounds ~/ 2) + 1;

  @override
  void initState() {
    super.initState();
    _formatRounds = _resolveInitialFormatRounds();
  }

  @override
  void didUpdateWidget(covariant LiveScorepadController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFormatRounds != oldWidget.initialFormatRounds &&
        widget.initialFormatRounds != null) {
      _formatRounds = _kSupportedFormats.contains(widget.initialFormatRounds!)
          ? widget.initialFormatRounds!
          : widget.initialFormatRounds!.clamp(1, 7);
    } else if (widget.maxPoints != oldWidget.maxPoints &&
        widget.initialFormatRounds == null) {
      if (widget.maxPoints >= 99) {
        _formatRounds = 99;
      } else {
        _formatRounds = ((widget.maxPoints * 2) - 1).clamp(1, 7);
      }
    }
  }

  int _resolveInitialFormatRounds() {
    if (widget.initialFormatRounds != null &&
        _kSupportedFormats.contains(widget.initialFormatRounds)) {
      return widget.initialFormatRounds!;
    }
    if (widget.maxPoints >= 99) {
      return 99;
    }
    final derived = ((widget.maxPoints * 2) - 1).clamp(1, 7);
    if (_kSupportedFormats.contains(derived)) {
      return derived;
    }
    return 5;
  }

  @override
  void dispose() {
    _actionLockTimer?.cancel();
    _timer?.cancel();
    _foulFlashTimer?.cancel();
    _foulHapticTimer?.cancel();
    super.dispose();
  }

  /// Atomic Touch Lock mutex — blocks simultaneous 2-finger multi-touch (`_activePointers > 1`),
  /// same-frame duplicate dispatches, and cross-control collisions within 350ms.
  void _executeAtomicAction(String actionKey, VoidCallback action) {
    if (_isProcessingTap || _isMatchDecided) return;
    if (_activePointers > 1) return;
    if (_sameFrameLocked) return;
    if (_isActionLocked && _lastActionKey != null && _lastActionKey != actionKey) {
      return;
    }

    _isProcessingTap = true;
    _isActionLocked = true;
    _sameFrameLocked = true;
    _lastActionKey = actionKey;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _sameFrameLocked = false;
    });

    _actionLockTimer?.cancel();
    _actionLockTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        _isActionLocked = false;
        _lastActionKey = null;
      }
    });

    try {
      action();
    } finally {
      _isProcessingTap = false;
    }
  }

  void _selectFormatRounds(int formatRounds) {
    if (_formatRounds == formatRounds) return;
    HapticFeedback.selectionClick();
    setState(() {
      _formatRounds = formatRounds;
      final newTarget = _targetWins;
      if (_scoreRed >= newTarget || _scoreWhite >= newTarget) {
        // Reset bout state cleanly when switching to a shorter format mid-match
        _scoreRed = 0;
        _scoreWhite = 0;
        _foulsRed = 0;
        _foulsWhite = 0;
        _warningsRed = 0;
        _warningsWhite = 0;
        _isMatchDecided = false;
        _matchWinner = null;
        _pointHistory.clear();
      } else {
        _isMatchDecided = false;
        _matchWinner = null;
      }
    });
    widget.onFormatChanged?.call(formatRounds);
  }

  void _triggerFoulFlash(bool isRed) {
    _foulFlashTimer?.cancel();
    _foulHapticTimer?.cancel();
    HapticFeedback.heavyImpact();
    _foulHapticTimer = Timer(const Duration(milliseconds: 60), () {
      HapticFeedback.heavyImpact();
    });
    setState(() {
      _isFoulFlashing = true;
      _foulFlashSide = isRed ? 'RED' : 'WHITE';
    });
    _foulFlashTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isFoulFlashing = false;
          _foulFlashSide = null;
        });
      }
    });
  }

  void _toggleTimer() {
    if (_isMatchDecided) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_timerRunning) {
        _timer?.cancel();
        _timerRunning = false;
      } else {
        _timerRunning = true;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() => _secondsElapsed++);
          }
        });
      }
    });
  }

  void _resetTimer() {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
      _secondsElapsed = 0;
    });
  }

  String _formatTimer() {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _incrementScore(bool isRed) {
    if (_isMatchDecided) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (isRed) {
        if (_scoreRed < _targetWins) {
          _scoreRed++;
          _pointHistory.add(true);
        }
      } else {
        if (_scoreWhite < _targetWins) {
          _scoreWhite++;
          _pointHistory.add(false);
        }
      }
    });
    _checkMatchCompletion();
  }

  void _decrementScore(bool isRed) {
    if (_isMatchDecided) return;
    HapticFeedback.mediumImpact();
    setState(() {
      if (isRed && _scoreRed > 0) {
        _scoreRed--;
        final lastIdx = _pointHistory.lastIndexOf(true);
        if (lastIdx != -1) _pointHistory.removeAt(lastIdx);
      } else if (!isRed && _scoreWhite > 0) {
        _scoreWhite--;
        final lastIdx = _pointHistory.lastIndexOf(false);
        if (lastIdx != -1) _pointHistory.removeAt(lastIdx);
      }
    });
  }

  void _undoLastPoint() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_pointHistory.isNotEmpty) {
        final lastWasRed = _pointHistory.removeLast();
        if (lastWasRed && _scoreRed > 0) {
          _scoreRed--;
        } else if (!lastWasRed && _scoreWhite > 0) {
          _scoreWhite--;
        }
      } else if (_scoreRed >= _scoreWhite && _scoreRed > 0) {
        _scoreRed--;
      } else if (_scoreWhite > 0) {
        _scoreWhite--;
      }
      _isMatchDecided = false;
      _matchWinner = null;
      _isActionLocked = false;
      _sameFrameLocked = false;
      _lastActionKey = null;
    });
  }

  void _addFoul(bool isRed) {
    if (_isMatchDecided) return;
    _triggerFoulFlash(isRed);
    setState(() {
      if (isRed) {
        _foulsRed++;
        if (_foulsRed >= 2) {
          // 2 fouls = automatic point to opponent per WAF rules
          _foulsRed = 0;
          if (_scoreWhite < _targetWins) {
            _scoreWhite++;
            _pointHistory.add(false);
          }
          _showFoulSnackbar('2 Fouls on Red Corner: Point awarded to White Corner.');
        }
      } else {
        _foulsWhite++;
        if (_foulsWhite >= 2) {
          _foulsWhite = 0;
          if (_scoreRed < _targetWins) {
            _scoreRed++;
            _pointHistory.add(true);
          }
          _showFoulSnackbar('2 Fouls on White Corner: Point awarded to Red Corner.');
        }
      }
    });
    _checkMatchCompletion();
  }

  void _addWarning(bool isRed) {
    if (_isMatchDecided) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (isRed) {
        _warningsRed++;
        if (_warningsRed >= 2) {
          _warningsRed = 0;
          _addFoul(true);
          _showFoulSnackbar('2 Warnings on Red Corner = 1 Foul assessed.');
        }
      } else {
        _warningsWhite++;
        if (_warningsWhite >= 2) {
          _warningsWhite = 0;
          _addFoul(false);
          _showFoulSnackbar('2 Warnings on White Corner = 1 Foul assessed.');
        }
      }
    });
  }

  void _toggleStraps() {
    if (_isMatchDecided) return;
    HapticFeedback.selectionClick();
    setState(() {
      _inStraps = !_inStraps;
    });
  }

  void _openFoulSheet(bool isRed) {
    if (_isMatchDecided) return;
    FoulSheetModal.show(
      context,
      athleteAName: widget.challengerName,
      athleteBName: widget.opponentName,
      currentRound: (_scoreRed + _scoreWhite + 1).clamp(1, _formatRounds),
      initialCorner: isRed ? 'RED' : 'BLUE',
      onFoulConfirmed: (foulData) {
        if (_isMatchDecided) return;
        _addFoul(isRed);
        _showFoulSnackbar('${foulData['type']} recorded on ${foulData['athleteName']}');
      },
    );
  }

  void _showFoulSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: AppTheme.fontBody, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _checkMatchCompletion() {
    if (_scoreRed >= _targetWins || _scoreWhite >= _targetWins) {
      _timer?.cancel();
      _timerRunning = false;
      final isRedWinner = _scoreRed >= _targetWins;
      setState(() {
        _isMatchDecided = true;
        _matchWinner = isRedWinner ? widget.challengerName : widget.opponentName;
      });
      _notifyMatchFinished();
    }
  }

  void _notifyMatchFinished() {
    final winnerSide = _scoreRed >= _targetWins ? 'challenger' : 'opponent';
    final scoreLine = '$_scoreRed-$_scoreWhite';

    widget.onMatchFinished(
      challengerScore: _scoreRed,
      opponentScore: _scoreWhite,
      winnerSide: winnerSide,
      scoreLine: scoreLine,
    );
  }

  void _confirmPin(bool isRed) {
    if (_isMatchDecided) return;
    // Pin confirmed via 400ms long press
    _executeAtomicAction(isRed ? 'RED_PIN' : 'WHITE_PIN', () => _incrementScore(isRed));
  }

  void _resetBout() {
    HapticFeedback.heavyImpact();
    _actionLockTimer?.cancel();
    setState(() {
      _scoreRed = 0;
      _scoreWhite = 0;
      _foulsRed = 0;
      _foulsWhite = 0;
      _warningsRed = 0;
      _warningsWhite = 0;
      _inStraps = false;
      _isMatchDecided = false;
      _matchWinner = null;
      _pointHistory.clear();
      _isActionLocked = false;
      _sameFrameLocked = false;
      _lastActionKey = null;
      _secondsElapsed = 0;
      _timerRunning = false;
      _timer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final currentRoundNumber = (_scoreRed + _scoreWhite + 1).clamp(1, _formatRounds);
    final decidedInRound = (_scoreRed + _scoreWhite).clamp(1, _formatRounds);

    return Listener(
      onPointerDown: (_) => _activePointers++,
      onPointerUp: (_) => _activePointers = (_activePointers - 1).clamp(0, 10),
      onPointerCancel: (_) => _activePointers = (_activePointers - 1).clamp(0, 10),
      child: RepaintBoundary(
        child: AnimatedContainer(
          duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 180),
          curve: Curves.easeOutQuad,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: _isFoulFlashing ? const Color(0xFFEF4444) : Colors.transparent,
              width: _isFoulFlashing ? 3.5 : 0.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------------------------------------------------------------------
              // Pre-Match Regulation Format Selector (Best of 1, 3, 5, 7)
              // -------------------------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x4704060B),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: const Color(0x38FFFFFF), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'REGULATION MATCH FORMAT',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          _isMatchDecided
                              ? 'BOUT LOCKED • FINAL $_scoreRed-$_scoreWhite'
                              : (_formatRounds >= 99
                                  ? 'ROUND ${_scoreRed + _scoreWhite + 1} • SUPERMATCH CUSTOM'
                                  : 'ROUND $currentRoundNumber OF $_formatRounds • FIRST TO $_targetWins ${_targetWins == 1 ? 'PIN' : 'PINS'}'),
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: _isMatchDecided ? AppTheme.success : AppTheme.goldPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (int i = 0; i < _kSupportedFormats.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          Expanded(
                            child: _FormatSegmentChip(
                              formatRounds: _kSupportedFormats[i],
                              isSelected: _formatRounds == _kSupportedFormats[i],
                              isLocked: _isMatchDecided,
                              onTap: () => _selectFormatRounds(_kSupportedFormats[i]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.space12),

              // -------------------------------------------------------------------
              // Table Telemetry & Timer Strip
              // -------------------------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                  vertical: AppTheme.space12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.border, width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Arm & Division Pill
                    Row(
                      children: [
                        ArmIndicatorPill(isRightArm: widget.arm.toUpperCase() == 'RIGHT'),
                        const SizedBox(width: AppTheme.space8),
                        if (_inStraps)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(color: AppTheme.secondaryAccent, width: 1.0),
                            ),
                            child: const Text(
                              'IN STRAPS',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: AppTheme.secondaryAccent,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Running Match Clock
                    Semantics(
                      button: true,
                      excludeSemantics: true,
                      label: _timerRunning ? 'Pause match timer' : 'Start match timer',
                      value: _formatTimer(),
                      child: InkWell(
                        onTap: _isMatchDecided ? null : _toggleTimer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _timerRunning
                                ? AppTheme.info.withValues(alpha: 0.15)
                                : AppTheme.cardSurface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: _timerRunning ? AppTheme.info : AppTheme.border,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _timerRunning ? Icons.pause : Icons.play_arrow,
                                size: 14,
                                color: _timerRunning ? AppTheme.info : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimer(),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                  color: _timerRunning ? AppTheme.info : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Strap Toggle Action
                    Semantics(
                      button: true,
                      excludeSemantics: true,
                      label: _inStraps ? 'Release straps' : 'Apply straps to competitors',
                      value: _inStraps ? 'In Straps' : 'Straps Off',
                      child: OutlinedButton.icon(
                        onPressed: _isMatchDecided ? null : _toggleStraps,
                        icon: Icon(
                          Icons.link,
                          size: 14,
                          color: _inStraps ? AppTheme.secondaryAccent : AppTheme.textSecondary,
                        ),
                        label: Text(
                          _inStraps ? 'Release' : 'Straps',
                          style: TextStyle(
                            fontSize: 12,
                            color: _inStraps ? AppTheme.secondaryAccent : AppTheme.textSecondary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(44, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          side: BorderSide(
                            color: _inStraps ? AppTheme.secondaryAccent : AppTheme.border,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.space16),

              // -------------------------------------------------------------------
              // Prominent Crystal Victory Banner (Shown immediately on Win-Lock)
              // -------------------------------------------------------------------
              if (_isMatchDecided) ...[
                ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  borderColor: AppTheme.goldPrimary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0x26D4AF37),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.goldPrimary, width: 1.0),
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: AppTheme.goldPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${(_matchWinner ?? 'WINNER').toUpperCase()} WINS BOUT!',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'MATCH DECIDED: ${(_matchWinner ?? 'WINNER').toUpperCase()} WINS ($_scoreRed - $_scoreWhite)',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPure,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatRounds >= 99
                                      ? 'Final Score: $_scoreRed — $_scoreWhite • Supermatch Custom (${_scoreRed + _scoreWhite} Rounds)'
                                      : 'Final Score: $_scoreRed — $_scoreWhite • Decided in Round $decidedInRound (Best of $_formatRounds)',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontBody,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _notifyMatchFinished,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.verified_rounded, size: 18),
                        label: const Text(
                          'PROCEED TO OFFICIAL CERTIFICATION',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _undoLastPoint,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: Color(0x4DFFFFFF)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: const Text(
                          'UNDO LAST POINT',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
              ],

              // -------------------------------------------------------------------
              // Symmetrical Corner Scoring Columns (Red vs White/Cyan)
              // -------------------------------------------------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Corner Red (Challenger)
                  Expanded(
                    child: _CornerScoringCard(
                      cornerName: 'CORNER RED',
                      athleteName: widget.challengerName,
                      score: _scoreRed,
                      fouls: _foulsRed,
                      warnings: _warningsRed,
                      cornerColor: AppTheme.primaryAccent,
                      isFoulFlashing: _isFoulFlashing && _foulFlashSide == 'RED',
                      isMatchLocked: _isMatchDecided,
                      onAddPoint: () =>
                          _executeAtomicAction('RED_POINT', () => _incrementScore(true)),
                      onDeductPoint: () =>
                          _executeAtomicAction('RED_DEDUCT', () => _decrementScore(true)),
                      onAddFoul: () =>
                          _executeAtomicAction('RED_FOUL', () => _addFoul(true)),
                      onAddFoulDetails: () => _openFoulSheet(true),
                      onAddWarning: () =>
                          _executeAtomicAction('RED_WARN', () => _addWarning(true)),
                      onPinConfirmed: () => _confirmPin(true),
                    ),
                  ),

                  const SizedBox(width: AppTheme.space12),

                  // Right Column: Corner White/Cyan (Opponent)
                  Expanded(
                    child: _CornerScoringCard(
                      cornerName: 'CORNER WHITE',
                      athleteName: widget.opponentName,
                      score: _scoreWhite,
                      fouls: _foulsWhite,
                      warnings: _warningsWhite,
                      cornerColor: AppTheme.cyanAccent,
                      isFoulFlashing: _isFoulFlashing && _foulFlashSide == 'WHITE',
                      isMatchLocked: _isMatchDecided,
                      onAddPoint: () =>
                          _executeAtomicAction('WHITE_POINT', () => _incrementScore(false)),
                      onDeductPoint: () =>
                          _executeAtomicAction('WHITE_DEDUCT', () => _decrementScore(false)),
                      onAddFoul: () =>
                          _executeAtomicAction('WHITE_FOUL', () => _addFoul(false)),
                      onAddFoulDetails: () => _openFoulSheet(false),
                      onAddWarning: () =>
                          _executeAtomicAction('WHITE_WARN', () => _addWarning(false)),
                      onPinConfirmed: () => _confirmPin(false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.space24),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              const SizedBox(height: AppTheme.space12),

              // -------------------------------------------------------------------
              // Table Utility Bar (Reset Clock / Reset Score)
              // Spatially separated from active corner scoring and pin-lock targets
              // -------------------------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      button: true,
                      label: 'Reset match clock',
                      child: TextButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.replay, size: 16),
                        label: const Text('Reset Clock', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Reset score and bout state',
                      child: TextButton.icon(
                        onPressed: () async {
                          HapticFeedback.selectionClick();
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.cardSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                side: const BorderSide(color: AppTheme.cardBorder),
                              ),
                              title: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 22),
                                  SizedBox(width: AppTheme.space8),
                                  Text(
                                    'Reset Score & Bout State?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: AppTheme.fontDisplay,
                                    ),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'This action will clear all live scoring progress recorded for this bout:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.space12),
                                  Container(
                                    padding: const EdgeInsets.all(AppTheme.space12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.elevatedSurface,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                      border: Border.all(color: AppTheme.cardBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '• Current Score: Red $_scoreRed — White $_scoreWhite',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '• Fouls: Red $_foulsRed/2 — White $_foulsWhite/2',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '• Warnings: Red $_warningsRed/2 — White $_warningsWhite/2',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        if (_inStraps) ...[
                                          const SizedBox(height: 2),
                                          const Text(
                                            '• In-Straps: Engaged (will disengage)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                        if (_secondsElapsed > 0) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '• Match Clock: ${_secondsElapsed}s elapsed',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.space12),
                                  const Text(
                                    'Score data cannot be recovered once reset. Keep existing scores if this was triggered accidentally.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel (Keep Score)'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
                                  child: const Text('Reset Score'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) _resetBout();
                        },
                        icon: const Icon(Icons.refresh, size: 16, color: AppTheme.error),
                        label: const Text(
                          'Reset Score',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatSegmentChip extends StatelessWidget {
  final int formatRounds;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _FormatSegmentChip({
    required this.formatRounds,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom = formatRounds >= 99;
    final target = (formatRounds ~/ 2) + 1;
    final topLabel = isCustom ? 'CUSTOM' : 'BEST OF $formatRounds';
    final subLabel = isCustom ? 'Supermatch' : 'First to $target';
    return Semantics(
      button: true,
      selected: isSelected,
      label: isCustom
          ? 'Supermatch Custom format, unlimited exhibition rounds'
          : 'Best of $formatRounds, first to $target wins',
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryAccent.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryAccent
                  : const Color(0x2EFFFFFF),
              width: isSelected ? 1.3 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  topLabel,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subLabel,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppTheme.fontBody,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.goldPrimary : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Symmetrical Corner Card with 64dp Hit Targets & 400ms Pin Hold
class _CornerScoringCard extends StatelessWidget {
  final String cornerName;
  final String athleteName;
  final int score;
  final int fouls;
  final int warnings;
  final Color cornerColor;
  final bool isFoulFlashing;
  final bool isMatchLocked;
  final VoidCallback onAddPoint;
  final VoidCallback onDeductPoint;
  final VoidCallback onAddFoul;
  final VoidCallback? onAddFoulDetails;
  final VoidCallback onAddWarning;
  final VoidCallback onPinConfirmed;

  const _CornerScoringCard({
    required this.cornerName,
    required this.athleteName,
    required this.score,
    required this.fouls,
    required this.warnings,
    required this.cornerColor,
    this.isFoulFlashing = false,
    this.isMatchLocked = false,
    required this.onAddPoint,
    required this.onDeductPoint,
    required this.onAddFoul,
    this.onAddFoulDetails,
    required this.onAddWarning,
    required this.onPinConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedContainer(
      duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOutQuad,
      decoration: BoxDecoration(
        color: isFoulFlashing
            ? AppTheme.competitionCrimson.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ElevatedActionCard(
        padding: const EdgeInsets.all(AppTheme.space12),
        borderColor: isFoulFlashing
            ? AppTheme.competitionCrimson
            : cornerColor.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Corner Header Pill
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isFoulFlashing
                    ? AppTheme.competitionCrimson.withValues(alpha: 0.25)
                    : cornerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: isFoulFlashing ? AppTheme.competitionCrimson : cornerColor,
                  width: 1.0,
                ),
              ),
              child: Text(
                cornerName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isFoulFlashing ? AppTheme.competitionCrimson : cornerColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: AppTheme.space8),

            // Athlete Name
            Text(
              athleteName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.fontBody,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppTheme.space8),

            // Giant Score Readout (SpaceGrotesk 52sp, Tabular Figures)
            Semantics(
              label: 'Score for $athleteName: $score',
              child: Center(
                child: Text(
                  '$score',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w800,
                    fontSize: 52,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppTheme.textPrimary,
                    height: 1.1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.space8),

            // Fouls and Warnings Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Fouls (Max 2)
                Semantics(
                  label: 'Fouls for $athleteName: $fouls of 2',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: fouls > 0
                          ? AppTheme.primaryAccent.withValues(alpha: 0.2)
                          : AppTheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: fouls > 0 ? AppTheme.primaryAccent : AppTheme.border,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'F: $fouls/2',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: fouls > 0 ? AppTheme.primaryAccent : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space6),
                // Warnings (Max 2)
                Semantics(
                  label: 'Warnings for $athleteName: $warnings of 2',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: warnings > 0
                          ? AppTheme.secondaryAccent.withValues(alpha: 0.2)
                          : AppTheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: warnings > 0 ? AppTheme.secondaryAccent : AppTheme.border,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'W: $warnings/2',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: warnings > 0 ? AppTheme.secondaryAccent : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.space12),

            // -------------------------------------------------------------------
            // Primary 64×64dp Point Increment Button
            // -------------------------------------------------------------------
            SizedBox(
              height: 64.0, // Strict 64dp hit target for chalked hands
              child: Semantics(
                button: true,
                enabled: !isMatchLocked,
                label: 'Add point for $athleteName on $cornerName',
                child: ElevatedButton(
                  onPressed: isMatchLocked ? null : onAddPoint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cornerColor,
                    foregroundColor: AppTheme.voidBackground,
                    disabledBackgroundColor: cornerColor.withValues(alpha: 0.2),
                    disabledForegroundColor: AppTheme.textMuted,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 22),
                      SizedBox(width: 4),
                      Text(
                        'POINT',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.space8),

            // -------------------------------------------------------------------
            // Secondary 64dp Foul Button & Point Deduct Button
            // -------------------------------------------------------------------
            Row(
              children: [
                // Deduct Button (-1)
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 64.0, // Strict 64dp hit target per Canary 7 spec
                    child: Semantics(
                      button: true,
                      enabled: !isMatchLocked,
                      label: 'Deduct point from $athleteName on $cornerName',
                      child: OutlinedButton(
                        onPressed: isMatchLocked ? null : onDeductPoint,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: AppTheme.border),
                        ),
                        child: const Text(
                          '-1',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space6),
                // Foul Button (+1 Foul)
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 64.0, // Strict 64dp hit target per Canary 7 spec
                    child: Semantics(
                      button: true,
                      enabled: !isMatchLocked,
                      label:
                          'Assess foul on $athleteName on $cornerName. Current fouls: $fouls of 2',
                      child: OutlinedButton(
                        onPressed: isMatchLocked ? null : onAddFoul,
                        onLongPress: isMatchLocked ? null : onAddFoulDetails,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: BorderSide(color: AppTheme.primaryAccent.withValues(alpha: 0.6)),
                          foregroundColor: AppTheme.primaryAccent,
                        ),
                        child: const Text(
                          'FOUL',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.space6),

            // Warning Button (Compact)
            SizedBox(
              height: 38.0,
              child: Semantics(
                button: true,
                enabled: !isMatchLocked,
                label:
                    'Assess warning on $athleteName on $cornerName. Current warnings: $warnings of 2',
                child: OutlinedButton(
                  onPressed: isMatchLocked ? null : onAddWarning,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: BorderSide(color: AppTheme.secondaryAccent.withValues(alpha: 0.5)),
                    foregroundColor: AppTheme.secondaryAccent,
                  ),
                  child: const Text(
                    '+ WARNING',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.space10),

            // -------------------------------------------------------------------
            // 400ms Long-Press Pin Confirmation Button (SIG-2)
            // -------------------------------------------------------------------
            _PinHoldButton(
              cornerColor: cornerColor,
              isDisabled: isMatchLocked,
              onPinLocked: onPinConfirmed,
            ),
          ],
        ),
      ),
    );
  }
}

/// 400ms Hold-to-Pin Button with Continuous Feedback (SIG-2)
class _PinHoldButton extends StatefulWidget {
  final Color cornerColor;
  final bool isDisabled;
  final VoidCallback onPinLocked;

  const _PinHoldButton({
    required this.cornerColor,
    this.isDisabled = false,
    required this.onPinLocked,
  });

  @override
  State<_PinHoldButton> createState() => _PinHoldButtonState();
}

class _PinHoldButtonState extends State<_PinHoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _holdController;
  Timer? _tickTimer;
  Timer? _settleTimer;
  bool _isHolding = false;
  bool _isLocked = false;
  bool _midpointFired = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // Strict 400ms hold threshold
    );

    _holdController.addListener(() {
      if (_holdController.value >= 0.5 && !_midpointFired) {
        _midpointFired = true;
        HapticFeedback.selectionClick();
      }
    });

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tickTimer?.cancel();
        HapticFeedback.heavyImpact(); // Authoritative impact at moment of lock
        setState(() {
          _isLocked = true;
        });
        widget.onPinLocked();
        // 80ms locked flash settle before reset
        _settleTimer?.cancel();
        _settleTimer = Timer(const Duration(milliseconds: 80), () {
          if (mounted) {
            _holdController.reset();
            setState(() {
              _isHolding = false;
              _isLocked = false;
              _midpointFired = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _settleTimer?.cancel();
    _holdController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isDisabled) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isHolding = true;
      _midpointFired = false;
    });
    _holdController.forward(from: 0.0);

    // Continuous 100ms haptic ticks while holding
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_isHolding && !widget.isDisabled) {
        HapticFeedback.selectionClick();
      } else {
        t.cancel();
      }
    });
  }

  void _onTapUp(TapUpDetails details) {
    _cancelHold();
  }

  void _onTapCancel() {
    _cancelHold();
  }

  void _cancelHold() {
    _tickTimer?.cancel();
    if (_holdController.isAnimating || _holdController.value > 0.0) {
      _holdController.reverse();
    }
    setState(() {
      _isHolding = false;
      _midpointFired = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return GestureDetector(
      onTapDown: widget.isDisabled ? null : _onTapDown,
      onTapUp: widget.isDisabled ? null : _onTapUp,
      onTapCancel: widget.isDisabled ? null : _onTapCancel,
      child: AnimatedBuilder(
        animation: _holdController,
        builder: (context, child) {
          final progress = _holdController.value;
          final remainingMs = ((1.0 - progress) * 400).ceil();
          return Semantics(
            button: true,
            enabled: !widget.isDisabled,
            excludeSemantics: true,
            label: widget.isDisabled
                ? 'Pin lock disabled because match is decided'
                : (_isLocked
                    ? 'Pin confirmed'
                    : (_isHolding
                        ? 'Locking pin, $remainingMs milliseconds remaining'
                        : 'Hold for 400 milliseconds to confirm pin lock')),
            value: _isLocked ? 'Locked' : (_isHolding ? '${(progress * 100).toInt()}%' : 'Ready'),
            child: AnimatedScale(
              scale: _isHolding ? 0.96 : 1.0,
              duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 50),
              curve: Curves.easeOutQuad,
              child: Container(
                height: 64.0, // Strict 64dp hit target per Canary 7 spec
                decoration: BoxDecoration(
                  color: _isLocked
                      ? Colors.white
                      : (_isHolding
                          ? widget.cornerColor.withValues(alpha: 0.25)
                          : AppTheme.elevatedSurface),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: _isHolding ? widget.cornerColor : AppTheme.border,
                    width: _isHolding ? 2.0 : 1.0,
                  ),
                  boxShadow: _isHolding
                      ? [
                          BoxShadow(
                            color: widget.cornerColor.withValues(alpha: 0.35),
                            blurRadius: 10.0,
                          )
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    // Horizontal Filling Progress Track
                    FractionallySizedBox(
                      widthFactor: progress,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.cornerColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 1),
                        ),
                      ),
                    ),

                    // Button Label
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isDisabled
                                ? Icons.lock_outline
                                : (_isLocked
                                    ? Icons.check_circle
                                    : (_isHolding ? Icons.lock_clock : Icons.touch_app)),
                            size: 16,
                            color: widget.isDisabled
                                ? AppTheme.textMuted
                                : (_isLocked
                                    ? Colors.black
                                    : (_isHolding ? widget.cornerColor : AppTheme.textSecondary)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isDisabled
                                ? 'MATCH DECIDED'
                                : (_isLocked
                                    ? 'PIN CONFIRMED'
                                    : (_isHolding
                                        ? 'LOCKING PIN: ${remainingMs}ms'
                                        : 'HOLD TO PIN (400ms)')),
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: widget.isDisabled
                                  ? AppTheme.textMuted
                                  : (_isLocked
                                      ? Colors.black
                                      : (_isHolding ? AppTheme.textPrimary : AppTheme.textSecondary)),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

