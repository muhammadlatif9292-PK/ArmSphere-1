import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../storage/hive_storage.dart';
import '../storage/secure_storage.dart';
import '../api/dio_client.dart';
import '../api/differential_sync.dart';
import '../api/offline_sync.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final hiveStorageProvider = Provider<HiveStorage>((ref) {
  return HiveStorage();
});

final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final connectivity = ref.watch(connectivityProvider);
  return DioClient(secureStorage: secureStorage, connectivity: connectivity);
});

final differentialSyncManagerProvider = Provider<DifferentialSyncManager>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return DifferentialSyncManager(dioClient: dioClient, hiveStorage: hiveStorage);
});

final offlineSyncManagerProvider = Provider<OfflineSyncManager>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final hiveStorage = ref.watch(hiveStorageProvider);
  return OfflineSyncManager(dioClient: dioClient, hiveStorage: hiveStorage);
});
