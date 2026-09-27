import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/social_provider.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/theme/app_theme.dart';

/// Blocked Users Screen
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(blockedUsersProvider),
        child: blockedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(AppTheme.space20),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                'Could not load blocked users',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.invalidate(blockedUsersProvider);
                  },
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (blocked) {
            if (blocked.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.block_outlined,
                    title: 'No blocked users',
                    subtitle: 'People you block will no longer be able to message you or view your private activity.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppTheme.space16),
              itemCount: blocked.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space10),
              itemBuilder: (context, index) {
                final user = blocked[index];
                final name = user['displayName']?.toString() ?? 'User';
                final location = [
                  user['city']?.toString(),
                  user['province']?.toString(),
                ].where((v) => v != null && v.isNotEmpty).join(', ');
                final id = user['id']?.toString() ?? '';

                return RepaintBoundary(
                  child: ElevatedActionCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.error.withValues(alpha: 0.12),
                          child: const Icon(Icons.block, size: 20, color: AppTheme.error),
                        ),
                        const SizedBox(width: AppTheme.space14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space4),
                              Text(
                                location.isEmpty ? 'Blocked User' : location,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: id.isEmpty
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  ref.read(blockedUsersProvider.notifier).unblockUser(id);
                                },
                          child: const Text('Unblock', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// My Tickets Screen
class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(myTicketsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets & Passes')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myTicketsProvider),
        child: ticketsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(AppTheme.space20),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                'Could not load tickets',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.invalidate(myTicketsProvider);
                  },
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (tickets) {
            if (tickets.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.confirmation_number_outlined,
                    title: 'No purchased tickets',
                    subtitle: 'Passes and registration tickets you purchase for tournaments and seminars will appear here.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppTheme.space16),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space12),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final event = ticket['event'] as Map<String, dynamic>?;
                final tier = ticket['ticketType'] as Map<String, dynamic>?;
                final eventName = event?['name']?.toString() ?? 'Official ArmSphere Event';
                final accessSpec = tier?['name']?.toString() ?? 'GENERAL PASS';
                final startDate = event?['startDate']?.toString() ?? '';
                final location = [
                  event?['city']?.toString(),
                  event?['province']?.toString(),
                ].where((v) => v != null && v.isNotEmpty).join(', ');

                return RepaintBoundary(
                  child: ElevatedActionCard(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.space8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldPrimary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    border: Border.all(
                                      color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(Icons.confirmation_number, size: 20, color: AppTheme.goldPrimary),
                                ),
                                const SizedBox(width: AppTheme.space10),
                                const Text(
                                  'OFFICIAL PASS',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            StatusChip(
                              label: accessSpec.toUpperCase(),
                              type: StatusType.info,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space14),
                        Text(
                          eventName,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.space6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: AppTheme.space4),
                              Text(location, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppTheme.space14),
                        const Divider(color: AppTheme.cardBorder, height: 1),
                        const SizedBox(height: AppTheme.space10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'VERIFIED ENTRY',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.success),
                            ),
                            Text(
                              startDate.length >= 10 ? startDate.substring(0, 10) : startDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
