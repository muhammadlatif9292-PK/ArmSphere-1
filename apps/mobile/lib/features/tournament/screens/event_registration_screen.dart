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
    final isEventLoading = eventAsync.isLoading;
    final rawFee = eventAsync.valueOrNull?['registrationFeeCents'];
    final baseFeeCents = (rawFee is num)
        ? rawFee.toInt()
        : int.tryParse('${rawFee ?? ''}') ?? 0;
    final totalFeeCents = baseFeeCents;

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
                      const SizedBox(height: AppTheme.space16),

                      // Anchored Registration & Pricing Summary Card
                      _RegistrationSummaryCard(
                        division: _selectedDivision,
                        weightClass: _selectedWeightClass,
                        arm: _armChoice,
                        baseFeeCents: baseFeeCents,
                        totalFeeCents: totalFeeCents,
                        isLoading: isEventLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Persistent Sticky Bottom Action Bar with Dynamic Pricing CTA & Keyboard Avoidance
            StickyBottomActionBar(
              primaryActionLabel: isEventLoading
                  ? 'Loading Event Details...'
                  : (totalFeeCents > 0
                      ? 'Complete Registration — ${formatEventFee(totalFeeCents)}'
                      : 'Complete Registration — Free Entry'),
              primaryActionIcon: Icons.how_to_reg_outlined,
              isLoading: _isLoading || isEventLoading,
              disclaimerText: 'Official sanctioned entry • Bracket seeded upon check-in',
              onPrimaryAction: (_isLoading || isEventLoading) ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dynamic Registration & Pricing Summary Card
///
/// Anchors selected competition tier and live fee calculations directly
/// above the persistent sticky submission CTA, eliminating visual voids
/// and ensuring transparent financial breakdown for single and double brackets.
class _RegistrationSummaryCard extends StatelessWidget {
  final String division;
  final String weightClass;
  final String arm;
  final int baseFeeCents;
  final int totalFeeCents;
  final bool isLoading;

  const _RegistrationSummaryCard({
    required this.division,
    required this.weightClass,
    required this.arm,
    required this.baseFeeCents,
    required this.totalFeeCents,
    this.isLoading = false,
  });

  String _formatDivision(String d) {
    switch (d.toUpperCase()) {
      case 'SENIOR':
        return 'Senior (Open)';
      case 'JUNIOR':
        return 'Junior (U21)';
      case 'MASTERS':
        return 'Masters (40+)';
      case 'FEMALE':
        return 'Women\'s Division';
      default:
        return d;
    }
  }

  String _formatArm(String a) {
    switch (a.toUpperCase()) {
      case 'RIGHT':
        return 'Right Arm (1 Bracket)';
      case 'LEFT':
        return 'Left Arm (1 Bracket)';
      case 'BOTH':
        return 'Both Arms (Double Bracket)';
      default:
        return a;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDoubleBracket = arm.toUpperCase() == 'BOTH';

    return Container(
      key: const ValueKey('registration_summary_card'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 16,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'REGISTRATION SUMMARY',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.8,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const StatusChip(
                label: 'SANCTIONED ENTRY',
                type: StatusType.success,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),

          // Division & Bracket Configuration Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.elevatedSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_kabaddi, size: 16, color: AppTheme.goldPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_formatDivision(division)} • $weightClass • ${_formatArm(arm)}',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space12),

          // Itemized Pricing Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Division Entry Fee',
                style: TextStyle(
                  fontFamily: AppTheme.fontBody,
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                isLoading ? 'Loading...' : formatEventFee(baseFeeCents),
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          if (isDoubleBracket) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Second Arm Entry (Left Arm)',
                  style: TextStyle(
                    fontFamily: AppTheme.fontBody,
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Text(
                  'Included',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Divider(color: AppTheme.borderSubtle, height: 1),
          const SizedBox(height: 10),

          // Total Due Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Entry Fee Due',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                isLoading ? 'Loading...' : formatEventFee(totalFeeCents),
                key: const ValueKey('registration_total_fee_text'),
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.goldPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
