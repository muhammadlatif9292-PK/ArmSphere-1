import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/map_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/armsphere_location_picker.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/sticky_bottom_action_bar.dart';
import '../../../core/widgets/sticky_form_scaffold.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/widgets/crystal_toast.dart';

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
  double? _latitude;
  double? _longitude;
  String _city = '';
  String _province = 'Punjab';
  String? _resolvedAddress;

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
        city: _city.trim().isNotEmpty ? _city.trim() : address,
        province: _province.trim().isNotEmpty ? _province.trim() : 'Punjab',
        address: address,
        latitude: _latitude,
        longitude: _longitude,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text('Venue submitted for federation certification!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
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
    return StickyFormScaffold(
      stageDomain: ArmSphereStageDomain.venues,
      appBar: AppBar(
        leading: const CrystalBackButton(fallbackRoute: '/venues'),
        title: const Text(
          'Register Training Venue',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: const [CrystalHomeButton()],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      primaryActionLabel: 'Submit Facility for Certification',
      primaryActionIcon: Icons.verified_outlined,
      isLoading: _isLoading,
      disclaimerText: 'Facility enters verification queue for official sanctioning',
      onPrimaryAction: _isLoading ? null : _submit,
      formKey: _formKey,
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

                ArmSphereLocationFieldCard(
                  title: 'Pin Exact Facility Location',
                  subtitle:
                      'Drop a 2D map pin to auto-fill address, city & appear on ArmSphere Radar',
                  latitude: _latitude,
                  longitude: _longitude,
                  resolvedAddress: _resolvedAddress,
                  onPickLocation: () async {
                    final picked = await ArmSphereLocationPicker.show(
                      context,
                      title: 'Pin Training Venue',
                      initialLatitude: _latitude,
                      initialLongitude: _longitude,
                      initialLabel: _resolvedAddress ?? _addressController.text,
                    );
                    if (picked == null || !mounted) return;
                    setState(() {
                      _latitude = picked.latitude;
                      _longitude = picked.longitude;
                      _resolvedAddress = picked.formattedAddress;
                      if (picked.formattedAddress.trim().isNotEmpty) {
                        _addressController.text = picked.formattedAddress.trim();
                      }
                      if (picked.city.trim().isNotEmpty) {
                        _city = picked.city.trim();
                      }
                      _province = ArmSphereMapConfig.normalizeProvince(
                        picked.province,
                        fallbackCity: picked.city,
                      );
                    });
                  },
                  onClear: () {
                    setState(() {
                      _latitude = null;
                      _longitude = null;
                      _resolvedAddress = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

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
    );
  }
}
