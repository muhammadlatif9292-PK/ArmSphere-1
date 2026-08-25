import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'tournament_screens.dart';

class EventRegistrationScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const EventRegistrationScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<EventRegistrationScreen> createState() => _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends ConsumerState<EventRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedDivision = 'SENIOR';
  String _selectedWeightClass = '-85kg';
  String _armChoice = 'RIGHT';
  bool _isLoading = false;

  String? _currentAthleteId() {
    final auth = ref.read(authProvider);
    final user = auth.userProfile?['user'] as Map<String, dynamic>? ?? auth.userProfile ?? {};
    return user['id']?.toString() ?? user['userId']?.toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final athleteId = _currentAthleteId();
    if (athleteId == null || athleteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired — please sign in again.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final registration = await ref.read(tournamentProvider.notifier).registerAthlete(
            eventId: widget.tournamentId,
            athleteId: athleteId,
            division: _selectedDivision,
            weightClass: _selectedWeightClass,
            arm: _armChoice,
          );
      if (!mounted || registration == null) return;

      final status = (registration['status']?.toString() ?? '').toUpperCase();
      switch (status) {
        case 'PENDING':
          _showResult(
            title: 'Registered!',
            body: 'Your entry has been recorded and is awaiting organizer approval.',
            color: Colors.green,
          );
          break;
        case 'WAITLISTED':
          _showResult(
            title: 'You are on the waitlist',
            body: 'This competition is at capacity. The organizer will promote you if a spot opens.',
            color: Colors.orange,
          );
          break;
        case 'PENDING_PAYMENT':
          final clientSecret = registration['clientSecret']?.toString();
          if ((clientSecret ?? '').isNotEmpty) {
            await _showPaymentRequired(registration);
          } else {
            await _showManualQrPayment();
          }
          break;
        default:
          _showResult(
            title: 'Registration submitted',
            body: 'Status: ${status.isNotEmpty ? status : "unknown"}.',
            color: Colors.blueGrey,
          );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.detail), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showResult({required String title, required String body, required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title $body'),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
    context.pop();
  }

  Future<void> _showPaymentRequired(Map<String, dynamic> registration) async {
    final eventAsync = ref.read(eventDetailProvider(widget.tournamentId));
    final fee = eventAsync.valueOrNull?['registrationFeeCents'];
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entry fee required'),
        content: Text(
          'Your spot is held but payment is still pending.\n'
          'Amount: ${formatEventFee(fee)}\n\n'
          'Card payment completes your entry — online card checkout is being activated '
          'and will appear here automatically.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
    if (mounted) context.pop();
  }

  Future<void> _showManualQrPayment() async {
    final eventAsync = ref.read(eventDetailProvider(widget.tournamentId));
    final qrUrl = eventAsync.valueOrNull?['paymentQrImageUrl']?.toString();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pay via QR code'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scan the organizer\'s payment code, then the organizer will confirm your entry.'),
              const SizedBox(height: 12),
              if (qrUrl != null && qrUrl.isNotEmpty)
                SizedBox(width: 180, height: 180, child: Image.network(qrUrl, fit: BoxFit.contain))
              else
                const Text('The organizer has not uploaded a payment QR yet.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Done')),
        ],
      ),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.tournamentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: GlassCard(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (eventAsync.hasValue) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          eventAsync.value!['name']?.toString() ?? 'Competition',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Text(
                        formatEventFee(eventAsync.value!['registrationFeeCents']),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                ],
                const Text(
                  'Division',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDivision,
                  items: const [
                    DropdownMenuItem(value: 'SENIOR', child: Text('Senior')),
                    DropdownMenuItem(value: 'JUNIOR', child: Text('Junior')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                  ],
                  validator: (v) => v == null || v.isEmpty ? 'Select a division' : null,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDivision = val);
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  'Weight Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedWeightClass,
                  items: const [
                    DropdownMenuItem(value: '-70kg', child: Text('Lightweight (-70kg)')),
                    DropdownMenuItem(value: '-85kg', child: Text('Middleweight (-85kg)')),
                    DropdownMenuItem(value: '-95kg', child: Text('Heavyweight (-95kg)')),
                    DropdownMenuItem(value: '+95kg', child: Text('Super Heavyweight (95kg+)')),
                  ],
                  validator: (v) => v == null || v.isEmpty ? 'Select a weight category' : null,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedWeightClass = val);
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  'Pulling Arms Registration',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _armChoice,
                  items: const [
                    DropdownMenuItem(value: 'RIGHT', child: Text('Right Arm Only')),
                    DropdownMenuItem(value: 'LEFT', child: Text('Left Arm Only')),
                    DropdownMenuItem(value: 'BOTH', child: Text('Both Arms')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _armChoice = val);
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Complete Registration'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
