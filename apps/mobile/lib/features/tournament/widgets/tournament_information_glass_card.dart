import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class TournamentInformationGlassCard extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentInformationGlassCard({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<TournamentInformationGlassCard> createState() => _TournamentInformationGlassCardState();
}

class _TournamentInformationGlassCardState extends State<TournamentInformationGlassCard> {
  bool _isExpanded = false; // Collapsed by default

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final organizer = t['organizer'] ?? t['organizerName'] ?? 'Pakistan Armwrestling Federation (PAFF)';
    final hostClub = t['hostClub'] ?? 'Iron Arms Club Lahore';
    final venue = t['venue'] ?? t['location'] ?? 'Nishtar Sports Complex Indoor Arena';
    final address = t['address'] ?? 'Ferozepur Road, Nishtar Colony, Lahore, Punjab 54000';
    final province = t['province'] ?? 'Punjab';
    final dateStr = t['startDate'] != null 
        ? t['startDate'].toString().split('T').first 
        : 'August 15, 2026 • 09:00 AM PST';
    final regDeadline = t['registrationDeadline'] ?? 'August 10, 2026 • 11:59 PM';
    final categories = t['categories'] ?? 'Senior Men (-70kg, -80kg, -90kg, 100kg+), Masters (-85kg), Women Open • Left & Right Arm';
    final maxParticipants = t['capacity'] != null ? '${t['capacity']} Athletes Cap' : '100 Athletes Cap';
    final entryRequirements = t['entryRequirements'] ?? 'Active PAFF Athlete License • Medical Clearance Form • CNIC / Passport ID';
    final rulesPdfName = t['rulesPdfName'] ?? 'PAFF_Official_Rules_2026.pdf';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF0D1527).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.goldPrimary.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppTheme.goldPrimary.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Toggle Row
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.goldPrimary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'TOURNAMENT INFORMATION',
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
                              'Venue, Categories, Rules & Requirements',
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isExpanded
                            ? AppTheme.goldPrimary.withOpacity(0.2)
                            : Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isExpanded
                              ? AppTheme.goldPrimary.withOpacity(0.6)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _isExpanded ? 'COLLAPSE' : 'EXPAND',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: _isExpanded ? AppTheme.goldPrimary : AppTheme.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: _isExpanded ? AppTheme.goldPrimary : AppTheme.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Always visible quick preview summary when collapsed
              if (!_isExpanded) ...[
                const SizedBox(height: 14),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF162032).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF00E5FF)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$venue • $province',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_month_outlined, size: 14, color: AppTheme.goldPrimary),
                      const SizedBox(width: 6),
                      Text(
                        dateStr.contains('•') ? dateStr.split('•').first.trim() : dateStr,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Expanded Detailed View
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 20),

                      // Organizer & Host Club
                      _buildInfoSection(
                        icon: Icons.verified_user_rounded,
                        title: 'ORGANIZER & HOST CLUB',
                        contentWidgets: [
                          _buildDetailRow(Icons.corporate_fare_rounded, 'Official Organizer', organizer),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.groups_rounded, 'Host Club', hostClub),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Venue & Location
                      _buildInfoSection(
                        icon: Icons.place_rounded,
                        title: 'VENUE & LOCATION',
                        contentWidgets: [
                          _buildDetailRow(Icons.stadium_rounded, 'Stadium / Venue', venue),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.map_rounded, 'Full Address', address),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.map_outlined, 'Province / State', province),
                          const SizedBox(height: 14),

                          // Google Maps Button
                          TactilePressWrapper(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.map_rounded, color: Colors.black, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Opening $venue in Google Maps navigation...'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF00E5FF),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                              decoration: BoxDecoration(
                                color: Color(0xFF00E5FF).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Color(0xFF00E5FF).withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.directions_outlined, size: 16, color: Color(0xFF00E5FF)),
                                  SizedBox(width: 8),
                                  Text(
                                    'OPEN IN GOOGLE MAPS',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF00E5FF),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Schedule & Deadlines
                      _buildInfoSection(
                        icon: Icons.event_available_rounded,
                        title: 'SCHEDULE & DEADLINES',
                        contentWidgets: [
                          _buildDetailRow(Icons.calendar_today_rounded, 'Event Date & Time', dateStr),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.timer_off_rounded, 'Registration Deadline', regDeadline),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Categories & Capacity
                      _buildInfoSection(
                        icon: Icons.fitness_center_rounded,
                        title: 'CATEGORIES & CAPACITY',
                        contentWidgets: [
                          _buildDetailRow(Icons.category_rounded, 'Weight & Class Categories', categories),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.people_alt_rounded, 'Maximum Participants', maxParticipants),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Rules PDF & Entry Requirements
                      _buildInfoSection(
                        icon: Icons.gavel_rounded,
                        title: 'RULES & ENTRY REQUIREMENTS',
                        contentWidgets: [
                          _buildDetailRow(Icons.assignment_turned_in_rounded, 'Entry Requirements', entryRequirements),
                          const SizedBox(height: 14),

                          // Download Rules PDF Button
                          TactilePressWrapper(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Downloading $rulesPdfName...'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFFFF2A6D),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                              decoration: BoxDecoration(
                                color: Color(0xFFFF2A6D).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Color(0xFFFF2A6D).withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFFFF2A6D)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'DOWNLOAD RULES PDF ($rulesPdfName)',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFF2A6D),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required List<Widget> contentWidgets,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: AppTheme.goldPrimary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: AppTheme.goldPrimary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Color(0xFF141E2F).withOpacity(0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: contentWidgets,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

