import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_providers.dart';
import 'athlete_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Notifier to track if the current user follows a given athlete.
class FollowStatusNotifier extends AutoDisposeFamilyAsyncNotifier<bool, String> {
  @override
  Future<bool> build(String arg) async {
    final authState = ref.watch(authProvider);
    if (authState.userProfile == null) return false;

    try {
      final currentProfile = await ref.watch(athleteProfileProvider.future);
      final currentAthleteId = currentProfile['id']?.toString();
      if (currentAthleteId == null) return false;

      // Cannot follow oneself
      if (currentAthleteId == arg) return false;

      final repo = ref.watch(socialRepositoryProvider);
      return await repo.checkFollowStatus(arg);
    } catch (_) {
      return false;
    }
  }

  /// Follow the athlete
  Future<bool> follow() async {
    try {
      final repo = ref.read(socialRepositoryProvider);
      await repo.followAthlete(arg);
      state = const AsyncValue.data(true);

      // Invalidate the following list of the current user
      final currentProfile = await ref.read(athleteProfileProvider.future);
      final currentAthleteId = currentProfile['id']?.toString();
      if (currentAthleteId != null) {
        ref.invalidate(followingProvider(currentAthleteId));
      }

      // Invalidate the followers list of the target athlete
      ref.invalidate(followersProvider(arg));
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Unfollow the athlete
  Future<bool> unfollow() async {
    try {
      final repo = ref.read(socialRepositoryProvider);
      await repo.unfollowAthlete(arg);
      state = const AsyncValue.data(false);

      // Invalidate the following list of the current user
      final currentProfile = await ref.read(athleteProfileProvider.future);
      final currentAthleteId = currentProfile['id']?.toString();
      if (currentAthleteId != null) {
        ref.invalidate(followingProvider(currentAthleteId));
      }

      // Invalidate the followers list of the target athlete
      ref.invalidate(followersProvider(arg));
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

/// Provider for FollowStatusNotifier family.
final followStatusProvider = AsyncNotifierProvider.autoDispose.family<FollowStatusNotifier, bool, String>(() {
  return FollowStatusNotifier();
});

/// Notifier to track followers of a given athlete.
class FollowersNotifier extends AutoDisposeFamilyAsyncNotifier<List<Map<String, dynamic>>, String> {
  @override
  Future<List<Map<String, dynamic>>> build(String arg) async {
    final repo = ref.watch(socialRepositoryProvider);
    return repo.getFollowers(arg);
  }
}

/// Provider for FollowersNotifier family.
final followersProvider = AsyncNotifierProvider.autoDispose.family<FollowersNotifier, List<Map<String, dynamic>>, String>(() {
  return FollowersNotifier();
});

/// Notifier to track athletes a given athlete is following.
class FollowingNotifier extends AutoDisposeFamilyAsyncNotifier<List<Map<String, dynamic>>, String> {
  @override
  Future<List<Map<String, dynamic>>> build(String arg) async {
    final repo = ref.watch(socialRepositoryProvider);
    return repo.getFollowing(arg);
  }
}

/// Provider for FollowingNotifier family.
final followingProvider = AsyncNotifierProvider.autoDispose.family<FollowingNotifier, List<Map<String, dynamic>>, String>(() {
  return FollowingNotifier();
});

/// Notifier to fetch team details and manage member operations.
class TeamNotifier extends AutoDisposeFamilyAsyncNotifier<Map<String, dynamic>, String> {
  @override
  Future<Map<String, dynamic>> build(String arg) async {
    final repo = ref.watch(socialRepositoryProvider);
    return repo.getTeam(arg);
  }

  /// Adds a new member to the team
  Future<bool> addMember(String athleteId, String role) async {
    try {
      final repo = ref.read(socialRepositoryProvider);
      await repo.addTeamMember(arg, athleteId, role);
      ref.invalidateSelf();
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Removes a member from the team
  Future<bool> removeMember(String athleteId) async {
    try {
      final repo = ref.read(socialRepositoryProvider);
      await repo.removeTeamMember(arg, athleteId);
      ref.invalidateSelf();
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Updates a member's role on the team ('CAPTAIN' or 'MEMBER')
  Future<bool> updateMemberRole(String athleteId, String role) async {
    try {
      final repo = ref.read(socialRepositoryProvider);
      await repo.updateTeamMemberRole(arg, athleteId, role);
      ref.invalidateSelf();
      ref.invalidate(myTeamsProvider);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Updates team metadata (name, description, foundedAt, clubId)
  Future<Map<String, dynamic>> updateTeam(Map<String, dynamic> payload) async {
    try {
      final repo = ref.read(socialRepositoryProvider);
      final updated = await repo.updateTeam(arg, payload);
      ref.invalidateSelf();
      ref.invalidate(myTeamsProvider);
      return updated;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Deletes the team
  Future<void> deleteTeam() async {
    final repo = ref.read(socialRepositoryProvider);
    await repo.deleteTeam(arg);
    ref.invalidate(myTeamsProvider);
  }

  /// Leaves the team as the authenticated athlete
  Future<void> leaveTeam() async {
    final repo = ref.read(socialRepositoryProvider);
    await repo.leaveTeam(arg);
    ref.invalidateSelf();
    ref.invalidate(myTeamsProvider);
  }
}

/// Provider for TeamNotifier family.
final teamProvider = AsyncNotifierProvider.autoDispose.family<TeamNotifier, Map<String, dynamic>, String>(() {
  return TeamNotifier();
});

/// Provider to list/search federation teams for directory and sparring invites.
final teamsDirectoryProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String?>((ref, search) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.listTeams(search: search);
});

/// Notifier to list and manage inter-team sparring invites (optionally scoped by teamId).
class SparringInvitesNotifier extends AutoDisposeFamilyAsyncNotifier<List<Map<String, dynamic>>, String?> {
  @override
  Future<List<Map<String, dynamic>>> build(String? arg) async {
    final repo = ref.watch(socialRepositoryProvider);
    return repo.listSparringInvites(teamId: arg);
  }

  Future<Map<String, dynamic>> createInvite(Map<String, dynamic> payload) async {
    final repo = ref.read(socialRepositoryProvider);
    final created = await repo.createSparringInvite(payload);
    ref.invalidateSelf();
    return created;
  }

  Future<Map<String, dynamic>> respondInvite(String inviteId, String action) async {
    final repo = ref.read(socialRepositoryProvider);
    final updated = await repo.respondSparringInvite(inviteId, action);
    ref.invalidateSelf();
    return updated;
  }

  Future<Map<String, dynamic>> cancelInvite(String inviteId) async {
    final repo = ref.read(socialRepositoryProvider);
    final updated = await repo.cancelSparringInvite(inviteId);
    ref.invalidateSelf();
    return updated;
  }
}

final sparringInvitesProvider = AsyncNotifierProvider.autoDispose
    .family<SparringInvitesNotifier, List<Map<String, dynamic>>, String?>(() {
  return SparringInvitesNotifier();
});

/// Notifier for managing team creation action.
class TeamCreationNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Creates a new team and returns its data if successful
  Future<Map<String, dynamic>> createTeam(Map<String, dynamic> payload) async {
    try {
      final repo = ref.read(socialRepositoryProvider);
      final newTeam = await repo.createTeam(payload);
      return newTeam;
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for TeamCreationNotifier.
final teamCreationProvider = AsyncNotifierProvider.autoDispose<TeamCreationNotifier, void>(() {
  return TeamCreationNotifier();
});

/// Notifier to fetch the teams the current user belongs to.
class MyTeamsNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repo = ref.watch(socialRepositoryProvider);
    return repo.getMyTeams();
  }
}

/// Provider for MyTeamsNotifier.
final myTeamsProvider = AsyncNotifierProvider.autoDispose<MyTeamsNotifier, List<Map<String, dynamic>>>(() {
  return MyTeamsNotifier();
});

/// Notifier to list and manage blocked users
class BlockedUsersNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repo = ref.watch(socialRepositoryProvider);
    return repo.getBlockedUsers();
  }

  Future<void> blockUser(String athleteId) async {
    final repo = ref.read(socialRepositoryProvider);
    await repo.blockUser(athleteId);
    ref.invalidateSelf();
  }

  Future<void> unblockUser(String athleteId) async {
    final repo = ref.read(socialRepositoryProvider);
    await repo.unblockUser(athleteId);
    ref.invalidateSelf();
  }
}

/// Provider for BlockedUsersNotifier.
final blockedUsersProvider = AsyncNotifierProvider.autoDispose<BlockedUsersNotifier, List<Map<String, dynamic>>>(() {
  return BlockedUsersNotifier();
});
