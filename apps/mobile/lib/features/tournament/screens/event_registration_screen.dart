import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/sticky_bottom_action_bar.dart';
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
        const SnackBar(
          content: Text('Session expired — please sign in again.'),
          backgroundColor: AppTheme.error,
        ),
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
            title: 'Registration Recorded!',
            body: 'Your entry has been submitted and is awaiting organizer approval.',
            color: AppTheme.success,
          );
          break;
        case 'WAITLISTED':
          _showResult(
            title: 'Placed on Waitlist',
            body: 'This weight class is currently at capacity. You will be notified if a bracket spot opens.',
            color: AppTheme.secondaryAccent,
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
            body: 'Status: ${status.isNotEmpty ? status : "Recorded"}.',
            color: AppTheme.info,
          );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.detail), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'), backgroundColor: AppTheme.error),
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
        backgroundColor: AppTheme.cardSurface,
        title: const Text(
          'Entry Fee Required',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Your registration spot is held pending payment.\n\n'
          'Amount: ${formatEventFee(fee)}\n\n'
          'Card payment completes your official bracket placement.',
          style: const TextStyle(
            fontFamily: AppTheme.fontBody,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: AppTheme.primaryAccent)),
          ),
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
        backgroundColor: AppTheme.cardSurface,
        title: const Text(
          'Pay via QR Code',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan the organizer\'s payment code, then the tournament director will confirm your bracket entry.',
                style: TextStyle(
                  fontFamily: AppTheme.fontBody,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              if (qrUrl != null && qrUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: SizedBox(width: 180, height: 180, child: Image.network(qrUrl, fit: BoxFit.contain)),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'The organizer has not uploaded a payment QR yet. Payment can be settled at on-site weigh-in.',
                    style: TextStyle(
                      fontFamily: AppTheme.fontBody,
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done', style: TextStyle(color: AppTheme.primaryAccent)),
          ),
        ],
      ),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Official Event Registration',
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
                      // Event summary card
                      if (eventAsync.hasValue) ...[
                        ElevatedActionCard(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          borderColor: AppTheme.border,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      eventAsync.value!['name']?.toString() ?? 'Tournament Competition',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    ),
                                    child: Text(
                                      formatEventFee(eventAsync.value!['registrationFeeCents']),
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textMuted),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${eventAsync.value!['location'] ?? 'Venue'}, ${eventAsync.value!['city'] ?? ''}',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontBody,
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.space16),
                      ],

                      // Form parameters container
                      ElevatedActionCard(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Competition Division',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedDivision,
                              dropdownColor: AppTheme.cardSurface,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontBody,
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.group_outlined, size: 20),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'SENIOR', child: Text('Senior Division (Open)')),
                                DropdownMenuItem(value: 'JUNIOR', child: Text('Junior Division (Under 21)')),
                                DropdownMenuItem(value: 'MASTERS', child: Text('Masters Division (40+)')),
                                DropdownMenuItem(value: 'FEMALE', child: Text('Women\'s Division')),
                              ],
                              validator: (v) => v == null || v.isEmpty ? 'Select a division' : null,
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedDivision = val);
                              },
                            ),
                            const SizedBox(height: 20),

                            const Text(
                              'Weight Class',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedWeightClass,
                              dropdownColor: AppTheme.cardSurface,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontBody,
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.scale_outlined, size: 20),
                              ),
                              items: const [
                                DropdownMenuItem(value: '-70kg', child: Text('Lightweight (-70kg / 154 lbs)')),
                                DropdownMenuItem(value: '-78kg', child: Text('Welterweight (-78kg / 172 lbs)')),
                                DropdownMenuItem(value: '-85kg', child: Text('Middleweight (-85kg / 187 lbs)')),
                                DropdownMenuItem(value: '-95kg', child: Text('Heavyweight (-95kg / 209 lbs)')),
                                DropdownMenuItem(value: '+95kg', child: Text('Super Heavyweight (+95kg / 209+ lbs)')),
                              ],
                              validator: (v) => v == null || v.isEmpty ? 'Select a weight category' : null,
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedWeightClass = val);
                              },
                            ),
                            const SizedBox(height: 20),

                            const Text(
                              'Pulling Arm Choice',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _armChoice,
                              dropdownColor: AppTheme.cardSurface,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontBody,
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.pan_tool_outlined, size: 20),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'RIGHT', child: Text('Right Arm Bracket')),
                                DropdownMenuItem(value: 'LEFT', child: Text('Left Arm Bracket')),
                                DropdownMenuItem(value: 'BOTH', child: Text('Both Arms (Double Bracket)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _armChoice = val);
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
              primaryActionLabel: 'Complete Registration',
              primaryActionIcon: Icons.how_to_reg_outlined,
              isLoading: _isLoading,
              disclaimerText: 'Official sanctioned entry • Bracket seeded upon check-in',
              onPrimaryAction: _isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
