import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
class OfficialDocumentsWidget extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const OfficialDocumentsWidget({
    Key? key,
    required this.tournament,
  }) : super(key: key);

  @override
  State<OfficialDocumentsWidget> createState() => _OfficialDocumentsWidgetState();
}

class _OfficialDocumentsWidgetState extends State<OfficialDocumentsWidget> {
  bool _isExpanded = true;

  final List<Map<String, dynamic>> _documents = [
    {
      'id': 'doc_1',
      'title': 'Tournament Rulebook',
      'type': 'PDF',
      'size': '2.4 MB',
      'tag': 'PAFF 2026 OFFICIAL',
      'icon': Icons.menu_book_rounded,
      'accentColor': AppTheme.goldPrimary,
      'downloadState': 'idle', // 'idle', 'downloading', 'completed'
    },
    {
      'id': 'doc_2',
      'title': 'Medical Guidelines',
      'type': 'PDF',
      'size': '1.1 MB',
      'tag': 'SAFETY & WEIGH-IN',
      'icon': Icons.health_and_safety_rounded,
      'accentColor': const Color(0xFF00E676),
      'downloadState': 'idle',
    },
    {
      'id': 'doc_3',
      'title': 'Venue Map',
      'type': 'PNG',
      'size': '3.8 MB',
      'tag': 'ARENA & STAGE LAYOUT',
      'icon': Icons.map_rounded,
      'accentColor': const Color(0xFF00E5FF),
      'downloadState': 'idle',
    },
    {
      'id': 'doc_4',
      'title': 'Schedule PDF',
      'type': 'PDF',
      'size': '850 KB',
      'tag': 'TIMELINE & BOUTS',
      'icon': Icons.picture_as_pdf_rounded,
      'accentColor': const Color(0xFFFF2A6D),
      'downloadState': 'idle',
    },
    {
      'id': 'doc_5',
      'title': 'Certificate Template',
      'type': 'PDF',
      'size': '4.2 MB',
      'tag': 'AWARDS & DIPLOMA',
      'icon': Icons.card_membership_rounded,
      'accentColor': const Color(0xFFA855F7),
      'downloadState': 'idle',
    },
  ];

  void _triggerDownload(int index) {
    if (_documents[index]['downloadState'] == 'downloading') return;

    HapticFeedback.mediumImpact();

    setState(() {
      _documents[index]['downloadState'] = 'downloading';
    });

    _performDownload(index);
  }

  Future<void> _performDownload(int index) async {
    try {
      final tournamentId = widget.tournament['id']?.toString() ?? '';
      final documentId = _documents[index]['id']?.toString() ?? '';
      final tournamentRepository = ref.read(tournamentRepositoryProvider);
      await tournamentRepository.downloadDocument(tournamentId, documentId);
      
      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() {
          _documents[index]['downloadState'] = 'completed';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${_documents[index]['title']} downloaded successfully'),
            backgroundColor: _documents[index]['accentColor'] as Color,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() {
          _documents[index]['downloadState'] = 'idle';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download ${_documents[index]['title']}: \${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            // Expandable Header
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(18.0),
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
                            Icons.folder_special_rounded,
                            color: AppTheme.goldPrimary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'OFFICIAL DOCUMENTS',
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
                              'Rulebook, Medical, Maps & Official Guides',
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

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            '${_documents.length} FILES',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Animated Expandable Content
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(left: 18.0, right: 18.0, bottom: 18.0),
                child: Column(
                  children: List.generate(_documents.length, (index) {
                    final doc = _documents[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildGlassDocumentRow(doc, index),
                    );
                  }),
                ),
              ),
              crossFadeState:
                  _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassDocumentRow(Map<String, dynamic> doc, int index) {
    final Color accentColor = doc['accentColor'] as Color;
    final String state = doc['downloadState'] as String;

    return TactilePressWrapper(
      onTap: () => _triggerDownload(index),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFF141E2F).withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accentColor.withOpacity(0.35),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          children: [
            // File Icon with Accent Glow
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withOpacity(0.4),
                ),
              ),
              child: Icon(
                doc['icon'] as IconData,
                color: accentColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Document Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          doc['title'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          doc['type'],
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        doc['size'],
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '•',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white24,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        doc['tag'],
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: accentColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Download Action Button with Animation
            _buildDownloadButton(state, accentColor, () => _triggerDownload(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(String state, Color accentColor, VoidCallback onTap) {
    if (state == 'downloading') {
      return Container(
        padding: EdgeInsets.all(8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.18),
          shape: BoxShape.circle,
          border: Border.all(color: accentColor.withOpacity(0.4)),
        ),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
      );
    } else if (state == 'completed') {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFF00E676).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00E676)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: Color(0xFF00E676),
            ),
            SizedBox(width: 4),
            Text(
              'OPEN',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Color(0xFF00E676),
              ),
            ),
          ],
        ),
      );
    } else {
      // Idle download button
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_download_rounded,
              size: 14,
              color: accentColor,
            ),
            const SizedBox(width: 4),
            Text(
              'GET',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
          ],
        ),
      );
    }
  }
}

