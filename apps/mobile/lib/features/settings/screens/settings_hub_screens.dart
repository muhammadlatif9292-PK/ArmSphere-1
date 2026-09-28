import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/biometric_settings_tile.dart';

/// Account & Settings hub (spec §36). Every section maps to a real surface.
class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.space16),
        children: [
          _sectionHeader(context, 'ACCOUNT'),
          ElevatedActionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  subtitle: 'View and manage your athlete profile',
                  onTap: () => context.push('/athlete/profile'),
                ),
                const Divider(height: 1, color: AppTheme.cardBorder),
                _SettingsTile(
                  icon: Icons.badge_outlined,
                  title: 'Account Roles',
                  subtitle: 'Manage verified roles and persona',
                  onTap: () => context.push('/settings/roles'),
                ),
                const Divider(height: 1, color: AppTheme.cardBorder),
                const BiometricSettingsTile(),
                const Divider(height: 1, color: AppTheme.cardBorder),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Security & Active Sessions',
                  subtitle: 'Devices signed in and MFA',
                  onTap: () => context.push('/session'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space20),

          _sectionHeader(context, 'PREFERENCES'),
          ElevatedActionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(height: 1, color: AppTheme.cardBorder),
                _SettingsTile(
                  icon: Icons.payment,
                  title: 'Payment Methods',
                  onTap: () => context.push('/settings/payment-methods'),
                ),
                const Divider(height: 1, color: AppTheme.cardBorder),
                _SettingsTile(
                  icon: Icons.confirmation_number_outlined,
                  title: 'My Tickets & Passes',
                  onTap: () => context.push('/settings/tickets'),
                ),
                const Divider(height: 1, color: AppTheme.cardBorder),
                _SettingsTile(
                  icon: Icons.block_flipped,
                  title: 'Blocked Users',
                  onTap: () => context.push('/settings/blocked'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space20),

          _sectionHeader(context, 'SUPPORT & LEGAL'),
          ElevatedActionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.contact_support_outlined,
                  title: 'Support Requests',
                  subtitle: 'Raise and track support requests',
                  onTap: () => context.push('/settings/tickets'),
                ),
                const Divider(height: 1, color: AppTheme.cardBorder),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => context.push('/settings/terms'),
                ),
                const Divider(height: 1, color: AppTheme.cardBorder),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => context.push('/settings/privacy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space20),

          _sectionHeader(context, 'DANGER ZONE'),
          ElevatedActionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.delete_forever,
                  iconColor: AppTheme.error,
                  title: 'Delete Account',
                  titleColor: AppTheme.error,
                  subtitle: 'Permanently deactivate and anonymize your account',
                  onTap: () => context.push('/settings/deletion'),
                ),
                const Divider(height: 1, color: AppTheme.cardBorder),
                _SettingsTile(
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
          const SizedBox(height: AppTheme.space24),
        ],
      ),
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
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppTheme.textPrimary, size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: titleColor ?? AppTheme.textPrimary,
            fontSize: 14,
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
        SnackBar(
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
      appBar: AppBar(title: const Text('Delete Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
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
                          color: AppTheme.error.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
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
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: (_acknowledged && !_deleting) ? _deleteAccount : null,
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
    );
  }
}

/// Terms of Service — static legal content describing actual platform rules.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.space16),
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
    );
  }
}

/// Privacy Policy — describes the actual data handling implemented by the API.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.space16),
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
