// test/features/admin/admin_workspace_convergence_test.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/core/providers/admin_provider.dart';
import 'package:mobile/core/providers/tournament_provider.dart';
import 'package:mobile/core/security/admin_permissions.dart';
import 'package:mobile/core/security/audit_chain_verifier.dart';
import 'package:mobile/core/widgets/main_shell_screen.dart';
import 'package:mobile/features/admin/screens/admin_arena_ops_screen.dart';
import 'package:mobile/features/admin/screens/admin_command_screen.dart';
import 'package:mobile/features/admin/screens/admin_dossier_screen.dart';
import 'package:mobile/features/admin/screens/admin_governance_screen.dart';
import 'package:mobile/features/admin/screens/admin_roster_screen.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';

class _TestAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _TestAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestTournamentNotifier extends TournamentNotifier {
  final List<Map<String, dynamic>> _data;
  _TestTournamentNotifier([this._data = const []]);

  @override
  Future<List<Map<String, dynamic>>> build() async => _data;
}

void main() {
  group('Canonical SHA-256 Audit Chain Verifier', () {
    String computeHash8({
      required String parentHash,
      required String id,
      required String actorId,
      required String entityType,
      required String entityId,
      required String actionType,
      required Map<String, dynamic> payload,
      required String createdAt,
    }) {
      final canonicalPayload = jsonEncode(payload);
      final raw = '$parentHash|$id|$actorId|$entityType|$entityId|$actionType|$canonicalPayload|$createdAt';
      return sha256.convert(utf8.encode(raw)).toString();
    }

    test('validates authentic genesis-anchored event chain successfully', () {
      final genesisParent = '0' * 64;
      final t1 = '2026-11-01T10:00:00.000Z';
      final h1 = computeHash8(
        parentHash: genesisParent,
        id: 'evt_1',
        actorId: 'admin_sys',
        entityType: 'ATHLETE',
        entityId: 'ath_10',
        actionType: 'ATHLETE_VERIFIED',
        payload: {'status': 'VERIFIED'},
        createdAt: t1,
      );

      final t2 = '2026-11-01T10:05:00.000Z';
      final h2 = computeHash8(
        parentHash: h1,
        id: 'evt_2',
        actorId: 'ref_1',
        entityType: 'MATCH',
        entityId: 'match_99',
        actionType: 'MATCH_COMPLETED',
        payload: {'winnerId': 'ath_10'},
        createdAt: t2,
      );

      final events = [
        {
          'id': 'evt_1',
          'parentHash': genesisParent,
          'currentHash': h1,
          'actorId': 'admin_sys',
          'entityType': 'ATHLETE',
          'entityId': 'ath_10',
          'actionType': 'ATHLETE_VERIFIED',
          'payload': {'status': 'VERIFIED'},
          'createdAt': t1,
        },
        {
          'id': 'evt_2',
          'parentHash': h1,
          'currentHash': h2,
          'actorId': 'ref_1',
          'entityType': 'MATCH',
          'entityId': 'match_99',
          'actionType': 'MATCH_COMPLETED',
          'payload': {'winnerId': 'ath_10'},
          'createdAt': t2,
        },
      ];

      final report = AuditChainVerifier.verifyChain(rawEvents: events);
      expect(report.isValid, isTrue);
      expect(report.verifiedCount, equals(2));
      expect(report.failureReason, isNull);
      expect(report.brokenIndex, isNull);
    });

    test('detects tampered payload data and pinpoints corrupt event index', () {
      final genesisParent = '0' * 64;
      final t1 = '2026-11-01T10:00:00.000Z';
      final h1 = computeHash8(
        parentHash: genesisParent,
        id: 'evt_1',
        actorId: 'admin_sys',
        entityType: 'ATHLETE',
        entityId: 'ath_10',
        actionType: 'ATHLETE_VERIFIED',
        payload: {'status': 'VERIFIED'},
        createdAt: t1,
      );

      final events = [
        {
          'id': 'evt_1',
          'parentHash': genesisParent,
          'currentHash': h1,
          'actorId': 'admin_sys',
          'entityType': 'ATHLETE',
          'entityId': 'ath_10',
          'actionType': 'ATHLETE_VERIFIED',
          // Tampered payload field
          'payload': {'status': 'TAMPERED_ILLEGAL'},
          'createdAt': t1,
        },
      ];

      final report = AuditChainVerifier.verifyChain(rawEvents: events);
      expect(report.isValid, isFalse);
      expect(report.brokenIndex, equals(0));
      expect(report.failureReason, contains('Hash mismatch at block #0'));
    });

    test('detects broken parent-hash link continuity between blocks', () {
      final genesisParent = '0' * 64;
      final t1 = '2026-11-01T10:00:00.000Z';
      final h1 = computeHash8(
        parentHash: genesisParent,
        id: 'evt_1',
        actorId: 'admin_sys',
        entityType: 'ATHLETE',
        entityId: 'ath_10',
        actionType: 'ATHLETE_VERIFIED',
        payload: {'status': 'VERIFIED'},
        createdAt: t1,
      );

      final t2 = '2026-11-01T10:05:00.000Z';
      final h2 = computeHash8(
        parentHash: 'corrupt_broken_parent_link',
        id: 'evt_2',
        actorId: 'ref_1',
        entityType: 'MATCH',
        entityId: 'match_99',
        actionType: 'MATCH_COMPLETED',
        payload: {'winnerId': 'ath_10'},
        createdAt: t2,
      );

      final events = [
        {
          'id': 'evt_1',
          'parentHash': genesisParent,
          'currentHash': h1,
          'actorId': 'admin_sys',
          'entityType': 'ATHLETE',
          'entityId': 'ath_10',
          'actionType': 'ATHLETE_VERIFIED',
          'payload': {'status': 'VERIFIED'},
          'createdAt': t1,
        },
        {
          'id': 'evt_2',
          // Corrupt parent link does not match h1
          'parentHash': 'corrupt_broken_parent_link',
          'currentHash': h2,
          'actorId': 'ref_1',
          'entityType': 'MATCH',
          'entityId': 'match_99',
          'actionType': 'MATCH_COMPLETED',
          'payload': {'winnerId': 'ath_10'},
          'createdAt': t2,
        },
      ];

      final report = AuditChainVerifier.verifyChain(rawEvents: events);
      expect(report.isValid, isFalse);
      expect(report.brokenIndex, equals(1));
      expect(report.failureReason, contains('Parent hash link broken'));
    });
  });

  group('AdminPermissions RBAC & Jurisdiction Policy', () {
    test('identifies the 5 Admin Workspace roles vs Athlete/Official roles', () {
      expect(AdminPermissions.isAdminWorkspaceRole('SYSTEM_ADMIN'), isTrue);
      expect(AdminPermissions.isAdminWorkspaceRole('NATIONAL_DIRECTOR'), isTrue);
      expect(
        AdminPermissions.isAdminWorkspaceRole('PROVINCIAL_DIRECTOR'),
        isTrue,
      );
      expect(
        AdminPermissions.isAdminWorkspaceRole('COMPLIANCE_OFFICER'),
        isTrue,
      );
      expect(AdminPermissions.isAdminWorkspaceRole('SUPPORT_AGENT'), isTrue);

      expect(AdminPermissions.isAdminWorkspaceRole('ATHLETE'), isFalse);
      expect(AdminPermissions.isAdminWorkspaceRole('REFEREE'), isFalse);
      expect(
        AdminPermissions.isAdminWorkspaceRole('TOURNAMENT_OPERATOR'),
        isFalse,
      );
      expect(
        AdminPermissions.isAdminWorkspaceRole('ORGANIZATION_LEADER'),
        isFalse,
      );
    });

    test('enforces Provincial Director jurisdiction lock on province-scoped actions', () {
      expect(
        AdminPermissions.canPerform(
          'PROVINCIAL_DIRECTOR',
          AdminAction.reviewAthlete,
          jurisdiction: 'Punjab',
          targetProvince: 'Punjab',
        ),
        isTrue,
      );
      expect(
        AdminPermissions.canPerform(
          'PROVINCIAL_DIRECTOR',
          AdminAction.reviewAthlete,
          jurisdiction: 'Punjab',
          targetProvince: 'Sindh',
        ),
        isFalse,
      );
      // Provincial Director cannot blacklist
      expect(
        AdminPermissions.canPerform(
          'PROVINCIAL_DIRECTOR',
          AdminAction.blacklistAthlete,
          jurisdiction: 'Punjab',
          targetProvince: 'Punjab',
        ),
        isFalse,
      );
      expect(
        AdminPermissions.canPerform(
          'NATIONAL_DIRECTOR',
          AdminAction.blacklistAthlete,
        ),
        isTrue,
      );
    });

    test('validates expanded administrative actions across all roles', () {
      // SYSTEM_ADMIN and NATIONAL_DIRECTOR have executive federation actions
      expect(
        AdminPermissions.canPerform('SYSTEM_ADMIN', AdminAction.overrideMatch),
        isTrue,
      );
      expect(
        AdminPermissions.canPerform('NATIONAL_DIRECTOR', AdminAction.overrideMatch),
        isTrue,
      );
      expect(
        AdminPermissions.canPerform('PROVINCIAL_DIRECTOR', AdminAction.overrideMatch),
        isFalse,
      );

      // Audit chain verification permission
      expect(
        AdminPermissions.canPerform('SYSTEM_ADMIN', AdminAction.verifyAuditChain),
        isTrue,
      );
      expect(
        AdminPermissions.canPerform('COMPLIANCE_OFFICER', AdminAction.verifyAuditChain),
        isTrue,
      );
      expect(
        AdminPermissions.canPerform('SUPPORT_AGENT', AdminAction.verifyAuditChain),
        isFalse,
      );

      // Referee license and suspension controls
      expect(
        AdminPermissions.canPerform('SYSTEM_ADMIN', AdminAction.updateRefereeLicense),
        isTrue,
      );
      expect(
        AdminPermissions.canPerform('NATIONAL_DIRECTOR', AdminAction.suspendReferee),
        isTrue,
      );
      expect(
        AdminPermissions.canPerform('PROVINCIAL_DIRECTOR', AdminAction.assignRefereeRegion),
        isTrue,
      );

      // Ordinary athlete cannot perform admin actions
      expect(
        AdminPermissions.canPerform('ATHLETE', AdminAction.reviewAthlete),
        isFalse,
      );
      expect(
        AdminPermissions.canPerform('ATHLETE', AdminAction.verifyVenue),
        isFalse,
      );
    });
  });

  group('MainShellScreen Role-Adaptive 5-Tab Bottom Navigation Dock', () {
    testWidgets(
      'switches bottom dock between Athlete tabs and Admin tabs based on Admin Mode',
      (tester) async {
        bool adminMode = false;
        late StateSetter outerSetState;

        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) {
                return StatefulBuilder(
                  builder: (ctx, setState) {
                    outerSetState = setState;
                    return MainShellScreen(
                      navigationShell: navigationShell,
                      isAdminModeOverride: adminMode,
                    );
                  },
                );
              },
              branches: [
                for (final path in const [
                  '/home',
                  '/discover',
                  '/tournaments',
                  '/community/feed',
                  '/athlete/profile',
                ])
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: path,
                        builder: (context, state) =>
                            Center(child: Text('Route $path')),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Athlete Mode tabs
        expect(find.text('Arena'), findsOneWidget);
        expect(find.text('Discover'), findsOneWidget);
        expect(find.text('Events'), findsOneWidget);
        expect(find.text('Community'), findsOneWidget);
        expect(find.text('Passport'), findsOneWidget);
        expect(find.text('Command'), findsNothing);

        // Switch to Admin Mode
        outerSetState(() => adminMode = true);
        await tester.pumpAndSettle();

        // Admin Mode 5 native tabs
        expect(find.text('Command'), findsOneWidget);
        expect(find.text('Roster'), findsOneWidget);
        expect(find.text('Arena Ops'), findsOneWidget);
        expect(find.text('Governance'), findsOneWidget);
        expect(find.text('Dossier'), findsOneWidget);
        expect(find.text('Arena'), findsNothing);
      },
    );
  });

  group('Native Admin Screens Rendering & Integrity Checks', () {
    testWidgets(
      'AdminCommandScreen renders backlog triage grid, role grants, and ELO distribution',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => _TestAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    activeRole: 'SYSTEM_ADMIN',
                    verifiedRoles: const ['ATHLETE', 'SYSTEM_ADMIN'],
                    userProfile: const {
                      'id': 'admin_1',
                      'displayName': 'Chief Commissioner',
                      'role': 'SYSTEM_ADMIN',
                    },
                  ),
                ),
              ),
              adminDashboardStatsProvider.overrideWith(
                (ref) async => const {
                  'pendingVerifications': 7,
                  'openDisputes': 3,
                  'totalAthletes': 120,
                  'totalMatches': 340,
                },
              ),
              adminRoleApplicationsProvider.overrideWith(
                (ref) async => const <Map<String, dynamic>>[],
              ),
              adminAnalyticsOverviewProvider.overrideWith(
                (ref) async => const {
                  'activeTournaments': 4,
                  'averageElo': 1360,
                },
              ),
              adminEloDistributionProvider.overrideWith(
                (ref) async => const <Map<String, dynamic>>[],
              ),
            ],
            child: const MaterialApp(home: AdminCommandScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Executive Command'), findsOneWidget);
        expect(find.text('SYS ADMIN'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('GRANT ROLE'), findsOneWidget);
        expect(find.text('EXPORT REPORT'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminRosterScreen displays Jurisdiction Lock Banner for PROVINCIAL_DIRECTOR',
      (tester) async {
        const filter = AdminAthleteFilter(
          search: '',
          status: '',
          province: 'Punjab',
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => _TestAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    activeRole: 'PROVINCIAL_DIRECTOR',
                    verifiedRoles: const ['ATHLETE', 'PROVINCIAL_DIRECTOR'],
                    userProfile: const {
                      'id': 'prov_1',
                      'displayName': 'Punjab Director',
                      'role': 'PROVINCIAL_DIRECTOR',
                      'jurisdiction': 'Punjab',
                    },
                  ),
                ),
              ),
              adminAthletesProvider(filter).overrideWith(
                (ref) async => const [
                  {
                    'id': 'ath_1',
                    'displayName': 'Tariq Javed',
                    'province': 'Punjab',
                    'weightClass': '95kg',
                    'rightArmElo': 1490,
                    'leftArmElo': 1420,
                    'verificationStatus': 'PENDING',
                  },
                ],
              ),
              adminRefereesProvider.overrideWith((ref) async => const []),
              adminNominationsProvider.overrideWith((ref) async => const []),
            ],
            child: const MaterialApp(home: AdminRosterScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('admin_locked_jurisdiction_banner')),
          findsOneWidget,
        );
        expect(find.textContaining('JURISDICTION LOCK: PUNJAB'), findsOneWidget);
        expect(find.text('Tariq Javed'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminArenaOpsScreen renders matches, belts, and tournaments segments',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => _TestAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    activeRole: 'SYSTEM_ADMIN',
                    verifiedRoles: const ['ATHLETE', 'SYSTEM_ADMIN'],
                    userProfile: const {
                      'id': 'admin_1',
                      'displayName': 'Commissioner',
                      'role': 'SYSTEM_ADMIN',
                    },
                  ),
                ),
              ),
              adminMatchesProvider.overrideWith((ref) async => const [
                {
                  'id': 'm_1',
                  'athleteAId': 'ath_1',
                  'athleteAName': 'Zubair Khan',
                  'athleteBId': 'ath_2',
                  'athleteBName': 'Hamza Ali',
                  'scoreA': 3,
                  'scoreB': 1,
                  'winnerId': 'ath_1',
                  'arm': 'RIGHT',
                  'weightClass': '85kg',
                  'status': 'COMPLETED',
                },
              ]),
              adminChampionshipTitlesProvider.overrideWith((ref) async => const []),
              adminPendingChallengesProvider.overrideWith((ref) async => const []),
              tournamentProvider.overrideWith(() => _TestTournamentNotifier()),
            ],
            child: const MaterialApp(home: AdminArenaOpsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Arena Operations'), findsOneWidget);
        expect(find.text('Match Oversight'), findsOneWidget);
        expect(find.text('Belt Titles'), findsOneWidget);
        expect(find.text('Tournaments'), findsOneWidget);
        expect(find.text('Zubair Khan'), findsOneWidget);
        expect(find.text('Hamza Ali'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminGovernanceScreen renders disputes, moderation, and gyms segments',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => _TestAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    activeRole: 'COMPLIANCE_OFFICER',
                    verifiedRoles: const ['ATHLETE', 'COMPLIANCE_OFFICER'],
                    userProfile: const {
                      'id': 'comp_1',
                      'displayName': 'Auditor Sana',
                      'role': 'COMPLIANCE_OFFICER',
                    },
                  ),
                ),
              ),
              adminDisputesProvider.overrideWith((ref) async => const [
                {
                  'id': 'disp_1',
                  'status': 'OPEN',
                  'reason': 'Protest on early elbow slip foul at table 2',
                  'claimantName': 'Bilal Qureshi',
                  'createdAt': '2026-11-01T10:00:00Z',
                },
              ]),
              adminPendingCommunityLinksProvider.overrideWith((ref) async => const []),
              adminVenuesProvider.overrideWith((ref) async => const []),
              adminSupportTicketsProvider(const AdminSupportFilter()).overrideWith((ref) async => const []),
            ],
            child: const MaterialApp(home: AdminGovernanceScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Federation Governance'), findsOneWidget);
        expect(find.text('Disputes'), findsOneWidget);
        expect(find.text('Moderation'), findsOneWidget);
        expect(find.text('Gyms'), findsOneWidget);
        expect(find.text('Helpdesk'), findsOneWidget);
        expect(find.textContaining('Protest on early elbow slip'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminDossierScreen renders credential passport and SHA-256 Audit Chain Verifier',
      (tester) async {
        const filter = AdminAuditFilter();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => _TestAuthNotifier(
                  AuthState(
                    status: AuthStatus.authenticated,
                    activeRole: 'COMPLIANCE_OFFICER',
                    verifiedRoles: const ['ATHLETE', 'COMPLIANCE_OFFICER'],
                    userProfile: const {
                      'id': 'comp_1',
                      'displayName': 'Auditor Sana',
                      'email': 'sana@armsphere.org',
                      'role': 'COMPLIANCE_OFFICER',
                    },
                  ),
                ),
              ),
              adminFullAuditReportProvider.overrideWith(
                (ref) async => AuditChainVerificationReport(
                  isValid: true,
                  clientChainValid: true,
                  serverChainValid: true,
                  totalEventsVerified: 64,
                  corruptedEventIds: const [],
                  verifiedAt: DateTime(2026, 11, 1),
                ),
              ),
              adminAuditVerificationProvider.overrideWith(
                (ref) async => const {
                  'valid': true,
                  'isValid': true,
                  'status': 'VALID',
                  'checkedCount': 64,
                },
              ),
              adminAuditEventsProvider(filter).overrideWith(
                (ref) async => const [
                  {
                    'id': 'evt_1',
                    'actionType': 'DISPUTE_RESOLVED',
                    'actorId': 'comp_1',
                    'currentHash': 'a94f820b771c9910',
                  },
                ],
              ),
            ],
            child: const MaterialApp(home: AdminDossierScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Official Dossier & Audit'), findsOneWidget);
        expect(
          find.text('SHA-256 Hash Chain Integrity: VALID'),
          findsOneWidget,
        );
        expect(find.text('DISPUTE_RESOLVED'), findsOneWidget);
      },
    );
  });
}
