import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/biometric_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Configures biometric unlock with zero dead-end device compatibility.
///
/// Differentiates between:
/// - [BiometricCapability.unsupported]: hardware missing or web platform.
/// - [BiometricCapability.notEnrolled]: hardware supported, but user has not enrolled biometrics.
/// - [BiometricCapability.available]: hardware and credentials ready; allows toggle with verification.
class BiometricSettingsTile extends ConsumerWidget {
  const BiometricSettingsTile({super.key});

  void _showNotEnrolledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fingerprint, color: AppTheme.goldPrimary),
            SizedBox(width: 8),
            Text('Biometrics Not Enrolled'),
          ],
        ),
        content: const Text(
          'Your device supports biometric security, but no face or fingerprint '
          'credentials are registered.\n\nTo enable Biometric Unlock in ArmSphere, '
          'first set up Face ID or Fingerprint in your device Settings, then return here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilityAsync = ref.watch(biometricCapabilityProvider);
    final enabledAsync = ref.watch(biometricEnabledProvider);

    return capabilityAsync.when(
      loading: () => const ListTile(
        leading: Icon(Icons.fingerprint),
        title: Text('Biometric Unlock'),
        subtitle: Text('Checking hardware capability...'),
        trailing: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const ListTile(
        leading: Icon(Icons.fingerprint, color: AppTheme.textMuted),
        title: Text('Biometric Unlock'),
        subtitle: Text('Hardware check unavailable'),
      ),
      data: (capability) {
        final isAvailable = capability == BiometricCapability.available;
        final isNotEnrolled = capability == BiometricCapability.notEnrolled;
        final isUnsupported = capability == BiometricCapability.unsupported;

        final isEnabled = enabledAsync.value ?? false;
        final isBusy = enabledAsync.isLoading;

        Widget iconWidget;
        String subtitleText;
        Color? subtitleColor;

        if (isUnsupported) {
          iconWidget = const Icon(Icons.fingerprint, color: AppTheme.textMuted);
          subtitleText = 'Not supported on this device';
          subtitleColor = AppTheme.textMuted;
        } else if (isNotEnrolled) {
          iconWidget = const Icon(Icons.fingerprint, color: Colors.orangeAccent);
          subtitleText = 'Not enrolled — tap to configure';
          subtitleColor = Colors.orangeAccent;
        } else {
          iconWidget = Icon(
            Icons.fingerprint,
            color: isEnabled ? AppTheme.goldPrimary : AppTheme.textMuted,
          );
          subtitleText = isEnabled
              ? 'Active — sign in quickly with Face ID / Fingerprint'
              : 'Disabled — standard password entry required';
          subtitleColor = isEnabled ? AppTheme.textSecondary : AppTheme.textMuted;
        }

        return ListTile(
          leading: iconWidget,
          title: const Text(
            'Biometric Unlock',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitleText,
            style: TextStyle(fontSize: 12, color: subtitleColor),
          ),
          onTap: isNotEnrolled ? () => _showNotEnrolledDialog(context) : null,
          trailing: isUnsupported || isNotEnrolled
              ? Tooltip(
                  message: isNotEnrolled
                      ? 'Enroll biometrics in device settings'
                      : 'Biometric hardware unsupported',
                  child: const Switch(
                    value: false,
                    onChanged: null,
                  ),
                )
              : Switch(
                  value: isEnabled,
                  activeColor: AppTheme.goldPrimary,
                  onChanged: isBusy
                      ? null
                      : (newVal) async {
                          final success = await ref
                              .read(biometricEnabledProvider.notifier)
                              .toggle(newVal);

                          if (!context.mounted) return;

                          if (newVal && !success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Biometric verification was canceled or failed. Biometric unlock remained off.',
                                ),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          } else if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  newVal
                                      ? 'Biometric unlock enabled.'
                                      : 'Biometric unlock disabled.',
                                ),
                              ),
                            );
                          }
                        },
                ),
        );
      },
    );
  }
}
