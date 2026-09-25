import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Full Interactive Modal for Tournament Brackets
///
/// Upgraded to Canonical Stage 2 Specification (Slice 8 / [P0-04]):
/// - RepaintBoundary layer isolation.
/// - Two-axis InteractiveViewer virtualization with 0.5x - 2.5x pinch-to-zoom.
/// - Normalized AppTheme tokens (voidBackground, cardSurface, info, goldPrimary).
class FullInteractiveBracketModal extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const FullInteractiveBracketModal({
    super.key,
    required this.tournament,
  });

  @override
  State<FullInteractiveBracketModal> createState() => _FullInteractiveBracketModalState();
}

class _FullInteractiveBracketModalState extends State<FullInteractiveBracketModal> {
  int _selectedBracketTab = 0; // 0: Winners, 1: Losers, 2: Finals

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_tree_rounded, color: AppTheme.info, size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FULL TOURNAMENT BRACKET',
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (widget.tournament['category'] ?? widget.tournament['division'] ?? 'Official Championship Draw').toString(),
                        style: const TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bracket Category Segment Selector
          Row(
            children: [
              _buildTabChip(0, 'WINNERS BRACKET'),
              const SizedBox(width: 8),
              _buildTabChip(1, 'LOSERS BRACKET'),
              const SizedBox(width: 8),
              _buildTabChip(2, 'GRAND FINALS'),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderSubtle, height: 1),
          const SizedBox(height: 16),

          // Full Bracket Canvas View with InteractiveViewer & RepaintBoundary
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              child: Container(
                color: AppTheme.voidBackground,
                child: InteractiveViewer(
                  constrained: false,
                  minScale: 0.4,
                  maxScale: 2.5,
                  boundaryMargin: const EdgeInsets.all(80.0),
                  child: RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedBracketTab == 0) _buildWinnersBracketFullView(),
                          if (_selectedBracketTab == 1) _buildLosersBracketFullView(),
                          if (_selectedBracketTab == 2) _buildFinalsBracketFullView(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(int index, String label) {
    final isSelected = _selectedBracketTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedBracketTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.info.withValues(alpha: 0.18) : AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: isSelected ? AppTheme.info : AppTheme.borderSubtle,
              width: isSelected ? 1.2 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppTheme.info : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinnersBracketFullView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFullStageColumn('ROUND 1 (16 ATHLETES)', 8),
            const SizedBox(width: 32),
            _buildFullStageColumn('QUARTER FINALS', 4),
            const SizedBox(width: 32),
            _buildFullStageColumn('SEMI FINALS', 2),
            const SizedBox(width: 32),
            _buildFullStageColumn('GRAND FINAL', 1),
          ],
        ),
      ],
    );
  }

  Widget _buildLosersBracketFullView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFullStageColumn('LOSERS ROUND 1', 4),
            const SizedBox(width: 32),
            _buildFullStageColumn('LOSERS ROUND 2', 2),
            const SizedBox(width: 32),
            _buildFullStageColumn('LOSERS FINALS', 1),
          ],
        ),
      ],
    );
  }

  Widget _buildFinalsBracketFullView() {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_events_rounded, size: 48, color: AppTheme.goldPrimary),
          SizedBox(height: 12),
          Text(
            'CHAMPIONSHIP MATCH',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.goldPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Winners Bracket Champion vs. Losers Bracket Champion',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFullStageColumn(String title, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.info,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Column(
          children: List.generate(count, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                width: 170,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Match #${i + 1}',
                      style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontFamily: 'Space Grotesk'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seed #${(i * 2) + 1}',
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 11,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Seed #${(i * 2) + 2}',
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
