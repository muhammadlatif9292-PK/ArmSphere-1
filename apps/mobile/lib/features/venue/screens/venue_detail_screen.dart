import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/venue_provider.dart';
import '../../../core/widgets/glass_card.dart';

class VenueDetailScreen extends ConsumerWidget {
  final String venueId;

  const VenueDetailScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueAsync = ref.watch(venueDetailProvider(venueId));

    return Scaffold(
      appBar: AppBar(title: const Text('Venue Details')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(venueDetailProvider(venueId)),
        child: venueAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Could not load venue', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => ref.invalidate(venueDetailProvider(venueId)),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (venue) {
            final name = venue['name']?.toString() ?? 'Venue';
            final addressLine = [
              venue['address']?.toString(),
              venue['city']?.toString(),
              venue['province']?.toString(),
            ].where((part) => part != null && part.isNotEmpty).join(', ');
            final description = venue['description']?.toString() ?? '';
            final contactInfo = venue['contactInfo']?.toString() ?? '';
            final verificationStatus =
                (venue['verificationStatus']?.toString() ?? '').toUpperCase();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (addressLine.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(addressLine,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                      if (contactInfo.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.contact_phone_outlined,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(contactInfo,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const Divider(height: 32),
                        const Text('About this venue',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(description,
                            style:
                                const TextStyle(height: 1.6, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                if (verificationStatus.isNotEmpty &&
                    verificationStatus != 'VERIFIED')
                  const SizedBox(height: 16),
                if (verificationStatus.isNotEmpty &&
                    verificationStatus != 'VERIFIED')
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        verificationStatus == 'REJECTED'
                            ? Icons.gpp_bad_outlined
                            : Icons.hourglass_empty,
                        size: 22,
                      ),
                      title: const Text('Verification pending',
                          style: TextStyle(fontSize: 14)),
                      subtitle: Text(
                        'Federation admins are reviewing this venue.',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
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
