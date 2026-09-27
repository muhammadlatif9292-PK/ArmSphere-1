import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/widgets/biometric_settings_tile.dart';

/// Active login sessions (account security — spec section 33).
class ActiveSessionsListScreen extends ConsumerWidget {
  const ActiveSessionsListScreen({super.key});

  String _deviceLabel(Map<String, dynamic> s) {
    final parts = [
      s['browser']?.toString(),
      s['os']?.toString(),
      s['device']?.toString(),
    ].where((v) => v != null && v.isNotEmpty && v != 'Unknown').toList();
    if (parts.isNotEmpty) return parts.join(' • ');
    final ua = s['userAgent']?.toString() ?? '';
    return ua.isEmpty ? 'Unknown device' : ua;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Sessions & Security'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(sessionProvider),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space16),
          children: [
            Text(
              'DEVICE SECURITY',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppTheme.space8),
            const ElevatedActionCard(
              padding: EdgeInsets.zero,
              child: BiometricSettingsTile(),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              'SIGNED-IN DEVICES',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppTheme.space8),
            sessionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(AppTheme.space12),
                child: ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space20),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: AppTheme.error),
                      const SizedBox(height: AppTheme.space12),
                      Text(
                        'Could not load sessions',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppTheme.space16),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.invalidate(sessionProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: AppEmptyState(
                      icon: Icons.devices_outlined,
                      title: 'No active sessions',
                      subtitle: 'Devices you are signed in with will appear here.',
                    ),
                  );
                }
                return Column(
                  children: [
                    for (int i = 0; i < sessions.length; i++) ...[
                      Builder(
                        builder: (context) {
                          final s = sessions[i];
                          final id = s['id']?.toString() ?? '';
                          final device = _deviceLabel(s);
                          final ip = s['ipAddress']?.toString() ?? '';
                          final created = s['createdAt']?.toString() ?? '';
                          final isCurrent = i == 0; // Top session is current device

                          return RepaintBoundary(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: AppTheme.space10),
                              child: ElevatedActionCard(
                                onTap: id.isEmpty
                                    ? null
                                    : () {
                                        HapticFeedback.lightImpact();
                                        context.push('/athlete/session/$id');
                                      },
                                padding: const EdgeInsets.all(AppTheme.space16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppTheme.space10),
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? AppTheme.success.withValues(alpha: 0.12)
                                            : AppTheme.info.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                        border: Border.all(
                                          color: isCurrent
                                              ? AppTheme.success.withValues(alpha: 0.3)
                                              : AppTheme.info.withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        isCurrent ? Icons.laptop_chromebook : Icons.phone_android,
                                        size: 24,
                                        color: isCurrent ? AppTheme.success : AppTheme.info,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.space14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  device,
                                                  style: const TextStyle(
                                                    fontFamily: AppTheme.fontDisplay,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isCurrent) ...[
                                                const SizedBox(width: AppTheme.space8),
                                                const StatusChip(
                                                  label: 'CURRENT',
                                                  type: StatusType.success,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: AppTheme.space4),
                                          Row(
                                            children: [
                                              if (ip.isNotEmpty) ...[
                                                Text(
                                                  'IP $ip',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.textSecondary,
                                                    fontFeatures: [FontFeature.tabularFigures()],
                                                  ),
                                                ),
                                                if (created.length >= 10)
                                                  const Text(
                                                    ' • ',
                                                    style: TextStyle(color: AppTheme.textMuted),
                                                  ),
                                              ],
                                              if (created.length >= 10)
                                                Text(
                                                  'Since ${created.substring(0, 10)}',
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
                                    const SizedBox(width: AppTheme.space8),
                                    const Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Session control screen — inspect and revoke a single login session
/// (account security — spec section 33).
class ActiveSessionControlScreen extends ConsumerWidget {
  final String sessionId;

  const ActiveSessionControlScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionProvider);

    final session = sessionsAsync.value
        ?.where((s) => s['id']?.toString() == sessionId)
        .cast<Map<String, dynamic>?>()
        .firstWhere((s) => s != null, orElse: () => null);

    final created = session?['createdAt']?.toString() ?? '';
    final expires = session?['expiresAt']?.toString() ?? '';
    final ip = session?['ipAddress']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(sessionProvider),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space16),
          children: [
            ElevatedActionCard(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.info.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(Icons.devices_outlined, size: 48, color: AppTheme.info),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  const Text(
                    'Signed-In Device Session',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space6),
                  const Text(
                    'Cryptographically authenticated session token tied to your device fingerprint.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                  ),
                  const SizedBox(height: AppTheme.space20),
                  const Divider(color: AppTheme.cardBorder, height: 1),
                  const SizedBox(height: AppTheme.space16),
                  _detailRow('Session ID', sessionId, isMonospace: true),
                  if (ip.isNotEmpty) _detailRow('IP Address', ip, isMonospace: true),
                  if (created.length >= 10)
                    _detailRow('Signed In', created.substring(0, 10)),
                  if (expires.length >= 10)
                    _detailRow('Expires', expires.substring(0, 10)),
                  const SizedBox(height: AppTheme.space24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Revoke This Session'),
                    onPressed: sessionsAsync.isLoading
                        ? null
                        : () async {
                            HapticFeedback.mediumImpact();
                            final ok = await ref
                                .read(sessionProvider.notifier)
                                .revokeSession(sessionId);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Session revoked successfully.'
                                    : 'Could not revoke session.'),
                                backgroundColor: ok ? AppTheme.success : AppTheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            if (ok && context.mounted) Navigator.pop(context);
                          },
                  ),
                  const SizedBox(height: AppTheme.space12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.phonelink_erase_outlined),
                    label: const Text('Revoke All Other Sessions'),
                    onPressed: sessionsAsync.isLoading
                        ? null
                        : () async {
                            HapticFeedback.mediumImpact();
                            final ok = await ref
                                .read(sessionProvider.notifier)
                                .revokeOthers();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'All other sessions revoked.'
                                    : 'Could not revoke other sessions.'),
                                backgroundColor: ok ? AppTheme.success : AppTheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(width: AppTheme.space12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isMonospace ? FontWeight.bold : FontWeight.w500,
                color: AppTheme.textPrimary,
                fontFamily: isMonospace ? AppTheme.fontDisplay : AppTheme.fontBody,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
