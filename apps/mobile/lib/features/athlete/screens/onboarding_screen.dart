import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/step_header.dart';

/// Guided athlete profile setup shown to every newly registered account.
///
/// Three focused steps replace the original single long form so each screen
/// asks for one coherent group of details:
///   1. Identity    — ring name, date of birth, gender
///   2. Location    — province + city used for events and rankings scope
///   3. Competition — weight / height / reach and pulling arm
///
/// Payload keys match the backend athlete contract exactly.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _provinces = <String>[
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Gilgit-Baltistan',
    'Azad Kashmir',
    'Islamabad Capital Territory',
  ];

  int _step = 0;
  bool _isLoading = false;

  final _identityFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();
  final _specsFormKey = GlobalKey<FormState>();

  // Identity
  final _displayNameController = TextEditingController();
  DateTime _dob = DateTime(2000, 1, 1);
  String _gender = 'MALE';

  // Location
  final _cityController = TextEditingController();
  String _province = 'Punjab';

  // Competition specs
  double _weightKg = 75.0;
  double _heightCm = 175.0;
  double _reachCm = 175.0;
  String _armDominance = 'RIGHT';

  @override
  void dispose() {
    _displayNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        return _identityFormKey.currentState?.validate() ?? false;
      case 1:
        return _locationFormKey.currentState?.validate() ?? false;
      default:
        return _specsFormKey.currentState?.validate() ?? false;
    }
  }

  Future<void> _next() async {
    if (!_validateCurrentStep()) return;
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    await _submit();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      helpText: 'Select your date of birth',
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final payload = {
        'displayName': _displayNameController.text.trim(),
        'city': _cityController.text.trim(),
        'province': _province,
        'weightKg': _weightKg,
        'heightCm': _heightCm,
        'reachCm': _reachCm,
        'armDominance': _armDominance,
        'gender': _gender,
        'dateOfBirth': _dob.toIso8601String(),
      };

      await ref.read(authProvider.notifier).completeOnboarding(payload);
      // Auth notifier advances the router once isOnboarded flips to true.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = const [
      ('Who are you on the table?', 'This is how athletes, referees and fans will see you.'),
      ('Where do you compete?', 'We use your region to suggest local events and provincial rankings.'),
      ('Your competition specs', 'Divisions and weight classes are matched from these numbers.'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Build your athlete profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StepHeader(
                    step: _step + 1,
                    totalSteps: 3,
                    title: titles[_step].$1,
                    subtitle: titles[_step].$2,
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: AppTheme.animationNormal,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: Form(
                      key: _step == 0
                          ? _identityFormKey
                          : _step == 1
                              ? _locationFormKey
                              : _specsFormKey,
                      child: _buildStep(_step),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (_step > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => setState(() => _step--),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              side: const BorderSide(color: AppTheme.glassBorder, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              ),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                      if (_step > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _next,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.goldPrimary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : Text(_step == 2 ? 'Finish setup' : 'Continue'),
                        ),
                      ),
                    ],
                  ),
                  if (_step == 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'You can update all of this later from your profile.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _identityStep();
      case 1:
        return _locationStep();
      default:
        return _specsStep();
    }
  }

  // ── Step 1: Identity ────────────────────────────────────────────────
  Widget _identityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _displayNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Display / Ring Name',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your athlete display name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickDateOfBirth,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
            child: Text(
              '${_dob.day.toStringAsFixed(0).padLeft(2, '0')} ${_monthName(_dob.month)} ${_dob.year}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _gender,
          decoration: const InputDecoration(
            labelText: 'Gender',
            prefixIcon: Icon(Icons.people_outline),
          ),
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('Male')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _gender = val);
          },
        ),
      ],
    );
  }

  // ── Step 2: Location ────────────────────────────────────────────────
  Widget _locationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _province,
          decoration: const InputDecoration(
            labelText: 'Province / Region',
            prefixIcon: Icon(Icons.map_outlined),
          ),
          items: _provinces
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _province = val);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cityController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'City',
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your city';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ── Step 3: Competition specs ───────────────────────────────────────
  Widget _specsStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SpecSlider(
          label: 'Weight',
          value: _weightKg,
          min: 40,
          max: 180,
          suffix: 'kg',
          decimals: 0,
          onChanged: (v) => setState(() => _weightKg = v),
        ),
        _SpecSlider(
          label: 'Height',
          value: _heightCm,
          min: 100,
          max: 230,
          suffix: 'cm',
          decimals: 0,
          onChanged: (v) => setState(() => _heightCm = v),
        ),
        _SpecSlider(
          label: 'Arm reach',
          value: _reachCm,
          min: 100,
          max: 230,
          suffix: 'cm',
          decimals: 0,
          onChanged: (v) => setState(() => _reachCm = v),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _armDominance,
          decoration: const InputDecoration(
            labelText: 'Dominant / Pulling Arm',
            prefixIcon: Icon(Icons.sports_kabaddi),
          ),
          items: const [
            DropdownMenuItem(value: 'RIGHT', child: Text('Right Arm')),
            DropdownMenuItem(value: 'LEFT', child: Text('Left Arm')),
            DropdownMenuItem(value: 'AMBIDEXTROUS', child: Text('Ambidextrous')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _armDominance = val);
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.elevatedSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppTheme.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Officials verify these at weigh-in. Estimates are fine for matching divisions.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}

class _SpecSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final int decimals;
  final ValueChanged<double> onChanged;

  const _SpecSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.decimals,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.goldGlow,
                borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Text(
                '${value.toStringAsFixed(decimals)} $suffix',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: (max - min).round(),
          activeColor: AppTheme.goldPrimary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
