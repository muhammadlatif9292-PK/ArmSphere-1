import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class TournamentContextActionsWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentContextActionsWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<TournamentContextActionsWidget> createState() => _TournamentContextActionsWidgetState();
}

class _TournamentContextActionsWidgetState extends State<TournamentContextActionsWidget> {
  int _activePhaseIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.goldPrimary.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                      ),
                      child: Icon(
                        Icons.bolt_rounded,
                        color: AppTheme.goldPrimary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'CONTEXT-AWARE ACTIONS',
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
                          'Active Athlete Controls & Status',
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
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PHASE: ',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        _getPhaseName(_activePhaseIndex),
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPhaseChip(0, '1. Registration'),
                  const SizedBox(width: 6),
                  _buildPhaseChip(1, '2. Pre-Match Prep'),
                  const SizedBox(width: 6),
                  _buildPhaseChip(2, '3. Live Competition'),
                  const SizedBox(width: 6),
                  _buildPhaseChip(3, '4. Post-Tournament'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_activePhaseIndex == 0) _buildRegistrationPhaseContent(context),
            if (_activePhaseIndex == 1) _buildPreMatchPhaseContent(context),
            if (_activePhaseIndex == 2) _buildLiveCompetitionPhaseContent(context),
            if (_activePhaseIndex == 3) _buildPostTournamentPhaseContent(context),
            const SizedBox(height: 14),
            TactilePressWrapper(
              onTap: () {
                HapticFeedback.lightImpact();
                _showShareModal(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.share_rounded, size: 15, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'SHARE TOURNAMENT',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPhaseName(int index) {
    switch (index) {
      case 0:
        return 'REGISTRATION';
      case 1:
        return 'WEIGH-IN / CHECK-IN';
      case 2:
        return 'LIVE MATCHES';
      case 3:
        return 'COMPLETED';
      default:
        return 'ACTIVE';
    }
  }

  Widget _buildPhaseChip(int index, String label) {
    final isSelected = _activePhaseIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activePhaseIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.goldPrimary : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
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

  Widget _buildRegistrationPhaseContent(BuildContext context) {
    return Column(
      children: [
        _buildPrimaryActionButton(
          label: 'REGISTER NOW',
          icon: Icons.app_registration_rounded,
          gradientColors: const [Color(0xFFFFB300), Color(0xFFFF8F00)],
          textColor: Colors.black,
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/events/${widget.tournament['id']}/register', extra: widget.tournament);
          },
        ),
        const SizedBox(height: 10),
        _buildInformativeStatusCard(
          icon: Icons.info_outline_rounded,
          title: 'Weigh-In & Check-In Locked',
          description: 'Weigh-In opens 24 hours prior to tournament start at venue.',
          accentColor: const Color(0xFF00E5FF),
        ),
      ],
    );
  }

  Widget _buildPreMatchPhaseContent(BuildContext context) {
    return Column(
      children: [
        _buildInformativeStatusCard(
          icon: Icons.check_circle_rounded,
          title: 'Registered Competitor',
          description: 'Class: Senior Right -80kg • Slot #42 Confirmed',
          accentColor: const Color(0xFF00E676),
        ),
        const SizedBox(height: 10),
        _buildPrimaryActionButton(
          label: 'UPLOAD MEDICAL CERTIFICATE',
          icon: Icons.upload_file_rounded,
          gradientColors: const [Color(0xFF00E5FF), Color(0xFF00B0FF)],
          textColor: Colors.black,
          onTap: () => _showMedicalUploadModal(context),
        ),
        const SizedBox(height: 10),
        _buildPrimaryActionButton(
          label: 'COMPLETE WEIGH-IN',
          icon: Icons.scale_rounded,
          gradientColors: const [Color(0xFFFFB300), Color(0xFFFF8F00)],
          textColor: Colors.black,
          onTap: () => _showWeighInModal(context),
        ),
        const SizedBox(height: 10),
        _buildPrimaryActionButton(
          label: 'CHECK IN TO STAGE A',
          icon: Icons.how_to_reg_rounded,
          gradientColors: const [Color(0xFF00E676), Color(0xFF00C853)],
          textColor: Colors.black,
          onTap: () {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Digital Check-In Complete! Assigned to Holding Zone A.'),
                backgroundColor: Color(0xFF00E676),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLiveCompetitionPhaseContent(BuildContext context) {
    return Column(
      children: [
        _buildPrimaryActionButton(
          label: 'VIEW LIVE BRACKET',
          icon: Icons.account_tree_rounded,
          gradientColors: const [Color(0xFF00E5FF), Color(0xFF0099FF)],
          textColor: Colors.black,
          onTap: () => _showBracketModal(context),
        ),
        const SizedBox(height: 10),
        _buildPrimaryActionButton(
          label: 'WATCH LIVE STREAM',
          icon: Icons.live_tv_rounded,
          gradientColors: const [Color(0xFFFF2A6D), Color(0xFFFF0055)],
          textColor: Colors.white,
          onTap: () => _showYouTubeLiveDialog(context),
        ),
        const SizedBox(height: 10),
        _buildInformativeStatusCard(
          icon: Icons.verified_rounded,
          title: 'Weigh-In & Check-In Verified',
          description: 'Official Weight: 78.4 kg • Standing by for Match #42 on Table 2',
          accentColor: const Color(0xFF00E676),
        ),
      ],
    );
  }

  Widget _buildPostTournamentPhaseContent(BuildContext context) {
    return Column(
      children: [
        _buildInformativeStatusCard(
          icon: Icons.emoji_events_rounded,
          title: 'Tournament Completed',
          description: 'Final Standing: 2nd Place (Silver Medalist) -80kg Right Arm',
          accentColor: AppTheme.goldPrimary,
        ),
        const SizedBox(height: 10),
        _buildPrimaryActionButton(
          label: 'DOWNLOAD CERTIFICATE',
          icon: Icons.card_membership_rounded,
          gradientColors: const [Color(0xFFFFB300), Color(0xFFFF8F00)],
          textColor: Colors.black,
          onTap: () => _showCertificateModal(context),
        ),
        const SizedBox(height: 10),
        _buildPrimaryActionButton(
          label: 'VIEW FINAL RESULTS & BRACKET',
          icon: Icons.leaderboard_rounded,
          gradientColors: const [Color(0xFF00E5FF), Color(0xFF0099FF)],
          textColor: Colors.black,
          onTap: () => _showBracketModal(context),
        ),
      ],
    );
  }

  Widget _buildPrimaryActionButton({
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return TactilePressWrapper(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(colors: gradientColors),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformativeStatusCard({
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMedicalUploadModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.upload_file_rounded, size: 40, color: Color(0xFF00E5FF)),
            const SizedBox(height: 12),
            const Text(
              'UPLOAD MEDICAL CERTIFICATE',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload official doctor fit clearance for PAFF competitive armwrestling.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Medical certificate uploaded successfully. Pending doctor sign-off.'),
                    backgroundColor: Color(0xFF00E5FF),
                  ),
                );
              },
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('SELECT DOCUMENT (PDF/JPG)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeighInModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.scale_rounded, size: 40, color: AppTheme.goldPrimary),
            const SizedBox(height: 12),
            const Text(
              'WEIGH-IN STATION SCANNER',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Show your athlete digital QR pass to Station Official #1 at venue.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.black),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CLOSE PASS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBracketModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOURNAMENT BRACKET',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.account_tree_rounded, size: 48, color: Color(0xFF00E5FF)),
                    SizedBox(height: 12),
                    Text(
                      'Double Elimination Bracket - Senior Right -80kg',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '16 Athletes • Winners Quarter-Finals Table #2',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCertificateModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_rounded, size: 44, color: AppTheme.goldPrimary),
            const SizedBox(height: 12),
            const Text(
              'OFFICIAL PAFF CERTIFICATE',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silver Medalist • Senior Right -80kg Class\nVerified Digital Certificate #PAFF-2026-8821',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Official Certificate downloaded to device.'),
                    backgroundColor: AppTheme.goldPrimary,
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('DOWNLOAD PDF CERTIFICATE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showYouTubeLiveDialog(BuildContext context) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.live_tv, color: Color(0xFFFF2A6D)),
              SizedBox(width: 8),
              Text('Live Broadcast', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Official PAFF Live Stream is broadcasting live on YouTube & ArmSphere TV.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2A6D)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Open Stream', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showShareModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.share_rounded, size: 36, color: Color(0xFF00E5FF)),
            const SizedBox(height: 12),
            const Text(
              'SHARE TOURNAMENT',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share ${widget.tournament['name']} with athletes and armwrestling fans.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Tournament link copied to clipboard!'),
                    backgroundColor: Color(0xFF00E5FF),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('COPY OFFICIAL LINK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

