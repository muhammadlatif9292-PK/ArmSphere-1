import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/sticky_bottom_action_bar.dart';
import '../../../core/providers/state_providers.dart';

class SubmitVenueScreen extends ConsumerStatefulWidget {
  const SubmitVenueScreen({super.key});

  @override
  ConsumerState<SubmitVenueScreen> createState() => _SubmitVenueScreenState();
}

class _SubmitVenueScreenState extends ConsumerState<SubmitVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final address = _addressController.text.trim();
      final venueRepository = ref.read(venueRepositoryProvider);
      await venueRepository.submitVenue(
        name: name,
        city: address,
        province: 'UNKNOWN',
        address: address,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venue submitted for federation certification!'),
            backgroundColor: AppTheme.success,
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Register Training Venue',
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
                      // Guidance Card
                      ElevatedActionCard(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        borderColor: AppTheme.border,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              ),
                              child: const Icon(
                                Icons.storefront_outlined,
                                color: AppTheme.secondaryAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verified Training Facility',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Submit your gym or club table location. Once certified by the federation, pullers can discover your facility in the directory.',
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

                      // Form Inputs
                      ElevatedActionCard(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Venue / Club Name',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontBody,
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'e.g. Iron Grip Club Lahore',
                                prefixIcon: Icon(Icons.fitness_center, size: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Venue name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            const Text(
                              'Address & City',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _addressController,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontBody,
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Street address, district, and city',
                                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Address is required';
                                }
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

            // Persistent Sticky Bottom Action Bar with Keyboard Avoidance
            StickyBottomActionBar(
              primaryActionLabel: 'Submit Facility for Certification',
              primaryActionIcon: Icons.verified_outlined,
              isLoading: _isLoading,
              disclaimerText: 'Facility enters verification queue for official sanctioning',
              onPrimaryAction: _isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
