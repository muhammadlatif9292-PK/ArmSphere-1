import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/mfa_setup_screen.dart';
import '../../features/auth/screens/mfa_verification_screen.dart';
import '../../features/auth/screens/recovery_codes_screen.dart';
import '../../features/auth/screens/role_intent_screen.dart';
import '../../features/athlete/screens/onboarding_screen.dart';
import '../../features/athlete/screens/athlete_screens.dart';
import '../../features/athlete/screens/public_profile_screen.dart';
import '../../features/athlete/screens/training_log_screen.dart';
import '../../features/athlete/screens/followers_list_screen.dart';
import '../../features/athlete/screens/rankings_screen.dart';
import '../../features/home/screens/discover_screen.dart';
import '../../features/referee/screens/referee_screens.dart';
import '../../features/tournament/screens/tournament_screens.dart';
import '../../features/tournament/screens/tournament_operations_screen.dart';
import '../../features/tournament/screens/event_registration_screen.dart';
import '../../features/governance/screens/governance_screens.dart';
import '../../features/governance/screens/submit_complaint_screen.dart';
import '../../features/notifications/screens/notification_screens.dart';
import '../../features/session/screens/session_screens.dart';
import '../../features/championship/screens/championship_screens.dart';
import '../../features/messaging/screens/messaging_screens.dart';
import '../../features/messaging/screens/announcement_screens.dart';
import '../../features/settings/screens/settings_screens.dart';
import '../../features/settings/screens/payment_methods_screen.dart';
import '../../features/settings/screens/settings_hub_screens.dart';
import '../../features/team/screens/team_screens.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/community/screens/community_feed_screen.dart';
import '../../features/community/screens/post_comments_screen.dart';
import '../../features/community/screens/create_post_screen.dart';
import '../../features/venue/screens/venue_directory_screen.dart';
import '../../features/venue/screens/venue_detail_screen.dart';
import '../../features/venue/screens/submit_venue_screen.dart';
import '../../features/nomination/screens/my_nominations_screen.dart';
import '../../features/nomination/screens/nominate_talent_screen.dart';
import '../../features/informal_event/screens/informal_event_directory_screen.dart';
import '../../features/informal_event/screens/informal_event_detail_screen.dart';
import '../../features/informal_event/screens/create_informal_event_screen.dart';
import '../widgets/main_shell_screen.dart';
import 'page_transitions.dart';

/// Roles that route to the referee / official dashboard.
bool _isRefereeLikeRole(String? role) {
  const refereeRoles = {
    'REFEREE',
    'PROVINCIAL_DIRECTOR',
    'NATIONAL_DIRECTOR',
    'SYSTEM_ADMIN',
  };
  return role != null && refereeRoles.contains(role);
}

/// Roles that route to the governance dashboard.
bool _isGovernanceRole(String? role) {
  const govRoles = {
    'TOURNAMENT_OPERATOR',
    'COMPLIANCE_OFFICER',
    'SUPPORT_AGENT',
    'ORGANIZATION_LEADER',
  };
  return role != null && govRoles.contains(role);
}

/// Cold-start journey enforced by [redirect]:
///   splash → welcome → register/login → role intent → athlete onboarding → home
///
/// Auth-state changes are delivered through [GoRouter.refreshListenable] so a
/// sign-in/out never rebuilds the route table itself.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => refreshNotifier.value++);
  ref.onDispose(refreshNotifier.dispose);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final location = state.uri.toString();

      // Hold everyone on the splash until session restore resolves.
      if (status == AuthStatus.unknown) {
        return location == '/' ? null : '/';
      }

      const publicRoutes = <String>{
        '/welcome',
        '/login',
        '/register',
        '/forgot-password',
        '/reset-password',
      };

      switch (status) {
        case AuthStatus.unauthenticated:
          return publicRoutes.contains(location) ? null : '/welcome';

        case AuthStatus.mfaRequired:
          return location.startsWith('/mfa/verify') ? null : '/mfa/verify';

        case AuthStatus.onboardingRequired:
          const setupRoutes = <String>{'/role-intent', '/onboarding'};
          return setupRoutes.contains(location) ? null : '/role-intent';

        case AuthStatus.authenticated:
          const entryRoutes = <String>{
            '/',
            '/welcome',
            '/login',
            '/register',
            '/forgot-password',
            '/reset-password',
            '/role-intent',
            '/onboarding',
          };
          final atEntry =
              location == '/' || entryRoutes.contains(location) || location.startsWith('/mfa/verify');
          
          if (atEntry) {
            // Get verified server-side role from profile for routing decision
            final userRole = authState.userProfile?['role']?.toString().toUpperCase();
            
            if (_isRefereeLikeRole(userRole)) {
              return '/referee/dashboard';
            }
            // For athletes or pending roles, go to home
            return '/home';
          }
          
          // After authentication — redirect away from entry routes to the
          // correct dashboard. Route is based solely on the verified server-
          // side role; the client roleIntent is never used for authorization.
          final userRole = authState.userProfile?['role']?.toString().toUpperCase();
          if (_isRefereeLikeRole(userRole)) {
            return '/referee/dashboard';
          } else if (_isGovernanceRole(userRole)) {
            return '/governance';
          }
          return null; // Already at a non-entry route — allow navigation

        case AuthStatus.unknown:
          return location == '/' ? null : '/';
      }
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset_password',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const ResetPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/mfa/setup',
        name: 'mfa_setup',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const MfaSetupScreen(),
        ),
      ),
      GoRoute(
        path: '/mfa/verify',
        name: 'mfa_verify',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          return AppTransitionPage(
            key: state.pageKey,
            child: MfaVerificationScreen(
              email: extra?['email'],
              password: extra?['password'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/recovery-codes',
        name: 'recovery_codes',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const RecoveryCodesScreen(),
        ),
      ),
      GoRoute(
        path: '/role-intent',
        name: 'role_intent',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const RoleIntentScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const AthleteDashboardScreen(),
              ),
              GoRoute(
                path: '/athlete/dashboard',
                name: 'athlete_dashboard',
                builder: (context, state) => const AthleteDashboardScreen(),
              ),
              GoRoute(
                path: '/referee/dashboard',
                name: 'referee_dashboard',
                builder: (context, state) => const RefereeDashboardScreen(),
              ),
              GoRoute(
                path: '/governance',
                name: 'governance',
                builder: (context, state) => const GovernanceDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                name: 'discover',
                builder: (context, state) => const DiscoverScreen(),
              ),
              GoRoute(
                path: '/rankings',
                name: 'rankings',
                builder: (context, state) => const RankingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tournaments',
                name: 'tournaments_tab',
                builder: (context, state) => const TournamentsListScreen(),
              ),
              GoRoute(
                path: '/tournament/dashboard',
                name: 'tournament_dashboard_tab',
                builder: (context, state) => const TournamentsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community/feed',
                name: 'community_feed',
                builder: (context, state) => const CommunityFeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/athlete/profile',
                name: 'athlete_profile_tab',
                builder: (context, state) => const AthleteProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const GlobalSearchScreen(),
        ),
      ),
      GoRoute(
        path: '/athlete/:athleteId',
        name: 'public_athlete_profile',
        pageBuilder: (context, state) {
          final athleteId = state.pathParameters['athleteId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: PublicAthleteProfileScreen(athleteId: athleteId),
          );
        },
      ),
      GoRoute(
        path: '/athlete/:athleteId/followers',
        name: 'athlete_followers',
        pageBuilder: (context, state) {
          final athleteId = state.pathParameters['athleteId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: FollowersListScreen(athleteId: athleteId),
          );
        },
      ),
      GoRoute(
        path: '/athlete/:athleteId/training-log',
        name: 'athlete_training_log',
        pageBuilder: (context, state) {
          final athleteId = state.pathParameters['athleteId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: AthleteTrainingLogScreen(athleteId: athleteId),
          );
        },
      ),
      GoRoute(
        path: '/athlete/:athleteId/following',
        name: 'athlete_following',
        pageBuilder: (context, state) {
          final athleteId = state.pathParameters['athleteId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: FollowingListScreen(athleteId: athleteId),
          );
        },
      ),
      GoRoute(
        path: '/teams',
        name: 'teams_list',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const TeamsListScreen(),
        ),
      ),
      GoRoute(
        path: '/teams/create',
        name: 'create_team',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const CreateTeamScreen(),
        ),
      ),
      GoRoute(
        path: '/teams/:teamId',
        name: 'team_detail',
        pageBuilder: (context, state) {
          final teamId = state.pathParameters['teamId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: TeamDetailScreen(teamId: teamId),
          );
        },
      ),
      GoRoute(
        path: '/referee/dashboard',
        name: 'referee_dashboard',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const RefereeDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/tournament/:tournamentId',
        name: 'tournament_detail',
        pageBuilder: (context, state) {
          final tournamentId = state.pathParameters['tournamentId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: TournamentDetailScreen(tournamentId: tournamentId),
          );
        },
      ),
      GoRoute(
        path: '/tournament/:tournamentId/register',
        name: 'tournament_registration',
        pageBuilder: (context, state) {
          final tournamentId = state.pathParameters['tournamentId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: EventRegistrationScreen(tournamentId: tournamentId),
          );
        },
      ),
      GoRoute(
        path: '/tournament/:tournamentId/brackets',
        name: 'tournament_brackets',
        pageBuilder: (context, state) {
          final tournamentId = state.pathParameters['tournamentId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: TournamentBracketsScreen(tournamentId: tournamentId),
          );
        },
      ),
      GoRoute(
        path: '/tournament/:tournamentId/operations',
        name: 'tournament_operations',
        pageBuilder: (context, state) {
          final tournamentId = state.pathParameters['tournamentId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: TournamentOperationsScreen(tournamentId: tournamentId),
          );
        },
      ),
      GoRoute(
        path: '/events/:eventId/register',
        name: 'event_registration_legacy',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: EventRegistrationScreen(tournamentId: eventId),
          );
        },
      ),
      GoRoute(
        path: '/tournament/details',
        name: 'tournament_details_legacy',
        pageBuilder: (context, state) {
          final tournament = (state.extra as Map<String, dynamic>?) ?? {};
          final tournamentId = tournament['id']?.toString() ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: TournamentDetailScreen(tournamentId: tournamentId),
          );
        },
      ),
      GoRoute(
        path: '/tournament/operations',
        name: 'tournament_operations_legacy',
        pageBuilder: (context, state) {
          final tournament = (state.extra as Map<String, dynamic>?) ?? {};
          final tournamentId = tournament['id']?.toString() ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: TournamentOperationsScreen(tournamentId: tournamentId),
          );
        },
      ),
      GoRoute(
        path: '/tournament/brackets',
        name: 'tournament_brackets_legacy',
        pageBuilder: (context, state) {
          final tournament = (state.extra as Map<String, dynamic>?) ?? {};
          final tournamentId = tournament['id']?.toString() ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: TournamentBracketsScreen(tournamentId: tournamentId),
          );
        },
      ),
      GoRoute(
        path: '/championship/titles',
        name: 'championship_titles',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const ChampionshipsListScreen(),
        ),
      ),
      GoRoute(
        path: '/championship/:championshipId',
        name: 'championship_detail',
        pageBuilder: (context, state) {
          final championshipId = state.pathParameters['championshipId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: ChampionshipDetailScreen(championshipId: championshipId),
          );
        },
      ),
      GoRoute(
        path: '/governance',
        name: 'governance',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const GovernanceDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/governance/federation',
        name: 'governance_federation',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const GovernanceDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/governance/disputes',
        name: 'governance_disputes',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const GovernanceDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/governance/dispute/:disputeId',
        name: 'governance_dispute_detail',
        pageBuilder: (context, state) {
          final disputeId = state.pathParameters['disputeId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: DisputeDetailScreen(disputeId: disputeId),
          );
        },
      ),
      GoRoute(
        path: '/governance/disputes/detail',
        name: 'governance_dispute_detail_legacy',
        pageBuilder: (context, state) {
          final dispute = (state.extra as Map<String, dynamic>?) ?? {};
          final disputeId = dispute['id']?.toString() ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: DisputeDetailScreen(disputeId: disputeId),
          );
        },
      ),
      GoRoute(
        path: '/governance/submit-complaint',
        name: 'governance_submit_complaint',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const SubmitComplaintScreen(),
        ),
      ),
      GoRoute(
        path: '/messages',
        name: 'conversations_list',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const ConversationsListScreen(),
        ),
      ),
      GoRoute(
        path: '/messages/:conversationId',
        name: 'messaging_thread',
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: ChatScreen(conversationId: conversationId),
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const NotificationsListScreen(),
        ),
      ),
      GoRoute(
        path: '/announcements',
        name: 'announcements',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const AnnouncementsListScreen(),
        ),
      ),
      GoRoute(
        path: '/session',
        name: 'session',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const ActiveSessionsListScreen(),
        ),
      ),
      GoRoute(
        path: '/athlete/session/:sessionId',
        name: 'active_session_detail',
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: ActiveSessionControlScreen(sessionId: sessionId),
          );
        },
      ),
      GoRoute(
        path: '/settings/payment-methods',
        name: 'payment_methods',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const PaymentMethodsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/tickets',
        name: 'my_tickets',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const MyTicketsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/blocked',
        name: 'blocked_users',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const BlockedUsersScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings_hub',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const SettingsHubScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/deletion',
        name: 'account_deletion',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const AccountDeletionScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/terms',
        name: 'terms',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const TermsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/privacy',
        name: 'privacy_policy',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
        ),
      ),
      GoRoute(
        path: '/community/posts/:postId/comments',
        name: 'post_comments',
        pageBuilder: (context, state) {
          final postId = state.pathParameters['postId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: PostCommentsScreen(postId: postId),
          );
        },
      ),
      GoRoute(
        path: '/community/post/:postId/comments',
        name: 'post_comments_alternate',
        pageBuilder: (context, state) {
          final postId = state.pathParameters['postId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: PostCommentsScreen(postId: postId),
          );
        },
      ),
      GoRoute(
        path: '/community/create',
        name: 'create_post',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const CreatePostScreen(),
        ),
      ),
      GoRoute(
        path: '/community/post/create',
        name: 'create_post_alternate',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const CreatePostScreen(),
        ),
      ),
      GoRoute(
        path: '/venues',
        name: 'venues',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const VenueDirectoryScreen(),
        ),
      ),
      GoRoute(
        path: '/venues/submit',
        name: 'submit_venue',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const SubmitVenueScreen(),
        ),
      ),
      GoRoute(
        path: '/venues/:venueId',
        name: 'venue_detail',
        pageBuilder: (context, state) {
          final venueId = state.pathParameters['venueId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: VenueDetailScreen(venueId: venueId),
          );
        },
      ),
      GoRoute(
        path: '/venues/detail/:venueId',
        name: 'venue_detail_legacy',
        pageBuilder: (context, state) {
          final venueId = state.pathParameters['venueId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: VenueDetailScreen(venueId: venueId),
          );
        },
      ),
      GoRoute(
        path: '/nominations/my',
        name: 'my_nominations',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const MyNominationsScreen(),
        ),
      ),
      GoRoute(
        path: '/nominations/submit',
        name: 'submit_nomination',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const NominateTalentScreen(),
        ),
      ),
      GoRoute(
        path: '/nominate',
        name: 'submit_nomination_alternate',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const NominateTalentScreen(),
        ),
      ),
      GoRoute(
        path: '/informal-events',
        name: 'informal_events',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const InformalEventDirectoryScreen(),
        ),
      ),
      GoRoute(
        path: '/informal-events/create',
        name: 'create_informal_event',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const CreateInformalEventScreen(),
        ),
      ),
      GoRoute(
        path: '/informal-events/:eventId',
        name: 'informal_event_detail',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: InformalEventDetailScreen(eventId: eventId),
          );
        },
      ),
      GoRoute(
        path: '/informal-events/detail/:eventId',
        name: 'informal_event_detail_legacy',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          return AppTransitionPage(
            key: state.pageKey,
            child: InformalEventDetailScreen(eventId: eventId),
          );
        },
      ),
      GoRoute(
        path: '/referee/certifications',
        name: 'referee_certifications',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const RefereeCertificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/referee/submit-scorepad',
        name: 'referee_submit_scorepad',
        pageBuilder: (context, state) {
          final match = state.extra as Map<String, dynamic>?;
          return AppTransitionPage(
            key: state.pageKey,
            child: MatchSubmissionScreen(match: match),
          );
        },
      ),
      GoRoute(
        path: '/referee/search-athletes',
        name: 'referee_search_athletes',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const AthleteSearchScreen(),
        ),
      ),
      GoRoute(
        path: '/referee/upload-evidence',
        name: 'referee_upload_evidence',
        pageBuilder: (context, state) => AppTransitionPage(
          key: state.pageKey,
          child: const EvidenceUploadScreen(),
        ),
      ),
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        pageBuilder: (context, state) {
          final athleteId = state.extra as String?;
          return AppTransitionPage(
            key: state.pageKey,
            child: AthleteAchievementsScreen(athleteId: athleteId),
          );
        },
      ),
      GoRoute(
        path: '/athlete/achievements',
        name: 'athlete_achievements',
        pageBuilder: (context, state) {
          final athleteId = state.extra as String?;
          return AppTransitionPage(
            key: state.pageKey,
            child: AthleteAchievementsScreen(athleteId: athleteId),
          );
        },
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
