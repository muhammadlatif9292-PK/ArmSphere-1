import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/dispute_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/sticky_bottom_action_bar.dart';

/// Submit Complaint Screen — files an official dispute via
/// POST /governance/disputes (title >= 5 chars, description >= 10 chars).
///
/// Features sticky bottom action bar with keyboard avoidance for long-form input.
class SubmitComplaintScreen extends ConsumerStatefulWidget {
  const SubmitComplaintScreen({super.key});

  @override
  ConsumerState<SubmitComplaintScreen> createState() =>
      _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends ConsumerState<SubmitComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final ok = await ref.read(disputeProvider.notifier).submitDispute(
            {
              'title': _subjectController.text.trim(),
              'description': _descController.text.trim(),
            },
          );

      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispute filed successfully. Track review under Governance & Disputes.'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/governance');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not file dispute. Please verify network and try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'File Official Complaint',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.elevatedSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space16),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Guidance Banner
                      ElevatedActionCard(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        borderColor: AppTheme.border,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: AppTheme.primaryAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Arbitration & Ethics Review',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Disputes are reviewed by the WAF ethics committee. Provide clear references to matches, tables, or officials.',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontBody,
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),

                      // Form Fields
                      ElevatedActionCard(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Incident Subject',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _subjectController,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontBody,
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Brief summary of what occurred',
                                prefixIcon: Icon(Icons.title, size: 20),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) return 'Incident subject is required';
                                if (v.length < 5) return 'At least 5 characters required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            const Text(
                              'Detailed Explanation & Evidence',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descController,
                              maxLines: 6,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontBody,
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Include match table references, timeline, witness athlete IDs, and video evidence URLs...',
                                alignLabelWithHint: true,
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) return 'Detailed explanation is required';
                                if (v.length < 10) return 'At least 10 characters required';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Persistent Sticky Action Bar with Keyboard Avoidance
            StickyBottomActionBar(
              primaryActionLabel: 'File Arbitration Request',
              primaryActionIcon: Icons.gavel_outlined,
              isLoading: _isLoading,
              disclaimerText: 'Official submission with immutable federation audit log',
              onPrimaryAction: _isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
