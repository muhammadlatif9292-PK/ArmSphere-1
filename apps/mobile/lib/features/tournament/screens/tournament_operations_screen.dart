import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart';

class TournamentOperationsScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentOperationsScreen({super.key, required this.tournamentId});

  @override
  State<TournamentOperationsScreen> createState() => _TournamentOperationsScreenState();
}

class _TournamentOperationsScreenState extends State<TournamentOperationsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Admin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'BRACKET OPERATIONS',
              style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _AdminActionRow(
                    icon: Icons.alt_route,
                    title: 'Resolve Bracket Disputes',
                    subtitle: 'Review contested referee reports',
                    onTap: () {},
                  ),
                  const Divider(height: 24),
                  _AdminActionRow(
                    icon: Icons.shuffle,
                    title: 'Re-seed Players',
                    subtitle: 'Regenerate double elimination layouts',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'DIVISION SETUP',
              style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _AdminActionRow(
                    icon: Icons.add_circle_outline,
                    title: 'Create Weight Division',
                    subtitle: 'Define kg classes & hand dominance rules',
                    onTap: () {},
                  ),
                  const Divider(height: 24),
                  _AdminActionRow(
                    icon: Icons.people_outline,
                    title: 'Manage Officials',
                    subtitle: 'Assign certified WAF referees to divisions',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
