import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/informal_event_provider.dart';
import '../../../core/widgets/glass_card.dart';

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
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a date and time for the meetup')),
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
            maxParticipants: int.tryParse(_maxParticipantsController.text.trim()),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Practice meetup posted successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not post meetup: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        ref.watch(informalEventCreationProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Post Practice Meetup')),
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
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Meetup Title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'What will this session cover?'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration:
                      const InputDecoration(labelText: 'City'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _provinceController,
                  decoration: const InputDecoration(
                      labelText: 'Province (optional)'),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Date & Time',
                        suffixIcon: Icon(Icons.calendar_today_outlined)),
                    child: Text(
                      _scheduledAt == null
                          ? 'Select date and time'
                          : _formatDateTime(_scheduledAt!),
                      style: TextStyle(
                        fontSize: 15,
                        color: _scheduledAt == null
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4)
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxParticipantsController,
                  decoration: const InputDecoration(
                      labelText: 'Max participants (optional)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final n = int.tryParse(value.trim());
                    if (n == null || n < 1) return 'Enter a number of 1 or more';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  child: isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Host Meetup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }
}
