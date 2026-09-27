import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/providers/state_providers.dart';

class NominateTalentScreen extends ConsumerStatefulWidget {
  const NominateTalentScreen({super.key});

  @override
  ConsumerState<NominateTalentScreen> createState() => _NominateTalentScreenState();
}

class _NominateTalentScreenState extends ConsumerState<NominateTalentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final reason = _reasonController.text.trim();
      final nominationRepository = ref.read(nominationRepositoryProvider);
      await nominationRepository.nominateTalent(name, reason);
      
      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nomination filed successfully with Federation Review!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
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
      appBar: AppBar(title: const Text('Nominate Talent')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Form(
          key: _formKey,
          child: ElevatedActionCard(
            padding: const EdgeInsets.all(AppTheme.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space10),
                      decoration: BoxDecoration(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(Icons.star, size: 22, color: AppTheme.goldPrimary),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grassroots Scout Submission',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppTheme.space2),
                          Text(
                            'Recommend upcoming talent for official federation ranking and sponsorship invites.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Candidate Athlete / Referee Name',
                    hintText: 'e.g. John Doe',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please provide candidate name';
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.space16),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Scout Evaluation & Achievements',
                    hintText: 'Describe their performance, tournament record, club affiliations, or standout puller attributes...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please provide evaluation details';
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.space24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('File Official Nomination'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
