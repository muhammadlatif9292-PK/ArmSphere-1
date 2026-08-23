import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/state_providers.dart';

class PublicAthleteProfileScreen extends ConsumerStatefulWidget {
  final String athleteId;

  const PublicAthleteProfileScreen({super.key, required this.athleteId});

  @override
  ConsumerState<PublicAthleteProfileScreen> createState() => _PublicAthleteProfileScreenState();
}

class _PublicAthleteProfileScreenState extends ConsumerState<PublicAthleteProfileScreen> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final repo = ref.read(socialRepositoryProvider);
    try {
      final isFollowing = await repo.checkFollowStatus(widget.athleteId);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    setState(() {
      _isLoading = true;
    });

    final repo = ref.read(socialRepositoryProvider);
    try {
      if (_isFollowing) {
        await repo.unfollowAthlete(widget.athleteId);
      } else {
        await repo.followAthlete(widget.athleteId);
      }
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlete Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header spec
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                    child: Icon(Icons.person, size: 50, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Haider "The Hammer" Khan',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lahore, Pakistan',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Social Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _toggleFollow,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(_isFollowing ? 'Unfollow' : 'Follow'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/messages/conv_${widget.athleteId}'),
                    child: const Text('Message'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Specs
            Text(
              'ATHLETIC OVERVIEW',
              style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _SpecRow(label: 'Weight Category', value: '95kg (Heavyweight)'),
                  const Divider(height: 24),
                  _SpecRow(label: 'Dominant Arm', value: 'Right Arm'),
                  const Divider(height: 24),
                  _SpecRow(label: 'ELO Rank Right', value: '1,920 (#4 National)'),
                  const Divider(height: 24),
                  _SpecRow(label: 'Win / Loss Record', value: '24 Wins / 3 Losses'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
