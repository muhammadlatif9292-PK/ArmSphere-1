import '../services/sensory_feedback_service.dart';

/// Legacy SoundService adapter delegating to canonical SensoryFeedbackService.
/// Preserves backward compatibility across existing surfaces.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  static SoundService get instance => _instance;

  final SensoryFeedbackService _sensoryService = SensoryFeedbackService.instance;

  SoundService._internal();

  bool isSoundEnabled() => _sensoryService.isSoundEnabled;

  Future<void> setSoundEnabled(bool enabled) => _sensoryService.setSoundEnabled(enabled);

  Future<void> playPrAchieved() =>
      _sensoryService.playSensoryCeremony(
        audioEvent: ArmSphereAudioEvent.prAchieved,
        hapticType: HapticFeedbackType.heavy,
      );

  Future<void> playMatchWon() =>
      _sensoryService.playSensoryCeremony(
        audioEvent: ArmSphereAudioEvent.matchWon,
        hapticType: HapticFeedbackType.ceremonialTriple,
      );

  Future<void> playChallengeAccepted() =>
      _sensoryService.playSensoryCeremony(
        audioEvent: ArmSphereAudioEvent.challengeAccepted,
        hapticType: HapticFeedbackType.medium,
      );

  void dispose() => _sensoryService.dispose();
}
