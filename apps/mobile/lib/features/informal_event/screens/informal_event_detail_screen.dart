import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/informal_event_provider.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/widgets/glass_card.dart';

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
      {bool popOnSuccess = false}) async {
    if (_actionInProgress) return;
    setState(() => _actionInProgress = true);
    try {
      await action();
      if (popOnSuccess && mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
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
      appBar: AppBar(title: const Text('Practice Sparring Details')),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(informalEventDetailProvider(widget.eventId)),
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Could not load meetup', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => ref
                      .invalidate(informalEventDetailProvider(widget.eventId)),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (event) {
            final title = event['title']?.toString() ?? 'Meetup';
            final description = event['description']?.toString() ?? '';
            final city = event['city']?.toString() ?? '';
            final province = event['province']?.toString() ?? '';
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
              padding: const EdgeInsets.all(20),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [city, province].where((s) => s.isNotEmpty).join(', '),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (scheduledAt.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(scheduledAt,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text('$participantCount joined',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (description.isNotEmpty) ...[
                        const Divider(height: 32),
                        const Text('Details:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(description,
                            style: const TextStyle(
                                height: 1.5, fontSize: 13, color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
                if (participants.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('Participants (${participants.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        ...participants.map((p) => ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundImage:
                                    p['profilePhoto']?.toString().isNotEmpty == true
                                        ? NetworkImage(p['profilePhoto'].toString())
                                        : null,
                                child: p['profilePhoto']?.toString().isNotEmpty == true
                                    ? null
                                    : const Icon(Icons.person, size: 14),
                              ),
                              title: Text(
                                p['fullName']?.toString() ??
                                    p['username']?.toString() ??
                                    'Athlete',
                                style: const TextStyle(fontSize: 13),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (_actionInProgress)
                  const Center(child: CircularProgressIndicator())
                else if (isCreator)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _runAction(
                      () async {
                        await ref
                            .read(informalEventDetailProvider(widget.eventId)
                                .notifier)
                            .cancel();
                      },
                      popOnSuccess: true,
                    ),
                    child: const Text('Cancel Meetup'),
                  )
                else if (isParticipant)
                  ElevatedButton(
                    onPressed: () => _runAction(
                      () async {
                        await ref
                            .read(informalEventDetailProvider(widget.eventId)
                                .notifier)
                            .leave();
                      },
                    ),
                    child: const Text('Leave Meetup'),
                  )
                else if (!isFull)
                  ElevatedButton(
                    onPressed: () => _runAction(
                      () async {
                        await ref
                            .read(informalEventDetailProvider(widget.eventId)
                                .notifier)
                            .join();
                      },
                    ),
                    child: const Text('Join Practice Meetup'),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('This meetup is full.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5))),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
