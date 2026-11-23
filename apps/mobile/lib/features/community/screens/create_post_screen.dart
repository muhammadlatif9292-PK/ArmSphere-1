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
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/sticky_form_scaffold.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../models/community_video_category.dart';

/// Compose screen — submits a real video-link post via POST /community/links.
/// The backend only accepts YouTube/TikTok/Facebook URLs; exercise details
/// (type/weight/reps) are only allowed in the GYM category.
class CreatePostScreen extends ConsumerStatefulWidget {
  final String? initialCategory;

  const CreatePostScreen({super.key, this.initialCategory});

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

  static const List<({String id, String label})> _canonicalGymMoves = [
    (id: 'PRONATION', label: 'Pronation'),
    (id: 'RISER', label: 'Riser'),
    (id: 'BACK_PRESSURE', label: 'Back pressure'),
    (id: 'SIDE_PRESSURE', label: 'Side pressure'),
    (id: 'CUPPING', label: 'Cupping'),
    (id: 'CONTAINMENT', label: 'Containment'),
    (id: 'HAMMER_CURL', label: 'Hammer curl'),
    (id: 'CURVE_BICEPS_CURL', label: 'Curve biceps curl'),
    (id: 'LAT_DRAG', label: 'Lat Drag'),
  ];

  String _selectedGymMove = 'PRONATION';

  @override
  void initState() {
    super.initState();
    final incoming = widget.initialCategory?.trim().toUpperCase();
    if (incoming == 'GYM') {
      _category = 'GYM';
    } else {
      final parsed = CommunityVideoCategory.fromWire(incoming);
      _category = (parsed ?? CommunityVideoCategory.highlights).wireValue;
    }
    _exerciseTypeController.text = _selectedGymMove;
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
      final resolvedExercise = _isGym
          ? (_exerciseTypeController.text.trim().isNotEmpty
              ? _exerciseTypeController.text.trim()
              : _selectedGymMove)
          : null;

      await ref.read(linkSubmissionProvider.notifier).submitLink(
            externalUrl: _urlController.text.trim(),
            category: _category,
            caption: _captionController.text.trim().isEmpty
                ? null
                : _captionController.text.trim(),
            exerciseType: resolvedExercise,
            weightKg: _isGym && _weightController.text.trim().isNotEmpty
                ? double.tryParse(_weightController.text.trim())
                : null,
            reps: _isGym && _repsController.text.trim().isNotEmpty
                ? int.tryParse(_repsController.text.trim())
                : null,
            isTrainingLogEntry: _isGym,
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
          CrystalSnackBar(
            content: Text(
              _isGym
                  ? 'Training PR logged and updated in your top PR carousel!'
                  : 'Video link submitted for federation moderation.',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text(e.detail),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text('Could not submit: $e'),
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
    return StickyFormScaffold(
      stageDomain: _isGym ? ArmSphereStageDomain.training : ArmSphereStageDomain.community,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const CrystalBackButton(fallbackRoute: '/community/feed'),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ArmSphereImage(
              assetPath: ArmSphereAssets.sealFed,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              semanticLabel: 'Official Federation Seal',
            ),
            const SizedBox(width: 8),
            Text(_isGym ? 'Log Training & PR' : 'Share a Video Clip'),
          ],
        ),
        actions: const [CrystalHomeButton()],
      ),
      primaryActionLabel: _isGym ? 'Submit Training PR' : 'Submit Video Link',
      primaryActionIcon: _isGym ? Icons.emoji_events_outlined : Icons.upload_file_outlined,
      onPrimaryAction: _submitting ? null : _submit,
      isLoading: _submitting,
      disclaimerText: _isGym
          ? 'Submitted PRs immediately update your Training Log top carousel. Adding a video link is optional and good to have for verification.'
          : 'Community links are reviewed by federation moderators before appearing in public feeds.',
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isGym
                              ? 'Training Log & Personal Record (PR)'
                              : 'Combat Sports Feed Submission',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space2),
                        Text(
                          _isGym
                              ? 'Video URL is optional (good to have). Latest PRs appear in your top carousel.'
                              : 'Supported platforms: YouTube, TikTok, Facebook Reel',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                decoration: InputDecoration(
                  labelText: _isGym
                      ? 'Video URL (Optional — good to have)'
                      : 'Video URL',
                  hintText: _isGym
                      ? 'Optional YouTube, TikTok, or Facebook link...'
                      : 'https://youtube.com/shorts/...',
                  helperText: _isGym
                      ? 'Optional — good to have a video URL for lift proof, not compulsory'
                      : null,
                  helperMaxLines: 2,
                  prefixIcon: const Icon(Icons.link, color: AppTheme.textSecondary),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) {
                    return _isGym ? null : 'URL is required';
                  }
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
              if (!_isGym)
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Content Category',
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  dropdownColor: AppTheme.overlayG6Surface,
                  items: CommunityVideoCategory.values
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.wireValue,
                          child: Text(c.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => _category = value);
                  },
                ),
              if (_isGym) ...[
                const SizedBox(height: AppTheme.space16),
                const Text(
                  'SELECT ARM-WRESTLING MOVE / LIFT',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.goldPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _canonicalGymMoves.map((move) {
                    final isSelected = _selectedGymMove == move.id;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedGymMove = move.id;
                          _exerciseTypeController.text = move.id;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0x24D4AF37)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.goldPrimary
                                : const Color(0x38FFFFFF),
                            width: isSelected ? 1.3 : 1.0,
                          ),
                        ),
                        child: Text(
                          move.label,
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppTheme.goldPrimary : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.space16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'PR / Lift Weight (kg)',
                          hintText: 'e.g. 35',
                          prefixIcon: Icon(Icons.fitness_center, color: AppTheme.goldPrimary),
                        ),
                        validator: (value) {
                          if (!_isGym) return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter weight (kg)';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) return 'Invalid weight';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: TextFormField(
                        controller: _repsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Reps (Optional)',
                          hintText: 'e.g. 1',
                        ),
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
              const SizedBox(height: AppTheme.space16),
              TextFormField(
                controller: _captionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _isGym ? 'Training Notes (Optional)' : 'Caption (optional)',
                  hintText: _isGym
                      ? 'Optional strap setup, pulley height, or hand feel notes...'
                      : 'Describe technique, workout notes, or match contest...',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
