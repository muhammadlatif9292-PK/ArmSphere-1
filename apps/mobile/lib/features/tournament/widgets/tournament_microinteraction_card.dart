import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
class _TournamentMicrointeractionCard extends StatefulWidget {
  final Widget child;

  const _TournamentMicrointeractionCard({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<_TournamentMicrointeractionCard> createState() => _TournamentMicrointeractionCardState();
}

class _TournamentMicrointeractionCardState extends State<_TournamentMicrointeractionCard> {
  bool _isHoveredOrPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHoveredOrPressed = true),
      onTapUp: (_) => setState(() => _isHoveredOrPressed = false),
      onTapCancel: () => setState(() => _isHoveredOrPressed = false),
      onTap: null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHoveredOrPressed ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHoveredOrPressed ? 0.7 : 0.4),
              blurRadius: _isHoveredOrPressed ? 20 : 8.0,
              offset: Offset(0, _isHoveredOrPressed ? 10 : 4),
            ),
            if (_isHoveredOrPressed)
              BoxShadow(
                color: AppTheme.goldPrimary.withOpacity(0.18),
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}


// Empty States & Interactive Showcase Row
