import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';

/// Account & Settings hub (spec §36). Every section maps to a real surface.
class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(context, 'ACCOUNT'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profile'),
                  subtitle: const Text('View and manage your athlete profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/athlete/profile'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Security & Active Sessions'),
                  subtitle: const Text('Devices signed in and MFA'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/session'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionHeader(context, 'PREFERENCES'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Payment Methods'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/payment-methods'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.local_activity_outlined),
                  title: const Text('My Tickets'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/tickets'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block_flipped),
                  title: const Text('Blocked Users'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/blocked'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionHeader(context, 'SUPPORT & LEGAL'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.confirmation_number_outlined),
                  title: const Text('Support Tickets'),
                  subtitle: const Text('Raise and track support requests'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/tickets'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/terms'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/privacy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionHeader(context, 'DANGER ZONE'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Account',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      'Permanently deactivate and anonymize your account'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/deletion'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Log Out',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _SectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
      ),
    );
  }
}

/// In-app account deletion (Apple requirement for account-based apps).
class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() =>
      _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  bool _acknowledged = false;
  bool _deleting = false;

  Future<void> _deleteAccount() async {
    setState(() => _deleting = true);
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (!mounted) return;
      // Auth state change reroutes to the entry flow; this pop is a safety net.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange[700]),
                      const SizedBox(width: 10),
                      Text('This action is permanent',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Deleting your account will:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const _Bullet(
                      'Deactivate your login permanently — you will not be able to sign in again with this email.'),
                  const _Bullet(
                      'Anonymize your name and contact details from the platform.'),
                  const _Bullet(
                      'Remove your athlete profile from search and public view.'),
                  const _Bullet(
                      'Sign out and revoke every device session immediately.'),
                  const SizedBox(height: 8),
                  const Text(
                    'Your past match results remain part of official competition '
                    'history but are no longer linked to an identifiable person. '
                    'This cannot be undone.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _acknowledged,
              onChanged: _deleting
                  ? null
                  : (v) => setState(() => _acknowledged = v ?? false),
              title: const Text(
                'I understand that this permanently deletes my account.',
                style: TextStyle(fontSize: 13),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: (_acknowledged && !_deleting) ? _deleteAccount : null,
              child: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
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
        padding: const EdgeInsets.all(20),
        children: const [
          GlassCard(
            padding: EdgeInsets.all(20),
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
        padding: const EdgeInsets.all(20),
        children: const [
          GlassCard(
            padding: EdgeInsets.all(20),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 5),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
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
    return Text(text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14));
  }
}

class _LegalBody extends StatelessWidget {
  final String text;
  const _LegalBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 12.5, height: 1.5));
  }
}
