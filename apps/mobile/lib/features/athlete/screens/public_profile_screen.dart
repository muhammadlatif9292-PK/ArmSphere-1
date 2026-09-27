import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/social_provider.dart';
import '../../../core/providers/messaging_provider.dart';

class PublicAthleteProfileScreen extends ConsumerWidget {
  final String athleteId;

  const PublicAthleteProfileScreen({super.key, required this.athleteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(publicAthleteProfileProvider(athleteId));
    final followAsync = ref.watch(followStatusProvider(athleteId));

    // Own profile id (athlete_profiles.id) decides whether to hide Follow.
    final myProfileId =
        ref.watch(athleteProfileProvider).value?['id']?.toString();
    final isSelf = myProfileId != null && myProfileId == athleteId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlete Profile'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: ElevatedActionCard(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined, size: 44, color: AppTheme.error),
                  const SizedBox(height: AppTheme.space12),
                  Text('Profile unavailable', style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppTheme.space6),
                  Text(
                    '$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.invalidate(publicAthleteProfileProvider(athleteId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (p) {
          final displayName = (p['displayName']?.toString().isNotEmpty ?? false)
              ? p['displayName'].toString()
              : 'Athlete';
          final photo = p['profilePhoto']?.toString() ?? '';
          final location = [
            p['city']?.toString(),
            p['province']?.toString(),
          ].where((v) => v != null && v.isNotEmpty).join(', ');
          final weightClass = p['weightClass']?.toString();
          final dominantArm = p['dominantArm']?.toString();
          final rightElo = (p['rightArmElo'] as num?)?.toInt();
          final leftElo = (p['leftArmElo'] as num?)?.toInt();
          final clubName = p['club'] is Map ? p['club']['name']?.toString() : null;
          final bio = p['biography']?.toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with 2px Role-Coded Avatar Ring
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.goldPrimary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldPrimary.withValues(alpha: 0.2),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: AppTheme.cardSurface,
                          backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                          onBackgroundImageError: photo.isNotEmpty
                              ? (exception, stackTrace) {}
                              : null,
                          child: photo.isEmpty
                              ? Text(
                                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.goldPrimary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: AppTheme.space4),
                            Text(
                              location,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                      if (clubName != null && clubName.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space6),
                        StatusChip(
                          label: clubName.toUpperCase(),
                          type: StatusType.info,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space20),

                // Social Action buttons
                if (!isSelf)
                  Row(
                    children: [
                      Expanded(
                        child: followAsync.when(
                          loading: () => const SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: null,
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          error: (_, __) => SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                ref.invalidate(followStatusProvider(athleteId));
                              },
                              child: const Text('Follow'),
                            ),
                          ),
                          data: (isFollowing) => SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                try {
                                  final notifier = ref.read(
                                      followStatusProvider(athleteId).notifier);
                                  if (isFollowing) {
                                    await notifier.unfollow();
                                  } else {
                                    await notifier.follow();
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Could not update follow status'),
                                        backgroundColor: AppTheme.error,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.chat_outlined, size: 18),
                            label: const Text('Message'),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _startConversation(context, ref, p);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                if (!isSelf) const SizedBox(height: AppTheme.space24),

                // Specs — Athletic Overview
                Text(
                  'ATHLETIC OVERVIEW',
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.space10),
                ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Column(
                    children: [
                      _SpecRow(
                        label: 'Weight Category',
                        value: (weightClass == null || weightClass.isEmpty) ? '—' : weightClass,
                      ),
                      const Divider(height: 20, color: AppTheme.cardBorder),
                      _SpecRow(
                        label: 'Dominant Arm',
                        value: (dominantArm == null || dominantArm.isEmpty)
                            ? '—'
                            : (dominantArm == 'LEFT' ? 'Left Arm' : 'Right Arm'),
                      ),
                      const Divider(height: 20, color: AppTheme.cardBorder),
                      _SpecRow(
                        label: 'Right Arm ELO',
                        value: rightElo != null ? '$rightElo ELO' : '—',
                        isHighlighted: true,
                        isTabular: true,
                      ),
                      const Divider(height: 20, color: AppTheme.cardBorder),
                      _SpecRow(
                        label: 'Left Arm ELO',
                        value: leftElo != null ? '$leftElo ELO' : '—',
                        isHighlighted: true,
                        isTabular: true,
                      ),
                    ],
                  ),
                ),
                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space20),
                  Text(
                    'ABOUT',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space10),
                  ElevatedActionCard(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Text(
                      bio,
                      style: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Opens (or creates) a DIRECT conversation with this athlete and
  /// navigates to the chat thread.
  Future<void> _startConversation(
      BuildContext context, WidgetRef ref, Map<String, dynamic> profile) async {
    final targetUserId = profile['userId']?.toString();
    if (targetUserId == null || targetUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This athlete cannot be messaged yet'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final conversation = await ref
          .read(conversationsProvider.notifier)
          .getOrCreateConversation(targetUserId);
      if (!context.mounted) return;
      if (conversation == null || conversation['id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start conversation'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      context.push('/messages/${conversation['id']}');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start conversation'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;
  final bool isTabular;

  const _SpecRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.isTabular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHighlighted ? AppTheme.goldPrimary : AppTheme.textPrimary,
            fontSize: 14,
            fontFamily: isTabular ? AppTheme.fontDisplay : AppTheme.fontBody,
            fontFeatures: isTabular ? const [FontFeature.tabularFigures()] : null,
          ),
        ),
      ],
    );
  }
}
