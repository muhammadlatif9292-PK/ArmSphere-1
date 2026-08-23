import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/glass_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  final _displayNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  
  double _weightKg = 75.0;
  double _heightCm = 175.0;
  double _reachCm = 175.0;
  String _armDominance = 'RIGHT';
  String _gender = 'MALE';
  DateTime _dob = DateTime(2000, 1, 1);
  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final payload = {
        'displayName': _displayNameController.text.trim(),
        'city': _cityController.text.trim(),
        'province': _provinceController.text.trim(),
        'weightKg': _weightKg,
        'heightCm': _heightCm,
        'reachCm': _reachCm,
        'armDominance': _armDominance,
        'gender': _gender,
        'dateOfBirth': _dob.toIso8601String(),
      };

      await ref.read(authProvider.notifier).completeOnboarding(payload);
      // Auth notifier automatically advances the router once isOnboarded changes
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlete Onboarding'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Build Your Athlete Profile',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about your physical specs and location to match you in divisions and tournaments.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: GlassCard(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Display Name
                    TextFormField(
                      controller: _displayNameController,
                      textCapitalization: TextCapitalization.words,
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
                    const SizedBox(height: 20),

                    // City & Province
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'City',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _provinceController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Province / State',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // spec sliders
                    Text(
                      'Weight: ${_weightKg.toStringAsFixed(1)} kg',
                      style: theme.textTheme.labelLarge,
                    ),
                    Slider(
                      value: _weightKg,
                      min: 40,
                      max: 180,
                      divisions: 280,
                      onChanged: (val) {
                        setState(() {
                          _weightKg = val;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    Text(
                      'Height: ${_heightCm.toStringAsFixed(0)} cm',
                      style: theme.textTheme.labelLarge,
                    ),
                    Slider(
                      value: _heightCm,
                      min: 100,
                      max: 230,
                      divisions: 130,
                      onChanged: (val) {
                        setState(() {
                          _heightCm = val;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    Text(
                      'Arm Reach: ${_reachCm.toStringAsFixed(0)} cm',
                      style: theme.textTheme.labelLarge,
                    ),
                    Slider(
                      value: _reachCm,
                      min: 100,
                      max: 230,
                      divisions: 130,
                      onChanged: (val) {
                        setState(() {
                          _reachCm = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Arm dominance
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
                        if (val != null) {
                          setState(() {
                            _armDominance = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Gender
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
                        if (val != null) {
                          setState(() {
                            _gender = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Complete Registration'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
