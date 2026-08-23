import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'community_provider.dart';
import 'state_providers.dart';

enum LinkSubmissionStatus {
  idle,
  submitting,
  success,
  failure,
}

class LinkSubmissionState {
  final LinkSubmissionStatus status;
  final String? errorMessage;

  LinkSubmissionState({
    required this.status,
    this.errorMessage,
  });

  LinkSubmissionState copyWith({
    LinkSubmissionStatus? status,
    String? errorMessage,
  }) {
    return LinkSubmissionState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LinkSubmissionNotifier extends AutoDisposeNotifier<LinkSubmissionState> {
  @override
  LinkSubmissionState build() {
    return LinkSubmissionState(status: LinkSubmissionStatus.idle);
  }

  Future<void> submitLink({
    required String externalUrl,
    String? category,
    String? caption,
    String? exerciseType,
    double? weightKg,
    int? reps,
  }) async {
    state = LinkSubmissionState(status: LinkSubmissionStatus.submitting);
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.submitLink(
        externalUrl,
        category,
        caption,
        exerciseType: exerciseType,
        weightKg: weightKg,
        reps: reps,
      );
      state = LinkSubmissionState(status: LinkSubmissionStatus.success);
      ref.invalidate(communityFeedProvider);
    } catch (e) {
      state = LinkSubmissionState(
        status: LinkSubmissionStatus.failure,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  void reset() {
    state = LinkSubmissionState(status: LinkSubmissionStatus.idle);
  }
}

final linkSubmissionProvider = AutoDisposeNotifierProvider<LinkSubmissionNotifier, LinkSubmissionState>(() {
  return LinkSubmissionNotifier();
});
