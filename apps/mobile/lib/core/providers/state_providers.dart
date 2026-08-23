import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/repositories.dart';
import 'dependency_providers.dart';

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return AuthRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

final athleteRepositoryProvider = Provider<AthleteRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return AthleteRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return MatchRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return TournamentRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

final rankingsRepositoryProvider = Provider<RankingsRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return RankingsRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

final disputeRepositoryProvider = Provider<DisputeRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return DisputeRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return NotificationRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

final championshipRepositoryProvider = Provider<ChampionshipRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return ChampionshipRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return MessagingRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return SocialRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return CommunityRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return VenueRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

final nominationRepositoryProvider = Provider<NominationRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return NominationRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});

final informalEventRepositoryProvider = Provider<InformalEventRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return InformalEventRepository(dioClient: dioClient, hiveStorage: hiveStorage);
});
