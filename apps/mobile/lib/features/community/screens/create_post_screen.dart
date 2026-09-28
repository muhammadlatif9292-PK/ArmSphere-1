import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/post_creation_provider.dart';
import '../../../core/services/sensory_feedback_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/embed_url_builder.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/elevated_action_card.dart';

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
  String? _previewThumbnailUrl;

  static const _categories = ['HIGHLIGHTS', 'TUTORIALS', 'GYM'];

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    final text = _urlController.text.trim();
    final ytId = EmbedUrlBuilder.extractYouTubeId(text);
    final nextThumb = ytId != null ? 'https://img.youtube.com/vi/$ytId/hqdefault.jpg' : null;
    if (_previewThumbnailUrl != nextThumb) {
      setState(() => _previewThumbnailUrl = nextThumb);
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
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

    HapticFeedback.mediumImpact();
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
        if (_isGym) {
          SensoryFeedbackService.instance.playSensoryCeremony(
            audioEvent: ArmSphereAudioEvent.prAchieved,
            hapticType: HapticFeedbackType.heavy,
          );
        } else {
          HapticFeedback.lightImpact();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video link submitted for federation moderation.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.detail),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not submit link: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ArmSphereImage(
              assetPath: ArmSphereAssets.sealFed,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              semanticLabel: 'Official Federation Seal',
            ),
            SizedBox(width: 8),
            Text('Share a Video Clip'),
          ],
        ),
      ),
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
                        color: AppTheme.primaryRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: AppTheme.primaryRed.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const ArmSphereImage(
                        assetPath: ArmSphereAssets.sealFed,
                        width: 22,
                        height: 22,
                        semanticLabel: 'Federation Submission Seal',
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Combat Sports Feed Submission',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppTheme.space2),
                          Text(
                            'Supported platforms: YouTube, TikTok, Facebook Reel',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space20),
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Video URL',
                    hintText: 'https://youtube.com/shorts/...',
                    prefixIcon: Icon(Icons.link, color: AppTheme.textSecondary),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'URL is required';
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
                if (_previewThumbnailUrl != null) ...[
                  const SizedBox(height: AppTheme.space12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.primaryRed.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ArmSphereImage(
                            imageUrl: _previewThumbnailUrl,
                            fallbackAsset: ArmSphereAssets.heroGrip,
                            fit: BoxFit.cover,
                            cacheWidth: 480,
                            cacheHeight: 270,
                            semanticLabel: 'Video Preview Thumbnail',
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppTheme.voidBackground.withValues(alpha: 0.75),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 12,
                            child: Row(
                              children: const [
                                Icon(Icons.check_circle_outline, size: 14, color: AppTheme.goldPrimary),
                                SizedBox(width: 6),
                                Text(
                                  'Federation Preview Verified',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.space16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Content Category',
                    prefixIcon: Icon(Icons.category_outlined, color: AppTheme.textSecondary),
                  ),
                  dropdownColor: AppTheme.cardSurface,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => _category = value);
                  },
                ),
                const SizedBox(height: AppTheme.space16),
                TextFormField(
                  controller: _captionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Caption (optional)',
                    hintText: 'Describe technique, workout notes, or match contest...',
                  ),
                ),
                if (_isGym) ...[
                  const SizedBox(height: AppTheme.space16),
                  TextFormField(
                    controller: _exerciseTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Armwrestling Exercise Specifics',
                      hintText: 'e.g. Cupping, Pronation, Rising, Strap Pull',
                      prefixIcon: Icon(Icons.fitness_center, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Weight (kg)'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return null;
                            if (double.tryParse(value.trim()) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: TextFormField(
                          controller: _repsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Reps'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return null;
                            if (int.tryParse(value.trim()) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppTheme.space24),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Video Link'),
                ),
                const SizedBox(height: AppTheme.space12),
                const Text(
                  'Community links are reviewed by federation moderators before appearing in public feeds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
