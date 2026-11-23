import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/offline_sync.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/sticky_bottom_action_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../services/tournament_offline_store.dart';
import 'event_qr_passport_screen.dart';
import 'tournament_screens.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/widgets/crystal_toast.dart';

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
  int _guestCount = 0;
  bool _isLoading = false;

  String _currentAthleteId() {
    final profile = ref.read(athleteProfileProvider).valueOrNull;
    final profileId = profile?['id']?.toString();
    if (profileId != null && profileId.isNotEmpty) {
      return profileId;
    }
    final auth = ref.read(authProvider);
    final user = auth.userProfile?['user'] as Map<String, dynamic>? ?? auth.userProfile ?? {};
    return (user['athleteProfileId'] ??
            user['id'] ??
            user['userId'] ??
            'ath-pk-local')
        .toString();
  }

  String _currentAthleteName() {
    final profile = ref.read(athleteProfileProvider).valueOrNull;
    final name = profile?['displayName'] ?? profile?['fullName'] ?? profile?['name'];
    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }
    final auth = ref.read(authProvider);
    final user = auth.userProfile?['user'] as Map<String, dynamic>? ?? auth.userProfile ?? {};
    return (user['displayName'] ?? user['fullName'] ?? user['name'] ?? 'ArmSphere Athlete').toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final athleteId = _currentAthleteId();
    final athleteName = _currentAthleteName();

    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();

    // 1. Always save locally first via Offline-First Optimistic Store & generate local QR Code
    final hive = ref.read(hiveStorageProvider);
    OfflineSyncManager? syncManager;
    try {
      syncManager = ref.read(offlineSyncManagerProvider);
    } catch (_) {}

    final localEntry = await TournamentOfflineStore.submitAthleteApplicationOfflineSafe(
      hive: hive,
      syncManager: syncManager,
      tournamentId: widget.tournamentId,
      athleteId: athleteId,
      athleteName: athleteName,
      weightCategory: _selectedWeightClass,
      arm: _armChoice,
      guestCount: _guestCount,
    );

    // 2. Attempt online registration in background without ever failing or losing input
    try {
      await ref.read(tournamentProvider.notifier).registerAthlete(
            eventId: widget.tournamentId,
            athleteId: athleteId,
            division: _selectedDivision,
            weightClass: _selectedWeightClass,
            arm: _armChoice,
          );
    } catch (_) {
      // Offline sync queue already holds SUBMIT_ATHLETE_APPLICATION — never show an error!
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;
    final currentEvent = ref.read(eventDetailProvider(widget.tournamentId)).valueOrNull;
    final feeCents = (currentEvent?['registrationFeeCents'] as num?)?.toInt() ?? 0;
    final feePkr = (currentEvent?['entryFeePkr'] as num?)?.toInt() ?? 0;
    final isFreeEvent = feeCents <= 0 && feePkr <= 0;
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          isFreeEvent
              ? 'Registration Confirmed! Your official QR credential is ready.'
              : 'Registration Recorded! Complete event fee check-in to finalize.',
        ),
        backgroundColor: AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _showOfflineSafeSubmittedQrDialog(localEntry);
  }

  Future<void> _showOfflineSafeSubmittedQrDialog(Map<String, dynamic> localEntry) async {
    final qrData = (localEntry['qrCode'] ?? localEntry['qrCodePayload'] ?? 'ARMSPHERE-QR').toString();
    final armLabel = ArmSphereFormatters.formatArmLabel(
      (localEntry['registeredArm'] ?? localEntry['arm'] ?? _armChoice).toString(),
    );
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppTheme.overlayG6Barrier,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.overlayG6Surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.overlayG6Border, width: 1.4),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'REGISTRATION CONFIRMED',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppTheme.emerald,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${localEntry['athleteName']} • ${localEntry['registeredWeightLabel'] ?? localEntry['weightCategory'] ?? _selectedWeightClass} ($armLabel)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ArmSphereQrMatrixView(
                data: qrData,
                size: 160,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Official Local Tournament QR:\n$qrData',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.fontMono,
                fontSize: 11,
                color: AppTheme.goldPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Saved locally for instant offline weigh-in & referee table verification. Auto-syncs to server in the background.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                context.push('/tournament/${widget.tournamentId}/qr');
              }
            },
            child: const Text(
              'OPEN QR PASSPORT',
              style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.w800),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted && context.canPop()) {
                context.pop();
              }
            },
            child: const Text(
              'DONE',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
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

    // Warm athlete profile provider so canonical profile ID is ready on submit
    ref.watch(athleteProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        flexibleSpace: const CrystalHeaderStageBar(domain: ArmSphereStageDomain.events),
        leading: const CrystalBackButton(fallbackRoute: '/tournaments'),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Official Event Registration',
            style: TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        actions: [
          CrystalIconPillButton(
            icon: Icons.qr_code_2_rounded,
            iconColor: AppTheme.emerald,
            tooltip: 'View Event QR Passport',
            onPressed: () => context.push('/tournament/${widget.tournamentId}/qr'),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CrystalStageBackdrop(domain: ArmSphereStageDomain.events),
          SafeArea(
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

                      // Category-First Quick-Select Matrix Cards
                      ElevatedActionCard(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        borderColor: AppTheme.goldPrimary.withValues(alpha: 0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SANCTIONED BRACKET CATEGORIES',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                    letterSpacing: 0.8,
                                    color: AppTheme.goldPrimary,
                                  ),
                                ),
                                StatusChip(
                                  label: 'DOUBLE ELIMINATION',
                                  color: AppTheme.cyan,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tap a category card to quick-select your weight class & arm, or customize below.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Builder(
                              builder: (context) {
                                final eventData = eventAsync.valueOrNull;
                                final rawCats = (eventData?['weightCategories'] is List)
                                    ? (eventData!['weightCategories'] as List).whereType<Map>().toList()
                                    : const <Map>[];
                                final dynamicPresets = rawCats.isNotEmpty
                                    ? rawCats
                                        .where((c) => c['enabled'] != false)
                                        .map((c) => (
                                              (c['division'] ?? 'SENIOR').toString().toUpperCase(),
                                              (c['weightLabel'] ?? c['label'] ?? '-85kg').toString(),
                                              (c['arm'] ?? 'RIGHT').toString().toUpperCase(),
                                            ))
                                        .toList()
                                    : const <(String, String, String)>[
                                        ('SENIOR', '-70kg', 'RIGHT'),
                                        ('SENIOR', '-78kg', 'RIGHT'),
                                        ('SENIOR', '-85kg', 'RIGHT'),
                                        ('SENIOR', '-85kg', 'BOTH'),
                                        ('SENIOR', '-95kg', 'RIGHT'),
                                        ('SENIOR', '+95kg', 'BOTH'),
                                      ];
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final preset in dynamicPresets)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedDivision = preset.$1;
                                            _selectedWeightClass = preset.$2;
                                            _armChoice = preset.$3;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: (_selectedDivision == preset.$1 &&
                                                      _selectedWeightClass == preset.$2 &&
                                                      _armChoice == preset.$3)
                                                  ? AppTheme.goldPrimary
                                                  : const Color(0x33FFFFFF),
                                              width: (_selectedDivision == preset.$1 &&
                                                      _selectedWeightClass == preset.$2 &&
                                                      _armChoice == preset.$3)
                                                  ? 1.4
                                                  : 1.0,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${preset.$2} • ${ArmSphereFormatters.formatArmLabel(preset.$3)}',
                                                style: const TextStyle(
                                                  fontFamily: AppTheme.fontDisplay,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${ArmSphereFormatters.formatDivisionLabel(preset.$1)} • Open',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppTheme.emerald,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),

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
              isLoading: _isLoading,
              disclaimerText: 'Official sanctioned entry • Bracket seeded upon check-in',
              onPrimaryAction: (_isLoading || isEventLoading) ? null : _submit,
            ),
          ],
        ),
      ),
        ],
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
        color: AppTheme.glassSurface,
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
              color: AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.borderTitanium, width: 0.8),
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.goldPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DUAL-ARM REGISTRATION CART (2 BRACKET ENTRIES):',
                    style: TextStyle(
                      fontFamily: AppTheme.fontDisplay,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.goldPrimary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Entry 1: ${_formatDivision(division)} · $weightClass · Right Arm Bracket\n'
                    '• Entry 2: ${_formatDivision(division)} · $weightClass · Left Arm Bracket',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontBody,
                      fontSize: 11.5,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
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
