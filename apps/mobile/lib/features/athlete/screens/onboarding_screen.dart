import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/step_header.dart';
import '../../../core/widgets/sticky_bottom_action_bar.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/utils/error_formatter.dart';

/// Guided athlete profile setup shown to every newly registered account.
///
/// Upgraded to Canonical Stage 2 Specification (Slice 6 / [P1-02]):
/// - Directional animated PageView wizard with 280ms Curves.easeInOutCubic slide.
/// - StickyBottomActionBar with automatic keyboard avoidance & 640dp constraints.
/// - Normalized 8dp radiusSmall badges and Space Grotesk numeric typography.
/// - Tactile haptic feedback on step transitions and slider updates.
///
/// Payload keys match the backend athlete contract exactly:
///   1. Identity    — displayName, dateOfBirth, gender
///   2. Location    — province, city
///   3. Competition — weightKg, heightCm, reachCm, armDominance
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

  static const _titles = [
    ('Who are you on the table?', 'This is how athletes, referees and fans will see you in rankings.'),
    ('Where do you compete?', 'We use your region to suggest local events and provincial rankings.'),
    ('Your competition specs', 'Divisions and weight classes are automatically matched from these numbers.'),
  ];

  late final PageController _pageController;
  int _currentStep = 0;
  bool _isLoading = false;

  final _identityFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();
  final _specsFormKey = GlobalKey<FormState>();

  // 1. Identity
  final _displayNameController = TextEditingController();
  DateTime _dob = DateTime(2000, 1, 1);
  String _gender = 'MALE';

  // 2. Location
  final _cityController = TextEditingController();
  String _province = 'Punjab';

  // 3. Competition specs
  double _weightKg = 75.0;
  double _heightCm = 175.0;
  double _reachCm = 175.0;
  String _armDominance = 'RIGHT';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _displayNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
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
    if (_currentStep < 2) {
      HapticFeedback.selectionClick();
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep++);
      return;
    }
    await _submit();
  }

  void _prev() {
    if (_currentStep > 0) {
      HapticFeedback.selectionClick();
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickDateOfBirth() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      helpText: 'Select your date of birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.goldPrimary,
              onPrimary: Colors.black,
              surface: AppTheme.cardSurface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
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
        'dateOfBirth': _dob.toUtc().toIso8601String(),
      };

      await ref.read(authProvider.notifier).completeOnboarding(payload);
      // Auth notifier advances the router once isOnboarded flips to true.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorFormatter.format(e)),
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
          'Build Your Athlete Profile',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w700,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              await ref.read(authProvider.notifier).skipOnboarding();
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Skip to Tour',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    color: AppTheme.goldPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppTheme.goldPrimary,
                ),
                SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed top stepper bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: StepHeader(
                  step: _currentStep + 1,
                  totalSteps: 3,
                  title: _titles[_currentStep].$1,
                  subtitle: _titles[_currentStep].$2,
                ),
              ),
            ),

            // Animated directional PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildPageWrapper(
                    formKey: _identityFormKey,
                    child: _buildIdentityStep(),
                  ),
                  _buildPageWrapper(
                    formKey: _locationFormKey,
                    child: _buildLocationStep(),
                  ),
                  _buildPageWrapper(
                    formKey: _specsFormKey,
                    child: _buildSpecsStep(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StickyBottomActionBar(
        primaryActionLabel: _currentStep == 2 ? 'Complete Profile' : 'Continue',
        primaryActionIcon: _currentStep == 2 ? Icons.check_circle_outline : Icons.arrow_forward,
        isLoading: _isLoading,
        onPrimaryAction: _isLoading ? null : _next,
        secondaryAction: _currentStep > 0
            ? OutlinedButton(
                onPressed: _isLoading ? null : _prev,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.border, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Back'),
              )
            : null,
        disclaimerText: _currentStep == 0
            ? 'You can update your stats and details later from your profile.'
            : null,
      ),
    );
  }

  Widget _buildPageWrapper({required GlobalKey<FormState> formKey, required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Form(
            key: formKey,
            child: child,
          ),
        ),
      ),
    );
  }

  // ── Step 1: Identity ────────────────────────────────────────────────
  Widget _buildIdentityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _displayNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Display / Ring Name',
            hintText: 'e.g. Iron Grip Tariq',
            prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.goldPrimary),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your athlete display name';
            }
            if (value.trim().length < 2) {
              return 'Display name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickDateOfBirth,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              prefixIcon: Icon(Icons.calendar_today_outlined, color: AppTheme.goldPrimary),
              suffixIcon: Icon(Icons.arrow_drop_down, color: AppTheme.textMuted),
            ),
            child: Text(
              '${_dob.day.toString().padLeft(2, '0')} ${_monthName(_dob.month)} ${_dob.year}',
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          dropdownColor: AppTheme.elevatedSurface,
          decoration: const InputDecoration(
            labelText: 'Gender Division',
            prefixIcon: Icon(Icons.people_outline, color: AppTheme.goldPrimary),
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
  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _province,
          dropdownColor: AppTheme.elevatedSurface,
          decoration: const InputDecoration(
            labelText: 'Province / Territory',
            prefixIcon: Icon(Icons.map_outlined, color: AppTheme.goldPrimary),
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
            labelText: 'City / Municipality',
            hintText: 'e.g. Lahore, Karachi, Rawalpindi',
            prefixIcon: Icon(Icons.location_city_outlined, color: AppTheme.goldPrimary),
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
  Widget _buildSpecsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SpecSlider(
          label: 'Competition Weight',
          value: _weightKg,
          min: 40,
          max: 180,
          suffix: 'kg',
          decimals: 0,
          onChanged: (v) => setState(() => _weightKg = v),
        ),
        const SizedBox(height: 14),
        _SpecSlider(
          label: 'Standing Height',
          value: _heightCm,
          min: 100,
          max: 230,
          suffix: 'cm',
          decimals: 0,
          onChanged: (v) => setState(() => _heightCm = v),
        ),
        const SizedBox(height: 14),
        _SpecSlider(
          label: 'Arm Reach (Wingspan)',
          value: _reachCm,
          min: 100,
          max: 230,
          suffix: 'cm',
          decimals: 0,
          onChanged: (v) => setState(() => _reachCm = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _armDominance,
          dropdownColor: AppTheme.elevatedSurface,
          decoration: const InputDecoration(
            labelText: 'Dominant Pulling Arm',
            prefixIcon: Icon(Icons.sports_kabaddi, color: AppTheme.goldPrimary),
          ),
          items: const [
            DropdownMenuItem(value: 'RIGHT', child: Text('Right Arm')),
            DropdownMenuItem(value: 'LEFT', child: Text('Left Arm')),
            DropdownMenuItem(value: 'AMBIDEXTROUS', child: Text('Ambidextrous (Both Arms)')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _armDominance = val);
          },
        ),
        const SizedBox(height: 20),
        ElevatedActionCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppTheme.goldPrimary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Officials verify weight and metrics at official tournament weigh-in. Estimates calibrate your initial division.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${value.toStringAsFixed(decimals)} $suffix',
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  color: AppTheme.goldPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.goldPrimary,
            inactiveTrackColor: AppTheme.borderSubtle,
            thumbColor: AppTheme.goldPrimary,
            overlayColor: AppTheme.goldPrimary.withValues(alpha: 0.15),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}
