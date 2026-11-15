import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_slash_painter.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/skeleton_placeholder.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/main_shell_screen.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../auth/providers/auth_provider.dart';

const List<String> _kPakistanProvinces = [
  'Punjab',
  'Sindh',
  'KPK',
  'Balochistan',
  'Islamabad',
  'Gilgit-Baltistan',
  'Azad Kashmir',
];

/// Tournament Operator Landing Dashboard
///
/// Dedicated operational command center for event directors & arena operators:
/// - Full Sanctioned Tournament Creation & Publishing modal.
/// - Active Tournament selector & Event War Room launcher.
/// - Live Arena Tables & Queue status monitoring (`match_tables` & `tournament_table_queue`).
/// - Official Weigh-In scale & rubber-stamp desk shortcut.
/// - Bracket generation & seeding progression overview.
/// - Podium ceremony & awards launcher.
class TournamentOperatorDashboardScreen extends ConsumerStatefulWidget {
  const TournamentOperatorDashboardScreen({super.key});

  @override
  ConsumerState<TournamentOperatorDashboardScreen> createState() =>
      _TournamentOperatorDashboardScreenState();
}

class _TournamentOperatorDashboardScreenState
    extends ConsumerState<TournamentOperatorDashboardScreen> {
  String? _selectedTournamentId;

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      final dt = DateTime.parse(dateVal.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateVal.toString();
    }
  }

  Future<void> _showCreateTournamentModal(
    BuildContext context, {
    Map<String, dynamic>? existingEvent,
  }) async {
    HapticFeedback.mediumImpact();
    final authProfile = ref.read(authProvider).userProfile ?? {};
    final userProvince = authProfile['province']?.toString().trim() ?? '';
    String selectedProvince = _kPakistanProvinces.firstWhere(
      (p) => p.toLowerCase() == userProvince.toLowerCase(),
      orElse: () => _kPakistanProvinces.first,
    );
    if (existingEvent?['province'] != null &&
        _kPakistanProvinces.contains(existingEvent!['province'].toString())) {
      selectedProvince = existingEvent['province'].toString();
    }

    int wizardStep = 0;
    final hostOrgNameCtrl = TextEditingController(
      text: (existingEvent?['organizationName'] ??
              authProfile['organizationName'] ??
              'Pakistan Armwrestling Federation (PAFF)')
          .toString(),
    );
    final nameCtrl = TextEditingController(
      text: (existingEvent?['name'] ?? 'PAF Championship Cup 2026').toString(),
    );
    final descriptionCtrl = TextEditingController(
      text: (existingEvent?['description'] ??
              'Official sanctioned championship with QR weigh-ins, double-elimination brackets, and live table dispatch.')
          .toString(),
    );
    final cityCtrl = TextEditingController(
      text: (existingEvent?['city'] ??
              (selectedProvince == 'Sindh'
                  ? 'Karachi'
                  : selectedProvince == 'KPK'
                      ? 'Peshawar'
                      : selectedProvince == 'Islamabad'
                          ? 'Islamabad'
                          : 'Lahore'))
          .toString(),
    );
    final venueCtrl = TextEditingController(
      text: (existingEvent?['venue'] ??
              existingEvent?['venueName'] ??
              'Federation Championship Arena')
          .toString(),
    );
    final capacityCtrl = TextEditingController(
      text: (existingEvent?['capacity'] ?? '128').toString(),
    );
    final initialFeeCents =
        (existingEvent?['registrationFeeCents'] as num?)?.toInt() ?? 0;
    final feeCtrl = TextEditingController(
      text: (initialFeeCents / 100).round().toString(),
    );

    String selectedBackdrop = 'ARENA_COLOSSEUM';
    String eliminationFormat = 'DOUBLE_ELIMINATION';
    final Set<String> selectedDivisions = {'MEN_SENIOR', 'JUNIOR_U21'};
    final Set<String> selectedArms = {'RIGHT', 'LEFT'};
    final Set<String> selectedWeights = {
      '-65kg',
      '-75kg',
      '-85kg',
      '-95kg',
      '-105kg',
      '+105kg',
    };
    int tableCount = 2;
    bool runningFouls = true;
    bool strapAfterFirstSlip = true;
    bool refereeGripAfter30s = true;
    String currency = 'CAD';
    String paymentMethod = 'MANUAL_QR';
    bool publishImmediately = true;
    bool autoCreateTables = true;
    bool isSubmitting = false;

    final now = DateTime.now();
    DateTime regStart = now.subtract(const Duration(hours: 2));
    DateTime regEnd = now.add(const Duration(days: 14));
    DateTime eventStart = now.add(const Duration(days: 15));
    DateTime eventEnd = now.add(const Duration(days: 16));

    final createdEvent = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> pickDate({
              required DateTime initial,
              required ValueChanged<DateTime> onPicked,
            }) async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: initial,
                firstDate: now.subtract(const Duration(days: 7)),
                lastDate: now.add(const Duration(days: 730)),
              );
              if (picked != null) {
                setModalState(() => onPicked(picked));
              }
            }

            const stepLabels = [
              '1. Identity',
              '2. Venue',
              '3. Brackets',
              '4. Arena',
              '5. Fees',
            ];

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.90,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xF5070A11),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: const Color(0x66D4AF37), width: 1.2),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x73D4AF37)),
                            ),
                            child: const Icon(
                              Icons.emoji_events_outlined,
                              color: AppTheme.goldPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  existingEvent != null
                                      ? 'EDIT SANCTIONED TOURNAMENT'
                                      : '5-STEP TOURNAMENT CREATOR WIZARD',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.goldPrimary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                Text(
                                  'Step ${wizardStep + 1} of 5 · Configure identity, categories, tables & QR weigh-ins',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Interactive 5-Step Progress Selector
                      Row(
                        children: List.generate(stepLabels.length, (i) {
                          final active = i <= wizardStep;
                          final current = i == wizardStep;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => wizardStep = i),
                              child: Padding(
                                padding: EdgeInsets.only(right: i < 4 ? 5 : 0),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: current
                                            ? AppTheme.goldPrimary
                                            : (active
                                                ? AppTheme.emerald
                                                : const Color(0x33FFFFFF)),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      stepLabels[i],
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontDisplay,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: current
                                            ? AppTheme.goldPrimary
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Step 1: Identity & Host Organization
                      if (wizardStep == 0) ...[
                        TextField(
                          controller: hostOrgNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Host Sanctioning Organization *',
                            prefixIcon: Icon(Icons.shield_outlined, size: 18),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Tournament Name *',
                            hintText: 'e.g. PAF National Championship 2026',
                            prefixIcon: Icon(Icons.military_tech_outlined, size: 18),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedBackdrop,
                          decoration: const InputDecoration(
                            labelText: 'Stage Backdrop Theme',
                            prefixIcon: Icon(Icons.wallpaper_rounded, size: 18),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ARENA_COLOSSEUM',
                              child: Text('Grand Prix Colosseum Stage'),
                            ),
                            DropdownMenuItem(
                              value: 'CHAMPIONSHIP_GOLD',
                              child: Text('24K Championship Title Stage'),
                            ),
                            DropdownMenuItem(
                              value: 'UNDERGROUND_PIT',
                              child: Text('Pro Supermatch Pit Stage'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setModalState(() => selectedBackdrop = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descriptionCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Event Overview & Sanctioning Charter',
                          ),
                        ),
                      ],

                      // Step 2: Schedule & Venue
                      if (wizardStep == 1) ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedProvince,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Province *',
                                ),
                                items: [
                                  for (final p in _kPakistanProvinces)
                                    DropdownMenuItem(
                                      value: p,
                                      child: Text(p, overflow: TextOverflow.ellipsis),
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setModalState(() => selectedProvince = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: cityCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'City *',
                                  hintText: 'e.g. Lahore',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: venueCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Arena / Venue Name *',
                            hintText: 'e.g. Nishtar Park Sports Complex',
                            prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => pickDate(
                                  initial: regEnd,
                                  onPicked: (d) {
                                    regEnd = DateTime(d.year, d.month, d.day, 18, 0);
                                    if (!eventStart.isAfter(regEnd)) {
                                      eventStart = regEnd.add(const Duration(days: 1));
                                    }
                                    if (eventEnd.isBefore(eventStart)) {
                                      eventEnd = eventStart.add(const Duration(days: 1));
                                    }
                                  },
                                ),
                                icon: const Icon(Icons.scale_outlined, size: 15),
                                label: Text(
                                  'Weigh-In: ${regEnd.day}/${regEnd.month}/${regEnd.year}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => pickDate(
                                  initial: eventStart,
                                  onPicked: (d) {
                                    eventStart = DateTime(d.year, d.month, d.day, 9, 0);
                                    if (!regEnd.isBefore(eventStart)) {
                                      regEnd = eventStart.subtract(const Duration(hours: 12));
                                    }
                                    if (eventEnd.isBefore(eventStart)) {
                                      eventEnd = eventStart.add(const Duration(hours: 12));
                                    }
                                  },
                                ),
                                icon: const Icon(Icons.event_available_outlined, size: 15),
                                label: Text(
                                  'Event Date: ${eventStart.day}/${eventStart.month}/${eventStart.year}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Step 3: Categories & Brackets
                      if (wizardStep == 2) ...[
                        DropdownButtonFormField<String>(
                          initialValue: eliminationFormat,
                          decoration: const InputDecoration(
                            labelText: 'Bracket Elimination Format',
                            prefixIcon: Icon(Icons.account_tree_outlined, size: 18),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'DOUBLE_ELIMINATION',
                              child: Text('WAF Double Elimination (2 Losses to Eliminate)'),
                            ),
                            DropdownMenuItem(
                              value: 'SINGLE_ELIMINATION',
                              child: Text('Single Elimination Knockout'),
                            ),
                            DropdownMenuItem(
                              value: 'ROUND_ROBIN',
                              child: Text('Round Robin Pool Stage'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setModalState(() => eliminationFormat = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'ACTIVE DIVISIONS & ARMS',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final div in const [
                              'MEN_SENIOR',
                              'WOMEN_SENIOR',
                              'JUNIOR_U21',
                              'MASTERS_40',
                              'AMATEUR',
                            ])
                              FilterChip(
                                label: Text(
                                  div.replaceAll('_', ' '),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                selected: selectedDivisions.contains(div),
                                onSelected: (sel) {
                                  setModalState(() {
                                    if (sel) {
                                      selectedDivisions.add(div);
                                    } else if (selectedDivisions.length > 1) {
                                      selectedDivisions.remove(div);
                                    }
                                  });
                                },
                              ),
                            for (final arm in const ['RIGHT', 'LEFT'])
                              FilterChip(
                                label: Text(
                                  '$arm ARM',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                selected: selectedArms.contains(arm),
                                onSelected: (sel) {
                                  setModalState(() {
                                    if (sel) {
                                      selectedArms.add(arm);
                                    } else if (selectedArms.length > 1) {
                                      selectedArms.remove(arm);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'WEIGHT CLASSES',
                          style: TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final wc in const [
                              '-65kg',
                              '-75kg',
                              '-85kg',
                              '-95kg',
                              '-105kg',
                              '+105kg',
                            ])
                              FilterChip(
                                label: Text(wc, style: const TextStyle(fontSize: 11)),
                                selected: selectedWeights.contains(wc),
                                onSelected: (sel) {
                                  setModalState(() {
                                    if (sel) {
                                      selectedWeights.add(wc);
                                    } else if (selectedWeights.length > 1) {
                                      selectedWeights.remove(wc);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ],

                      // Step 4: Arena Tables & Rules
                      if (wizardStep == 3) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Physical Arena Tables (1–10)',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: tableCount > 1
                                      ? () => setModalState(() => tableCount--)
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '$tableCount TABLES',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontMono,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.goldPrimary,
                                  ),
                                ),
                                IconButton(
                                  onPressed: tableCount < 10
                                      ? () => setModalState(() => tableCount++)
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppTheme.goldPrimary,
                          title: const Text(
                            'Running Fouls System',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          value: runningFouls,
                          onChanged: (v) => setModalState(() => runningFouls = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppTheme.goldPrimary,
                          title: const Text(
                            'Automatic Strap on First Slip',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          value: strapAfterFirstSlip,
                          onChanged: (v) => setModalState(() => strapAfterFirstSlip = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppTheme.goldPrimary,
                          title: const Text(
                            'Referee Grip after 30s Setup',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          value: refereeGripAfter30s,
                          onChanged: (v) => setModalState(() => refereeGripAfter30s = v),
                        ),
                      ],

                      // Step 5: Registration, Fees & Publish
                      if (wizardStep == 4) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: capacityCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Max Athletes *',
                                  hintText: '128',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: feeCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Entry Fee ($currency)',
                                  hintText: '0 for Free',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: paymentMethod,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Payment',
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'MANUAL_QR', child: Text('Manual / QR')),
                                  DropdownMenuItem(value: 'STRIPE', child: Text('Card / Stripe')),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setModalState(() => paymentMethod = v);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppTheme.goldPrimary,
                          title: const Text(
                            'Publish Immediately for Athlete Registration',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'Makes event live in Competitions list so athletes can register & get QR Passports',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          value: publishImmediately,
                          onChanged: (v) => setModalState(() => publishImmediately = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppTheme.goldPrimary,
                          title: Text(
                            'Auto-Provision $tableCount Official Arena Tables',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          value: autoCreateTables,
                          onChanged: (v) => setModalState(() => autoCreateTables = v),
                        ),
                      ],

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (wizardStep > 0) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => setModalState(() => wizardStep--),
                                child: const Text('PREVIOUS'),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.goldPrimary,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        if (wizardStep < 4) {
                                          HapticFeedback.selectionClick();
                                          setModalState(() => wizardStep++);
                                          return;
                                        }
                                        final name = nameCtrl.text.trim();
                                        final city = cityCtrl.text.trim();
                                        final venue = venueCtrl.text.trim();
                                        final capacity =
                                            int.tryParse(capacityCtrl.text.trim()) ?? 128;
                                        final feeDollars =
                                            double.tryParse(feeCtrl.text.trim()) ?? 0;
                                        final feeCents = (feeDollars * 100).round();

                                        if (name.length < 3 ||
                                            city.length < 2 ||
                                            venue.length < 3) {
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            CrystalSnackBar(
                                              content: const Text(
                                                'Please enter a valid Tournament Name, City, and Venue.',
                                              ),
                                              backgroundColor: AppTheme.error,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }

                                        setModalState(() => isSubmitting = true);
                                        try {
                                          final generatedTables = List.generate(
                                            tableCount,
                                            (i) => i == 0
                                                ? 'Table 1 — Main Stage'
                                                : 'Table ${i + 1} — Arena Pit ${i + 1}',
                                          );
                                          final created = await ref
                                              .read(tournamentProvider.notifier)
                                              .createEvent(
                                                data: {
                                                  'name': name,
                                                  'organizationName':
                                                      hostOrgNameCtrl.text.trim(),
                                                  'description':
                                                      descriptionCtrl.text.trim(),
                                                  'province': selectedProvince,
                                                  'city': city,
                                                  'venue': venue,
                                                  'capacity':
                                                      capacity > 0 ? capacity : 128,
                                                  'registrationFeeCents':
                                                      feeCents >= 0 ? feeCents : 0,
                                                  'paymentMethod': paymentMethod,
                                                  'eliminationFormat':
                                                      eliminationFormat,
                                                  'divisions':
                                                      selectedDivisions.toList(),
                                                  'arms': selectedArms.toList(),
                                                  'weightClasses':
                                                      selectedWeights.toList(),
                                                  'registrationStart':
                                                      regStart.toUtc().toIso8601String(),
                                                  'registrationEnd':
                                                      regEnd.toUtc().toIso8601String(),
                                                  'startDate':
                                                      eventStart.toUtc().toIso8601String(),
                                                  'endDate':
                                                      eventEnd.toUtc().toIso8601String(),
                                                },
                                                publishImmediately:
                                                    publishImmediately,
                                                initialTables: autoCreateTables
                                                    ? generatedTables
                                                    : const [],
                                              );
                                          if (ctx.mounted) {
                                            Navigator.of(ctx).pop(created);
                                          }
                                        } on ApiException catch (e) {
                                          if (ctx.mounted) {
                                            setModalState(() => isSubmitting = false);
                                            ScaffoldMessenger.of(ctx).showSnackBar(
                                              CrystalSnackBar(
                                                content: Text(e.detail),
                                                backgroundColor: AppTheme.error,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                icon: Icon(
                                  wizardStep < 4
                                      ? Icons.arrow_forward_rounded
                                      : Icons.rocket_launch_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  wizardStep < 4
                                      ? 'NEXT STEP (${wizardStep + 2}/5)'
                                      : (publishImmediately
                                          ? 'PUBLISH SANCTIONED TOURNAMENT'
                                          : 'SAVE TOURNAMENT DRAFT'),
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (createdEvent != null && mounted) {
      final newId = createdEvent['id']?.toString();
      if (newId != null && newId.isNotEmpty) {
        setState(() => _selectedTournamentId = newId);
        ScaffoldMessenger.of(context).showSnackBar(
          CrystalSnackBar(
            content: Text(
              'Tournament "${createdEvent['name'] ?? 'Event'}" created and ready for operations!',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(tournamentProvider);
    final authState = ref.watch(authProvider);
    final profile = authState.userProfile ?? {};
    final operatorName = profile['displayName'] ?? profile['name'] ?? 'Operator';

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: CrystalBackButton.maybeForInnerScreen(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.goldPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ARENA OPERATIONS COMMAND',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 10,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              operatorName,
              style: const TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: CrystalHeaderActionPill(
              label: 'NEW EVENT',
              icon: Icons.add,
              onTap: () => _showCreateTournamentModal(context),
            ),
          ),
          const SizedBox(width: 4),
          CrystalIconPillButton(
            icon: Icons.refresh,
            iconColor: AppTheme.goldPrimary,
            tooltip: 'Refresh Arena Status',
            onPressed: () {
              ref.invalidate(tournamentProvider);
              if (_selectedTournamentId != null) {
                ref.invalidate(eventDetailProvider(_selectedTournamentId!));
                ref.invalidate(eventMatchTablesProvider(_selectedTournamentId!));
                ref.invalidate(eventRegistrationsProvider(_selectedTournamentId!));
                ref.invalidate(eventBracketsProvider(_selectedTournamentId!));
              }
            },
          ),
          CrystalIconPillButton(
            icon: Icons.shield_outlined,
            iconColor: AppTheme.textSecondary,
            tooltip: 'Account Roles',
            onPressed: () {
              context.push('/settings/roles');
            },
          ),
          if (!MainShellScope.isInsideShell(context)) const CrystalHomeButton(),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CrystalStageBackdrop(
            domain: ArmSphereStageDomain.arena,
            customImageOverride: ArmSphereAssets.stageArena,
          ),
          SafeArea(
            bottom: false,
            child: CrystalVaporDissolve(
              bottomMargin: MainShellScope.isInsideShell(context)
                  ? (kFloatingDockTotalHeight + MediaQuery.paddingOf(context).bottom + 10.0)
                  : 12.0,
              child: tournamentsAsync.when(
                loading: () => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    191,
                    AppTheme.space16,
                    28,
                  ),
                  itemCount: 4,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTheme.space16),
                  itemBuilder: (_, __) => const SkeletonPlaceholder(
                    height: 120,
                    borderRadius: AppTheme.radiusMedium,
                  ),
                ),
                error: (error, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    191,
                    AppTheme.space16,
                    28,
                  ),
                  children: [
                    AppEmptyState(
                      icon: Icons.error_outline,
                      title: 'Could not load tournaments',
                      subtitle: error.toString(),
                      bannerAsset: ArmSphereAssets.cardStandbyTable,
                      bannerAlignment: Alignment.centerRight,
                      ctaLabel: 'Retry',
                      onCtaTap: () => ref.invalidate(tournamentProvider),
                    ),
                  ],
                ),
                data: (tournaments) {
                  if (tournaments.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.space16,
                        191,
                        AppTheme.space16,
                        28,
                      ),
                      children: [
                        AppEmptyState(
                          icon: Icons.emoji_events_outlined,
                          title: 'No Tournaments Created Yet',
                          subtitle:
                              'Create your first sanctioned tournament to open athlete registrations, configure weight-class brackets, assign table referees, and run live match operations.',
                          bannerAsset: ArmSphereAssets.cardStandbyTable,
                          bannerAlignment: Alignment.centerRight,
                          ctaLabel: 'Create Sanctioned Tournament',
                          onCtaTap: () => _showCreateTournamentModal(context),
                        ),
                      ],
                    );
                  }

                  final effectiveId = (_selectedTournamentId != null &&
                          tournaments.any(
                            (t) => t['id']?.toString() == _selectedTournamentId,
                          ))
                      ? _selectedTournamentId!
                      : tournaments.first['id'].toString();

                  final currentTournament = tournaments.firstWhere(
                    (t) => t['id']?.toString() == effectiveId,
                    orElse: () => tournaments.first,
                  );

                  final tablesAsync =
                      ref.watch(eventMatchTablesProvider(effectiveId));
                  final registrationsAsync =
                      ref.watch(eventRegistrationsProvider(effectiveId));
                  final bracketsAsync =
                      ref.watch(eventBracketsProvider(effectiveId));

                  return RefreshIndicator(
                    color: AppTheme.goldPrimary,
                    backgroundColor: AppTheme.cardSurface,
                    onRefresh: () async {
                      HapticFeedback.mediumImpact();
                      ref.invalidate(tournamentProvider);
                      ref.invalidate(eventDetailProvider(effectiveId));
                      ref.invalidate(eventMatchTablesProvider(effectiveId));
                      ref.invalidate(eventRegistrationsProvider(effectiveId));
                      ref.invalidate(eventBracketsProvider(effectiveId));
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.space16,
                        191,
                        AppTheme.space16,
                        28,
                      ),
                      children: [
                // 1. Tournament Selector & Create Event Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ACTIVE TOURNAMENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showCreateTournamentModal(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.goldPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 15),
                      label: const Text(
                        'CREATE NEW TOURNAMENT',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (tournaments.length > 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(color: const Color(0x4DD4AF37), width: 1.0),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: effectiveId,
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: AppTheme.cardSurface,
                        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.goldPrimary),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        items: tournaments.map((t) {
                          final st = (t['status'] ?? 'DRAFT').toString().toUpperCase();
                          return DropdownMenuItem<String>(
                            value: t['id'].toString(),
                            child: Text(
                              '${t['name'] ?? 'Tournament'} ($st)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (newId) {
                          if (newId != null) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedTournamentId = newId);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),
                ],

                // 2. Primary Event War Room Launcher Card
                ElevatedActionCard(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space10),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0x73D4AF37), width: 1.0),
                            ),
                            child: const Icon(
                              Icons.stadium_outlined,
                              color: AppTheme.goldPrimary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        currentTournament['name'] ?? 'Tournament',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontDisplay,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusChip(
                                      label: (currentTournament['status'] ?? 'ACTIVE').toString().toUpperCase(),
                                      type: StatusType.success,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        currentTournament['venue'] ?? currentTournament['city'] ?? 'Arena Venue',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (currentTournament['startDate'] != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_formatDate(currentTournament['startDate'])} - ${_formatDate(currentTournament['endDate'])}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space16),
                      const Divider(height: 1, thickness: 1, color: Color(0x22FFFFFF)),
                      const SizedBox(height: AppTheme.space16),

                      // Primary Launch Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppTheme.goldPrimary,
                            shadowColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              side: const BorderSide(color: Color(0x73D4AF37), width: 1.2),
                            ),
                          ),
                          icon: const Icon(Icons.dashboard_customize_outlined, size: 20),
                          label: const Text(
                            'LAUNCH EVENT OPERATIONS DESK',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            context.push('/tournament/$effectiveId/operations');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space20),

                // 3. Operational Quick Action Grids
                const Text(
                  'ARENA MANAGEMENT SUITE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),

                // Table & Queue Status Card
                tablesAsync.when(
                  loading: () => const SkeletonPlaceholder(height: 110, borderRadius: AppTheme.radiusMedium),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (tables) {
                    final activeCount = tables.where((t) => (t['status']?.toString().toUpperCase() == 'ACTIVE')).length;
                    final idleCount = tables.where((t) => (t['status']?.toString().toUpperCase() == 'IDLE')).length;

                    return ElevatedActionCard(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0x6638BDF8), width: 1.0),
                                    ),
                                    child: const Icon(Icons.table_restaurant_outlined, color: Color(0xFF38BDF8), size: 22),
                                  ),
                                  const SizedBox(width: AppTheme.space10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Match Tables & Arena Queue',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${tables.length} Arena ${tables.length == 1 ? "Table" : "Tables"} Active',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/tournament/$effectiveId/operations');
                                },
                                child: const Text('Manage'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space12),
                          Row(
                            children: [
                              _buildMetricPill('ACTIVE PULLING', '$activeCount', StatusType.success),
                              const SizedBox(width: AppTheme.space8),
                              _buildMetricPill('IDLE / READY', '$idleCount', StatusType.info),
                              const SizedBox(width: AppTheme.space8),
                              _buildMetricPill('TABLES TOTAL', '${tables.length}', StatusType.neutral),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.space12),

                // Weigh-In & Registrations Desk Card
                registrationsAsync.when(
                  loading: () => const SkeletonPlaceholder(height: 110, borderRadius: AppTheme.radiusMedium),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (regs) {
                    final approvedCount = regs.where((r) => r['status']?.toString().toUpperCase() == 'APPROVED').length;
                    final pendingCount = regs.where((r) => r['status']?.toString().toUpperCase() == 'PENDING').length;

                    return ElevatedActionCard(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0x73D4AF37), width: 1.0),
                                    ),
                                    child: const Icon(Icons.scale_outlined, color: AppTheme.goldPrimary, size: 22),
                                  ),
                                  const SizedBox(width: AppTheme.space10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Official Weigh-In Desk',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${regs.length} Total Registered Competitors',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: AppTheme.goldPrimary,
                                  shadowColor: Colors.transparent,
                                  surfaceTintColor: Colors.transparent,
                                  elevation: 0,
                                  side: const BorderSide(color: Color(0x73D4AF37), width: 1.0),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/tournament/$effectiveId/weigh-in');
                                },
                                child: const Text(
                                  'Open Scale',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space12),
                          Row(
                            children: [
                              _buildMetricPill('APPROVED PASSES', '$approvedCount', StatusType.success),
                              const SizedBox(width: AppTheme.space8),
                              _buildMetricPill('PENDING CHECK-IN', '$pendingCount', StatusType.warning),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.space12),

                // Brackets & Ceremony Quick Cards
                Row(
                  children: [
                    // Brackets Card
                    Expanded(
                      child: bracketsAsync.when(
                        loading: () => const SkeletonPlaceholder(height: 100, borderRadius: AppTheme.radiusMedium),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (brackets) {
                          return ElevatedActionCard(
                            padding: const EdgeInsets.all(AppTheme.space14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.account_tree_outlined, color: AppTheme.goldPrimary, size: 22),
                                    StatusChip(
                                      label: '${brackets.length}',
                                      type: StatusType.info,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Brackets',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Seeding & Trees',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 28),
                                      side: const BorderSide(color: AppTheme.cardBorder),
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      context.push('/tournament/$effectiveId/brackets');
                                    },
                                    child: const Text('View', style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),

                    // Awards Card
                    Expanded(
                      child: ElevatedActionCard(
                        padding: const EdgeInsets.all(AppTheme.space14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(Icons.emoji_events_outlined, color: AppTheme.goldPrimary, size: 22),
                                StatusChip(
                                  label: 'Podium',
                                  type: StatusType.success,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Awards Desk',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Medals & Citations',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 28),
                                  side: const BorderSide(color: AppTheme.cardBorder),
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/tournaments/$effectiveId/awards');
                                },
                                child: const Text('Ceremony', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space24),

                // 4. Quick Governance Escalation Link
                ElevatedActionCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
                  child: Row(
                    children: [
                      const Icon(Icons.gavel_outlined, color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: AppTheme.space12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Federation Arbitration & Protests',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textPrimary),
                            ),
                            Text(
                              'Review match disputes or official rule protests',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.push('/governance');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
              ],
            ),
          );
        },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, StatusType type) {
    Color borderColor;
    Color fg;
    switch (type) {
      case StatusType.success:
        borderColor = const Color(0x6610B981);
        fg = AppTheme.success;
        break;
      case StatusType.warning:
        borderColor = const Color(0x73D4AF37);
        fg = AppTheme.goldPrimary;
        break;
      case StatusType.info:
        borderColor = const Color(0x6638BDF8);
        fg = const Color(0xFF38BDF8);
        break;
      default:
        borderColor = const Color(0x38FFFFFF);
        fg = AppTheme.textSecondary;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.85),
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
