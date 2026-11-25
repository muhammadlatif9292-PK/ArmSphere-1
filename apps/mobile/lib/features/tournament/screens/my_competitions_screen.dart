import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';

/// Athlete "My Competitions" Hub (`/athlete/competitions`).
///
/// Displays all tournaments the athlete is registered for, live status
/// progression (`REGISTERED` -> `WEIGH-IN` -> `IN BRACKET` -> `PODIUM`),
/// and links to their permanent Profile QR Code in Settings for venue
/// entrance, weigh-in, and referee table check-in.
class MyCompetitionsScreen extends ConsumerWidget {
  const MyCompetitionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regsAsync = ref.watch(myRegistrationsProvider);
    final tournamentsAsync = ref.watch(tournamentProvider);

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const CrystalBackButton(),
        title: const Text(
          'My Competitions',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: const [
          CrystalHomeButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.passport),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
              children: [
                ElevatedActionCard(
                  borderColor: AppTheme.goldPrimary.withValues(alpha: 0.45),
                  onTap: () => context.push('/settings'),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.qr_code_2_rounded,
                        color: AppTheme.goldPrimary,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PERMANENT PROFILE QR VERIFICATION',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Present your Profile QR Code at weigh-in, venue entrance, and your assigned table.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.goldPrimary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                regsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppTheme.goldPrimary),
                    ),
                  ),
                  error: (e, _) => Text(
                    'Could not load registrations: $e',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  data: (regs) {
                    final allEvents =
                        tournamentsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

                    final items = regs;

                    if (items.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration:
                            AppTheme.recessedObsidianWellDecoration(radius: 16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.emoji_events_outlined,
                              size: 36,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'No Active Tournament Registrations',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Browse upcoming sanctioned tournaments to register your division. Present your Profile QR Code at weigh-in, venue entrance, and your assigned table.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.goldPrimary,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () => context.push('/tournaments'),
                              icon: const Icon(Icons.explore_outlined, size: 16),
                              label: const Text(
                                'EXPLORE UPCOMING TOURNAMENTS',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: items.map((reg) {
                        final regId = (reg['id'] ?? reg['registrationId'] ?? 'reg_1').toString();
                        final eventId =
                            (reg['eventId'] ?? 'tourney_1').toString();
                        final eventMatch = allEvents.firstWhere(
                          (e) => e['id']?.toString() == eventId,
                          orElse: () => <String, dynamic>{},
                        );
                        final eventName = (reg['eventName'] ??
                                eventMatch['name'] ??
                                'Sanctioned Tournament #$eventId')
                            .toString();
                        final div = (reg['division'] ?? 'SENIOR').toString();
                        final wt = (reg['weightClass'] ?? '-85kg').toString();
                        final arm = (reg['arm'] ?? 'RIGHT').toString();
                        final status = (reg['status'] ?? 'CONFIRMED')
                            .toString()
                            .toUpperCase();
                        final canWithdraw = !status.contains('WEIGHED') &&
                            !status.contains('PASSED') &&
                            !status.contains('COMPLETED');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ElevatedActionCard(
                            borderColor:
                                AppTheme.goldPrimary.withValues(alpha: 0.4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    StatusChip(
                                      label: status.replaceAll('_', ' '),
                                      color: status.contains('PASSED') ||
                                              status.contains('WEIGHED') ||
                                              status.contains('CONFIRMED')
                                          ? AppTheme.emerald
                                          : AppTheme.goldPrimary,
                                      icon: Icons.verified_user_rounded,
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$div • $wt • $arm',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontMono,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.cyan,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  eventName,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Present your Profile QR Code at weigh-in, venue entrance, and your assigned table.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration:
                                      AppTheme.recessedObsidianWellDecoration(
                                          radius: 10),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '1. REGISTERED',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.emerald,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                      Text(
                                        '2. PROFILE QR',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.goldPrimary,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                      Text(
                                        '3. IN BRACKET',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                      Text(
                                        '4. PODIUM',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            context.push('/tournament/$eventId'),
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('EVENT DOSSIER'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.goldPrimary,
                                          foregroundColor: Colors.black,
                                        ),
                                        onPressed: () {
                                          HapticFeedback.mediumImpact();
                                          context.push('/settings');
                                        },
                                        icon: const Icon(
                                          Icons.qr_code_2_rounded,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'PROFILE QR',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (canWithdraw) ...[
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        HapticFeedback.selectionClick();
                                        final ok = await ref
                                            .read(tournamentProvider.notifier)
                                            .withdrawRegistration(
                                              eventId: eventId,
                                              registrationId: regId,
                                            );
                                        if (context.mounted && ok) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            CrystalSnackBar(
                                              content: Text(
                                                'Entry withdrawn for $eventName ($div · $wt · $arm).',
                                              ),
                                              backgroundColor: AppTheme.warning,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        size: 14,
                                        color: AppTheme.crimson,
                                      ),
                                      label: const Text(
                                        'WITHDRAW ENTRY',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10.5,
                                          color: AppTheme.crimson,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
