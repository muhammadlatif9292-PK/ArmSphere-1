import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import '../../../core/providers/state_providers.dart';
class OfficialDocumentsWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic> tournament;

  const OfficialDocumentsWidget({
    super.key,
    required this.tournament,
  });

  @override
  ConsumerState<OfficialDocumentsWidget> createState() => _OfficialDocumentsWidgetState();
}

class _OfficialDocumentsWidgetState extends ConsumerState<OfficialDocumentsWidget> {
  bool _isExpanded = true;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _initDocuments();
  }

  void _initDocuments() {
    final raw = widget.tournament['documents'];
    if (raw is List && raw.isNotEmpty) {
      _documents = raw.map<Map<String, dynamic>>((doc) {
        if (doc is! Map<String, dynamic>) return <String, dynamic>{};
        final title = doc['title'] ?? doc['name'] ?? 'Tournament Document';
        final type = (doc['type'] ?? doc['mimeType'] ?? 'PDF').toString().toUpperCase();
        return {
          'id': doc['id']?.toString() ?? 'doc_${DateTime.now().millisecondsSinceEpoch}',
          'title': title.toString(),
          'type': type.contains('PNG') || type.contains('JPG') || type.contains('JPEG') ? 'IMAGE' : 'PDF',
          'size': doc['size']?.toString() ?? 'Official File',
          'tag': doc['tag']?.toString() ?? 'PAFF OFFICIAL',
          'icon': _resolveDocIcon(title.toString()),
          'accentColor': _resolveDocColor(title.toString()),
          'downloadState': 'idle',
          'url': doc['url']?.toString(),
        };
      }).where((d) => d.isNotEmpty).toList();
    } else {
      _documents = [];
    }
  }

  static IconData _resolveDocIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('rule')) return Icons.menu_book_rounded;
    if (lower.contains('medic') || lower.contains('health')) return Icons.health_and_safety_rounded;
    if (lower.contains('map') || lower.contains('venue')) return Icons.map_rounded;
    if (lower.contains('cert')) return Icons.card_membership_rounded;
    return Icons.picture_as_pdf_rounded;
  }

  static Color _resolveDocColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('rule')) return AppTheme.goldPrimary;
    if (lower.contains('medic')) return const Color(0xFF00E676);
    if (lower.contains('map')) return const Color(0xFF00E5FF);
    if (lower.contains('cert')) return const Color(0xFFA855F7);
    return const Color(0xFFFF2A6D);
  }

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
        color: const Color(0xFF0D1527).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withValues(alpha: 0.12),
            blurRadius: 18,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
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
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.folder_special_rounded,
                            color: AppTheme.goldPrimary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                child: _documents.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        alignment: Alignment.center,
                        child: const Column(
                          children: [
                            Icon(Icons.folder_open_rounded, color: AppTheme.textMuted, size: 28),
                            SizedBox(height: 8),
                            Text(
                              'No official documents published for this event yet.',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141E2F).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          children: [
            // File Icon with Accent Glow
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.4),
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
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
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
                        style: const TextStyle(
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
                          color: accentColor.withValues(alpha: 0.8),
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
        padding: const EdgeInsets.all(8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00E676).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00E676)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
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

