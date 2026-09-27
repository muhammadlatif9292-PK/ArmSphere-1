import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/venue_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';

/// Domain 9 / Stage 6 Convergence: Venue Detail Screen
///
/// Implements Canonical Training Space & Hardware Inspection Architecture:
/// - Pulls venue profile and hardware verification status from GET /venues/:venueId.
/// - Unbundled venue dossier: Venue Header, Contact Information, Table Inventory, and Certification Badge.
/// - Eradication of nested `GlassCard` inside `ListView` in compliance with Audit Rule Item 2.2.
class VenueDetailScreen extends ConsumerWidget {
  final String venueId;

  const VenueDetailScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueAsync = ref.watch(venueDetailProvider(venueId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardSurface,
        elevation: 0,
        title: const Text(
          'Venue Dossier',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.goldPrimary,
        backgroundColor: AppTheme.cardSurface,
        onRefresh: () async => ref.invalidate(venueDetailProvider(venueId)),
        child: venueAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(AppTheme.space16),
            children: const [
              SkeletonPlaceholder(height: 140, borderRadius: AppTheme.radiusMedium),
              SizedBox(height: AppTheme.space16),
              SkeletonPlaceholder(height: 80, borderRadius: AppTheme.radiusMedium),
              SizedBox(height: AppTheme.space16),
              SkeletonPlaceholder(height: 120, borderRadius: AppTheme.radiusMedium),
            ],
          ),
          error: (e, _) => AppEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load venue dossier',
            subtitle: e.toString(),
            ctaLabel: 'Retry',
            onCtaTap: () => ref.invalidate(venueDetailProvider(venueId)),
          ),
          data: (venue) {
            final name = venue['name']?.toString() ?? 'Venue';
            final city = venue['city']?.toString() ?? '';
            final province = venue['province']?.toString() ?? '';
            final addressLine = [
              venue['address']?.toString(),
              city,
              province,
            ].where((part) => part != null && part.isNotEmpty).join(', ');
            final description = venue['description']?.toString() ?? '';
            final contactInfo = venue['contactInfo']?.toString() ?? '';
            final verificationStatus =
                (venue['verificationStatus']?.toString() ?? 'VERIFIED').toUpperCase();
            final isVerified = verificationStatus == 'VERIFIED';

            return ListView(
              padding: const EdgeInsets.all(AppTheme.space16),
              children: [
                // 1. Venue Header Dossier Card
                ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  borderColor: isVerified ? AppTheme.goldPrimary.withValues(alpha: 0.4) : AppTheme.border,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.elevatedSurface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isVerified ? AppTheme.goldPrimary : AppTheme.border,
                              ),
                            ),
                            child: Icon(
                              Icons.fitness_center_outlined,
                              color: isVerified ? AppTheme.goldPrimary : AppTheme.textSecondary,
                              size: 22,
                            ),
                          ),
                          StatusChip(
                            label: isVerified ? 'CERTIFIED TABLES' : 'VERIFICATION PENDING',
                            type: isVerified ? StatusType.success : StatusType.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (addressLine.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 15,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                addressLine,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space16),

                // 2. Contact & Hours Card
                if (contactInfo.isNotEmpty) ...[
                  ElevatedActionCard(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.contact_phone_outlined, size: 16, color: AppTheme.goldPrimary),
                            SizedBox(width: 8),
                            Text(
                              'COORDINATION & CONTACT',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: AppTheme.goldLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space12),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          contactInfo,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space16),
                ],

                // 3. Hardware & Table Description Card
                if (description.isNotEmpty) ...[
                  ElevatedActionCard(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.table_restaurant_outlined, size: 16, color: AppTheme.goldPrimary),
                            SizedBox(width: 8),
                            Text(
                              'TABLE HARDWARE & FACILITY SPECS',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: AppTheme.goldLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space12),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space16),
                ],

                // 4. Verification Status Notice (if pending or rejected)
                if (!isVerified)
                  ElevatedActionCard(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    borderColor: verificationStatus == 'REJECTED' ? AppTheme.error : AppTheme.secondaryAccent,
                    child: Row(
                      children: [
                        Icon(
                          verificationStatus == 'REJECTED'
                              ? Icons.gpp_bad_outlined
                              : Icons.hourglass_empty_outlined,
                          size: 24,
                          color: verificationStatus == 'REJECTED' ? AppTheme.error : AppTheme.secondaryAccent,
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                verificationStatus == 'REJECTED'
                                    ? 'Certification Declined'
                                    : 'Federation Review Pending',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                verificationStatus == 'REJECTED'
                                    ? 'This facility does not meet official federation table safety standards.'
                                    : 'Referees are auditing table padding, pin lines, and hardware tolerances.',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
