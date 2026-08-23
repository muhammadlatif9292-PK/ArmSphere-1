import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import 'shimmer_box.dart';
class TournamentSkeletonLoadingWidget extends StatefulWidget {
  const TournamentSkeletonLoadingWidget({Key? key}) : super(key: key);

  @override
  State<TournamentSkeletonLoadingWidget> createState() =>
      _TournamentSkeletonLoadingWidgetState();
}

class _TournamentSkeletonLoadingWidgetState
    extends State<TournamentSkeletonLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerPercent = _shimmerController.value;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Skeleton Status Badge
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFF0D1527).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.goldPrimary.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.goldPrimary,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldPrimary.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'GLASS SKELETON LOADING',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Text(
                        'NO SPINNERS',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Hero Card Placeholder
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Image Block Placeholder
                    ShimmerBox(
                      width: double.infinity,
                      height: 140,
                      borderRadius: 14,
                      percent: shimmerPercent,
                    ),
                    const SizedBox(height: 14),

                    // Category Tags Row Skeletons
                    Row(
                      children: [
                        ShimmerBox(
                          width: 70,
                          height: 20,
                          borderRadius: 8,
                          percent: shimmerPercent,
                        ),
                        const SizedBox(width: 8),
                        ShimmerBox(
                          width: 90,
                          height: 20,
                          borderRadius: 8,
                          percent: shimmerPercent,
                        ),
                        const SizedBox(width: 8),
                        ShimmerBox(
                          width: 60,
                          height: 20,
                          borderRadius: 8,
                          percent: shimmerPercent,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Title Line Skeletons
                    ShimmerBox(
                      width: double.infinity,
                      height: 18,
                      borderRadius: 6,
                      percent: shimmerPercent,
                    ),
                    const SizedBox(height: 8),
                    ShimmerBox(
                      width: 200,
                      height: 14,
                      borderRadius: 6,
                      percent: shimmerPercent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bracket Placeholder Glass Card
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ShimmerBox(
                              width: 24,
                              height: 24,
                              borderRadius: 12,
                              percent: shimmerPercent,
                            ),
                            const SizedBox(width: 8),
                            ShimmerBox(
                              width: 140,
                              height: 14,
                              borderRadius: 6,
                              percent: shimmerPercent,
                            ),
                          ],
                        ),
                        ShimmerBox(
                          width: 60,
                          height: 18,
                          borderRadius: 6,
                          percent: shimmerPercent,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 2-Round Bracket Diagrams Skeleton
                    Row(
                      children: [
                        // Round 1 Matches
                        Expanded(
                          child: Column(
                            children: [
                              _buildMatchSlotSkeleton(shimmerPercent),
                              const SizedBox(height: 10),
                              _buildMatchSlotSkeleton(shimmerPercent),
                            ],
                          ),
                        ),

                        // Connector Line Skeleton
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Container(
                            width: 16,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppTheme.goldPrimary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                right: BorderSide(
                                  color: AppTheme.goldPrimary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                bottom: BorderSide(
                                  color: AppTheme.goldPrimary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Finals Match
                        Expanded(
                          child: _buildMatchSlotSkeleton(shimmerPercent, isFinal: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Timeline Placeholder Glass Card
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ShimmerBox(
                          width: 24,
                          height: 24,
                          borderRadius: 12,
                          percent: shimmerPercent,
                        ),
                        const SizedBox(width: 8),
                        ShimmerBox(
                          width: 160,
                          height: 14,
                          borderRadius: 6,
                          percent: shimmerPercent,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Vertical Nodes Timeline
                    _buildTimelineNodeSkeleton(shimmerPercent, isLast: false),
                    _buildTimelineNodeSkeleton(shimmerPercent, isLast: false),
                    _buildTimelineNodeSkeleton(shimmerPercent, isLast: true),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Participants Carousel Skeleton Card
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      width: 150,
                      height: 14,
                      borderRadius: 6,
                      percent: shimmerPercent,
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 14.0),
                            child: Column(
                              children: [
                                ShimmerBox(
                                  width: 44,
                                  height: 44,
                                  borderRadius: 22,
                                  percent: shimmerPercent,
                                ),
                                const SizedBox(height: 6),
                                ShimmerBox(
                                  width: 40,
                                  height: 10,
                                  borderRadius: 4,
                                  percent: shimmerPercent,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF0D1527).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.goldPrimary.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMatchSlotSkeleton(double percent, {bool isFinal = false}) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF141E2F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFinal
              ? AppTheme.goldPrimary.withOpacity(0.6)
              : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ShimmerBox(
                width: 18,
                height: 18,
                borderRadius: 9,
                percent: percent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ShimmerBox(
                  width: double.infinity,
                  height: 10,
                  borderRadius: 4,
                  percent: percent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ShimmerBox(
                width: 18,
                height: 18,
                borderRadius: 9,
                percent: percent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ShimmerBox(
                  width: double.infinity,
                  height: 10,
                  borderRadius: 4,
                  percent: percent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNodeSkeleton(double percent, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                ShimmerBox(
                  width: 22,
                  height: 22,
                  borderRadius: 11,
                  percent: percent,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: EdgeInsets.symmetric(vertical: 4),
                      color: AppTheme.goldPrimary.withOpacity(0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF141E2F).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(
                          width: 110,
                          height: 12,
                          borderRadius: 4,
                          percent: percent,
                        ),
                        ShimmerBox(
                          width: 50,
                          height: 14,
                          borderRadius: 6,
                          percent: percent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ShimmerBox(
                      width: 140,
                      height: 10,
                      borderRadius: 4,
                      percent: percent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

