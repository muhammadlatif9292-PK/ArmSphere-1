import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_slash_painter.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tournament/services/tournament_offline_store.dart';
import '../../../core/widgets/profile_qr_matrix_view.dart';
import '../widgets/biometric_settings_tile.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/widgets/crystal_toast.dart';

/// Account & Settings hub (spec §36). Every section maps to a real surface.
class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool insideRootShell = MainShellScope.isInsideShell(context);
    final double bottomDockGap = insideRootShell
        ? (kFloatingDockTotalHeight - 34.0)
        : 0.0;
    final auth = ref.watch(authProvider);
    final profile = auth.userProfile;
    final settingsQrPayload = TournamentOfflineStore.buildSettingsIdentityQr(profile);
    final userId = (profile?['id'] ?? profile?['userId'] ?? profile?['athleteId'] ?? profile?['sub'] ?? 'ath-local').toString();
    final userName = (profile?['displayName'] ??
            profile?['fullName'] ??
            profile?['name'] ??
            profile?['username'] ??
            (profile?['email'] != null
                ? profile!['email'].toString().split('@').first
                : null) ??
            'Verified Athlete')
        .toString();

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const CrystalHeaderStageBar(
          domain: ArmSphereStageDomain.passport,
        ),
        leading: const CrystalBackButton(),
        title: const Text('Settings'),
        actions: const [CrystalHomeButton()],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.passport),
          ),
          SafeArea(
            bottom: false,
            child: CrystalVaporDissolve(
              bottomMargin: bottomDockGap,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.space16,
                  AppTheme.space16,
                  AppTheme.space16,
                  insideRootShell
                      ? 66.0
                      : kFloatingDockTotalHeight +
                          MediaQuery.paddingOf(context).bottom +
                          36,
                ),
                children: [
                  _sectionHeader(context, 'ATHLETE & OFFICIAL QR IDENTITY'),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showEnlargedQrDialog(context, settingsQrPayload, userName, userId);
                    },
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      Clipboard.setData(ClipboardData(text: userId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        CrystalSnackBar(
                          content: const Text('Athlete ID copied to clipboard'),
                          backgroundColor: AppTheme.emerald,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: ElevatedActionCard(
                      key: const ValueKey('settings_athlete_identity_qr_card'),
                      borderColor: AppTheme.goldPrimary.withValues(alpha: 0.5),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ArmSphereQrMatrixView(
                            data: settingsQrPayload,
                            size: 78,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'OFFICIAL ATHLETE QR IDENTITY',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11.5,
                                        color: AppTheme.goldPrimary,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  StatusChip(
                                    label: 'OFFLINE READY',
                                    color: AppTheme.emerald,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$userName • ID: $userId',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap to enlarge QR • Hold to copy ID',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space20),

                  _sectionHeader(context, 'ACCOUNT'),
                  ElevatedActionCard(
                    padding: EdgeInsets.zero,
                    enableSlashes: false,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Column(
                        children: [
                          _SettingsTile(
                            rowIndex: 0,
                            icon: Icons.badge_outlined,
                            title: 'Account Roles',
                            onTap: () => context.push('/settings/roles'),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0x22FFFFFF),
                          ),
                          const BiometricSettingsTile(rowIndex: 1),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0x22FFFFFF),
                          ),
                          _SettingsTile(
                            rowIndex: 2,
                            icon: Icons.shield_outlined,
                            title: 'Security & Active Sessions',
                            onTap: () => context.push('/session'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space20),

                  _sectionHeader(context, 'RADAR & LOCATION PRIVACY'),
                  _RadarLocationPrivacyCard(
                    fallbackVisibility:
                        profile?['locationVisibility']?.toString(),
                  ),
                  const SizedBox(height: AppTheme.space20),

                  _sectionHeader(context, 'PREFERENCES'),
                  ElevatedActionCard(
                    padding: EdgeInsets.zero,
                    enableSlashes: false,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Column(
                        children: [
                          _SettingsTile(
                            rowIndex: 3,
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            onTap: () => context.push('/notifications'),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0x22FFFFFF),
                          ),
                          _SettingsTile(
                            rowIndex: 4,
                            icon: Icons.payment,
                            title: 'Payment Methods',
                            onTap: () =>
                                context.push('/settings/payment-methods'),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0x22FFFFFF),
                          ),
                          _SettingsTile(
                            rowIndex: 5,
                            icon: Icons.confirmation_number_outlined,
                            title: 'My Tickets & Passes',
                            onTap: () => context.push('/settings/tickets'),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0x22FFFFFF),
                          ),
                          _SettingsTile(
                            rowIndex: 6,
                            icon: Icons.block_flipped,
                            title: 'Blocked Users',
                            onTap: () => context.push('/settings/blocked'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space20),

                  _sectionHeader(context, 'SUPPORT & LEGAL'),
                  ElevatedActionCard(
                    padding: EdgeInsets.zero,
                    enableSlashes: false,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Column(
                        children: [
                          _SettingsTile(
                            rowIndex: 7,
                            icon: Icons.contact_support_outlined,
                            title: 'Support Requests',
                            onTap: () => context.push('/support'),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0x22FFFFFF),
                          ),
                          _SettingsTile(
                            rowIndex: 8,
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            onTap: () => context.push('/settings/terms'),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0x22FFFFFF),
                          ),
                          _SettingsTile(
                            rowIndex: 9,
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            onTap: () => context.push('/settings/privacy'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space20),

                  _sectionHeader(context, 'DANGER ZONE'),
                  ElevatedActionCard(
                    padding: EdgeInsets.zero,
                    enableSlashes: false,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Column(
                        children: [
                          _SettingsTile(
                            rowIndex: 10,
                            icon: Icons.delete_forever,
                            iconColor: AppTheme.error,
                            title: 'Delete Account',
                            titleColor: AppTheme.error,
                            onTap: () => context.push('/settings/deletion'),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0x22FFFFFF),
                          ),
                          _SettingsTile(
                            rowIndex: 11,
                            icon: Icons.logout,
                            iconColor: AppTheme.error,
                            title: 'Log Out',
                            titleColor: AppTheme.error,
                            onTap: () async {
                              HapticFeedback.mediumImpact();
                              await ref.read(authProvider.notifier).logout();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return CrystalModalSheet(
          title: 'ARMSPHERE HELPDESK',
          subtitle: 'Official Support & Federation Operations Assistance',
          headerIcon: Icons.support_agent_rounded,
          primaryActionLabel: 'Close',
          onPrimaryAction: () => Navigator.of(ctx).pop(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Need assistance with your account, rules, disputes, or tournament operations? Our dedicated support team is available.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: AppTheme.space16),
              Container(
                padding: const EdgeInsets.all(AppTheme.space14),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x38FFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DIRECT EMAIL SUPPORT',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 18, color: AppTheme.primaryOrange),
                        const SizedBox(width: 8),
                        const SelectableText(
                          'support@armsphere.pk',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space6),
                    const Text(
                      'All verified inquiries are routed into the official ArmSphere Helpdesk queue.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8, left: AppTheme.space4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
      ),
    );
  }

  void _showEnlargedQrDialog(
    BuildContext context,
    String qrPayload,
    String userName,
    String userId,
  ) {
    showDialog(
      context: context,
      barrierColor: const Color(0xCC030509),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F131D),
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x4DFFFFFF), width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded, color: AppTheme.goldPrimary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'OFFICIAL ATHLETE QR',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: AppTheme.goldPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ArmSphereQrMatrixView(
                  data: qrPayload,
                  size: 230,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Athlete ID: $userId',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.fontMono,
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0x33D4AF37),
                  foregroundColor: AppTheme.goldPrimary,
                  side: const BorderSide(color: Color(0x66D4AF37), width: 1.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(ClipboardData(text: userId));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    CrystalSnackBar(
                      content: Text('Athlete ID copied to clipboard: $userId'),
                      backgroundColor: AppTheme.emerald,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text(
                  'Copy ID to Clipboard',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final int rowIndex;
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    this.rowIndex = 0,
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CrystalSlashWrapper.sequentialRow(
      rowIndex: rowIndex,
      borderRadius: BorderRadius.zero,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: iconColor ?? AppTheme.textPrimary, size: 22),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: titleColor ?? AppTheme.textPrimary,
              fontSize: 14,
              shadows: AppTheme.crystalTextShadows,
            ),
          ),
          subtitle: subtitle != null
              ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))
              : null,
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
        ),
      ),
    );
  }
}

/// In-app account deletion (Apple requirement for account-based apps).
class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  bool _acknowledged = false;
  bool _deleting = false;

  Future<void> _confirmAndDeleteAccount() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xEB0B0F19),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: const BorderSide(color: Color(0x38FFFFFF)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 24),
            SizedBox(width: AppTheme.space8),
            Expanded(
              child: Text(
                'Confirm Account Deletion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontDisplay,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you absolutely sure you want to permanently delete your ArmSphere account? '
          'All athlete passport data, rankings, and active sessions will be permanently purged. '
          'This action cannot be undone.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Account'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    HapticFeedback.heavyImpact();
    setState(() => _deleting = true);
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: Text('Could not delete account: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const CrystalHeaderStageBar(
          domain: ArmSphereStageDomain.passport,
        ),
        leading: const CrystalBackButton(),
        title: const Text('Delete Account'),
        actions: const [CrystalHomeButton()],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.passport),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppTheme.space16,
              MediaQuery.paddingOf(context).top + kToolbarHeight + AppTheme.space16,
              AppTheme.space16,
              MainShellScope.bottomClearance(context, additionalPadding: 24),
            ),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedActionCard(
              padding: const EdgeInsets.all(AppTheme.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x80E23B3B)),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 24),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      const Text(
                        'This action is irreversible',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space16),
                  const Text(
                    'Deleting your account will:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: AppTheme.space10),
                  const _Bullet('Permanently terminate your login — you will never be able to sign in again with this email.'),
                  const _Bullet('Anonymize your name and contact details from the platform index.'),
                  const _Bullet('Remove your athlete profile from all public searches and leaderboards.'),
                  const _Bullet('Sign out and revoke every device session immediately.'),
                  const SizedBox(height: AppTheme.space12),
                  const Text(
                    'Your historical match outcomes remain part of official federation records '
                    'for competitive integrity but will be detached from your personal identity.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            CheckboxListTile(
              value: _acknowledged,
              activeColor: AppTheme.error,
              onChanged: _deleting
                  ? null
                  : (v) {
                      HapticFeedback.lightImpact();
                      setState(() => _acknowledged = v ?? false);
                    },
              title: const Text(
                'I understand that this permanently deletes my account.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppTheme.space16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                side: BorderSide(
                  color: (_acknowledged && !_deleting)
                      ? const Color(0x80E23B3B)
                      : const Color(0x2EFFFFFF),
                  width: (_acknowledged && !_deleting) ? 1.2 : 1.0,
                ),
              ),
              onPressed: (_acknowledged && !_deleting) ? _confirmAndDeleteAccount : null,
              child: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Permanently Delete My Account'),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}

/// Terms of Service — static legal content describing actual platform rules.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const CrystalHeaderStageBar(
          domain: ArmSphereStageDomain.passport,
        ),
        leading: const CrystalBackButton(),
        title: const Text('Terms of Service'),
        actions: const [CrystalHomeButton()],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.passport),
          ),
          ListView(
            padding: EdgeInsets.fromLTRB(
              AppTheme.space16,
              MediaQuery.paddingOf(context).top + kToolbarHeight + AppTheme.space16,
              AppTheme.space16,
              MainShellScope.bottomClearance(context, additionalPadding: 24),
            ),
            children: const [
          ElevatedActionCard(
            padding: EdgeInsets.all(AppTheme.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegalHeading('1. The Service'),
                _LegalBody(
                    'ArmSphere is a platform for armwrestling athletes, referees, '
                    'clubs and event organizers. It provides rankings, competition '
                    'management, officiating tools and community features.'),
                SizedBox(height: 16),
                _LegalHeading('2. Your Account'),
                _LegalBody(
                    'You must provide accurate registration information and are '
                    'responsible for activity under your account. You may delete '
                    'your account at any time from Settings; deletion is permanent '
                    'and anonymizes your identity.'),
                SizedBox(height: 16),
                _LegalHeading('3. Competition Data'),
                _LegalBody(
                    'Match results, ELO ratings and certifications recorded through '
                    'the platform constitute official competition history. Attempting '
                    'to manipulate scores, ratings or other users\' data is prohibited.'),
                SizedBox(height: 16),
                _LegalHeading('4. Payments'),
                _LegalBody(
                    'Tournament entry fees are processed through our payment provider. '
                    'Refunds are governed by the organizer\'s published policy for the '
                    'specific event.'),
                SizedBox(height: 16),
                _LegalHeading('5. Community Conduct'),
                _LegalBody(
                    'Harassment, hate speech and illegal content are prohibited. '
                    'Reported content is reviewed through the platform governance '
                    'workflow, and accounts may be suspended for violations.'),
                SizedBox(height: 16),
                _LegalHeading('6. Changes'),
                _LegalBody(
                    'These terms may be updated as the platform evolves. Material '
                    'changes are announced in-app before taking effect.'),
              ],
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}

/// Privacy Policy — describes the actual data handling implemented by the API.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const CrystalHeaderStageBar(
          domain: ArmSphereStageDomain.passport,
        ),
        leading: const CrystalBackButton(),
        title: const Text('Privacy Policy'),
        actions: const [CrystalHomeButton()],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.passport),
          ),
          ListView(
            padding: EdgeInsets.fromLTRB(
              AppTheme.space16,
              MediaQuery.paddingOf(context).top + kToolbarHeight + AppTheme.space16,
              AppTheme.space16,
              MainShellScope.bottomClearance(context, additionalPadding: 24),
            ),
            children: const [
          ElevatedActionCard(
            padding: EdgeInsets.all(AppTheme.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegalHeading('Data We Collect'),
                _LegalBody(
                    'Account details (email, name), athlete profile data (province, '
                    'city, biometrics you enter), competition results, and technical '
                    'session metadata such as device type and IP address used for '
                    'account security.'),
                SizedBox(height: 16),
                _LegalHeading('How It Is Used'),
                _LegalBody(
                    'To operate rankings and competitions, secure your account, '
                    'process payments, and deliver notifications you opt into. '
                    'We do not sell personal data.'),
                SizedBox(height: 16),
                _LegalHeading('Profile Visibility Controls'),
                _LegalBody(
                    'Your profile visibility and searchability can be adjusted from '
                    'your profile settings. Private profiles are excluded from '
                    'public search results.'),
                SizedBox(height: 16),
                _LegalHeading('Data Retention & Deletion'),
                _LegalBody(
                    'Deleting your account deactivates your credential, anonymizes '
                    'your identity fields and revokes all sessions immediately. '
                    'Competition integrity records are retained without personal '
                    'identifiers. Audit logs never contain passwords or tokens.'),
                SizedBox(height: 16),
                _LegalHeading('Security'),
                _LegalBody(
                    'Passwords are stored only as salted hashes. Sessions use '
                    'rotating refresh tokens with reuse detection. All privileged '
                    'actions are recorded in a tamper-evident audit trail.'),
                SizedBox(height: 16),
                _LegalHeading('Your Rights'),
                _LegalBody(
                    'You may access and correct your data in-app, export what is '
                    'shown on your profile, control visibility, and delete your '
                    'account permanently at any time.'),
              ],
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 6, color: AppTheme.error),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35))),
        ],
      ),
    );
  }
}

class _LegalHeading extends StatelessWidget {
  final String text;
  const _LegalHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppTheme.fontDisplay,
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _LegalBody extends StatelessWidget {
  final String text;
  const _LegalBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
      ),
    );
  }
}

class _RadarLocationPrivacyCard extends ConsumerStatefulWidget {
  final String? fallbackVisibility;

  const _RadarLocationPrivacyCard({this.fallbackVisibility});

  @override
  ConsumerState<_RadarLocationPrivacyCard> createState() =>
      _RadarLocationPrivacyCardState();
}

class _RadarLocationPrivacyCardState
    extends ConsumerState<_RadarLocationPrivacyCard> {
  String? _optimisticMode;
  bool _saving = false;

  static const _options = <({
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color accent,
  })>[
    (
      value: 'AREA',
      title: 'Area Visible',
      subtitle:
          'Show approximate city/area (~1 km fuzzed, never your exact home address).',
      icon: Icons.radar_rounded,
      accent: AppTheme.cyan,
    ),
    (
      value: 'TRAVEL_ONLY',
      title: 'Traveling Only',
      subtitle:
          'Stay hidden by default. Only appear on Radar when you drop a Travel or Sparring Beacon.',
      icon: Icons.flight_takeoff_rounded,
      accent: AppTheme.goldPrimary,
    ),
    (
      value: 'GHOST',
      title: 'Ghost Mode',
      subtitle:
          'Completely invisible on ArmSphere Radar — hides both your home area and beacons.',
      icon: Icons.visibility_off_rounded,
      accent: AppTheme.crimson,
    ),
  ];

  String _resolveCurrentMode(AsyncValue<Map<String, dynamic>> profileAsync) {
    if (_optimisticMode != null) return _optimisticMode!;
    final fromAsync = profileAsync.valueOrNull?['locationVisibility']?.toString();
    final raw = (fromAsync ?? widget.fallbackVisibility ?? 'AREA').toUpperCase();
    if (raw == 'TRAVEL_ONLY' || raw == 'GHOST' || raw == 'AREA') {
      return raw;
    }
    return 'AREA';
  }

  Future<void> _selectMode(String mode, String label) async {
    if (_saving) return;
    HapticFeedback.selectionClick();
    final previous = _optimisticMode;
    setState(() {
      _optimisticMode = mode;
      _saving = true;
    });

    try {
      await ref
          .read(athleteProfileProvider.notifier)
          .updateLocationVisibility(mode);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: Text('Radar privacy updated: $label'),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optimisticMode = previous;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        CrystalSnackBar(
          content: Text(
            'Could not update Radar privacy. Check your connection and try again.',
          ),
          backgroundColor: AppTheme.crimson,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(athleteProfileProvider);
    final selectedMode = _resolveCurrentMode(profileAsync);

    return ElevatedActionCard(
      key: const ValueKey('settings_radar_location_privacy_card'),
      padding: EdgeInsets.zero,
      enableSlashes: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          children: [
            for (var i = 0; i < _options.length; i++) ...[
              Builder(
                builder: (context) {
                  final opt = _options[i];
                  final isSelected = selectedMode == opt.value;
                  return InkWell(
                    onTap: _saving
                        ? null
                        : () => _selectMode(opt.value, opt.title),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? opt.accent.withValues(alpha: 0.09)
                            : Colors.transparent,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: opt.accent.withValues(
                                alpha: isSelected ? 0.22 : 0.10,
                              ),
                              border: Border.all(
                                color: opt.accent.withValues(
                                  alpha: isSelected ? 0.85 : 0.30,
                                ),
                              ),
                            ),
                            child: Icon(
                              opt.icon,
                              size: 17,
                              color: isSelected
                                  ? opt.accent
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        opt.title,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                          color: isSelected
                                              ? AppTheme.textPure
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isSelected && _saving)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.goldPrimary,
                                        ),
                                      )
                                    else
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        size: 20,
                                        color: isSelected
                                            ? opt.accent
                                            : AppTheme.textMuted,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  opt.subtitle,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.35,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0x22FFFFFF),
              ),
            ],
            _SettingsTile(
              rowIndex: 2,
              icon: Icons.radar_rounded,
              iconColor: AppTheme.crimson,
              title: 'Open ArmSphere Radar',
              onTap: () {
                HapticFeedback.selectionClick();
                context.push('/radar');
              },
            ),
          ],
        ),
      ),
    );
  }
}
