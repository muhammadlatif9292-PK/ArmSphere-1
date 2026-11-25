import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/organization_session_provider.dart';
import '../../../core/providers/state_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/display_formatters.dart';
import '../../../core/widgets/crystal_glass_nav_controls.dart';
import '../../../core/widgets/crystal_modal_sheet.dart';
import '../../../core/widgets/crystal_stage_scaffold.dart';
import '../../../core/widgets/crystal_toast.dart';
import '../../../core/widgets/elevated_action_card.dart';

/// Organization-Issued Referee Certifications Management Screen
///
/// Follows ArmSphere's Smoked-Obsidian Forged-Crystal visual grammar:
/// - G1 translucent obsidian cards with subtle titanium/gold specular borders
/// - G6 opaque obsidian confirmation modals (#0C101A)
/// - 3 tabs:
///   1) Requests: Real incoming referee requests for this organization
///   2) Certify Athlete: Real case-insensitive search across registered athletes
///   3) Certified Officials: All real officials certified by this organization
class OrganizationCertificationsScreen extends ConsumerStatefulWidget {
  const OrganizationCertificationsScreen({super.key});

  @override
  ConsumerState<OrganizationCertificationsScreen> createState() =>
      _OrganizationCertificationsScreenState();
}

class _OrganizationCertificationsScreenState
    extends ConsumerState<OrganizationCertificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<String> _certificationLevels = [
    'Regional Official',
    'National Official',
    'Senior Official',
    'Head Table Official',
  ];

  // Tab 1: Requests
  bool _loadingRequests = true;
  String? _requestsError;
  List<Map<String, dynamic>> _requests = [];

  // Tab 2: Certify Athlete Search
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  bool _loadingAthletes = true;
  String? _athletesError;
  List<Map<String, dynamic>> _athletes = [];

  // Tab 3: Certified Officials
  bool _loadingOfficials = true;
  String? _officialsError;
  List<Map<String, dynamic>> _officials = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _orgId() => ref.read(organizationSessionProvider).orgId ?? '';
  String? _orgToken() => ref.read(organizationSessionProvider).token;
  String _orgName() => ArmSphereFormatters.formatOrganizationName(
        ref.read(organizationSessionProvider).orgName,
        fallback: 'Your Organization',
      );

  Future<void> _loadAll() async {
    await Future.wait([
      _fetchRequests(),
      _fetchAthletes(_searchCtrl.text),
      _fetchOfficials(),
    ]);
  }

  Future<void> _fetchRequests() async {
    final orgId = _orgId();
    if (orgId.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingRequests = false;
          _requestsError = 'Organization session not active.';
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _loadingRequests = true;
        _requestsError = null;
      });
    }
    try {
      final repo = ref.read(organizationRepositoryProvider);
      final data = await repo.getCertificationRequests(orgId, token: _orgToken());
      if (mounted) {
        setState(() {
          _requests = data;
          _loadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRequests = false;
          _requestsError = _cleanError(e);
        });
      }
    }
  }

  Future<void> _fetchAthletes(String query) async {
    final orgId = _orgId();
    if (orgId.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingAthletes = false;
          _athletesError = 'Organization session not active.';
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _loadingAthletes = true;
        _athletesError = null;
      });
    }
    try {
      final repo = ref.read(organizationRepositoryProvider);
      final data = await repo.searchAthletesForCertification(
        orgId,
        query: query,
        token: _orgToken(),
      );
      if (mounted) {
        setState(() {
          _athletes = data;
          _loadingAthletes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingAthletes = false;
          _athletesError = _cleanError(e);
        });
      }
    }
  }

  Future<void> _fetchOfficials() async {
    final orgId = _orgId();
    if (orgId.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingOfficials = false;
          _officialsError = 'Organization session not active.';
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _loadingOfficials = true;
        _officialsError = null;
      });
    }
    try {
      final repo = ref.read(organizationRepositoryProvider);
      final data =
          await repo.getOrganizationCertifications(orgId, token: _orgToken());
      if (mounted) {
        setState(() {
          _officials = data;
          _loadingOfficials = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingOfficials = false;
          _officialsError = _cleanError(e);
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _fetchAthletes(value);
    });
  }

  String _cleanError(Object error) {
    final msg = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (msg.isEmpty) return 'Unable to complete request. Please try again.';
    return msg;
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return 'Recent';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString().split('T').first;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _openApproveRequestModal(Map<String, dynamic> req) async {
    HapticFeedback.mediumImpact();
    String selectedLevel = _certificationLevels.first;
    final notesCtrl = TextEditingController();
    bool isSubmitting = false;

    final athleteName =
        (req['fullName'] ?? req['displayName'] ?? 'Athlete').toString();
    final requestId = req['id']?.toString() ?? '';

    final approved = await CrystalModalSheet.show<bool>(
      context: context,
      title: 'APPROVE & CERTIFY REFEREE',
      subtitle: 'Issue official ${_orgName()} referee credentials to $athleteName.',
      icon: Icons.verified_user_rounded,
      accentColor: AppTheme.emerald,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CERTIFICATION LEVEL',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: AppTheme.goldPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _certificationLevels.map((level) {
                  final active = selectedLevel == level;
                  return ChoiceChip(
                    label: Text(
                      level,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.black : AppTheme.textPrimary,
                      ),
                    ),
                    selected: active,
                    selectedColor: AppTheme.goldPrimary,
                    backgroundColor: const Color(0xFF141B29),
                    side: BorderSide(
                      color: active
                          ? AppTheme.goldPrimary
                          : const Color(0x38FFFFFF),
                    ),
                    onSelected: (_) =>
                        setSheetState(() => selectedLevel = level),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                scrollPadding: const EdgeInsets.only(bottom: 140),
                style: const TextStyle(color: AppTheme.textPure, fontSize: 13.5),
                decoration: CrystalModalSheet.inputDecoration(
                  labelText: 'Issuance Notes (Optional)',
                  hintText: 'e.g. Verified rules exam & regional clinic completion',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setSheetState(() => isSubmitting = true);
                        try {
                          final repo = ref.read(organizationRepositoryProvider);
                          await repo.reviewCertificationRequest(
                            _orgId(),
                            requestId,
                            decision: 'APPROVE',
                            certificationLevel: selectedLevel,
                            reviewNotes: notesCtrl.text.trim(),
                            token: _orgToken(),
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop(true);
                        } catch (e) {
                          setSheetState(() => isSubmitting = false);
                          if (mounted) {
                            CrystalToast.error(context, _cleanError(e));
                          }
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.verified_rounded, size: 18),
                label: Text(
                  isSubmitting
                      ? 'ISSUING CERTIFICATION...'
                      : 'CONFIRM & ISSUE CERTIFICATION',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    notesCtrl.dispose();
    if (approved == true && mounted) {
      CrystalToast.success(
        context,
        '$athleteName certified as $selectedLevel by ${_orgName()}.',
      );
      await _loadAll();
    }
  }

  Future<void> _openDeclineRequestModal(Map<String, dynamic> req) async {
    HapticFeedback.mediumImpact();
    final reasonCtrl = TextEditingController();
    bool isSubmitting = false;

    final athleteName =
        (req['fullName'] ?? req['displayName'] ?? 'Athlete').toString();
    final requestId = req['id']?.toString() ?? '';

    final declined = await CrystalModalSheet.show<bool>(
      context: context,
      title: 'DECLINE REQUEST',
      subtitle: 'Decline referee certification request from $athleteName.',
      icon: Icons.cancel_outlined,
      accentColor: AppTheme.crimson,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                scrollPadding: const EdgeInsets.only(bottom: 140),
                style: const TextStyle(color: AppTheme.textPure, fontSize: 13.5),
                decoration: CrystalModalSheet.inputDecoration(
                  labelText: 'Reason / Feedback (Optional)',
                  hintText: 'Provide helpful guidance for re-application...',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.crimson,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setSheetState(() => isSubmitting = true);
                        try {
                          final repo = ref.read(organizationRepositoryProvider);
                          await repo.reviewCertificationRequest(
                            _orgId(),
                            requestId,
                            decision: 'REJECT',
                            reviewNotes: reasonCtrl.text.trim(),
                            token: _orgToken(),
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop(true);
                        } catch (e) {
                          setSheetState(() => isSubmitting = false);
                          if (mounted) {
                            CrystalToast.error(context, _cleanError(e));
                          }
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.close_rounded, size: 18),
                label: Text(
                  isSubmitting ? 'DECLINING...' : 'DECLINE REQUEST',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    reasonCtrl.dispose();
    if (declined == true && mounted) {
      CrystalToast.info(context, 'Request from $athleteName declined.');
      await _fetchRequests();
    }
  }

  Future<void> _openGrantCertificationModal(Map<String, dynamic> athlete) async {
    HapticFeedback.mediumImpact();
    String selectedLevel = _certificationLevels.first;
    final notesCtrl = TextEditingController();
    bool isSubmitting = false;

    final athleteName =
        (athlete['displayName'] ?? athlete['fullName'] ?? 'Athlete').toString();
    final athleteId = athlete['athleteId']?.toString();
    final userId = athlete['userId']?.toString();

    final granted = await CrystalModalSheet.show<bool>(
      context: context,
      title: 'GRANT OFFICIAL CERTIFICATION',
      subtitle:
          'Directly certify $athleteName as an Official Referee under ${_orgName()}.',
      icon: Icons.workspace_premium_rounded,
      accentColor: AppTheme.goldPrimary,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CERTIFICATION LEVEL',
                style: TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: AppTheme.goldPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _certificationLevels.map((level) {
                  final active = selectedLevel == level;
                  return ChoiceChip(
                    label: Text(
                      level,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.black : AppTheme.textPrimary,
                      ),
                    ),
                    selected: active,
                    selectedColor: AppTheme.goldPrimary,
                    backgroundColor: const Color(0xFF141B29),
                    side: BorderSide(
                      color: active
                          ? AppTheme.goldPrimary
                          : const Color(0x38FFFFFF),
                    ),
                    onSelected: (_) =>
                        setSheetState(() => selectedLevel = level),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                scrollPadding: const EdgeInsets.only(bottom: 140),
                style: const TextStyle(color: AppTheme.textPure, fontSize: 13.5),
                decoration: CrystalModalSheet.inputDecoration(
                  labelText: 'Certification Notes (Optional)',
                  hintText: 'e.g. Appointed after regional table examination',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.goldPrimary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setSheetState(() => isSubmitting = true);
                        try {
                          final repo = ref.read(organizationRepositoryProvider);
                          await repo.grantOfficialCertification(
                            _orgId(),
                            athleteId: athleteId,
                            userId: userId,
                            certificationLevel: selectedLevel,
                            notes: notesCtrl.text.trim(),
                            token: _orgToken(),
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop(true);
                        } catch (e) {
                          setSheetState(() => isSubmitting = false);
                          if (mounted) {
                            CrystalToast.error(context, _cleanError(e));
                          }
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.verified_rounded, size: 18),
                label: Text(
                  isSubmitting
                      ? 'GRANTING CERTIFICATION...'
                      : 'GRANT OFFICIAL CERTIFICATION',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    notesCtrl.dispose();
    if (granted == true && mounted) {
      CrystalToast.success(
        context,
        '$athleteName is now certified as $selectedLevel by ${_orgName()}.',
      );
      await _loadAll();
    }
  }

  Future<void> _openRevokeModal(Map<String, dynamic> cert) async {
    HapticFeedback.mediumImpact();
    final reasonCtrl = TextEditingController();
    bool isSubmitting = false;

    final name = (cert['fullName'] ?? cert['displayName'] ?? 'Official').toString();
    final level = (cert['certificationLevel'] ?? 'Official').toString();
    final certId = cert['id']?.toString() ?? '';

    final revoked = await CrystalModalSheet.show<bool>(
      context: context,
      title: 'REVOKE CERTIFICATION',
      subtitle: 'Revoke $level credentials issued by ${_orgName()} for $name?',
      icon: Icons.gpp_bad_outlined,
      accentColor: AppTheme.crimson,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                scrollPadding: const EdgeInsets.only(bottom: 140),
                style: const TextStyle(color: AppTheme.textPure, fontSize: 13.5),
                decoration: CrystalModalSheet.inputDecoration(
                  labelText: 'Revocation Reason (Optional)',
                  hintText: 'State reason for revoking this official certification...',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.crimson,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setSheetState(() => isSubmitting = true);
                        try {
                          final repo = ref.read(organizationRepositoryProvider);
                          await repo.revokeOrganizationCertification(
                            _orgId(),
                            certId,
                            reason: reasonCtrl.text.trim(),
                            token: _orgToken(),
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop(true);
                        } catch (e) {
                          setSheetState(() => isSubmitting = false);
                          if (mounted) {
                            CrystalToast.error(context, _cleanError(e));
                          }
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.block_rounded, size: 18),
                label: Text(
                  isSubmitting ? 'REVOKING...' : 'CONFIRM REVOCATION',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    reasonCtrl.dispose();
    if (revoked == true && mounted) {
      CrystalToast.info(context, 'Certification revoked for $name.');
      await _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _requests
        .where((r) => (r['status'] ?? '').toString().toUpperCase() == 'PENDING')
        .length;
    final activeOfficialsCount = _officials
        .where((o) => (o['status'] ?? '').toString().toUpperCase() == 'ACTIVE')
        .length;

    return CrystalStageScaffold(
      domain: ArmSphereStageDomain.events,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xD90A0D14),
        leading: CrystalBackButton(
          fallbackRoute: '/organization/deck',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/organization/deck');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Referee Certifications',
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: AppTheme.textPure,
              ),
            ),
            Text(
              _orgName(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.fontBody,
                fontSize: 11.5,
                color: AppTheme.goldPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.goldPrimary),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldPrimary,
          indicatorWeight: 2.5,
          labelColor: AppTheme.goldPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(
            fontFamily: AppTheme.fontDisplay,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          tabs: [
            Tab(
              text: pendingCount > 0 ? 'Requests ($pendingCount)' : 'Requests',
            ),
            const Tab(text: 'Certify Athlete'),
            Tab(
              text: activeOfficialsCount > 0
                  ? 'Officials ($activeOfficialsCount)'
                  : 'Officials',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsTab(),
          _buildCertifyAthleteTab(),
          _buildCertifiedOfficialsTab(),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_loadingRequests) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldPrimary),
      );
    }
    if (_requestsError != null) {
      return _buildErrorState(_requestsError!, _fetchRequests);
    }
    if (_requests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No Referee Requests Yet',
        subtitle:
            'When athletes apply for Referee certification and select ${_orgName()}, their applications will appear here for review.',
      );
    }

    return RefreshIndicator(
      color: AppTheme.goldPrimary,
      onRefresh: _fetchRequests,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final req = _requests[index];
          final name =
              (req['fullName'] ?? req['displayName'] ?? 'Athlete').toString();
          final status = (req['status'] ?? 'PENDING').toString().toUpperCase();
          final isPending = status == 'PENDING';
          final city = ArmSphereFormatters.formatCleanAddress([
            req['city']?.toString(),
            req['province']?.toString(),
          ]);
          final elo = req['rightArmElo'] ?? 1200;
          final experience = (req['experienceDetails'] ?? '').toString().trim();
          final createdStr = _formatDate(req['createdAt']);

          return ElevatedActionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.goldPrimary.withValues(alpha: 0.16),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'R',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppTheme.textPure,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            city.isNotEmpty
                                ? '$city • ELO $elo'
                                : 'Registered Athlete • ELO $elo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusPill(status),
                  ],
                ),
                if (experience.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: Text(
                      experience,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'Submitted $createdStr',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.crimson,
                            side: BorderSide(
                              color: AppTheme.crimson.withValues(alpha: 0.55),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _openDeclineRequestModal(req),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text(
                            'Decline',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.emerald,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _openApproveRequestModal(req),
                          icon: const Icon(Icons.verified_rounded, size: 16),
                          label: const Text(
                            'Approve & Certify',
                            style: TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCertifyAthleteTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            scrollPadding: const EdgeInsets.only(bottom: 140),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            style: const TextStyle(color: AppTheme.textPure, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search registered athletes by name or city...',
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.goldPrimary,
              ),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: AppTheme.textSecondary,
                      onPressed: () {
                        _searchCtrl.clear();
                        _fetchAthletes('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0x990D121D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x38FFFFFF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x38FFFFFF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppTheme.goldPrimary,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loadingAthletes
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.goldPrimary),
                )
              : _athletesError != null
                  ? _buildErrorState(
                      _athletesError!, () => _fetchAthletes(_searchCtrl.text))
                  : _athletes.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.person_search_rounded,
                          title: 'No Registered Athletes Found',
                          subtitle: _searchCtrl.text.trim().isEmpty
                              ? 'Registered ArmSphere athletes will appear here for direct official certification.'
                              : 'No athletes matched "${_searchCtrl.text.trim()}". Try another name or city.',
                        )
                      : RefreshIndicator(
                          color: AppTheme.goldPrimary,
                          onRefresh: () => _fetchAthletes(_searchCtrl.text),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
                            itemCount: _athletes.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final athlete = _athletes[index];
                              final name = (athlete['displayName'] ??
                                      athlete['fullName'] ??
                                      'Athlete')
                                  .toString();
                              final city = ArmSphereFormatters.formatCleanAddress([
                                athlete['city']?.toString(),
                                athlete['province']?.toString(),
                              ]);
                              final weightClass =
                                  (athlete['weightClass'] ?? '').toString();
                              final elo = athlete['rightArmElo'] ?? 1200;
                              final alreadyCertified =
                                  athlete['alreadyCertifiedByOrg'] == true;
                              final activeLevel =
                                  athlete['activeCertificationLevel']
                                      ?.toString();

                              return ElevatedActionCard(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: AppTheme.goldPrimary
                                              .withValues(alpha: 0.16),
                                          child: Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : 'A',
                                            style: const TextStyle(
                                              fontFamily: AppTheme.fontDisplay,
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.goldPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily:
                                                      AppTheme.fontDisplay,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  color: AppTheme.textPure,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                [
                                                  if (city.isNotEmpty) city,
                                                  if (weightClass.isNotEmpty)
                                                    weightClass,
                                                  'ELO $elo',
                                                ].join(' • '),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                                    if (alreadyCertified)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 9,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.emerald
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppTheme.emerald
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.verified_rounded,
                                              size: 16,
                                              color: AppTheme.emerald,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'Certified Official${activeLevel != null && activeLevel.isNotEmpty ? ' • $activeLevel' : ''}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily:
                                                      AppTheme.fontDisplay,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                  color: AppTheme.emerald,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.goldPrimary,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 11,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () =>
                                              _openGrantCertificationModal(
                                                  athlete),
                                          icon: const Icon(
                                            Icons.workspace_premium_rounded,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Grant Official Certification',
                                            style: TextStyle(
                                              fontFamily: AppTheme.fontDisplay,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildCertifiedOfficialsTab() {
    if (_loadingOfficials) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldPrimary),
      );
    }
    if (_officialsError != null) {
      return _buildErrorState(_officialsError!, _fetchOfficials);
    }
    if (_officials.isEmpty) {
      return _buildEmptyState(
        icon: Icons.verified_user_outlined,
        title: 'No Certified Officials Yet',
        subtitle:
            'Approve incoming referee requests or search registered athletes to issue official ${_orgName()} certifications.',
      );
    }

    return RefreshIndicator(
      color: AppTheme.goldPrimary,
      onRefresh: _fetchOfficials,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        itemCount: _officials.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final cert = _officials[index];
          final name =
              (cert['fullName'] ?? cert['displayName'] ?? 'Certified Official')
                  .toString();
          final level =
              (cert['certificationLevel'] ?? 'Official Referee').toString();
          final status = (cert['status'] ?? 'ACTIVE').toString().toUpperCase();
          final isActive = status == 'ACTIVE';
          final issuedDate = _formatDate(cert['issuedAt']);
          final issuer = ArmSphereFormatters.formatOrganizationName(
            (cert['issuingOrganizationName'] ?? cert['issuingBody'] ?? _orgName())
                .toString(),
          );
          final city = ArmSphereFormatters.formatCleanAddress([
            cert['city']?.toString(),
            cert['province']?.toString(),
          ]);

          return ElevatedActionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isActive ? AppTheme.emerald : AppTheme.crimson)
                            .withValues(alpha: 0.14),
                        border: Border.all(
                          color: (isActive ? AppTheme.emerald : AppTheme.crimson)
                              .withValues(alpha: 0.45),
                        ),
                      ),
                      child: Icon(
                        isActive
                            ? Icons.verified_user_rounded
                            : Icons.gpp_bad_outlined,
                        color: isActive ? AppTheme.emerald : AppTheme.crimson,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppTheme.textPure,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            level,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusPill(status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Issued by: $issuer',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    'Issued $issuedDate',
                    if (city.isNotEmpty) city,
                  ].join(' • '),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.crimson,
                        side: BorderSide(
                          color: AppTheme.crimson.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _openRevokeModal(cert),
                      icon: const Icon(Icons.block_rounded, size: 15),
                      label: const Text(
                        'Revoke',
                        style: TextStyle(
                          fontFamily: AppTheme.fontDisplay,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    switch (status) {
      case 'ACTIVE':
      case 'APPROVED':
        color = AppTheme.emerald;
        break;
      case 'REJECTED':
      case 'REVOKED':
        color = AppTheme.crimson;
        break;
      default:
        color = AppTheme.goldPrimary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: AppTheme.fontDisplay,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ElevatedActionCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: AppTheme.goldPrimary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.fontDisplay,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPure,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, Future<void> Function() onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ElevatedActionCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 38, color: AppTheme.crimson),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.goldPrimary,
                  foregroundColor: Colors.black,
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
