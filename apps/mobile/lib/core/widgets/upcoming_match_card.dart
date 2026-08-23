import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// CustomPainter to render boarding pass side notches and perforated ticket line
class _BoardingPassTicketPainter extends CustomPainter {
  final Color borderColor;
  final Color dividerColor;

  _BoardingPassTicketPainter({
    required this.borderColor,
    required this.dividerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const notchRadius = 10.0;
    const dividerYRatio = 0.38; // Position of perforated divider
    final dividerY = size.height * dividerYRatio;

    // Border Path with left and right semi-circle notches
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, dividerY - notchRadius)
      ..arcToPoint(
        Offset(size.width, dividerY + notchRadius),
        radius: const Radius.circular(notchRadius),
        clockwise: false,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, dividerY + notchRadius)
      ..arcToPoint(
        Offset(0, dividerY - notchRadius),
        radius: const Radius.circular(notchRadius),
        clockwise: false,
      )
      ..close();

    // Draw background border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, borderPaint);

    // Draw dashed perforated separator line across the ticket
    final dashPaint = Paint()
      ..color = dividerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = notchRadius + 4;
    final endX = size.width - notchRadius - 4;

    while (startX < endX) {
      canvas.drawLine(
        Offset(startX, dividerY),
        Offset(startX + dashWidth, dividerY),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _BoardingPassTicketPainter oldDelegate) => false;
}

/// Premium Boarding Pass Style Upcoming Match Card
class UpcomingMatchCard extends StatefulWidget {
  final String tournamentName;
  final String tournamentLogoUrl;
  final String matchImportance;
  final String tableNumber;
  final String opponentName;
  final String opponentPhotoUrl;
  final int opponentElo;
  final String weightClass;
  final String dateString;
  final String venue;
  final String refereeName;
  final DateTime matchTime;
  final VoidCallback? onTapCTA;

  UpcomingMatchCard({
    Key? key,
    this.tournamentName = 'EAST VS WEST 12',
    this.tournamentLogoUrl = 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?auto=format&fit=crop&q=80&w=150',
    this.matchImportance = 'SUPERMATCH',
    this.tableNumber = 'TABLE #1',
    this.opponentName = 'Devon Larratt',
    this.opponentPhotoUrl = 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=300',
    this.opponentElo = 2280,
    this.weightClass = 'Right Hand • -95kg',
    this.dateString = '12 MAY • 7:00 PM PST',
    this.venue = 'Istanbul, Turkey',
    this.refereeName = 'Chief Ref Alex S.',
    DateTime? matchTime,
    this.onTapCTA,
  })  : matchTime = matchTime ?? const CustomMatchTime().defaultTime,
        super(key: key);

  @override
  State<UpcomingMatchCard> createState() => _UpcomingMatchCardState();
}

class CustomMatchTime {
  const CustomMatchTime();
  DateTime get defaultTime => DateTime.now().add(const Duration(days: 2, hours: 14, minutes: 38, seconds: 45));
}

class _UpcomingMatchCardState extends State<UpcomingMatchCard> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _timeRemaining;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.matchTime.difference(DateTime.now());

    // Countdown Timer running every 1 second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          final diff = widget.matchTime.difference(DateTime.now());
          _timeRemaining = diff.isNegative ? Duration.zero : diff;
        });
      }
    });

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.selectionClick();
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
    if (widget.onTapCTA != null) widget.onTapCTA!();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'UPCOMING MATCH',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontFamily: AppTheme.fontBody,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.goldLight,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Boarding Pass Ticket Container
        AnimatedBuilder(
          animation: _pressController,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 18.0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppTheme.goldPrimary.withOpacity(0.08),
                    blurRadius: 20.0,
                    spreadRadius: -2.0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
                  child: CustomPaint(
                    painter: _BoardingPassTicketPainter(
                      borderColor: AppTheme.goldPrimary.withOpacity(0.25),
                      dividerColor: AppTheme.goldPrimary.withOpacity(0.2),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        color: const Color(0xEE121622), // Deep Onyx Glass
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1E2332),
                            Color(0xFF121622),
                            Color(0xFF0D0F18),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Pass Header: Tournament Name, Importance, Table
                          Row(
                            children: [
                              // Tournament Badge Icon
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.goldPrimary.withOpacity(0.3),
                                    width: 0.8,
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(widget.tournamentLogoUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Tournament Name & Table
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.tournamentName,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${widget.tableNumber} • ${widget.refereeName}',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontBody,
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Match Importance Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldPrimary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.goldPrimary.withOpacity(0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  widget.matchImportance,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28), // Space around perforated ticket fold line

                          // Main Opponent & Match Bay
                          Row(
                            children: [
                              // Opponent Photo with Gold Border Ring
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.goldLight, AppTheme.goldDark],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.goldPrimary.withOpacity(0.25),
                                      blurRadius: 8.0,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppTheme.elevatedSurface,
                                  backgroundImage: NetworkImage(widget.opponentPhotoUrl),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Opponent Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NEXT OPPONENT',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                        color: AppTheme.textMuted.withOpacity(0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.opponentName,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${widget.opponentElo} ELO',
                                            style: const TextStyle(
                                              fontFamily: AppTheme.fontDisplay,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.goldLight,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.weightClass,
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontBody,
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Location & Date Info Bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0x880E111A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.goldPrimary),
                                const SizedBox(width: 6),
                                Text(
                                  widget.venue,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontBody,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.schedule, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  widget.dateString,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontBody,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Urgent Countdown Bar & CTA Button
                          Row(
                            children: [
                              // Live Countdown Block
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.success,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'MATCH COUNTDOWN',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.0,
                                            color: AppTheme.textMuted.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _buildTimeBox('${days}d'),
                                        _buildTimeSep(),
                                        _buildTimeBox('${_twoDigits(hours)}h'),
                                        _buildTimeSep(),
                                        _buildTimeBox('${_twoDigits(minutes)}m'),
                                        _buildTimeSep(),
                                        _buildTimeBox('${_twoDigits(seconds)}s'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Boarding Pass CTA Button
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.goldLight, AppTheme.goldPrimary],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.goldPrimary.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      'PASS',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.confirmation_num_outlined,
                                      size: 14,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1B202D),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.goldPrimary.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTheme.fontDisplay,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppTheme.goldLight,
        ),
      ),
    );
  }

  Widget _buildTimeSep() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.0),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}
