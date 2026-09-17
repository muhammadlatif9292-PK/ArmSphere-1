import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/glass_card.dart';
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
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'DEVICE SECURITY',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 8),
            const GlassCard(
              padding: EdgeInsets.zero,
              child: BiometricSettingsTile(),
            ),
            const SizedBox(height: 24),
            Text(
              'SIGNED-IN DEVICES',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 8),
            sessionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text('Could not load sessions',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(sessionProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: AppEmptyState(
                      icon: Icons.devices_outlined,
                      title: 'No active sessions',
                      subtitle:
                          'Devices you are signed in with will appear here.',
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final s in sessions) ...[
                      Builder(
                        builder: (context) {
                          final id = s['id']?.toString() ?? '';
                          final device = _deviceLabel(s);
                          final ip = s['ipAddress']?.toString() ?? '';
                          final created = s['createdAt']?.toString() ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: id.isEmpty
                                  ? null
                                  : () => context.push('/athlete/session/$id'),
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(device,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                              if (ip.isNotEmpty) 'IP $ip',
                                              if (created.length >= 10)
                                                'Since ${created.substring(0, 10)}',
                                            ].join(' • '),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        size: 20, color: AppTheme.textMuted),
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
          padding: const EdgeInsets.all(24.0),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.devices_outlined,
                      size: 56, color: AppTheme.info),
                  const SizedBox(height: 16),
                  const Text('Signed-in device',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  _detailRow('Session ID', sessionId),
                  if (ip.isNotEmpty) _detailRow('IP address', ip),
                  if (created.length >= 10)
                    _detailRow('Signed in', created.substring(0, 10)),
                  if (expires.length >= 10)
                    _detailRow('Expires', expires.substring(0, 10)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Revoke This Session'),
                    onPressed: sessionsAsync.isLoading
                        ? null
                        : () async {
                            final ok = await ref
                                .read(sessionProvider.notifier)
                                .revokeSession(sessionId);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Session revoked.'
                                    : 'Could not revoke session.'),
                              ),
                            );
                            if (ok && context.mounted) Navigator.pop(context);
                          },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.phonelink_erase_outlined),
                    label: const Text('Revoke All Other Sessions'),
                    onPressed: sessionsAsync.isLoading
                        ? null
                        : () async {
                            final ok = await ref
                                .read(sessionProvider.notifier)
                                .revokeOthers();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'All other sessions revoked.'
                                    : 'Could not revoke other sessions.'),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
