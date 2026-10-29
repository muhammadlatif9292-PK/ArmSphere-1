import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/tactile_press_wrapper.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/social_provider.dart';
import '../../../core/providers/messaging_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'athlete_screens.dart' show ArmSwitchEloCard;

class PublicAthleteProfileScreen extends ConsumerWidget {
  final String athleteId;

  const PublicAthleteProfileScreen({super.key, required this.athleteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(publicAthleteProfileProvider(athleteId));
    final followAsync = ref.watch(followStatusProvider(athleteId));
    final followersAsync = ref.watch(followersProvider(athleteId));
    final followingAsync = ref.watch(followingProvider(athleteId));
    final authState = ref.watch(authProvider);

    // Own profile id (athlete_profiles.id or userId) decides whether to hide Follow.
    final myProfile = ref.watch(athleteProfileProvider).value;
    final myProfileId = myProfile?['id']?.toString();
    final myUserId = myProfile?['userId']?.toString() ??
        authState.userProfile?['id']?.toString();
    final isSelf = (myProfileId != null && myProfileId == athleteId) ||
        (myUserId != null && myUserId == athleteId);
    final canViewTrainingLog = isSelf ||
        authState.hasAnyRole(const [
          'SYSTEM_ADMIN',
          'NATIONAL_DIRECTOR',
          'PROVINCIAL_DIRECTOR',
        ]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlete Dossier'),
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
          final clubName = p['club'] is Map ? p['club']['name']?.toString() : null;
          final bio = p['biography']?.toString();
          final biometrics = p['biometrics'] is Map<String, dynamic>
              ? p['biometrics'] as Map<String, dynamic>
              : const <String, dynamic>{};
          final weightVal = p['weight'] ?? p['weightKg'] ?? biometrics['weightKg'];
          final heightVal = p['height'] ?? p['heightCm'] ?? biometrics['heightCm'];
          final reachVal = p['reach'] ?? p['reachCm'] ?? biometrics['reachCm'];
          final forearmVal = p['forearmCircumference'] ?? biometrics['forearmCircumference'];
          final bicepVal = p['bicepCircumference'] ?? biometrics['bicepCircumference'];
          final handVal = p['handLength'] ?? biometrics['handLength'] ?? biometrics['handWidth'];

          final followersCount = followersAsync.value?.length ??
              (p['followersCount'] as num?)?.toInt() ??
              0;
          final followingCount = followingAsync.value?.length ??
              (p['followingCount'] as num?)?.toInt() ??
              0;

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
                        child: ArmSphereImage.avatar(
                          imageUrl: photo.isNotEmpty ? photo : null,
                          initial: displayName,
                          size: 96,
                          fallbackAsset: ArmSphereAssets.defaultAvatar,
                          semanticLabel: 'Athlete profile photo for $displayName',
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
                      if (weightClass != null && weightClass.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ArmSphereImage(
                              assetPath: _getDivisionBadge(null, weightClass),
                              width: 18,
                              height: 18,
                              semanticLabel: '$weightClass division badge',
                            ),
                            const SizedBox(width: AppTheme.space6),
                            Text(
                              weightClass.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.goldPrimary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                      const SizedBox(height: AppTheme.space16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TactilePressWrapper(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/athlete/$athleteId/followers');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space16,
                                vertical: AppTheme.space8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.cardSurface,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$followersCount',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'FOLLOWERS',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMuted,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          TactilePressWrapper(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/athlete/$athleteId/following');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space16,
                                vertical: AppTheme.space8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.cardSurface,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$followingCount',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'FOLLOWING',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMuted,
                                      letterSpacing: 1.0,
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
                const SizedBox(height: AppTheme.space20),

                // Social & Combat Action buttons
                if (!isSelf) ...[
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
                  const SizedBox(height: AppTheme.space12),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.compare_arrows_rounded,
                        size: 18,
                        color: AppTheme.goldPrimary,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.45),
                        ),
                      ),
                      label: const Text(
                        'TALE OF THE TAPE (COMPARE)',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1.0,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        final query = myProfileId != null && myProfileId.isNotEmpty
                            ? 'athleteId1=$myProfileId&athleteId2=$athleteId'
                            : 'athleteId2=$athleteId';
                        context.push('/matches/head-to-head?$query');
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                ],

                // Dual-Arm ELO Switch Card
                ArmSwitchEloCard(profileData: p),
                const SizedBox(height: AppTheme.space24),

                // Specs — Biometrics & Specifications
                Text(
                  'BIOMETRICS & SPECIFICATIONS',
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
                        label: 'Competition Weight',
                        value: weightVal != null ? '$weightVal kg' : '—',
                        isTabular: true,
                      ),
                      const Divider(height: 20, color: AppTheme.cardBorder),
                      _SpecRow(
                        label: 'Height / Wingspan',
                        value: (heightVal != null || reachVal != null)
                            ? '${heightVal != null ? '$heightVal cm' : '—'} / ${reachVal != null ? '$reachVal cm' : '—'}'
                            : '—',
                        isTabular: true,
                      ),
                      if (forearmVal != null || bicepVal != null || handVal != null) ...[
                        const Divider(height: 20, color: AppTheme.cardBorder),
                        _SpecRow(
                          label: 'Forearm / Bicep / Hand',
                          value: [
                            forearmVal != null ? '$forearmVal cm' : '—',
                            bicepVal != null ? '$bicepVal cm' : '—',
                            handVal != null ? '$handVal cm' : '—',
                          ].join(' • '),
                          isHighlighted: true,
                          isTabular: true,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.space24),
                Text(
                  'ATHLETE DOSSIER & RECORDS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.space10),
                if (canViewTrainingLog) ...[
                  ElevatedActionCard(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/athlete/$athleteId/training-log');
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space16,
                      vertical: AppTheme.space14,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.fitness_center, color: AppTheme.goldPrimary),
                        SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Training Log & Personal Records',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Verified gym lifts, table sessions & peak PRs',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space10),
                ],
                ElevatedActionCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push(
                      '/athlete/achievements?athleteId=$athleteId',
                      extra: athleteId,
                    );
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space14,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.workspace_premium, color: AppTheme.goldPrimary),
                      SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Athletic Honors & Medals',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Official championship medals and career milestones',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    ],
                  ),
                ),

                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space24),
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
                const SizedBox(height: AppTheme.space24),
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

String _getDivisionBadge(num? weight, String? weightClass) {
  final wc = (weightClass ?? '').toLowerCase();
  final w = weight ?? 0;
  if (wc.contains('junior') || wc.contains('youth')) return ArmSphereAssets.badgeJunior;
  if (wc.contains('master') || wc.contains('senior')) return ArmSphereAssets.badgeMasters;
  if (wc.contains('heavy') || w >= 95) return ArmSphereAssets.badgeHeavy;
  if (wc.contains('light') || (w > 0 && w < 75)) return ArmSphereAssets.badgeLight;
  return ArmSphereAssets.badgeMiddle;
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
