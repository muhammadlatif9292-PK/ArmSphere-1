import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/providers/post_creation_provider.dart';
import '../../../core/widgets/glass_card.dart';

/// Compose screen — submits a real video-link post via POST /community/links.
/// The backend only accepts YouTube/TikTok/Facebook URLs; exercise details
/// (type/weight/reps) are only allowed in the GYM category.
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _captionController = TextEditingController();
  final _exerciseTypeController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  String? _category;
  bool _submitting = false;

  static const _categories = ['HIGHLIGHTS', 'TUTORIALS', 'GYM'];

  @override
  void dispose() {
    _urlController.dispose();
    _captionController.dispose();
    _exerciseTypeController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  bool get _isGym => _category == 'GYM';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      await ref.read(linkSubmissionProvider.notifier).submitLink(
            externalUrl: _urlController.text.trim(),
            category: _category,
            caption: _captionController.text.trim().isEmpty
                ? null
                : _captionController.text.trim(),
            exerciseType: _isGym && _exerciseTypeController.text.trim().isNotEmpty
                ? _exerciseTypeController.text.trim()
                : null,
            weightKg: _isGym && _weightController.text.trim().isNotEmpty
                ? double.tryParse(_weightController.text.trim())
                : null,
            reps: _isGym && _repsController.text.trim().isNotEmpty
                ? int.tryParse(_repsController.text.trim())
                : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Link submitted for moderation. It will appear once approved.'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.detail), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not submit link: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share a Video')),
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
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Video URL',
                    hintText: 'YouTube, TikTok or Facebook link',
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Required';
                    final lower = v.toLowerCase();
                    final supported = lower.contains('youtube.com') ||
                        lower.contains('youtu.be') ||
                        lower.contains('tiktok.com') ||
                        lower.contains('facebook.com') ||
                        lower.contains('fb.watch');
                    if (!supported) {
                      return 'Only YouTube, TikTok or Facebook links are supported';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration:
                      const InputDecoration(labelText: 'Category (optional)'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _captionController,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Caption (optional)'),
                ),
                if (_isGym) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _exerciseTypeController,
                    decoration: const InputDecoration(
                        labelText: 'Exercise Type',
                        hintText: 'e.g. Rising lift, Strap pull'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Weight (kg)'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            if (double.tryParse(value.trim()) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _repsController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Reps'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            if (int.tryParse(value.trim()) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Submit Link'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Submissions are reviewed by moderators before appearing in the feed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
