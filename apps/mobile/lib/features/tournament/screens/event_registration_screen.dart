import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/offline_sync.dart';
import '../../../core/providers/athlete_provider.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/sticky_bottom_action_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../services/tournament_offline_store.dart';
import 'tournament_screens.dart';

class EventRegistrationScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final Map<String, dynamic>? initialEvent;

  const EventRegistrationScreen({
    super.key,
    required this.tournamentId,
    this.initialEvent,
  });

  @override
  ConsumerState<EventRegistrationScreen> createState() =>
      _EventRegistrationScreenState();
}

class _EventRegistrationScreenState
    extends ConsumerState<EventRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedDivisionId = '';
  String _selectedDivision = 'SENIOR';
  String _selectedWeightClass = '';
  String _armChoice = 'RIGHT';
  int _guestCount = 0;
  bool _isLoading = false;
  bool _didHydrateSelection = false;

  String _currentAthleteId() {
    final profile = ref.read(athleteProfileProvider).valueOrNull;
    final profileId = profile?['id']?.toString();
    if (profileId != null && profileId.isNotEmpty) {
      return profileId;
    }
    final auth = ref.read(authProvider);
    final user =
        auth.userProfile?['user'] as Map<String, dynamic>? ??
        auth.userProfile ??
        {};
    return (user['athleteProfileId'] ??
            user['id'] ??
            user['userId'] ??
            'ath-pk-local')
        .toString();
  }

  String _currentAthleteName() {
    final profile = ref.read(athleteProfileProvider).valueOrNull;
    final name =
        profile?['displayName'] ?? profile?['fullName'] ?? profile?['name'];
    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }
    final auth = ref.read(authProvider);
    final user =
        auth.userProfile?['user'] as Map<String, dynamic>? ??
        auth.userProfile ??
        {};
    return (user['displayName'] ??
            user['fullName'] ??
            user['name'] ??
            'ArmSphere Athlete')
        .toString();
  }

  String _normalizeArmCode(String rawArm) {
    final upper = rawArm.trim().toUpperCase();
    if (upper.startsWith('L')) return 'LEFT';
    if (upper == 'BOTH') return 'BOTH';
    return 'RIGHT';
  }

  void _ensureSelectionHydrated({
    required List<Map<String, dynamic>> realDivisions,
    required Map<String, dynamic>? existingRegistration,
  }) {
    if (realDivisions.isEmpty) return;

    if (!_didHydrateSelection) {
      if (existingRegistration != null) {
        final regDivId = (existingRegistration['divisionId'] ?? '')
            .toString()
            .trim();
        final regWeight =
            (existingRegistration['registeredWeightLabel'] ??
                    existingRegistration['weightCategory'] ??
                    existingRegistration['weightClass'] ??
                    existingRegistration['divisionName'] ??
                    '')
                .toString()
                .trim();
        final regArm = _normalizeArmCode(
          (existingRegistration['registeredArm'] ??
                  existingRegistration['arm'] ??
                  'RIGHT')
              .toString(),
        );
        final regGuests =
            (existingRegistration['guestCount'] as num?)?.toInt() ?? 0;

        Map<String, dynamic>? matched;
        if (regDivId.isNotEmpty) {
          for (final d in realDivisions) {
            if ((d['divisionId'] ?? '').toString() == regDivId) {
              matched = d;
              break;
            }
          }
        }
        if (matched == null && regWeight.isNotEmpty) {
          for (final d in realDivisions) {
            final dWeight = (d['weightClass'] ?? '').toString().trim();
            final dArm = _normalizeArmCode(
              (d['armCode'] ?? d['arm'] ?? 'RIGHT').toString(),
            );
            if (dWeight.toLowerCase() == regWeight.toLowerCase() &&
                dArm == regArm) {
              matched = d;
              break;
            }
          }
        }
        if (matched == null && regWeight.isNotEmpty) {
          for (final d in realDivisions) {
            final dWeight = (d['weightClass'] ?? '').toString().trim();
            if (dWeight.toLowerCase() == regWeight.toLowerCase()) {
              matched = d;
              break;
            }
          }
        }

        final chosen = matched ?? realDivisions.first;
        _selectedDivisionId = (chosen['divisionId'] ?? '').toString();
        _selectedDivision = (chosen['division'] ?? 'SENIOR').toString();
        _selectedWeightClass = (chosen['weightClass'] ?? '').toString();
        _armChoice = _normalizeArmCode(
          (chosen['armCode'] ?? chosen['arm'] ?? 'RIGHT').toString(),
        );
        _guestCount = regGuests;
        _didHydrateSelection = true;
        return;
      }

      final first = realDivisions.first;
      _selectedDivisionId = (first['divisionId'] ?? '').toString();
      _selectedDivision = (first['division'] ?? 'SENIOR').toString();
      _selectedWeightClass = (first['weightClass'] ?? '').toString();
      _armChoice = _normalizeArmCode(
        (first['armCode'] ?? first['arm'] ?? 'RIGHT').toString(),
      );
      _didHydrateSelection = true;
      return;
    }

    final exists = realDivisions.any(
      (d) => (d['divisionId'] ?? '').toString() == _selectedDivisionId,
    );
    if (!exists) {
      final first = realDivisions.first;
      _selectedDivisionId = (first['divisionId'] ?? '').toString();
      _selectedDivision = (first['division'] ?? 'SENIOR').toString();
      _selectedWeightClass = (first['weightClass'] ?? '').toString();
      _armChoice = _normalizeArmCode(
        (first['armCode'] ?? first['arm'] ?? 'RIGHT').toString(),
      );
    }
  }

  void _selectDivisionItem(Map<String, dynamic> division) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDivisionId = (division['divisionId'] ?? '').toString();
      _selectedDivision = (division['division'] ?? 'SENIOR').toString();
      _selectedWeightClass = (division['weightClass'] ?? '').toString();
      _armChoice = _normalizeArmCode(
        (division['armCode'] ?? division['arm'] ?? 'RIGHT').toString(),
      );
      _didHydrateSelection = true;
    });
  }

  String _formatEntryFeeLabel(Map<String, dynamic>? event) {
    if (event == null) return 'Free Entry';
    final feePkr =
        (event['entryFeePkr'] as num?)?.toInt() ??
        ((event['step1Config'] is Map)
            ? ((event['step1Config'] as Map)['entryFeePkr'] as num?)?.toInt()
            : null);
    if (feePkr != null) {
      return feePkr <= 0 ? 'Free Entry (0 PKR)' : 'PKR $feePkr';
    }
    final feeCents = (event['registrationFeeCents'] as num?)?.toInt() ?? 0;
    if (feeCents <= 0) return 'Free Entry';
    return formatEventFee(feeCents);
  }

  String _formatMatchFormatLabel(Map<String, dynamic>? event) {
    final step1 = (event?['step1Config'] is Map)
        ? Map<String, dynamic>.from(event!['step1Config'] as Map)
        : const <String, dynamic>{};
    final rawSub =
        (event?['eliminationSubFormat'] ??
                step1['eliminationSubFormat'] ??
                event?['formatCategory'] ??
                step1['formatCategory'] ??
                'DOUBLE_ELIMINATION')
            .toString()
            .trim()
            .toUpperCase();
    return rawSub.replaceAll('_', ' ');
  }

  int _resolveMaxGuests(Map<String, dynamic>? event) {
    if (event == null) return 2;
    final step1 = (event['step1Config'] is Map)
        ? Map<String, dynamic>.from(event['step1Config'] as Map)
        : const <String, dynamic>{};
    final gate = (event['spectatorGateConfig'] is Map)
        ? Map<String, dynamic>.from(event['spectatorGateConfig'] as Map)
        : (step1['spectatorGateConfig'] is Map)
        ? Map<String, dynamic>.from(step1['spectatorGateConfig'] as Map)
        : const <String, dynamic>{};
    return ((event['maxGuestsPerAthlete'] ??
                event['guestsPerCompetingAthlete'] ??
                event['athleteGuestAllowance'] ??
                step1['maxGuestsPerAthlete'] ??
                gate['allowedGuestsPerAthlete'])
            as num?)
        ?.toInt() ??
        2;
  }

  Future<void> _submit({required bool isUpdating}) async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedWeightClass.trim().isEmpty) return;

    final athleteId = _currentAthleteId();
    final athleteName = _currentAthleteName();

    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();

    final hive = ref.read(hiveStorageProvider);
    OfflineSyncManager? syncManager;
    try {
      syncManager = ref.read(offlineSyncManagerProvider);
    } catch (_) {}

    final authProfile = ref.read(authProvider).userProfile;
    final nestedUser = authProfile?['user'];
    final effectiveUserId = (authProfile?['id'] ??
            authProfile?['userId'] ??
            (nestedUser is Map ? nestedUser['id'] : null) ??
            athleteId)
        .toString();
    final canonicalProfileQr = TournamentOfflineStore.buildSettingsIdentityQr(
      authProfile ?? <String, dynamic>{'id': effectiveUserId},
    );

    final localEntry =
        await TournamentOfflineStore.submitAthleteApplicationOfflineSafe(
          hive: hive,
          syncManager: syncManager,
          tournamentId: widget.tournamentId,
          athleteId: athleteId,
          userId: effectiveUserId,
          profileQrCode: canonicalProfileQr,
          athleteName: athleteName,
          weightCategory: _selectedWeightClass,
          arm: _armChoice,
          division: _selectedDivision,
          divisionId: _selectedDivisionId,
          guestCount: _guestCount,
          elo:
              (authProfile?['eloRating'] as num?)?.toInt() ??
              (authProfile?['elo'] as num?)?.toInt() ??
              1000,
        );

    try {
      await ref
          .read(tournamentProvider.notifier)
          .registerAthlete(
            eventId: widget.tournamentId,
            athleteId: athleteId,
            division: _selectedDivision,
            weightClass: _selectedWeightClass,
            arm: _armChoice,
          );
    } catch (_) {
      // Offline sync queue already holds SUBMIT_ATHLETE_APPLICATION
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    ref.invalidate(eventDetailProvider(widget.tournamentId));
    ref.invalidate(myRegistrationsProvider);
    ref.invalidate(eventRegistrationsProvider(widget.tournamentId));
    ref.invalidate(tournamentProvider);

    if (!mounted) return;
    final armDisplay = ArmSphereFormatters.formatArmLabel(_armChoice);
    ScaffoldMessenger.of(context).showSnackBar(
      CrystalSnackBar(
        content: Text(
          isUpdating
              ? 'Division updated to $_selectedWeightClass ($armDisplay). Present your Profile QR Code at weigh-in, venue entrance, and your assigned table.'
              : 'Registered for $_selectedWeightClass ($armDisplay). Present your Profile QR Code at weigh-in, venue entrance, and your assigned table.',
        ),
        backgroundColor: AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _showOfflineSafeSubmittedConfirmationDialog(
      localEntry,
      isUpdating: isUpdating,
    );
  }

  Future<void> _showOfflineSafeSubmittedConfirmationDialog(
    Map<String, dynamic> localEntry, {
    required bool isUpdating,
  }) async {
    final armLabel = ArmSphereFormatters.formatArmLabel(
      (localEntry['registeredArm'] ?? localEntry['arm'] ?? _armChoice)
          .toString(),
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
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.emerald,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isUpdating ? 'DIVISION UPDATED' : 'REGISTRATION CONFIRMED',
                style: const TextStyle(
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
              'Confirmed • ${localEntry['registeredWeightLabel'] ?? localEntry['weightCategory'] ?? _selectedWeightClass} • $armLabel',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${localEntry['athleteName']}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.goldPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.emerald.withValues(alpha: 0.45),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    color: AppTheme.emerald,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Present your Profile QR Code at weigh-in, venue entrance, and your assigned table.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                context.push('/settings');
              }
            },
            child: const Text(
              'VIEW PROFILE QR',
              style: TextStyle(
                color: AppTheme.goldPrimary,
                fontWeight: FontWeight.w800,
              ),
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
                context.pop(localEntry);
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

  @override
  Widget build(BuildContext context) {
    final hive = ref.watch(hiveStorageProvider);
    final eventAsync = ref.watch(eventDetailProvider(widget.tournamentId));
    final tournamentState = ref.watch(tournamentProvider);
    final myRegistrationsAsync = ref.watch(myRegistrationsProvider);

    // Warm athlete profile provider so canonical profile ID is ready on submit
    ref.watch(athleteProfileProvider);

    final resolvedEvent =
        TournamentOfflineStore.getReleasedTournamentById(
          hive: hive,
          tournamentId: widget.tournamentId,
          serverEvents: [
            ...tournamentState.events,
            if (eventAsync.valueOrNull != null) eventAsync.valueOrNull!,
          ],
          fallbackEvent: eventAsync.valueOrNull ?? widget.initialEvent,
        ) ??
        eventAsync.valueOrNull ??
        widget.initialEvent;

    final isEventLoading = eventAsync.isLoading && resolvedEvent == null;
    final realDivisions = resolvedEvent != null
        ? TournamentOfflineStore.extractRealTournamentDivisions(resolvedEvent)
        : <Map<String, dynamic>>[];

    final authProfile =
        ref.watch(authProvider).userProfile ?? const <String, dynamic>{};
    final nestedUser = authProfile['user'];
    final currentUserId = (authProfile['id'] ??
            authProfile['userId'] ??
            (nestedUser is Map ? nestedUser['id'] : null) ??
            _currentAthleteId())
        .toString();
    final canonicalProfileQr = TournamentOfflineStore.buildSettingsIdentityQr(
      authProfile,
    );

    final existingRegistration =
        TournamentOfflineStore.findAthleteRegistrationForTournament(
          hive: hive,
          tournamentId: widget.tournamentId,
          tournament: resolvedEvent,
          athleteId: _currentAthleteId(),
          userId: currentUserId,
          profileQrCode: canonicalProfileQr,
          myRegistrations: myRegistrationsAsync.valueOrNull,
        );
    final isUpdating = existingRegistration != null;

    _ensureSelectionHydrated(
      realDivisions: realDivisions,
      existingRegistration: existingRegistration,
    );

    final feeLabel = _formatEntryFeeLabel(resolvedEvent);
    final formatLabel = _formatMatchFormatLabel(resolvedEvent);
    final maxGuests = _resolveMaxGuests(resolvedEvent);
    final appliedList = (resolvedEvent?['appliedAthletes'] is List)
        ? (resolvedEvent!['appliedAthletes'] as List)
        : const [];
    final registeredCount = appliedList.isNotEmpty
        ? appliedList.length
        : ((resolvedEvent?['registeredCount'] as num?)?.toInt() ?? 0);
    final capacity = (resolvedEvent?['capacity'] as num?)?.toInt() ?? 64;
    final remainingSlots = (capacity - registeredCount) < 0
        ? 0
        : (capacity - registeredCount);

    final distinctWeightClasses = <String>{
      for (final d in realDivisions)
        if ((d['weightClass'] ?? '').toString().trim().isNotEmpty)
          (d['weightClass'] ?? '').toString().trim(),
    }.toList();

    final availableArmsForWeight = <String>{
      for (final d in realDivisions)
        if ((d['weightClass'] ?? '').toString().trim() == _selectedWeightClass)
          _normalizeArmCode((d['armCode'] ?? d['arm'] ?? 'RIGHT').toString()),
    }.toList();

    final selectedDivisionLabel = _selectedWeightClass.isNotEmpty
        ? '$_selectedWeightClass • ${ArmSphereFormatters.formatArmLabel(_armChoice)}'
        : 'Select a Created Division';

    final venueSummary = [
      resolvedEvent?['venue'] ??
          resolvedEvent?['venueName'] ??
          resolvedEvent?['location'],
      resolvedEvent?['city'],
      resolvedEvent?['province'],
    ]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => e.toString().trim())
        .toSet()
        .join(', ');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        flexibleSpace: const CrystalHeaderStageBar(
          domain: ArmSphereStageDomain.events,
        ),
        leading: const CrystalBackButton(fallbackRoute: '/tournaments'),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            isUpdating
                ? 'Update Tournament Division'
                : 'Official Event Registration',
            style: const TextStyle(
              fontFamily: AppTheme.fontDisplay,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
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
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      AppTheme.space16,
                      AppTheme.space16,
                      MediaQuery.viewInsetsOf(context).bottom +
                          AppTheme.space24,
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isUpdating) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.overlayG6Surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.emerald.withValues(
                                    alpha: 0.65,
                                  ),
                                  width: 1.3,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: AppTheme.emerald,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ACTIVE REGISTRATION • UPDATE MODE',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11,
                                            letterSpacing: 0.6,
                                            color: AppTheme.emerald,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Currently registered in ${(existingRegistration['registeredWeightLabel'] ?? existingRegistration['weightCategory'] ?? existingRegistration['weightClass'] ?? _selectedWeightClass)} • ${ArmSphereFormatters.formatArmLabel((existingRegistration['registeredArm'] ?? existingRegistration['arm'] ?? _armChoice).toString())}',
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),
                          ],

                          // Tournament Overview & Real Metadata Card
                          if (resolvedEvent != null) ...[
                            ElevatedActionCard(
                              padding: const EdgeInsets.all(AppTheme.space16),
                              borderColor: AppTheme.overlayG6Border,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          resolvedEvent['name']?.toString() ??
                                              'Sanctioned Tournament',
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontDisplay,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusChip(
                                        label: feeLabel,
                                        color: AppTheme.goldPrimary,
                                      ),
                                    ],
                                  ),
                                  if (venueSummary.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 13,
                                          color: AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            venueSummary,
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
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      StatusChip(
                                        label:
                                            '$registeredCount / $capacity Athletes • $remainingSlots Slots Open',
                                        color: AppTheme.emerald,
                                      ),
                                      StatusChip(
                                        label: formatLabel,
                                        color: AppTheme.cyan,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),
                          ],

                          // Created Bracket Categories Matrix (ONLY Real Created Divisions)
                          ElevatedActionCard(
                            padding: const EdgeInsets.all(AppTheme.space16),
                            borderColor: AppTheme.goldPrimary.withValues(
                              alpha: 0.4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'CREATED TOURNAMENT DIVISIONS',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11.5,
                                          letterSpacing: 0.8,
                                          color: AppTheme.goldPrimary,
                                        ),
                                      ),
                                    ),
                                    StatusChip(
                                      label: '${realDivisions.length} ACTIVE',
                                      color: AppTheme.emerald,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Select from the official divisions created by the host organization for this tournament.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (realDivisions.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.overlayG6Surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.overlayG6Border,
                                      ),
                                    ),
                                    child: const Text(
                                      'No active divisions have been published for this tournament yet.',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final div in realDivisions)
                                        Builder(
                                          builder: (context) {
                                            final divId =
                                                (div['divisionId'] ?? '')
                                                    .toString();
                                            final divWeight =
                                                (div['weightClass'] ?? '')
                                                    .toString();
                                            final divArm = _normalizeArmCode(
                                              (div['armCode'] ??
                                                      div['arm'] ??
                                                      'RIGHT')
                                                  .toString(),
                                            );
                                            final isSelected =
                                                _selectedDivisionId == divId ||
                                                (_selectedWeightClass ==
                                                        divWeight &&
                                                    _armChoice == divArm);
                                            return GestureDetector(
                                              onTap: () =>
                                                  _selectDivisionItem(div),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 140,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppTheme.goldPrimary
                                                            .withValues(
                                                              alpha: 0.16,
                                                            )
                                                      : AppTheme
                                                            .overlayG6Surface,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? AppTheme.goldPrimary
                                                        : AppTheme
                                                              .overlayG6Border,
                                                    width: isSelected
                                                        ? 1.5
                                                        : 1.0,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      (div['label'] ??
                                                              '$divWeight • ${ArmSphereFormatters.formatArmLabel(divArm)}')
                                                          .toString(),
                                                      style: TextStyle(
                                                        fontFamily: AppTheme
                                                            .fontDisplay,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: isSelected
                                                            ? AppTheme
                                                                  .goldPrimary
                                                            : AppTheme
                                                                  .textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      isSelected
                                                          ? 'Selected Division ✓'
                                                          : 'Sanctioned Bracket',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w700
                                                            : FontWeight.w500,
                                                        color: isSelected
                                                            ? AppTheme.emerald
                                                            : AppTheme
                                                                  .textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // Opaque G6 Division / Weight / Arm / Guest Selectors
                          if (realDivisions.isNotEmpty) ...[
                            ElevatedActionCard(
                              padding: const EdgeInsets.all(AppTheme.space16),
                              borderColor: AppTheme.overlayG6Border,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Official Division Selector',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey(
                                      'division_selector_$_selectedDivisionId',
                                    ),
                                    initialValue:
                                        realDivisions.any(
                                          (d) =>
                                              (d['divisionId'] ?? '')
                                                  .toString() ==
                                              _selectedDivisionId,
                                        )
                                        ? _selectedDivisionId
                                        : (realDivisions.first['divisionId'] ??
                                                  '')
                                              .toString(),
                                    dropdownColor: AppTheme.overlayG6Surface,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontBody,
                                      color: AppTheme.textPure,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppTheme.overlayG6Surface,
                                      prefixIcon: const Icon(
                                        Icons.emoji_events_outlined,
                                        size: 20,
                                        color: AppTheme.goldPrimary,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppTheme.overlayG6Border,
                                        ),
                                      ),
                                    ),
                                    items: [
                                      for (final div in realDivisions)
                                        DropdownMenuItem<String>(
                                          value: (div['divisionId'] ?? '')
                                              .toString(),
                                          child: Text(
                                            (div['label'] ?? '').toString(),
                                          ),
                                        ),
                                    ],
                                    onChanged: (val) {
                                      if (val == null) return;
                                      final matched = realDivisions.firstWhere(
                                        (d) =>
                                            (d['divisionId'] ?? '')
                                                .toString() ==
                                            val,
                                        orElse: () => realDivisions.first,
                                      );
                                      _selectDivisionItem(matched);
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  const Text(
                                    'Weight Category',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey(
                                      'weight_selector_$_selectedWeightClass',
                                    ),
                                    initialValue:
                                        distinctWeightClasses.contains(
                                          _selectedWeightClass,
                                        )
                                        ? _selectedWeightClass
                                        : distinctWeightClasses.first,
                                    dropdownColor: AppTheme.overlayG6Surface,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontBody,
                                      color: AppTheme.textPure,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppTheme.overlayG6Surface,
                                      prefixIcon: const Icon(
                                        Icons.scale_outlined,
                                        size: 20,
                                        color: AppTheme.goldPrimary,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppTheme.overlayG6Border,
                                        ),
                                      ),
                                    ),
                                    items: [
                                      for (final w in distinctWeightClasses)
                                        DropdownMenuItem<String>(
                                          value: w,
                                          child: Text(w),
                                        ),
                                    ],
                                    onChanged: (val) {
                                      if (val == null) return;
                                      final matched = realDivisions.firstWhere(
                                        (d) =>
                                            (d['weightClass'] ?? '')
                                                    .toString() ==
                                                val &&
                                            _normalizeArmCode(
                                                  (d['armCode'] ??
                                                          d['arm'] ??
                                                          'RIGHT')
                                                      .toString(),
                                                ) ==
                                                _armChoice,
                                        orElse: () => realDivisions.firstWhere(
                                          (d) =>
                                              (d['weightClass'] ?? '')
                                                  .toString() ==
                                              val,
                                          orElse: () => realDivisions.first,
                                        ),
                                      );
                                      _selectDivisionItem(matched);
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  const Text(
                                    'Competition Arm',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontDisplay,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey(
                                      'arm_selector_${_selectedWeightClass}_$_armChoice',
                                    ),
                                    initialValue:
                                        availableArmsForWeight.contains(
                                          _armChoice,
                                        )
                                        ? _armChoice
                                        : (availableArmsForWeight.isNotEmpty
                                              ? availableArmsForWeight.first
                                              : 'RIGHT'),
                                    dropdownColor: AppTheme.overlayG6Surface,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontBody,
                                      color: AppTheme.textPure,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppTheme.overlayG6Surface,
                                      prefixIcon: const Icon(
                                        Icons.pan_tool_outlined,
                                        size: 20,
                                        color: AppTheme.goldPrimary,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppTheme.overlayG6Border,
                                        ),
                                      ),
                                    ),
                                    items: [
                                      for (final armCode
                                          in availableArmsForWeight)
                                        DropdownMenuItem<String>(
                                          value: armCode,
                                          child: Text(
                                            '${ArmSphereFormatters.formatArmLabel(armCode)} Bracket',
                                          ),
                                        ),
                                    ],
                                    onChanged: (val) {
                                      if (val == null) return;
                                      final matched = realDivisions.firstWhere(
                                        (d) =>
                                            (d['weightClass'] ?? '')
                                                    .toString() ==
                                                _selectedWeightClass &&
                                            _normalizeArmCode(
                                                  (d['armCode'] ??
                                                          d['arm'] ??
                                                          'RIGHT')
                                                      .toString(),
                                                ) ==
                                                val,
                                        orElse: () => realDivisions.first,
                                      );
                                      _selectDivisionItem(matched);
                                    },
                                  ),

                                  if (maxGuests > 0) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.overlayG6Surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.overlayG6Border,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Spectator Guests Allowance',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        AppTheme.fontDisplay,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  'Up to $maxGuests accompanied guests verified via your Profile QR',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: _guestCount > 0
                                                    ? () => setState(
                                                        () => _guestCount--,
                                                      )
                                                    : null,
                                                icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                ),
                                              ),
                                              Text(
                                                '$_guestCount',
                                                style: const TextStyle(
                                                  fontFamily:
                                                      AppTheme.fontDisplay,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15,
                                                  color: AppTheme.goldPrimary,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed:
                                                    _guestCount < maxGuests
                                                    ? () => setState(
                                                        () => _guestCount++,
                                                      )
                                                    : null,
                                                icon: const Icon(
                                                  Icons.add_circle_outline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),
                          ],

                          // Registration Summary & Permanent Profile QR Notice Card
                          _RegistrationSummaryCard(
                            selectedDivisionLabel: selectedDivisionLabel,
                            feeLabel: feeLabel,
                            formatLabel: formatLabel,
                            guestCount: _guestCount,
                            isUpdating: isUpdating,
                            isLoading: isEventLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                StickyBottomActionBar(
                  primaryActionLabel: isEventLoading
                      ? 'Loading Event Details...'
                      : (isUpdating
                            ? 'Update Registration'
                            : 'Apply to Compete — $feeLabel'),
                  primaryActionIcon: isUpdating
                      ? Icons.edit_note_rounded
                      : Icons.how_to_reg_outlined,
                  isLoading: _isLoading,
                  disclaimerText:
                      'Verified via your single permanent Profile QR Code at weigh-in, gate & table',
                  onPrimaryAction:
                      (_isLoading || isEventLoading || realDivisions.isEmpty)
                      ? null
                      : () => _submit(isUpdating: isUpdating),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationSummaryCard extends StatelessWidget {
  final String selectedDivisionLabel;
  final String feeLabel;
  final String formatLabel;
  final int guestCount;
  final bool isUpdating;
  final bool isLoading;

  const _RegistrationSummaryCard({
    required this.selectedDivisionLabel,
    required this.feeLabel,
    required this.formatLabel,
    required this.guestCount,
    required this.isUpdating,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('registration_summary_card'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.overlayG6Surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              StatusChip(
                label: isUpdating ? 'UPDATE MODE' : 'SANCTIONED ENTRY',
                type: StatusType.success,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.obsidian,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.overlayG6Border, width: 0.9),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_kabaddi,
                  size: 16,
                  color: AppTheme.goldPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$selectedDivisionLabel • $formatLabel',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Accompanied Spectator Guests',
                style: TextStyle(
                  fontFamily: AppTheme.fontBody,
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '$guestCount Guests',
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                isLoading ? 'Loading...' : feeLabel,
                key: const ValueKey('registration_total_fee_text'),
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.goldPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppTheme.borderSubtle, height: 1),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                size: 16,
                color: AppTheme.emerald,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Present your permanent Profile QR Code at weigh-in, venue gate, and your assigned referee table.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
