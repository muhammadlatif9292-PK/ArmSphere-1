import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class ParticipantsCarouselWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const ParticipantsCarouselWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<ParticipantsCarouselWidget> createState() => _ParticipantsCarouselWidgetState();
}

class _ParticipantsCarouselWidgetState extends State<ParticipantsCarouselWidget> {
  String _selectedCategoryFilter = 'ALL';

  final List<Map<String, dynamic>> _athletes = [
    {
      'id': 'ath_1',
      'name': 'Tariq Zafar',
      'province': 'Punjab',
      'club': 'Lahore Iron Grip Club',
      'elo': 2145,
      'leagueBadge': 'PRO LEAGUE',
      'leagueColor': Color(0xFFFF2A6D),
      'isVerified': true,
      'photoUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=300',
      'category': '-80kg',
      'rank': '#1 National',
      'winLoss': '38W - 4L',
      'armPreference': 'Right Arm Primary',
      'bio': '2x National Heavy-Middleweight Champion. Specializes in High-Hook & Toproll.',
    },
    {
      'id': 'ath_2',
      'name': 'Bilal Khan',
      'province': 'KPK',
      'club': 'Peshawar Titan Pullers',
      'elo': 1980,
      'leagueBadge': 'NATIONAL CHAMP',
      'leagueColor': AppTheme.goldPrimary,
      'isVerified': true,
      'photoUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=300',
      'category': '-80kg',
      'rank': '#3 National',
      'winLoss': '29W - 7L',
      'armPreference': 'Both Arms Pro',
      'bio': 'Explosive Press Specialist. Unbeaten in Northern Regional Qualifiers 2025.',
    },
    {
      'id': 'ath_3',
      'name': 'Usman Raza',
      'province': 'Islamabad',
      'club': 'Capital Power Gym',
      'elo': 1890,
      'leagueBadge': 'RISING STAR',
      'leagueColor': Color(0xFF00E5FF),
      'isVerified': true,
      'photoUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=300',
      'category': '-80kg',
      'rank': '#5 National',
      'winLoss': '22W - 5L',
      'armPreference': 'Left Arm Dominant',
      'bio': 'Fast riser in the -80kg Division. Known for lightning-fast shoulder press.',
    },
    {
      'id': 'ath_4',
      'name': 'Zain Ul-Abedin',
      'province': 'Punjab',
      'club': 'Rawalpindi Steel Arm Academy',
      'elo': 1820,
      'leagueBadge': 'PRO LEAGUE',
      'leagueColor': Color(0xFFFF2A6D),
      'isVerified': true,
      'photoUrl': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&q=80&w=300',
      'category': '-80kg',
      'rank': '#7 National',
      'winLoss': '19W - 8L',
      'armPreference': 'Right Arm Toproll',
      'bio': 'Technical Toproller with exceptional hand & wrist endurance.',
    },
    {
      'id': 'ath_5',
      'name': 'Hamza Shah',
      'province': 'Sindh',
      'club': 'Karachi Iron Warriors',
      'elo': 2050,
      'leagueBadge': 'ELITE MASTER',
      'leagueColor': Color(0xFFA855F7),
      'isVerified': true,
      'photoUrl': 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&q=80&w=300',
      'category': '+100kg',
      'rank': '#2 Super Heavy',
      'winLoss': '34W - 6L',
      'armPreference': 'Right Arm Super Heavy',
      'bio': 'Sindh Super Heavyweight Title Holder. Massive side pressure power.',
    },
    {
      'id': 'ath_6',
      'name': 'Faisal Mahmood',
      'province': 'Balochistan',
      'club': 'Quetta Apex Pullers',
      'elo': 1760,
      'leagueBadge': 'RISING STAR',
      'leagueColor': Color(0xFF00E5FF),
      'isVerified': true,
      'photoUrl': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&q=80&w=300',
      'category': '-90kg',
      'rank': '#9 National',
      'winLoss': '16W - 4L',
      'armPreference': 'Right Arm Hook',
      'bio': 'Quetta Regional Gold Medalist 2026. Feared for deep hook endurance.',
    },
  ];

  List<Map<String, dynamic>> get _filteredAthletes {
    if (_selectedCategoryFilter == 'ALL') return _athletes;
    return _athletes.where((a) => a['category'] == _selectedCategoryFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredAthletes;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0D1527).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.goldPrimary.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withOpacity(0.12),
            blurRadius: 18,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.goldPrimary.withOpacity(0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: AppTheme.goldPrimary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'PARTICIPANTS & ATHLETES',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Enrolled Competitors & Official ELO Ranks',
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        '128 ATHLETES',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Filter Category Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('ALL', 'All Classes'),
                      const SizedBox(width: 6),
                      _buildCategoryChip('-80kg', 'Senior -80kg'),
                      const SizedBox(width: 6),
                      _buildCategoryChip('-90kg', 'Senior -90kg'),
                      const SizedBox(width: 6),
                      _buildCategoryChip('+100kg', 'Super Heavy +100kg'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Horizontal Athletes Carousel
              SizedBox(
                height: 245,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final athlete = filteredList[index];
                    return _buildAthleteCard(athlete);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String code, String label) {
    final bool isSelected = _selectedCategoryFilter == code;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategoryFilter = code;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.goldPrimary : const Color(0xFF141E2F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.goldPrimary : Colors.white12,
          ),
        ),
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
    );
  }

  Widget _buildAthleteCard(Map<String, dynamic> athlete) {
    final String heroTag = 'athlete_hero_${athlete['id']}';

    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: Hero(
        tag: heroTag,
        child: Material(
          color: Colors.transparent,
          child: TactilePressWrapper(
            onTap: () {
              HapticFeedback.mediumImpact();
              _openAthleteProfileModal(context, athlete, heroTag);
            },
            child: Container(
              width: 165,
              decoration: BoxDecoration(
                color: Color(0xFF141E2F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (athlete['leagueColor'] as Color).withOpacity(0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (athlete['leagueColor'] as Color).withOpacity(0.12),
                    blurRadius: 10,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Photo Section with Badges
                    Stack(
                      children: [
                        // Photo
                        Image.network(
                          athlete['photoUrl'],
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 110,
                            color: Color(0xFF1E293B),
                            child: const Center(
                              child: Icon(Icons.person_rounded, size: 40, color: Colors.white38),
                            ),
                          ),
                        ),

                        // Gradient overlay at top/bottom of photo
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.4),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Verified Badge (Top Right)
                        if (athlete['isVerified'] == true)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Color(0xFF00E5FF),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF00E5FF).withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 10,
                                color: Colors.black,
                              ),
                            ),
                          ),

                        // League Badge (Bottom Left of Photo)
                        Positioned(
                          bottom: 6,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (athlete['leagueColor'] as Color),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              athlete['leagueBadge'],
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Card Body Details
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Name & Province
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  athlete['name'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 10,
                                      color: AppTheme.goldPrimary,
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        '${athlete['province']} • ${athlete['club']}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 9,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // ELO Rating Badge & Action Prompt
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldPrimary.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.goldPrimary.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.bolt_rounded,
                                        size: 11,
                                        color: AppTheme.goldPrimary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${athlete['elo']} ELO',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.goldPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAthleteProfileModal(
      BuildContext context, Map<String, dynamic> athlete, String heroTag) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Hero(
            tag: heroTag,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (athlete['leagueColor'] as Color),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (athlete['leagueColor'] as Color).withOpacity(0.35),
                      blurRadius: 24,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Header Photo Banner
                        Stack(
                          children: [
                            Image.network(
                              athlete['photoUrl'],
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.transparent,
                                      Color(0xFF0F172A),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Close Button
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),

                            // Name & Badges Overlay
                            Positioned(
                              bottom: 12,
                              left: 16,
                              right: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (athlete['leagueColor'] as Color),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          athlete['leagueBadge'],
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (athlete['isVerified'] == true)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF00E5FF).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF00E5FF)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.verified_rounded, size: 12, color: Color(0xFF00E5FF)),
                                              SizedBox(width: 4),
                                              Text(
                                                'PAFF VERIFIED',
                                                style: TextStyle(
                                                  fontFamily: AppTheme.fontDisplay,
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF00E5FF),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    athlete['name'],
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Stats & Info Grid
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 3 Big Metric Pill Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildProfileMetricTile(
                                      'ELO RATING',
                                      '${athlete['elo']}',
                                      Icons.bolt_rounded,
                                      AppTheme.goldPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildProfileMetricTile(
                                      'NAT. RANK',
                                      athlete['rank'],
                                      Icons.military_tech_rounded,
                                      const Color(0xFF00E5FF),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildProfileMetricTile(
                                      'RECORD',
                                      athlete['winLoss'],
                                      Icons.emoji_events_rounded,
                                      const Color(0xFF00E676),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Bio Section
                              const Text(
                                'ATHLETE BIO',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.goldPrimary,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                athlete['bio'],
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 11.5,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Additional Details List
                              _buildDetailRow(Icons.location_on_rounded, 'Province:', athlete['province']),
                              _buildDetailRow(Icons.fitness_center_rounded, 'Affiliated Club:', athlete['club']),
                              _buildDetailRow(Icons.category_rounded, 'Weight Class:', athlete['category']),
                              _buildDetailRow(Icons.pan_tool_rounded, 'Arm Style:', athlete['armPreference']),

                              const SizedBox(height: 18),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.goldPrimary,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('✓ Viewing Head-to-Head Stats for ${athlete['name']}'),
                                            backgroundColor: AppTheme.goldPrimary,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.analytics_rounded, size: 16),
                                      label: const Text(
                                        'COMPARE STATS',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Color(0xFF141E2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 8,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.goldPrimary),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 10.5,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

