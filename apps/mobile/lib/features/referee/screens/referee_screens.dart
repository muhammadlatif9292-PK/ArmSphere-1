import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/state_providers.dart';

/// Referee Dashboard Screen
class RefereeDashboardScreen extends ConsumerWidget {
  const RefereeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Referee Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'OFFICIAL ACTIONS',
              style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _RefCard(
                  icon: Icons.assignment_outlined,
                  label: 'Submit Scorepad',
                  onTap: () => context.push('/referee/submit-scorepad'),
                ),
                _RefCard(
                  icon: Icons.verified_outlined,
                  label: 'Certifications',
                  onTap: () => context.push('/referee/certifications'),
                ),
                _RefCard(
                  icon: Icons.search,
                  label: 'Search Athletes',
                  onTap: () => context.push('/referee/search-athletes'),
                ),
                _RefCard(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Upload Evidence',
                  onTap: () => context.push('/referee/upload-evidence'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text(
              'RECENT OFFICIATED MATCHES',
              style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _OfficiatedMatchRow(matchId: 'M-1092', pullers: 'Zain Shah vs Haider Khan', outcome: 'Zain won (3-2)'),
                  const Divider(height: 24),
                  _OfficiatedMatchRow(matchId: 'M-1081', pullers: 'Arsalan Malik vs Farhan Ahmed', outcome: 'Arsalan won (3-0)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RefCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficiatedMatchRow extends StatelessWidget {
  final String matchId;
  final String pullers;
  final String outcome;

  const _OfficiatedMatchRow({required this.matchId, required this.pullers, required this.outcome});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pullers, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('ID: $matchId', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        Text(outcome, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
      ],
    );
  }
}

/// Referee Certifications Screen
class RefereeCertificationsScreen extends StatelessWidget {
  const RefereeCertificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _CertCard(
            title: 'WAF Master Referee',
            issuer: 'World Armwrestling Federation',
            date: 'Expires Dec 2027',
            status: 'Active',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _CertCard(
            title: 'National Head Referee',
            issuer: 'Pakistan Armwrestling Federation',
            date: 'Expires Jun 2026',
            status: 'Active',
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _CertCard extends StatelessWidget {
  final String title;
  final String issuer;
  final String date;
  final String status;
  final Color color;

  const _CertCard({
    required this.title,
    required this.issuer,
    required this.date,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(issuer, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Match Submission (Scorepad) Screen
class MatchSubmissionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? match;

  const MatchSubmissionScreen({super.key, this.match});

  @override
  ConsumerState<MatchSubmissionScreen> createState() => _MatchSubmissionScreenState();
}

class _MatchSubmissionScreenState extends ConsumerState<MatchSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _opponentController = TextEditingController();
  final _divisionController = TextEditingController();
  String _score = '3-0';
  bool _isLoading = false;

  @override
  void dispose() {
    _opponentController.dispose();
    _divisionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final payload = {
      'opponentName': _opponentController.text.trim(),
      'divisionName': _divisionController.text.trim(),
      'score': _score,
    };

    try {
      await ref.read(liveMatchesProvider.notifier).submitMatchOptimistic(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match submitted successfully!')),
        );
        context.pop();
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Scorepad'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: GlassCard(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _opponentController,
                  decoration: const InputDecoration(labelText: 'Opponent Athlete Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _divisionController,
                  decoration: const InputDecoration(labelText: 'Division / Weight Category'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _score,
                  decoration: const InputDecoration(labelText: 'Outcome Score'),
                  items: const [
                    DropdownMenuItem(value: '3-0', child: Text('3 - 0 (Sweep)')),
                    DropdownMenuItem(value: '3-1', child: Text('3 - 1')),
                    DropdownMenuItem(value: '3-2', child: Text('3 - 2')),
                    DropdownMenuItem(value: '2-3', child: Text('2 - 3')),
                    DropdownMenuItem(value: '1-3', child: Text('1 - 3')),
                    DropdownMenuItem(value: '0-3', child: Text('0 - 3')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _score = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Submit Official Result'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Athlete Search Screen for Officials
class AthleteSearchScreen extends ConsumerStatefulWidget {
  const AthleteSearchScreen({super.key});

  @override
  ConsumerState<AthleteSearchScreen> createState() => _AthleteSearchScreenState();
}

class _AthleteSearchScreenState extends ConsumerState<AthleteSearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(athleteRepositoryProvider);
      final list = await repo.searchAthletes(query);
      setState(() {
        _results = list;
      });
    } catch (_) {
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Athletes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter Ring / Real Name',
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        return Card(
                          child: ListTile(
                            title: Text(item['displayName'] ?? ''),
                            subtitle: Text(item['weightClass'] ?? ''),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/// Evidence Upload Screen
class EvidenceUploadScreen extends StatefulWidget {
  const EvidenceUploadScreen({super.key});

  @override
  State<EvidenceUploadScreen> createState() => _EvidenceUploadScreenState();
}

class _EvidenceUploadScreenState extends State<EvidenceUploadScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence Upload')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('Upload Video Evidence / Match Footage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Footage must be unedited in high-frame rate', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.video_library_outlined),
              label: const Text('Select Video File'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video file selector mock')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
