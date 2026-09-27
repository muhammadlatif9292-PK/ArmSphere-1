import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/informal_event_provider.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';

/// Domain 9 / Stage 6 Convergence: Informal Event Detail Screen
///
/// Implements Grassroots Meetup & Sparring Session Inspection:
/// - Pulls session details and participant list from GET /informal-events/:id.
/// - Unbundled meetup dossier: Session Header, Schedule/Location specs, and Attending Pullers Roster.
/// - Eradication of nested `GlassCard` inside `ListView` in compliance with Audit Rule Item 2.2.
class InformalEventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const InformalEventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<InformalEventDetailScreen> createState() =>
      _InformalEventDetailScreenState();
}

class _InformalEventDetailScreenState
    extends ConsumerState<InformalEventDetailScreen> {
  bool _actionInProgress = false;

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }

  Future<void> _runAction(Future<void> Function() action,
      {bool popOnSuccess = false, String? successMessage}) async {
    if (_actionInProgress) return;
    setState(() => _actionInProgress = true);
    try {
      await action();
      if (mounted) {
        HapticFeedback.mediumImpact();
        if (successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage), backgroundColor: AppTheme.success),
          );
        }
        if (popOnSuccess) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(informalEventDetailProvider(widget.eventId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Practice Session Dossier',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.goldPrimary,
        backgroundColor: AppTheme.cardSurface,
        onRefresh: () async =>
            ref.invalidate(informalEventDetailProvider(widget.eventId)),
        child: detailAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(AppTheme.space16),
            children: const [
              SkeletonPlaceholder(height: 140, borderRadius: AppTheme.radiusMedium),
              SizedBox(height: AppTheme.space16),
              SkeletonPlaceholder(height: 80, borderRadius: AppTheme.radiusMedium),
              SizedBox(height: AppTheme.space16),
              SkeletonPlaceholder(height: 160, borderRadius: AppTheme.radiusMedium),
            ],
          ),
          error: (e, _) => AppEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load practice session',
            subtitle: e.toString(),
            ctaLabel: 'Retry',
            onCtaTap: () => ref
                .invalidate(informalEventDetailProvider(widget.eventId)),
          ),
          data: (event) {
            final title = event['title']?.toString() ?? 'Meetup';
            final description = event['description']?.toString() ?? '';
            final city = event['city']?.toString() ?? '';
            final province = event['province']?.toString() ?? '';
            final locationLine = [city, province].where((s) => s.isNotEmpty).join(', ');
            final scheduledAt =
                _formatDate(event['scheduledAt']?.toString() ?? '');
            final maxParticipants = event['maxParticipants'] as num?;
            final createdByUserId = event['createdByUserId']?.toString() ?? '';
            final participants = (event['participants'] as List? ?? [])
                .map((p) => Map<String, dynamic>.from(p))
                .toList();
            final participantCount =
                (event['participantCount'] as num?)?.toInt() ??
                    participants.length;

            final currentProfile = ref.watch(athleteProfileProvider).valueOrNull;
            final currentUserId = currentProfile?['id']?.toString();
            final isCreator =
                currentUserId != null && currentUserId == createdByUserId;
            final isParticipant = currentUserId != null &&
                participants.any((p) => p['id']?.toString() == currentUserId);
            final isFull = maxParticipants != null &&
                participantCount >= maxParticipants.toInt();

            return ListView(
              padding: const EdgeInsets.all(AppTheme.space16),
              children: [
                // 1. Session Overview Card
                ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.elevatedSurface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.goldPrimary),
                            ),
                            child: const Icon(
                              Icons.sports_martial_arts,
                              color: AppTheme.goldPrimary,
                              size: 22,
                            ),
                          ),
                          StatusChip(
                            label: isFull
                                ? 'TABLE CAPACITY REACHED'
                                : '$participantCount PULLERS REGISTERED',
                            type: isFull ? StatusType.error : StatusType.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space16),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (scheduledAt.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space8),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 14, color: AppTheme.goldPrimary),
                            const SizedBox(width: 6),
                            Text(
                              scheduledAt,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (locationLine.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space6),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              locationLine,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space12),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                // 2. Attending Pullers Roster
                Row(
                  children: [
                    const Icon(Icons.groups_outlined, size: 16, color: AppTheme.goldPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'ATTENDING PULLERS (${participants.length})',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppTheme.goldLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),

                if (participants.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Center(
                      child: Text(
                        'No pullers registered yet. Be the first to join the table.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...participants.map((p) {
                    final athleteName = p['fullName']?.toString() ??
                        p['displayName']?.toString() ??
                        p['username']?.toString() ??
                        'Athlete';
                    final photo = p['profilePhoto']?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.space8),
                      child: RepaintBoundary(
                        child: ElevatedActionCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.elevatedSurface,
                                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                                child: photo.isEmpty
                                    ? Text(
                                        athleteName.isNotEmpty ? athleteName[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppTheme.textPrimary,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: AppTheme.space12),
                              Expanded(
                                child: Text(
                                  athleteName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.verified_outlined,
                                size: 16,
                                color: AppTheme.goldPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: AppTheme.space24),

                // 3. Operational Action Bar
                if (_actionInProgress)
                  const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
                else if (isCreator)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: AppTheme.textPrimary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    onPressed: () => _runAction(
                      () async {
                        await ref
                            .read(informalEventDetailProvider(widget.eventId).notifier)
                            .cancel();
                      },
                      popOnSuccess: true,
                      successMessage: 'Meetup cancelled',
                    ),
                    child: const Text(
                      'CANCEL PRACTICE SESSION',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                else if (isParticipant)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    onPressed: () => _runAction(
                      () async {
                        await ref
                            .read(informalEventDetailProvider(widget.eventId).notifier)
                            .leave();
                      },
                      successMessage: 'Left practice session',
                    ),
                    child: const Text(
                      'LEAVE PRACTICE ROSTER',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                else if (!isFull)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: AppTheme.voidBackground,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    onPressed: () => _runAction(
                      () async {
                        await ref
                            .read(informalEventDetailProvider(widget.eventId).notifier)
                            .join();
                      },
                      successMessage: 'Added to sparring roster!',
                    ),
                    child: const Text(
                      'CLAIM TABLE SPOT (RSVP)',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Center(
                      child: Text(
                        'This practice session has reached maximum capacity.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
