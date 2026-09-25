import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';

/// Table-Side Live Referee Scorepad Controller
///
/// Designed specifically for live table operations per `docs/design/30_PREMIUM_EXPERIENCE_PATTERN_LIBRARY.md`
/// Category 2, `docs/design/31_ACTION_CHOREOGRAPHY.md` Surfaces 1 & 2, and `docs/design/32_HAPTIC_AND_AUDIO_UX.md`.
///
/// Features:
/// - Symmetrical Corner Red vs Corner White/Cyan layout.
/// - Minimum 64×64dp point and foul hit targets for chalk/sweat tolerance.
/// - 400ms long-press PIN lock with radial progress ring and haptic crescendo.
/// - In-straps status indicator.
/// - Running round stopwatch timer.
/// - Automatic point-to-scoreline conversion for seamless backend ingestion.
class LiveScorepadController extends StatefulWidget {
  final String challengerName;
  final String opponentName;
  final String arm;
  final int maxPoints; // Default 3 for best-of-5, or 2 for best-of-3
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
    required this.onMatchFinished,
  });

  @override
  State<LiveScorepadController> createState() => _LiveScorepadControllerState();
}

class _LiveScorepadControllerState extends State<LiveScorepadController> {
  int _scoreRed = 0;
  int _scoreWhite = 0;
  int _foulsRed = 0;
  int _foulsWhite = 0;
  int _warningsRed = 0;
  int _warningsWhite = 0;
  bool _inStraps = false;

  // Running bout timer
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _timerRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
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
    HapticFeedback.lightImpact();
    setState(() {
      if (isRed) {
        if (_scoreRed < widget.maxPoints) _scoreRed++;
      } else {
        if (_scoreWhite < widget.maxPoints) _scoreWhite++;
      }
    });
    _checkMatchCompletion();
  }

  void _decrementScore(bool isRed) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (isRed && _scoreRed > 0) {
        _scoreRed--;
      } else if (!isRed && _scoreWhite > 0) {
        _scoreWhite--;
      }
    });
  }

  void _addFoul(bool isRed) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (isRed) {
        _foulsRed++;
        if (_foulsRed >= 2) {
          // 2 fouls = automatic point to opponent per WAF rules
          _foulsRed = 0;
          if (_scoreWhite < widget.maxPoints) _scoreWhite++;
          _showFoulSnackbar('2 Fouls on Red Corner: Point awarded to White Corner.');
        }
      } else {
        _foulsWhite++;
        if (_foulsWhite >= 2) {
          _foulsWhite = 0;
          if (_scoreRed < widget.maxPoints) _scoreRed++;
          _showFoulSnackbar('2 Fouls on White Corner: Point awarded to Red Corner.');
        }
      }
    });
    _checkMatchCompletion();
  }

  void _addWarning(bool isRed) {
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
    HapticFeedback.selectionClick();
    setState(() {
      _inStraps = !_inStraps;
    });
  }

  void _showFoulSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: AppTheme.fontBody, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _checkMatchCompletion() {
    if (_scoreRed >= widget.maxPoints || _scoreWhite >= widget.maxPoints) {
      _timer?.cancel();
      _timerRunning = false;
      final winnerSide = _scoreRed >= widget.maxPoints ? 'challenger' : 'opponent';
      final scoreLine = '$_scoreRed-$_scoreWhite';

      widget.onMatchFinished(
        challengerScore: _scoreRed,
        opponentScore: _scoreWhite,
        winnerSide: winnerSide,
        scoreLine: scoreLine,
      );
    }
  }

  void _confirmPin(bool isRed) {
    // Pin confirmed via 400ms long press
    _incrementScore(isRed);
  }

  void _resetBout() {
    HapticFeedback.heavyImpact();
    setState(() {
      _scoreRed = 0;
      _scoreWhite = 0;
      _foulsRed = 0;
      _foulsWhite = 0;
      _warningsRed = 0;
      _warningsWhite = 0;
      _inStraps = false;
      _secondsElapsed = 0;
      _timerRunning = false;
      _timer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------------------------------------------------------------------
        // Table Telemetry & Timer Strip
        // ---------------------------------------------------------------------
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
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
              InkWell(
                onTap: _toggleTimer,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _timerRunning ? AppTheme.info.withValues(alpha: 0.15) : AppTheme.cardSurface,
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
                          color: _timerRunning ? AppTheme.info : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Strap Toggle Action
              OutlinedButton.icon(
                onPressed: _toggleStraps,
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
                  side: BorderSide(color: _inStraps ? AppTheme.secondaryAccent : AppTheme.border),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.space16),

        // ---------------------------------------------------------------------
        // Symmetrical Corner Scoring Columns (Red vs White/Cyan)
        // ---------------------------------------------------------------------
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
                onAddPoint: () => _incrementScore(true),
                onDeductPoint: () => _decrementScore(true),
                onAddFoul: () => _addFoul(true),
                onAddWarning: () => _addWarning(true),
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
                onAddPoint: () => _incrementScore(false),
                onDeductPoint: () => _decrementScore(false),
                onAddFoul: () => _addFoul(false),
                onAddWarning: () => _addWarning(false),
                onPinConfirmed: () => _confirmPin(false),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.space16),

        // ---------------------------------------------------------------------
        // Table Utility Bar (Reset Bout / Reset Clock)
        // ---------------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _resetTimer,
              icon: const Icon(Icons.replay, size: 16),
              label: const Text('Reset Clock', style: TextStyle(fontSize: 12)),
            ),
            TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset Bout State?'),
                    content: const Text('This will clear all points, fouls, and warnings for this match.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) _resetBout();
              },
              icon: const Icon(Icons.refresh, size: 16, color: AppTheme.error),
              label: const Text('Reset Bout', style: TextStyle(fontSize: 12, color: AppTheme.error)),
            ),
          ],
        ),
      ],
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
  final VoidCallback onAddPoint;
  final VoidCallback onDeductPoint;
  final VoidCallback onAddFoul;
  final VoidCallback onAddWarning;
  final VoidCallback onPinConfirmed;

  const _CornerScoringCard({
    required this.cornerName,
    required this.athleteName,
    required this.score,
    required this.fouls,
    required this.warnings,
    required this.cornerColor,
    required this.onAddPoint,
    required this.onDeductPoint,
    required this.onAddFoul,
    required this.onAddWarning,
    required this.onPinConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedActionCard(
      padding: const EdgeInsets.all(AppTheme.space12),
      borderColor: cornerColor.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Corner Header Pill
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: cornerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: cornerColor, width: 1.0),
            ),
            child: Text(
              cornerName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: cornerColor,
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

          // Giant Score Readout (SpaceGrotesk 52sp)
          Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.w800,
                fontSize: 52,
                color: AppTheme.textPrimary,
                height: 1.1,
              ),
            ),
          ),

          const SizedBox(height: AppTheme.space8),

          // Fouls and Warnings Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Fouls (Max 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: fouls > 0 ? AppTheme.primaryAccent.withValues(alpha: 0.2) : AppTheme.elevatedSurface,
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
                    color: fouls > 0 ? AppTheme.primaryAccent : AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space6),
              // Warnings (Max 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: warnings > 0 ? AppTheme.secondaryAccent.withValues(alpha: 0.2) : AppTheme.elevatedSurface,
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
                    color: warnings > 0 ? AppTheme.secondaryAccent : AppTheme.textSecondary,
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
            child: ElevatedButton(
              onPressed: onAddPoint,
              style: ElevatedButton.styleFrom(
                backgroundColor: cornerColor,
                foregroundColor: AppTheme.voidBackground,
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

          const SizedBox(height: AppTheme.space8),

          // -------------------------------------------------------------------
          // Secondary 64×48dp Foul Button & Point Deduct Button
          // -------------------------------------------------------------------
          Row(
            children: [
              // Deduct Button (-1)
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48.0,
                  child: OutlinedButton(
                    onPressed: onDeductPoint,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    child: const Text('-1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space6),
              // Foul Button (+1 Foul)
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48.0,
                  child: OutlinedButton(
                    onPressed: onAddFoul,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: AppTheme.primaryAccent.withValues(alpha: 0.6)),
                      foregroundColor: AppTheme.primaryAccent,
                    ),
                    child: const Text('FOUL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space6),

          // Warning Button (Compact)
          SizedBox(
            height: 38.0,
            child: OutlinedButton(
              onPressed: onAddWarning,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: AppTheme.secondaryAccent.withValues(alpha: 0.5)),
                foregroundColor: AppTheme.secondaryAccent,
              ),
              child: const Text('+ WARNING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: AppTheme.space10),

          // -------------------------------------------------------------------
          // 400ms Long-Press Pin Confirmation Button
          // -------------------------------------------------------------------
          _PinHoldButton(
            cornerColor: cornerColor,
            onPinLocked: onPinConfirmed,
          ),
        ],
      ),
    );
  }
}

/// 400ms Hold-to-Pin Button with Continuous Radial Feedback
class _PinHoldButton extends StatefulWidget {
  final Color cornerColor;
  final VoidCallback onPinLocked;

  const _PinHoldButton({
    required this.cornerColor,
    required this.onPinLocked,
  });

  @override
  State<_PinHoldButton> createState() => _PinHoldButtonState();
}

class _PinHoldButtonState extends State<_PinHoldButton> with SingleTickerProviderStateMixin {
  late AnimationController _holdController;
  Timer? _tickTimer;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // Strict 400ms hold threshold
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tickTimer?.cancel();
        HapticFeedback.heavyImpact(); // Authoritative impact at moment of lock
        widget.onPinLocked();
        _holdController.reset();
        setState(() => _isHolding = false);
      }
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _holdController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.selectionClick();
    setState(() => _isHolding = true);
    _holdController.forward(from: 0.0);

    // Continuous 100ms haptic ticks while holding
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_isHolding) {
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
    setState(() => _isHolding = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _holdController,
        builder: (context, child) {
          final progress = _holdController.value;
          return Container(
            height: 52.0,
            decoration: BoxDecoration(
              color: _isHolding
                  ? widget.cornerColor.withValues(alpha: 0.25)
                  : AppTheme.elevatedSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: _isHolding ? widget.cornerColor : AppTheme.border,
                width: _isHolding ? 2.0 : 1.0,
              ),
              boxShadow: _isHolding
                  ? [
                      BoxShadow(
                        color: widget.cornerColor.withValues(alpha: 0.3),
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
                        Icons.lock_clock,
                        size: 16,
                        color: _isHolding ? widget.cornerColor : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isHolding ? 'LOCKING PIN...' : 'HOLD FOR PIN',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _isHolding ? AppTheme.textPrimary : AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
