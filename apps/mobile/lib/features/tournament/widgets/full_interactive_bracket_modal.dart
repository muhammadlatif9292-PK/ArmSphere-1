import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
class FullInteractiveBracketModal extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const FullInteractiveBracketModal({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<FullInteractiveBracketModal> createState() => _FullInteractiveBracketModalState();
}

class _FullInteractiveBracketModalState extends State<FullInteractiveBracketModal> {
  int _selectedBracketTab = 0; // 0: Winners, 1: Losers, 2: Finals

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_tree_rounded, color: Color(0xFF00E5FF), size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'FULL TOURNAMENT BRACKET',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Senior Men Right -80kg Class',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
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
              _buildTabChip(2, 'FINALS'),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),

          // Full Bracket Canvas View
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white12,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Colors.black : AppTheme.textMuted,
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
            // Round 1
            _buildFullStageColumn('ROUND 1 (16 ATHLETES)', 8),
            const SizedBox(width: 30),
            // Quarter Finals
            _buildFullStageColumn('QUARTER FINALS', 4),
            const SizedBox(width: 30),
            // Semi Finals
            _buildFullStageColumn('SEMI FINALS', 2),
            const SizedBox(width: 30),
            // Final
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
            const SizedBox(width: 30),
            _buildFullStageColumn('LOSERS ROUND 2', 2),
            const SizedBox(width: 30),
            _buildFullStageColumn('LOSERS FINALS', 1),
          ],
        ),
      ],
    );
  }

  Widget _buildFinalsBracketFullView() {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141E2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldPrimary, width: 1.5),
      ),
      child: Column(
        children: const [
          Icon(Icons.emoji_events_rounded, size: 48, color: AppTheme.goldPrimary),
          SizedBox(height: 12),
          Text(
            'CHAMPIONSHIP MATCH',
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.goldPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Winners Bracket Champion vs. Losers Bracket Champion',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFullStageColumn(String title, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF00E5FF),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: List.generate(count, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                width: 160,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF141E2F),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Match #${i + 1}', style: const TextStyle(fontSize: 8.5, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text(i == 0 ? 'Tariq Z. (YOU)' : 'Competitor A', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Competitor B', style: const TextStyle(fontSize: 10, color: Colors.white70)),
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

