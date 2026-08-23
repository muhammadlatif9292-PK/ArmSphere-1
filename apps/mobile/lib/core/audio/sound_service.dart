import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  static SoundService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();
  static const String _soundSettingKey = 'sound_effects_enabled';
  static const String _cacheBoxName = 'local_data_cache';

  SoundService._internal() {
    // Enable low latency playback mode for quick UI clicks/sound effects
    _player.setReleaseMode(ReleaseMode.release);
  }

  /// Check if sound effects are enabled in persistent storage (defaults to true)
  bool isSoundEnabled() {
    try {
      if (Hive.isBoxOpen(_cacheBoxName)) {
        final box = Hive.box<dynamic>(_cacheBoxName);
        return box.get(_soundSettingKey, defaultValue: true) as bool;
      }
    } catch (_) {
      // Fallback if Hive is not initialized in some contexts (e.g., tests or cold start)
    }
    return true;
  }

  /// Toggle and persist sound effects setting
  Future<void> setSoundEnabled(bool enabled) async {
    try {
      if (Hive.isBoxOpen(_cacheBoxName)) {
        final box = Hive.box<dynamic>(_cacheBoxName);
        await box.put(_soundSettingKey, enabled);
      }
    } catch (_) {}
  }

  /// Play the "PR Achieved" sound (short synthetic laser chirp)
  Future<void> playPrAchieved() async {
    if (!isSoundEnabled()) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/pr_achieved.wav'));
    } catch (e) {
      debugPrint('Error playing pr_achieved sound: $e');
    }
  }

  /// Play the "Match Won" sound (Nasa mission phrase / gong)
  Future<void> playMatchWon() async {
    if (!isSoundEnabled()) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/match_won.mp3'));
    } catch (e) {
      debugPrint('Error playing match_won sound: $e');
    }
  }

  /// Play the "Challenge Accepted" sound (short synthetic coin click)
  Future<void> playChallengeAccepted() async {
    if (!isSoundEnabled()) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/challenge_accepted.wav'));
    } catch (e) {
      debugPrint('Error playing challenge_accepted sound: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}

// Global debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[SoundService] $message');
}
