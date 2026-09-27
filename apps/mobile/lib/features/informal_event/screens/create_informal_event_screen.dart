import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/informal_event_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';

/// Domain 9 / Stage 6 Convergence: Create Informal Event Screen
///
/// Implements Grassroots Sparring & Practice Session Hosting:
/// - Posts open meetup to GET /informal-events via Riverpod.
/// - Unbundled form sections: Guidance Banner, Session Coordinates, Date/Time Scheduler, and Capacity.
/// - Eradication of nested `GlassCard` in compliance with Audit Rule Item 2.2.
class CreateInformalEventScreen extends ConsumerStatefulWidget {
  const CreateInformalEventScreen({super.key});

  @override
  ConsumerState<CreateInformalEventScreen> createState() =>
      _CreateInformalEventScreenState();
}

class _CreateInformalEventScreenState
    extends ConsumerState<CreateInformalEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  DateTime? _scheduledAt;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.goldPrimary,
              surface: AppTheme.cardSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.goldPrimary,
              surface: AppTheme.cardSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduledAt == null) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify a date and start time for the meetup'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    try {
      await ref.read(informalEventCreationProvider.notifier).create(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            city: _cityController.text.trim(),
            province: _provinceController.text.trim().isEmpty
                ? null
                : _provinceController.text.trim(),
            scheduledAt: _scheduledAt!.toIso8601String(),
            maxParticipants:
                int.tryParse(_maxParticipantsController.text.trim()),
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Practice session posted to local pullers!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not post practice session: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(informalEventCreationProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Host Practice Meetup',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Directive Guidance Card
              ElevatedActionCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sports_martial_arts,
                            color: AppTheme.goldPrimary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'GRASSROOTS TABLE SPARRING',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppTheme.goldLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Host an open table for technique drills, strap work, and sparring. Fellow athletes can view coordinates and RSVP.',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space16),

              // Form Details Card
              ElevatedActionCard(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Meetup Title',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        hintText: 'e.g. Sunday Toproll & Strap Clinic',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.elevatedSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          borderSide: const BorderSide(color: AppTheme.goldPrimary),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a meetup title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Session Focus & Hardware Specs',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        hintText: 'Number of tables, beginner-friendly, chalk available...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.elevatedSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          borderSide: const BorderSide(color: AppTheme.goldPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'City',
                              labelStyle:
                                  const TextStyle(color: AppTheme.textSecondary),
                              hintText: 'e.g. Lahore',
                              hintStyle: const TextStyle(color: AppTheme.textMuted),
                              filled: true,
                              fillColor: AppTheme.elevatedSurface,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSmall),
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'City required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: TextFormField(
                            controller: _provinceController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Province (optional)',
                              labelStyle:
                                  const TextStyle(color: AppTheme.textSecondary),
                              hintText: 'e.g. Punjab',
                              hintStyle: const TextStyle(color: AppTheme.textMuted),
                              filled: true,
                              fillColor: AppTheme.elevatedSurface,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSmall),
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space16),

                    TextFormField(
                      controller: _maxParticipantsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Max Puller Capacity (optional)',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        hintText: 'e.g. 12',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.elevatedSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // Date & Time Picker Tile
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.elevatedSurface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SCHEDULED DATE & TIME',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _scheduledAt == null
                                      ? 'Tap to select session time'
                                      : '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year} at ${_scheduledAt!.hour.toString().padLeft(2, '0')}:${_scheduledAt!.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _scheduledAt == null
                                        ? AppTheme.textMuted
                                        : AppTheme.textPrimary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.schedule,
                                size: 20, color: AppTheme.goldPrimary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldPrimary,
                  foregroundColor: AppTheme.voidBackground,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                onPressed: isSubmitting ? null : _submit,
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.voidBackground),
                      )
                    : const Text(
                        'PUBLISH PRACTICE MEETUP',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
