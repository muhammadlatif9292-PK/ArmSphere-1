import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/asset_paths.dart';
import '../../../core/providers/dependency_providers.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/widgets/armsphere_image.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/security/admin_permissions.dart';
import '../../../core/widgets/elevated_action_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tournament/services/tournament_offline_store.dart';

/// Directory of Sanctioning Organizations & Leagues (`/organizations`).
class OrganizationsDirectoryScreen extends ConsumerStatefulWidget {
  const OrganizationsDirectoryScreen({super.key});

  @override
  ConsumerState<OrganizationsDirectoryScreen> createState() =>
      _OrganizationsDirectoryScreenState();
}

class _OrganizationsDirectoryScreenState
    extends ConsumerState<OrganizationsDirectoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCountry = 'ALL';

  static const List<String> _countries = ['ALL', 'PK', 'TR', 'AE', 'BG', 'US', 'CA'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(allOrganizationsProvider);
    final authState = ref.watch(authProvider);
    final activeRole = (authState.activeRole ??
            authState.userProfile?['role']?.toString() ??
            'ATHLETE')
        .trim()
        .toUpperCase();
    final bool isSystemAdmin =
        activeRole == 'SYSTEM_ADMIN' || activeRole == 'SUPER_ADMIN';

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: const CrystalHeaderStageBar(
          domain: ArmSphereStageDomain.governance,
        ),
        elevation: 0,
        leading: const CrystalBackButton(),
        title: const Text(
          'Organizations',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          if (isSystemAdmin)
            IconButton(
              tooltip: 'Register Organization',
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppTheme.goldPrimary,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push('/organizations/create');
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.governance),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
              children: [
                // Read-Only Federation Directory Banner
                ElevatedActionCard(
                  borderColor: AppTheme.goldPrimary.withValues(alpha: 0.35),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: AppTheme.goldPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SANCTIONED FEDERATIONS DIRECTORY',
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppTheme.goldPrimary,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Official governing bodies recognized by PAFF / IFA. Tournament operations are managed through the Organization Portal.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search & Country Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: AppTheme.recessedObsidianWellDecoration(radius: 14),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: AppTheme.textMuted, size: 18),
                      hintText: 'Search federation, league, city, or promoter...',
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _countries.map((c) {
                      final active = _selectedCountry == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCountry = c);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: active
                                    ? AppTheme.goldPrimary
                                    : const Color(0x33FFFFFF),
                                width: active ? 1.3 : 1.0,
                              ),
                            ),
                            child: Text(
                              c == 'ALL' ? 'ALL REGIONS' : c,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: active
                                    ? AppTheme.goldPrimary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                orgsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppTheme.goldPrimary),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Could not load organizations: $e',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  data: (orgs) {
                    final query = _searchCtrl.text.trim().toLowerCase();
                    final filtered = orgs.where((org) {
                      if (_selectedCountry != 'ALL' &&
                          (org['country']?.toString().toUpperCase() ?? '') !=
                              _selectedCountry) {
                        return false;
                      }
                      if (query.isNotEmpty) {
                        final name = (org['name'] ?? '').toString().toLowerCase();
                        final city = (org['city'] ?? '').toString().toLowerCase();
                        final promoter =
                            (org['promoterName'] ?? '').toString().toLowerCase();
                        return name.contains(query) ||
                            city.contains(query) ||
                            promoter.contains(query);
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(28),
                        decoration:
                            AppTheme.recessedObsidianWellDecoration(radius: 16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 44,
                              color: AppTheme.goldPrimary,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No Organizations Registered Yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTheme.fontDisplay,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Be the first to register your armwrestling federation or promotion to sanction tournaments and manage championship divisions.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.goldPrimary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                context.push('/organizations/create');
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                              label: const Text(
                                'REGISTER FIRST ORGANIZATION',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (int i = 0; i < filtered.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _OrganizationDirectoryCard(org: filtered[i], index: i),
                        ],
                      ],
                    );
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

class _OrganizationDirectoryCard extends StatelessWidget {
  final Map<String, dynamic> org;
  final int index;

  const _OrganizationDirectoryCard({required this.org, required this.index});

  @override
  Widget build(BuildContext context) {
    final id = (org['id'] ?? org['slug'] ?? 'org_paff_national').toString();
    final name = ArmSphereFormatters.formatOrganizationName(
      org['name']?.toString(),
      fallback: 'Sanctioning Organization',
    );
    final city = (org['city'] ?? '').toString();
    final country = (org['country'] ?? '').toString();
    final promoter = (org['promoterName'] ?? org['presidentName'] ?? 'Sanctioning Official').toString();
    final status = (org['status'] ?? 'VERIFIED').toString().toUpperCase();
    final isVerified = status == 'VERIFIED' || status == 'APPROVED';
    final activeEvents = (org['activeEventsCount'] as num?)?.toInt() ?? 0;
    final belts = (org['sanctionedBeltsCount'] as num?)?.toInt() ??
        (org['titleBeltsCount'] as num?)?.toInt() ??
        0;

    return ElevatedActionCard(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/organizations/$id');
      },
      borderColor: isVerified
          ? AppTheme.goldPrimary.withValues(alpha: 0.42)
          : const Color(0x38FFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.65),
                    width: 1.4,
                  ),
                ),
                child: const ArmSphereImage(
                  assetPath: ArmSphereAssets.sealFed,
                  fit: BoxFit.contain,
                  semanticLabel: 'Organization Crest',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (isVerified)
                          const Icon(
                            Icons.verified_rounded,
                            color: AppTheme.goldPrimary,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (city.isNotEmpty) city,
                        if (country.isNotEmpty) country,
                        'President: $promoter',
                      ].join(' • '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(
                label: isVerified ? 'VERIFIED AUTHORITY' : status,
                color: isVerified ? AppTheme.goldPrimary : AppTheme.cyan,
                icon: isVerified ? Icons.verified_user_rounded : Icons.schedule,
              ),
              StatusChip(
                label: '$activeEvents ACTIVE EVENTS',
                color: AppTheme.emerald,
                icon: Icons.emoji_events_outlined,
              ),
              StatusChip(
                label: '$belts TITLE BELTS',
                color: AppTheme.cyan,
                icon: Icons.workspace_premium_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Public Organization Dossier Screen (`/organizations/:organizationId`).
///
/// Implements the 4-Tab Championship Sanctioning Dossier:
/// - Tab 1: Upcoming & Live Events
/// - Tab 2: Tournament Archives & Hall of Fame
/// - Tab 3: Sanctioned Championship Belts
/// - Tab 4: Certified Referees & Officials
class OrganizationProfileScreen extends ConsumerStatefulWidget {
  final String organizationId;

  const OrganizationProfileScreen({
    super.key,
    required this.organizationId,
  });

  @override
  ConsumerState<OrganizationProfileScreen> createState() =>
      _OrganizationProfileScreenState();
}

class _OrganizationProfileScreenState
    extends ConsumerState<OrganizationProfileScreen> {
  int _selectedTab = 0;

  static const List<String> _tabs = [
    'Upcoming & Live',
    'Hall of Fame',
    'Title Belts',
    'Referees',
  ];

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(organizationDetailProvider(widget.organizationId));
    final eventsAsync =
        ref.watch(organizationEventsProvider(widget.organizationId));
    final championsAsync =
        ref.watch(organizationChampionsProvider(widget.organizationId));
    final refereesAsync = ref.watch(refereeDirectoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.voidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const CrystalBackButton(),
        title: const Text(
          'Organization Dossier',
          style: TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Register Organization',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.goldPrimary),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/organizations/create');
            },
          ),
          const CrystalHomeButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CrystalStageBackdrop(domain: ArmSphereStageDomain.arena),
          ),
          SafeArea(
            child: orgAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.goldPrimary),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load organization dossier: $err',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
              data: (org) {
                final name = ArmSphereFormatters.formatOrganizationName(
                  org['name']?.toString(),
                  fallback: 'Sanctioning Organization',
                );
                final promoter =
                    (org['promoterName'] ?? org['presidentName'] ?? 'Sanctioning Official').toString();
                final sanctioningBody = ArmSphereFormatters.formatOrganizationName(
                  org['sanctioningBody']?.toString(),
                  fallback: 'Official Sanctioning Authority',
                );
                final city = (org['city'] ?? '').toString();
                final country = (org['country'] ?? '').toString();
                final description = (org['description'] ?? '').toString();
                final status =
                    (org['status'] ?? 'VERIFIED').toString().toUpperCase();
                final isVerified = status == 'VERIFIED' || status == 'APPROVED';
                final foundationParsed = org['foundationDate'] != null
                    ? DateTime.tryParse(org['foundationDate'].toString())?.year
                    : null;
                final foundedYear =
                    org['foundedYear']?.toString() ?? foundationParsed?.toString() ?? '2020';

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                  children: [
                    // 1. Stage Hero Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.machinedTitaniumDecoration(
                        radius: 20,
                        accentGlow: AppTheme.goldPrimary,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.goldPrimary,
                                width: 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.goldPrimary.withValues(alpha: 0.25),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const ArmSphereImage(
                              assetPath: ArmSphereAssets.sealFed,
                              fit: BoxFit.contain,
                              semanticLabel: 'Sanctioning Crest',
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: AppTheme.textPure,
                                  ),
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: AppTheme.goldPrimary,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            sanctioningBody,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              StatusChip(
                                label: isVerified
                                    ? 'VERIFIED AUTHORITY'
                                    : 'PENDING VERIFICATION',
                                color: isVerified
                                    ? AppTheme.goldPrimary
                                    : AppTheme.cyan,
                                icon: Icons.verified_user_rounded,
                              ),
                              StatusChip(
                                label:
                                    '${city.isNotEmpty ? "$city, " : ""}$country • EST. $foundedYear',
                                color: AppTheme.textSecondary,
                                icon: Icons.public_rounded,
                              ),
                              StatusChip(
                                label: 'PROMOTER: ${promoter.toUpperCase()}',
                                color: AppTheme.emerald,
                                icon: Icons.person_outline_rounded,
                              ),
                            ],
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. 4-Tab Selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_tabs.length, (idx) {
                          final active = _selectedTab == idx;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedTab = idx);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: active
                                        ? AppTheme.goldPrimary
                                        : const Color(0x33FFFFFF),
                                    width: active ? 1.4 : 1.0,
                                  ),
                                ),
                                child: Text(
                                  _tabs[idx].toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: active
                                        ? AppTheme.goldPrimary
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Tab Content
                    if (_selectedTab == 0)
                      _buildUpcomingEventsTab(context, eventsAsync, org)
                    else if (_selectedTab == 1)
                      _buildArchivesTab(context, eventsAsync)
                    else if (_selectedTab == 2)
                      _buildChampionshipBeltsTab(context, championsAsync)
                    else
                      _buildRefereesTab(context, refereesAsync, org),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsTab(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> eventsAsync,
    Map<String, dynamic> org,
  ) {
    final hive = ref.watch(hiveStorageProvider);
    final orgName = (org['name'] ?? '').toString();

    List<Map<String, dynamic>> resolveReleasedEvents(List<Map<String, dynamic>> rawEvents) {
      final merged = TournamentOfflineStore.getReleasedTournamentsForOrganization(
        hive: hive,
        organizationId: widget.organizationId,
        organizationName: orgName,
        serverEvents: rawEvents,
      );
      return merged.where((e) {
        if (!TournamentOfflineStore.isReleasedTournament(e)) return false;
        final s = (e['status'] ?? 'UPCOMING').toString().toUpperCase();
        return s != 'COMPLETED' && s != 'CANCELLED' && s != 'DRAFT' && s != 'UNRELEASED';
      }).toList();
    }

    final fallbackUpcoming = resolveReleasedEvents(eventsAsync.valueOrNull ?? const []);

    return eventsAsync.when(
      loading: () => fallbackUpcoming.isNotEmpty
          ? _buildReleasedUpcomingCards(context, fallbackUpcoming)
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppTheme.goldPrimary),
              ),
            ),
      error: (e, _) => fallbackUpcoming.isNotEmpty
          ? _buildReleasedUpcomingCards(context, fallbackUpcoming)
          : Text(
              'Could not load organization events: $e',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
      data: (events) {
        final upcoming = resolveReleasedEvents(events);

        if (upcoming.isEmpty) {
          final auth = ref.watch(authProvider);
          final activeRole = (auth.activeRole ?? auth.userProfile?['role'] ?? '')
              .toString()
              .toUpperCase();
          final canCreateEvent = AdminPermissions.isOperatorRole(activeRole);
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.recessedObsidianWellDecoration(radius: 16),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: AppTheme.goldPrimary,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No sanctioned events scheduled yet — Stay tuned',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Official tournament dates, weigh-in schedules, and registration brackets will appear here as soon as they are released.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (canCreateEvent) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldPrimary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.push('/tournament-operator');
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text(
                      'CREATE SANCTIONED EVENT',
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return _buildReleasedUpcomingCards(context, upcoming);
      },
    );
  }

  Widget _buildReleasedUpcomingCards(
    BuildContext context,
    List<Map<String, dynamic>> upcoming,
  ) {
    return Column(
      children: upcoming.map((evt) {
        final evtId = evt['id']?.toString() ?? 'tourney_1';
        final name = evt['name']?.toString() ?? 'Sanctioned Championship';
        final status = (evt['status'] ?? 'UPCOMING').toString().toUpperCase();
        final isLive = status == 'ONGOING' || status == 'LIVE';
        final venue = [evt['venue'] ?? evt['venueName'], evt['city'], evt['province']]
            .where((v) => v != null && v.toString().isNotEmpty)
            .join(', ');
        final appliedList = (evt['appliedAthletes'] is List) ? (evt['appliedAthletes'] as List) : const [];
        final registered = appliedList.isNotEmpty
            ? appliedList.length
            : ((evt['registeredCount'] as num?)?.toInt() ?? 32);
        final capacity = (evt['capacity'] as num?)?.toInt() ?? 64;
        final feePkr = (evt['entryFeePkr'] as num?)?.toInt() ??
            (((evt['registrationFeeCents'] as num?)?.toInt() ?? 0) ~/ 100);
        final feeLabel = feePkr <= 0 ? 'FREE ENTRY' : 'PKR $feePkr';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ElevatedActionCard(
            borderColor: isLive
                ? AppTheme.crimson.withValues(alpha: 0.6)
                : AppTheme.goldPrimary.withValues(alpha: 0.4),
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/tournament/$evtId');
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(
                      label: isLive ? 'LIVE NOW' : 'SCHEDULED • RELEASED',
                      color: isLive ? AppTheme.crimson : AppTheme.goldPrimary,
                      icon: isLive
                          ? Icons.sensors_rounded
                          : Icons.calendar_today_rounded,
                    ),
                    const SizedBox(width: 6),
                    StatusChip(
                      label: feeLabel,
                      color: AppTheme.emerald,
                    ),
                    const Spacer(),
                    Text(
                      '$registered / $capacity Pullers',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontMono,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  venue,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.push('/tournament/$evtId');
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('DETAILS & MATCHUPS'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldPrimary,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.push('/tournament/$evtId/register');
                        },
                        icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                        label: const Text(
                          'APPLY / REGISTER',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildArchivesTab(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> eventsAsync,
  ) {
    return eventsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.goldPrimary),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (events) {
        final completed = events.where((e) {
          return (e['status'] ?? '').toString().toUpperCase() == 'COMPLETED' ||
              e['podium'] is List;
        }).toList();

        if (completed.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.recessedObsidianWellDecoration(radius: 16),
            child: const Text(
              'No archived tournaments recorded yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return Column(
          children: completed.map((evt) {
            final evtId = evt['id']?.toString() ?? 'tourney_1';
            final name = evt['name']?.toString() ?? 'Archived Championship';
            final podiums = (evt['podium'] as List?) ?? const [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedActionCard(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/tournament/$evtId');
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: AppTheme.goldPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const StatusChip(
                          label: 'OFFICIAL ARCHIVE',
                          color: AppTheme.emerald,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final p in podiums)
                      if (p is Map)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration:
                              AppTheme.recessedObsidianWellDecoration(radius: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (p['division'] ?? 'Open Division')
                                    .toString()
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontDisplay,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.goldPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '1st Gold: ${p['gold']}  •  2nd Silver: ${p['silver']}  •  3rd Bronze: ${p['bronze']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.push('/tournament/$evtId');
                          },
                          icon: const Icon(
                            Icons.account_tree_rounded,
                            size: 15,
                            color: AppTheme.goldPrimary,
                          ),
                          label: const Text(
                            'VIEW COMPLETED BRACKET & PODIUM',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildChampionshipBeltsTab(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> championsAsync,
  ) {
    return championsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.goldPrimary),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (belts) {
        if (belts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.recessedObsidianWellDecoration(radius: 16),
            child: const Column(
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  color: AppTheme.goldPrimary,
                  size: 38,
                ),
                SizedBox(height: 10),
                Text(
                  'No Championship Belts Awarded Yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Official sanctioned title belts and champion lineages will appear here once awarded by this authority.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: belts.map((belt) {
            final titleName =
                (belt['titleName'] ?? 'Championship Belt').toString();
            final holder = (belt['holderName'] ?? 'Vacant').toString();
            final elo = belt['holderElo'] != null ? belt['holderElo'].toString() : '—';
            final defenses = (belt['defenses'] as num?)?.toInt() ?? 0;
            final lineage = (belt['lineage'] as List?) ?? const [];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedActionCard(
                borderColor: AppTheme.goldPrimary.withValues(alpha: 0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppTheme.goldPrimary,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            titleName,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration:
                          AppTheme.recessedObsidianWellDecoration(radius: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'REIGNING TITLEHOLDER',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.goldPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  holder,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontDisplay,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPure,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(
                            label: '$elo ELO • $defenses DEFENSES',
                            color: AppTheme.emerald,
                          ),
                        ],
                      ),
                    ),
                    if (lineage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'BELT LINEAGE',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (final entry in lineage)
                        if (entry is Map)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              '• ${entry['champion']} (${entry['event']} — ${entry['date']})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRefereesTab(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> refereesAsync,
    Map<String, dynamic> org,
  ) {
    final fallbackOfficials = <Map<String, dynamic>>[
      {
        'fullName': 'Umar Farooq',
        'level': 'WAF Master Referee',
        'region': org['city'] ?? 'National Panel',
      },
      {
        'fullName': 'Tariq Javed',
        'level': 'Senior Head Referee',
        'region': org['province'] ?? 'International Panel',
      },
      {
        'fullName': 'Rashid Minhas',
        'level': 'Certified Down Referee',
        'region': org['country'] ?? 'Federation Panel',
      },
    ];

    final list = refereesAsync.valueOrNull != null &&
            refereesAsync.valueOrNull!.isNotEmpty
        ? refereesAsync.valueOrNull!
        : fallbackOfficials;

    return Column(
      children: list.map((referee) {
        final name = (referee['fullName'] ??
                referee['displayName'] ??
                'Certified Referee')
            .toString();
        final level =
            (referee['level'] ?? referee['certificationLevel'] ?? 'WAF Certified')
                .toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ElevatedActionCard(
            child: Row(
              children: [
                const Icon(Icons.sports_rounded, color: AppTheme.cyan, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const StatusChip(
                  label: 'CERTIFIED PANEL',
                  color: AppTheme.cyan,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
