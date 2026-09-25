import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum ArmSphereAudioEvent {
  challengeAccepted,
  matchWon,
  prAchieved,
}

enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
  vibrate,
  ceremonialTriple,
}

/// Central Sensory Feedback Service (Audio & Haptics)
///
/// Grounded in:
/// - `docs/design/32_HAPTIC_AND_AUDIO_UX.md` (§6)
/// - `docs/design/39_DESIGN_DEBT_MAP.md` (Domain 8, Slice 11)
/// - `docs/design/00_DESIGN_AUTHORITY.md`
///
/// Rules:
/// - Strictly utilizes ONLY the 3 pre-existing, verified sound assets in `assets/sounds/`.
/// - Bans generic UI click audio; audio is strictly reserved for earned athletic milestones.
/// - Pairs every audio event with simultaneous haptic impulses and accessible visual states.
class SensoryFeedbackService {
  static final SensoryFeedbackService _instance = SensoryFeedbackService._internal();
  static SensoryFeedbackService get instance => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  static const String _soundKey = 'sound_effects_enabled';
  static const String _hapticsKey = 'haptics_enabled';
  static const String _cacheBox = 'local_data_cache';

  SensoryFeedbackService._internal() {
    _initSettings();
    _configureAudioContext();
  }

  void _initSettings() {
    try {
      if (Hive.isBoxOpen(_cacheBox)) {
        final box = Hive.box<dynamic>(_cacheBox);
        _soundEnabled = box.get(_soundKey, defaultValue: true) as bool;
        _hapticsEnabled = box.get(_hapticsKey, defaultValue: true) as bool;
      }
    } catch (_) {}
  }

  Future<void> _configureAudioContext() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ));
    } catch (_) {}
  }

  bool get isSoundEnabled => _soundEnabled;
  bool get isHapticsEnabled => _hapticsEnabled;

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    try {
      if (Hive.isBoxOpen(_cacheBox)) {
        final box = Hive.box<dynamic>(_cacheBox);
        await box.put(_soundKey, enabled);
      }
    } catch (_) {}
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    _hapticsEnabled = enabled;
    try {
      if (Hive.isBoxOpen(_cacheBox)) {
        final box = Hive.box<dynamic>(_cacheBox);
        await box.put(_hapticsKey, enabled);
      }
    } catch (_) {}
  }

  /// Triggers ergonomic haptic feedback scaled to action severity.
  void triggerHaptic(HapticFeedbackType type) {
    if (!_hapticsEnabled) return;
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        HapticFeedback.vibrate();
        break;
      case HapticFeedbackType.ceremonialTriple:
        _playCeremonialHaptic();
        break;
    }
  }

  Future<void> _playCeremonialHaptic() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
  }

  /// Plays one of the 3 approved championship audio events.
  Future<void> playAudio(ArmSphereAudioEvent event) async {
    if (!_soundEnabled) return;
    String assetPath;
    switch (event) {
      case ArmSphereAudioEvent.challengeAccepted:
        assetPath = 'sounds/challenge_accepted.wav';
        break;
      case ArmSphereAudioEvent.matchWon:
        assetPath = 'sounds/match_won.mp3';
        break;
      case ArmSphereAudioEvent.prAchieved:
        assetPath = 'sounds/pr_achieved.wav';
        break;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      if (kDebugMode) {
        print('[SensoryFeedbackService] Error playing $assetPath: $e');
      }
    }
  }

  /// Combined multi-sensory execution: plays audio + triggers simultaneous haptic.
  Future<void> playSensoryCeremony({
    required ArmSphereAudioEvent audioEvent,
    required HapticFeedbackType hapticType,
  }) async {
    triggerHaptic(hapticType);
    await playAudio(audioEvent);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

final sensoryFeedbackServiceProvider = Provider<SensoryFeedbackService>((ref) {
  return SensoryFeedbackService.instance;
});
