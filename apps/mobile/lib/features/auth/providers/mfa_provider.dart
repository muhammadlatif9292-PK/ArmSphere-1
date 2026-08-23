import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class MfaState {
  final bool isLoading;
  final String? errorMessage;
  final String? qrCodeUrl;
  final String? secret;
  final List<String>? recoveryCodes;
  final bool isSetupComplete;
  final bool isVerified;

  MfaState({
    this.isLoading = false,
    this.errorMessage,
    this.qrCodeUrl,
    this.secret,
    this.recoveryCodes,
    this.isSetupComplete = false,
    this.isVerified = false,
  });

  MfaState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? qrCodeUrl,
    String? secret,
    List<String>? recoveryCodes,
    bool? isSetupComplete,
    bool? isVerified,
  }) {
    return MfaState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      secret: secret ?? this.secret,
      recoveryCodes: recoveryCodes ?? this.recoveryCodes,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class MfaNotifier extends StateNotifier<MfaState> {
  final Ref _ref;

  MfaNotifier(this._ref) : super(MfaState());

  Future<bool> setupMfa() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dioClient = _ref.read(dioClientProvider);
      final response = await dioClient.dio.post('/auth/mfa/setup');
      
      final body = response.data;
      final Map<String, dynamic> payload = (body is Map && body.containsKey('data')) 
          ? Map<String, dynamic>.from(body['data']) 
          : Map<String, dynamic>.from(body ?? {});

      final qrCode = payload['qrCode']?.toString();
      final secret = payload['secret']?.toString();
      final List<dynamic>? codesRaw = payload['recoveryCodes'] as List<dynamic>?;
      final List<String>? codes = codesRaw?.map((e) => e.toString()).toList();

      state = MfaState(
        isLoading: false,
        qrCodeUrl: qrCode,
        secret: secret,
        recoveryCodes: codes,
      );
      return true;
    } catch (e) {
      state = MfaState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> verifyAndEnableMfa(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dioClient = _ref.read(dioClientProvider);
      final response = await dioClient.dio.post('/auth/mfa/verify', data: {
        'code': code,
      });

      // Dio throws on non-2xx by default, but some backends return 200 with
      // an explicit success flag for an incorrect code — check for that
      // before marking MFA as verified instead of trusting the HTTP status alone.
      final body = response.data;
      final Map<String, dynamic>? payload = body is Map ? Map<String, dynamic>.from(body) : null;
      final bool? explicitSuccess = payload?['success'] as bool? ?? payload?['verified'] as bool?;
      if (explicitSuccess == false) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: payload?['message']?.toString() ?? 'Invalid verification code.',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        isSetupComplete: true,
        isVerified: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> verifyLoginMfa({required String email, required String password, required String code}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dioClient = _ref.read(dioClientProvider);
      final response = await dioClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'mfaCode': code,
      });

      final body = response.data;
      final Map<String, dynamic> payload = (body is Map && body.containsKey('data')) 
          ? Map<String, dynamic>.from(body['data']) 
          : Map<String, dynamic>.from(body ?? {});

      final accessToken = payload['accessToken']?.toString() ?? '';
      final refreshToken = payload['refreshToken']?.toString() ?? '';
      final user = payload['user'] as Map<String, dynamic>;

      final secureStorage = _ref.read(secureStorageProvider);
      await secureStorage.setAccessToken(accessToken);
      await secureStorage.setRefreshToken(refreshToken);
      importDataToAuth(user, accessToken);

      state = state.copyWith(isLoading: false, isVerified: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void importDataToAuth(Map<String, dynamic> user, String token) {
    _ref.read(authProvider.notifier).checkInitialSession();
  }

  Future<bool> useRecoveryCode(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dioClient = _ref.read(dioClientProvider);
      final response = await dioClient.dio.post('/auth/mfa/recovery', data: {
        'recoveryCode': code,
      });

      final body = response.data;
      final Map<String, dynamic> payload = (body is Map && body.containsKey('data')) 
          ? Map<String, dynamic>.from(body['data']) 
          : Map<String, dynamic>.from(body ?? {});

      final accessToken = payload['accessToken']?.toString() ?? '';
      final refreshToken = payload['refreshToken']?.toString() ?? '';
      final user = payload['user'] as Map<String, dynamic>;

      final secureStorage = _ref.read(secureStorageProvider);
      await secureStorage.setAccessToken(accessToken);
      await secureStorage.setRefreshToken(refreshToken);
      importDataToAuth(user, accessToken);

      state = state.copyWith(isLoading: false, isVerified: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dioClient = _ref.read(dioClientProvider);
      await dioClient.dio.post('/auth/password-reset/request', data: {
        'email': email,
      });
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> resetPassword({required String token, required String newPassword}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dioClient = _ref.read(dioClientProvider);
      await dioClient.dio.post('/auth/password-reset/reset', data: {
        'token': token,
        'password': newPassword,
      });
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final mfaProvider = StateNotifierProvider<MfaNotifier, MfaState>((ref) {
  return MfaNotifier(ref);
});
