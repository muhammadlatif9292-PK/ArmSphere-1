import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tactile_press_wrapper.dart';

class AppEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  const AppEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCtaTap,
  }) : super(key: key);

  @override
  State<AppEmptyState> createState() => _AppEmptyStateState();
}

class _AppEmptyStateState extends State<AppEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<double>(begin: 12.0, end: 0.0).animate(curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.border, width: 1.0),
                  gradient: const RadialGradient(
                    colors: [
                      AppTheme.elevatedSurface,
                      AppTheme.surface,
                    ],
                    center: Alignment.center,
                    radius: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    size: 32,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: AppTheme.fontDisplay,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontFamily: AppTheme.fontBody,
                ),
              ),
              if (widget.ctaLabel != null && widget.onCtaTap != null) ...[
                const SizedBox(height: AppTheme.space24),
                TactilePressWrapper(
                  onTap: widget.onCtaTap,
                  semanticLabel: widget.ctaLabel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space24,
                      vertical: AppTheme.space12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Text(
                      widget.ctaLabel!,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
