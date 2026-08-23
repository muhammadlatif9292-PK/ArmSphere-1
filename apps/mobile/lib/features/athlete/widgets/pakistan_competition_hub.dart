import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';

/// Data Model for Future-Ready Competition Entities
class CompetitionEntityData {
  final String id;
  final String name;
  final String type; // 'WORLD', 'COUNTRY', 'PROVINCE', 'CLUB'
  final String? parentId;
  final String emblemIcon;
  final int registeredAthletes;
  final int activeClubs;
  final int liveTournaments;
  final int avgElo;
  final String topRankedAthlete;
  final String latestTournament;
  final List<ClubEntityData> topClubs;

  const CompetitionEntityData({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    required this.emblemIcon,
    required this.registeredAthletes,
    required this.activeClubs,
    required this.liveTournaments,
    required this.avgElo,
    required this.topRankedAthlete,
    required this.latestTournament,
    required this.topClubs,
  });
}

/// Data Model for Club Entities
class ClubEntityData {
  final String id;
  final String name;
  final String city;
  final String logoUrl;
  final bool isVerified;
  final int registeredAthletes;
  final int avgElo;
  final String topAthlete;
  final String prestigeTier; // Bronze, Silver, Gold, Diamond, Elite, National Champion
  final int trophyCount;

  const ClubEntityData({
    required this.id,
    required this.name,
    required this.city,
    required this.logoUrl,
    required this.isVerified,
    required this.registeredAthletes,
    required this.avgElo,
    required this.topAthlete,
    required this.prestigeTier,
    required this.trophyCount,
  });
}

/// ARMSPHERE V1.0 - PREMIUM PAKISTAN COMPETITION HUB
/// Official Digital Platform Component for Pakistan Arm Wrestling
class PakistanCompetitionHubCard extends StatefulWidget {
  const PakistanCompetitionHubCard({Key? key}) : super(key: key);

  @override
  State<PakistanCompetitionHubCard> createState() =>
      _PakistanCompetitionHubCardState();
}

class _PakistanCompetitionHubCardState extends State<PakistanCompetitionHubCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _mapBreathingController;
  late AnimationController _sweepReflectionController;
  late Animation<double> _breathScale;

  String _selectedProvinceId = 'punjab';
  int? _hoveredClubIndex;

  // Comprehensive Pakistan Province Dataset
  static const Map<String, CompetitionEntityData> _provincesData = {
    'punjab': CompetitionEntityData(
      id: 'punjab',
      name: 'Punjab',
      type: 'PROVINCE',
      parentId: 'pakistan',
      emblemIcon: '🏰',
      registeredAthletes: 1842,
      activeClubs: 53,
      liveTournaments: 4,
      avgElo: 1792,
      topRankedAthlete: 'Muhammad Ali',
      latestTournament: 'Punjab Open Championship 2026',
      topClubs: [
        ClubEntityData(
          id: 'lahore_titans',
          name: 'Lahore Titans Arm Club',
          city: 'Lahore',
          logoUrl: '⚡',
          isVerified: true,
          registeredAthletes: 142,
          avgElo: 1845,
          topAthlete: 'Muhammad Ali',
          prestigeTier: 'Diamond',
          trophyCount: 18,
        ),
        ClubEntityData(
          id: 'pindi_iron',
          name: 'Rawalpindi Iron Arms',
          city: 'Rawalpindi',
          logoUrl: '🛡️',
          isVerified: true,
          registeredAthletes: 98,
          avgElo: 1790,
          topAthlete: 'Bilal Chaudhry',
          prestigeTier: 'Gold',
          trophyCount: 12,
        ),
        ClubEntityData(
          id: 'faisalabad_steel',
          name: 'Faisalabad Steel Grips',
          city: 'Faisalabad',
          logoUrl: '🦾',
          isVerified: true,
          registeredAthletes: 85,
          avgElo: 1755,
          topAthlete: 'Shahbaz Gujjar',
          prestigeTier: 'Gold',
          trophyCount: 9,
        ),
        ClubEntityData(
          id: 'multan_biceps',
          name: 'Multan Biceps Squad',
          city: 'Multan',
          logoUrl: '🔥',
          isVerified: false,
          registeredAthletes: 64,
          avgElo: 1710,
          topAthlete: 'Imran Raza',
          prestigeTier: 'Silver',
          trophyCount: 6,
        ),
      ],
    ),
    'sindh': CompetitionEntityData(
      id: 'sindh',
      name: 'Sindh',
      type: 'PROVINCE',
      parentId: 'pakistan',
      emblemIcon: '🌊',
      registeredAthletes: 1215,
      activeClubs: 38,
      liveTournaments: 3,
      avgElo: 1745,
      topRankedAthlete: 'Zubair Khan',
      latestTournament: 'Sindh Arm Showdown 2026',
      topClubs: [
        ClubEntityData(
          id: 'karachi_gladiators',
          name: 'Karachi Gladiators',
          city: 'Karachi',
          logoUrl: '👑',
          isVerified: true,
          registeredAthletes: 156,
          avgElo: 1880,
          topAthlete: 'Zubair Khan',
          prestigeTier: 'National Champion',
          trophyCount: 22,
        ),
        ClubEntityData(
          id: 'hyderabad_power',
          name: 'Hyderabad Powerhouse',
          city: 'Hyderabad',
          logoUrl: '⚡',
          isVerified: true,
          registeredAthletes: 78,
          avgElo: 1740,
          topAthlete: 'Rashid Soomro',
          prestigeTier: 'Gold',
          trophyCount: 8,
        ),
        ClubEntityData(
          id: 'sukkur_arm',
          name: 'Sukkur Arm Academy',
          city: 'Sukkur',
          logoUrl: '🎯',
          isVerified: false,
          registeredAthletes: 45,
          avgElo: 1690,
          topAthlete: 'Fahad Mahar',
          prestigeTier: 'Silver',
          trophyCount: 5,
        ),
      ],
    ),
    'kpk': CompetitionEntityData(
      id: 'kpk',
      name: 'KPK',
      type: 'PROVINCE',
      parentId: 'pakistan',
      emblemIcon: '🦅',
      registeredAthletes: 940,
      activeClubs: 29,
      liveTournaments: 2,
      avgElo: 1710,
      topRankedAthlete: 'Tariq Afridi',
      latestTournament: 'KPK Warrior Cup 2026',
      topClubs: [
        ClubEntityData(
          id: 'peshawar_warriors',
          name: 'Peshawar Warriors',
          city: 'Peshawar',
          logoUrl: '⚔️',
          isVerified: true,
          registeredAthletes: 112,
          avgElo: 1820,
          topAthlete: 'Tariq Afridi',
          prestigeTier: 'Elite',
          trophyCount: 15,
        ),
        ClubEntityData(
          id: 'swat_biceps',
          name: 'Swat Valley Biceps',
          city: 'Mingora',
          logoUrl: '🏔️',
          isVerified: true,
          registeredAthletes: 52,
          avgElo: 1705,
          topAthlete: 'Gulzar Khan',
          prestigeTier: 'Silver',
          trophyCount: 7,
        ),
        ClubEntityData(
          id: 'mardan_wrist',
          name: 'Mardan Steel Wrist',
          city: 'Mardan',
          logoUrl: '💪',
          isVerified: false,
          registeredAthletes: 40,
          avgElo: 1660,
          topAthlete: 'Asad Khattak',
          prestigeTier: 'Bronze',
          trophyCount: 4,
        ),
      ],
    ),
    'balochistan': CompetitionEntityData(
      id: 'balochistan',
      name: 'Balochistan',
      type: 'PROVINCE',
      parentId: 'pakistan',
      emblemIcon: '🦅',
      registeredAthletes: 480,
      activeClubs: 16,
      liveTournaments: 1,
      avgElo: 1685,
      topRankedAthlete: 'Jan Baloch',
      latestTournament: 'Quetta Grand Prix 2026',
      topClubs: [
        ClubEntityData(
          id: 'quetta_lions',
          name: 'Quetta Lions Arm Club',
          city: 'Quetta',
          logoUrl: '🦁',
          isVerified: true,
          registeredAthletes: 82,
          avgElo: 1765,
          topAthlete: 'Jan Baloch',
          prestigeTier: 'Gold',
          trophyCount: 11,
        ),
        ClubEntityData(
          id: 'gwadar_coastal',
          name: 'Gwadar Coastal Grips',
          city: 'Gwadar',
          logoUrl: '⚓',
          isVerified: true,
          registeredAthletes: 38,
          avgElo: 1680,
          topAthlete: 'Zarak Rind',
          prestigeTier: 'Silver',
          trophyCount: 4,
        ),
      ],
    ),
    'islamabad': CompetitionEntityData(
      id: 'islamabad',
      name: 'Islamabad',
      type: 'PROVINCE',
      parentId: 'pakistan',
      emblemIcon: '🏛️',
      registeredAthletes: 310,
      activeClubs: 12,
      liveTournaments: 2,
      avgElo: 1760,
      topRankedAthlete: 'Usman Malik',
      latestTournament: 'Capital Clash 2026',
      topClubs: [
        ClubEntityData(
          id: 'capital_force',
          name: 'Capital Force Islamabad',
          city: 'Islamabad',
          logoUrl: '⭐',
          isVerified: true,
          registeredAthletes: 94,
          avgElo: 1810,
          topAthlete: 'Usman Malik',
          prestigeTier: 'Elite',
          trophyCount: 14,
        ),
        ClubEntityData(
          id: 'margalla_titans',
          name: 'Margalla Arm Titans',
          city: 'Islamabad',
          logoUrl: '🏔️',
          isVerified: true,
          registeredAthletes: 62,
          avgElo: 1730,
          topAthlete: 'Danish Qureshi',
          prestigeTier: 'Gold',
          trophyCount: 8,
        ),
      ],
    ),
    'ajk': CompetitionEntityData(
      id: 'ajk',
      name: 'AJK',
      type: 'PROVINCE',
      parentId: 'pakistan',
      emblemIcon: '🏔️',
      registeredAthletes: 265,
      activeClubs: 9,
      liveTournaments: 1,
      avgElo: 1650,
      topRankedAthlete: 'Hamza Kashmir',
      latestTournament: 'Kashmir Arm Fest 2026',
      topClubs: [
        ClubEntityData(
          id: 'kashmir_fest_club',
          name: 'Muzaffarabad Arm Club',
          city: 'Muzaffarabad',
          logoUrl: '🌲',
          isVerified: true,
          registeredAthletes: 58,
          avgElo: 1695,
          topAthlete: 'Hamza Kashmir',
          prestigeTier: 'Silver',
          trophyCount: 6,
        ),
        ClubEntityData(
          id: 'mirpur_power',
          name: 'Mirpur Power Wrist',
          city: 'Mirpur',
          logoUrl: '💥',
          isVerified: false,
          registeredAthletes: 34,
          avgElo: 1640,
          topAthlete: 'Arslan Butt',
          prestigeTier: 'Bronze',
          trophyCount: 3,
        ),
      ],
    ),
    'gb': CompetitionEntityData(
      id: 'gb',
      name: 'Gilgit Baltistan',
      type: 'PROVINCE',
      parentId: 'pakistan',
      emblemIcon: '🏔️',
      registeredAthletes: 195,
      activeClubs: 7,
      liveTournaments: 1,
      avgElo: 1630,
      topRankedAthlete: 'Sher Mountain',
      latestTournament: 'Karakoram Titan Battle',
      topClubs: [
        ClubEntityData(
          id: 'karakoram_eagles',
          name: 'Karakoram Eagles',
          city: 'Gilgit',
          logoUrl: '🦅',
          isVerified: true,
          registeredAthletes: 46,
          avgElo: 1720,
          topAthlete: 'Sher Mountain',
          prestigeTier: 'Gold',
          trophyCount: 7,
        ),
        ClubEntityData(
          id: 'hunza_high',
          name: 'Hunza High Altitude Arms',
          city: 'Karimabad',
          logoUrl: '❄️',
          isVerified: false,
          registeredAthletes: 28,
          avgElo: 1625,
          topAthlete: 'Ali Hunzai',
          prestigeTier: 'Bronze',
          trophyCount: 2,
        ),
      ],
    ),
  };

  @override
  void initState() {
    super.initState();
    // Map slow breathing animation controller
    _mapBreathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathScale = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(
        parent: _mapBreathingController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Continuous metallic sweep reflection animation
    _sweepReflectionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _mapBreathingController.dispose();
    _sweepReflectionController.dispose();
    super.dispose();
  }

  void _selectProvince(String provinceId) {
    if (_selectedProvinceId == provinceId) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedProvinceId = provinceId;
    });
  }

  @override
  Widget build(BuildContext context) {
    const electricBlue = AppTheme.info;
    final selectedData =
        _provincesData[_selectedProvinceId] ?? _provincesData['punjab']!;

    return Container(
      margin: EdgeInsets.only(top: 8, bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: AppTheme.background,
        border: Border.all(
          color: electricBlue.withOpacity(0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: electricBlue.withOpacity(0.12),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title & Subtitle
                _buildHeaderTitle(electricBlue),

                const SizedBox(height: 16),

                // PART 1: Interactive Pakistan Vector Map
                _buildInteractivePakistanMap(electricBlue),

                const SizedBox(height: 14),

                // Province Selection Chips Bar
                _buildProvinceSelectorChips(electricBlue),

                const SizedBox(height: 18),

                // PART 2: Province Summary Card (Animated Glass)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_selectedProvinceId),
                    child: _buildProvinceSummaryCard(
                        selectedData, electricBlue),
                  ),
                ),

                const SizedBox(height: 22),

                // PART 3: Top Clubs Carousel
                _buildTopClubsHeader(selectedData.name, electricBlue),

                const SizedBox(height: 12),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: KeyedSubtree(
                    key: ValueKey('clubs_$_selectedProvinceId'),
                    child: _buildTopClubsCarousel(
                        selectedData.topClubs, electricBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section Header Title & Subtitle
  Widget _buildHeaderTitle(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.info.withOpacity(0.4),
                    ),
                  ),
                  child: const Text(
                    'PK 🇵🇰',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.info,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pakistan Competition Hub',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.success.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.sensors_rounded,
                    size: 11,
                    color: AppTheme.success,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'LIVE ECOSYSTEM',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.success,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Explore competitive activity across Pakistan.',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  /// PART 1: Interactive Pakistan Map Container
  Widget _buildInteractivePakistanMap(Color electricBlue) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            AppTheme.background,
            AppTheme.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(
          color: electricBlue.withOpacity(0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Floating background particle dots & telemetry grid lines
            CustomPaint(
              size: Size.infinite,
              painter: _MapTelemetryBackgroundPainter(),
            ),

            // Animated Breathing Stylized Pakistan Map Canvas
            Center(
              child: AnimatedBuilder(
                animation: _mapBreathingController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breathScale.value,
                    child: SizedBox(
                      width: 290,
                      height: 230,
                      child: GestureDetector(
                        onTapUp: (details) {
                          _handleMapTap(details.localPosition);
                        },
                        child: CustomPaint(
                          painter: _PakistanVectorMapPainter(
                            selectedProvinceId: _selectedProvinceId,
                            accentColor: electricBlue,
                            pulseProgress: _mapBreathingController.value,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Top-Left Floating Map Badge Indicator
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.background.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: electricBlue.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: electricBlue,
                        boxShadow: [
                          BoxShadow(
                            color: electricBlue,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SELECTED: ${_provincesData[_selectedProvinceId]?.name.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom-Right Tap Hint
            Positioned(
              bottom: 10,
              right: 12,
              child: Row(
                children: const [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 11,
                    color: AppTheme.textMuted,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Tap any province boundary to explore',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Map touch location handler mapping tap coordinates to province
  void _handleMapTap(Offset pos) {
    // Canvas bounds 290 x 230
    final x = pos.dx;
    final y = pos.dy;

    // Approximate bounding hit areas on the 290x230 map
    if (y < 70 && x > 140) {
      if (x > 210) {
        _selectProvince('gb'); // Gilgit Baltistan (Far North East)
      } else {
        _selectProvince('kpk'); // KPK (North West)
      }
    } else if (y >= 60 && y < 110 && x > 210) {
      _selectProvince('ajk'); // AJK (North East border strip)
    } else if (y >= 75 && y < 105 && x >= 170 && x <= 200) {
      _selectProvince('islamabad'); // Islamabad (Capital territory)
    } else if (y >= 80 && y < 160 && x >= 130) {
      _selectProvince('punjab'); // Punjab (Central East)
    } else if (y >= 150 && x >= 130) {
      _selectProvince('sindh'); // Sindh (South East)
    } else if (x < 140 && y >= 70) {
      _selectProvince('balochistan'); // Balochistan (South West)
    } else {
      _selectProvince('punjab');
    }
  }

  /// Province Selector Horizontal Chips Bar
  Widget _buildProvinceSelectorChips(Color electricBlue) {
    final list = _provincesData.values.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: list.map((prov) {
          final isSelected = prov.id == _selectedProvinceId;

          return Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: TactilePressWrapper(
              onTap: () => _selectProvince(prov.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isSelected
                      ? electricBlue.withOpacity(0.2)
                      : AppTheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? electricBlue
                        : Colors.white.withOpacity(0.12),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: electricBlue.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(
                      prov.emblemIcon,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      prov.name,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// PART 2: Province Summary Card
  Widget _buildProvinceSummaryCard(
      CompetitionEntityData data, Color electricBlue) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppTheme.background.withOpacity(0.9),
        border: Border.all(
          color: electricBlue.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: electricBlue.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Province Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: electricBlue.withOpacity(0.18),
                      border: Border.all(
                        color: electricBlue.withOpacity(0.5),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      data.emblemIcon,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            data.name,
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: electricBlue.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'PROVINCE',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: electricBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Latest Event: ${data.latestTournament}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.goldLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.goldLight.withOpacity(0.4),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      '#1 ATHLETE',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.goldLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.topRankedAthlete,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 14),

          // Grid of 4 Key Metrics with Animated Counting
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'REGISTERED ATHLETES',
                  value: data.registeredAthletes.toDouble(),
                  unit: '',
                  icon: Icons.groups_rounded,
                  color: AppTheme.goldPrimary,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  label: 'ACTIVE CLUBS',
                  value: data.activeClubs.toDouble(),
                  unit: '',
                  icon: Icons.shield_rounded,
                  color: AppTheme.success,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  label: 'LIVE TOURNAMENTS',
                  value: data.liveTournaments.toDouble(),
                  unit: '',
                  icon: Icons.emoji_events_rounded,
                  color: AppTheme.warning,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  label: 'AVERAGE ELO',
                  value: data.avgElo.toDouble(),
                  unit: '',
                  icon: Icons.speed_rounded,
                  color: electricBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required double value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) {
            final formatted = val.toInt().toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},');

            return Text(
              '$formatted$unit',
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted.withOpacity(0.85),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  /// PART 3: Top Clubs Section Header
  Widget _buildTopClubsHeader(String provinceName, Color electricBlue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Clubs',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Leading clubs in $provinceName',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        Container(
          padding:
              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: electricBlue.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: electricBlue.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: const [
              Icon(
                Icons.workspace_premium_rounded,
                size: 11,
                color: AppTheme.info,
              ),
              SizedBox(width: 4),
              Text(
                'PRESTIGE RANKED',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.info,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// PART 3: Top Clubs Horizontal Carousel
  Widget _buildTopClubsCarousel(
      List<ClubEntityData> clubs, Color electricBlue) {
    if (clubs.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const Text(
          'No clubs registered in this province yet.',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
      );
    }

    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: clubs.length,
        itemBuilder: (context, index) {
          final club = clubs[index];
          final isHovered = _hoveredClubIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TactilePressWrapper(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _hoveredClubIndex = index;
                });
              },
              child: AnimatedScale(
                scale: isHovered ? 1.03 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 220,
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppTheme.background.withOpacity(0.92),
                    border: Border.all(
                      color: isHovered
                          ? electricBlue
                          : electricBlue.withOpacity(0.25),
                      width: isHovered ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isHovered
                            ? electricBlue.withOpacity(0.25)
                            : Colors.black.withOpacity(0.4),
                        blurRadius: isHovered ? 18 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Logo, Name & Verification
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: electricBlue.withOpacity(0.18),
                                    border: Border.all(
                                      color: electricBlue.withOpacity(0.4),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    club.logoUrl,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              club.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: AppTheme.fontDisplay,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (club.isVerified) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.verified_rounded,
                                              size: 14,
                                              color: AppTheme.info,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '📍 ${club.city}',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Prestige Badge
                            _buildPrestigeBadge(
                                club.prestigeTier, electricBlue),

                            const SizedBox(height: 10),

                            // Metrics Grid
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ATHLETES',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${club.registeredAthletes}',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'AVG ELO',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${club.avgElo}',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.info,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'TROPHIES',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '🏆 ${club.trophyCount}',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.goldLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Top Athlete Footer Line
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 11,
                                  color: AppTheme.goldLight,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '#1 Athlete: ${club.topAthlete}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Metallic Prestige Tier Badge with Reflection Glow
  Widget _buildPrestigeBadge(String tier, Color electricBlue) {
    Color tierColor;
    String tierLabel;

    switch (tier) {
      case 'National Champion':
        tierColor = AppTheme.goldLight;
        tierLabel = '👑 NATIONAL CHAMPION';
        break;
      case 'Elite':
        tierColor = AppTheme.highlightPurple;
        tierLabel = '⚡ ELITE PRESTIGE';
        break;
      case 'Diamond':
        tierColor = AppTheme.info;
        tierLabel = '💎 DIAMOND TIER';
        break;
      case 'Gold':
        tierColor = AppTheme.secondaryAccent;
        tierLabel = '🥇 GOLD TIER';
        break;
      case 'Silver':
        tierColor = AppTheme.textSecondary;
        tierLabel = '🥈 SILVER TIER';
        break;
      default:
        tierColor = AppTheme.goldDark;
        tierLabel = '🥉 BRONZE TIER';
        break;
    }

    return AnimatedBuilder(
      animation: _sweepReflectionController,
      builder: (context, child) {
        final sweepVal = _sweepReflectionController.value;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                tierColor.withOpacity(0.25),
                tierColor.withOpacity(0.08),
                tierColor.withOpacity(0.25),
              ],
              stops: [
                (sweepVal - 0.3).clamp(0.0, 1.0),
                sweepVal.clamp(0.0, 1.0),
                (sweepVal + 0.3).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(
              color: tierColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            tierLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: tierColor,
              letterSpacing: 0.4,
            ),
          ),
        );
      },
    );
  }
}

/// CustomPainter for Stylized Pakistan Vector Map with 7 Province Boundaries
class _PakistanVectorMapPainter extends CustomPainter {
  final String selectedProvinceId;
  final Color accentColor;
  final double pulseProgress;

  _PakistanVectorMapPainter({
    required this.selectedProvinceId,
    required this.accentColor,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Canvas dimensions: 290 x 230
    final defaultFill = AppTheme.surface;
    final borderStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withOpacity(0.22);

    final highlightBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = accentColor;

    final selectedFillGradient = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          accentColor.withOpacity(0.65),
          accentColor.withOpacity(0.25),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Define Stylized Province Polygon Paths

    // 1. Gilgit Baltistan (GB) - Far North East
    final pathGB = Path()
      ..moveTo(200, 15)
      ..lineTo(260, 25)
      ..lineTo(275, 60)
      ..lineTo(225, 75)
      ..lineTo(195, 45)
      ..close();

    // 2. KPK (Khyber Pakhtunkhwa) - North West
    final pathKPK = Path()
      ..moveTo(145, 25)
      ..lineTo(195, 45)
      ..lineTo(185, 95)
      ..lineTo(140, 110)
      ..lineTo(125, 65)
      ..close();

    // 3. AJK (Azad Jammu & Kashmir) - Strip below GB / East of KPK
    final pathAJK = Path()
      ..moveTo(225, 75)
      ..lineTo(255, 65)
      ..lineTo(240, 115)
      ..lineTo(210, 100)
      ..close();

    // 4. Islamabad (Capital Territory) - Central North Dot/Polygon
    final pathIslamabad = Path()
      ..moveTo(180, 80)
      ..lineTo(195, 80)
      ..lineTo(195, 92)
      ..lineTo(180, 92)
      ..close();

    // 5. Punjab - Central East
    final pathPunjab = Path()
      ..moveTo(185, 95)
      ..lineTo(240, 115)
      ..lineTo(220, 175)
      ..lineTo(155, 160)
      ..lineTo(140, 110)
      ..close();

    // 6. Sindh - South East
    final pathSindh = Path()
      ..moveTo(155, 160)
      ..lineTo(220, 175)
      ..lineTo(195, 225)
      ..lineTo(135, 215)
      ..close();

    // 7. Balochistan - South West / Large West Region
    final pathBalochistan = Path()
      ..moveTo(140, 110)
      ..lineTo(155, 160)
      ..lineTo(135, 215)
      ..lineTo(25, 205)
      ..lineTo(15, 140)
      ..lineTo(75, 95)
      ..close();

    final Map<String, Path> provincePaths = {
      'gb': pathGB,
      'kpk': pathKPK,
      'ajk': pathAJK,
      'islamabad': pathIslamabad,
      'punjab': pathPunjab,
      'sindh': pathSindh,
      'balochistan': pathBalochistan,
    };

    // Draw all non-selected provinces first
    provincePaths.forEach((id, path) {
      if (id != selectedProvinceId) {
        // Draw Fill
        canvas.drawPath(path, Paint()..color = defaultFill);
        // Draw Border
        canvas.drawPath(path, borderStroke);
      }
    });

    // Draw selected province with electric blue glow & elevated shadow
    final selectedPath = provincePaths[selectedProvinceId];
    if (selectedPath != null) {
      // Glow Shadow
      canvas.drawPath(
        selectedPath,
        Paint()
          ..color = accentColor.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      // Selected Fill
      canvas.drawPath(selectedPath, selectedFillGradient);

      // Selected Border
      canvas.drawPath(selectedPath, highlightBorder);

      // Pulse Ring Highlight
      final pulseStroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * pulseProgress
        ..color = accentColor.withOpacity(0.8 * (1.0 - pulseProgress));

      canvas.drawPath(selectedPath, pulseStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _PakistanVectorMapPainter oldDelegate) {
    return oldDelegate.selectedProvinceId != selectedProvinceId ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}

/// CustomPainter for Map Background Floating Dots & Telemetry Lines
class _MapTelemetryBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    // Draw grid lines
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw tiny glowing dots
    final dotPaint = Paint()
      ..color = AppTheme.info.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final rand = math.Random(42);
    for (int i = 0; i < 24; i++) {
      final dx = rand.nextDouble() * size.width;
      final dy = rand.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
