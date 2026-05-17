import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'package:alarm_plus/features/sleep/models/sleep_sound.dart';

class SleepSoundService {
  static final AudioPlayer _player = AudioPlayer();
  static SleepSound? _current;
  static double _volume = 0.7;
  static Timer? _autoStopTimer;
  static Timer? _fadeTimer;

  static SleepSound? getCurrentSound() => _current;
  static bool isPlaying() => _player.state == PlayerState.playing;
  static double getVolume() => _volume;

  static Future<void> play(SleepSound sound, {int fadeInSeconds = 3}) async {
    if (_current == sound && isPlaying()) return;
    await _cancelFade();
    await _player.stop();
    _current = sound;

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0);
    await _player.play(AssetSource(sound.assetPath.replaceFirst('assets/', '')));

    // Fade in
    final steps = fadeInSeconds * 10;
    final stepVol = _volume / steps;
    var stepsDone = 0;
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      stepsDone++;
      final v = (stepVol * stepsDone).clamp(0.0, _volume);
      _player.setVolume(v);
      if (stepsDone >= steps) t.cancel();
    });
  }

  static Future<void> stop({int fadeOutSeconds = 3}) async {
    await _cancelFade();
    final startVol = _volume;
    final steps = fadeOutSeconds * 10;
    var stepsDone = 0;
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (t) async {
      stepsDone++;
      final v = (startVol - (startVol / steps) * stepsDone).clamp(0.0, 1.0);
      await _player.setVolume(v);
      if (stepsDone >= steps) {
        t.cancel();
        await _player.stop();
        _current = null;
      }
    });
  }

  static Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
  }

  static void scheduleAutoStop(int minutes) {
    _autoStopTimer?.cancel();
    if (minutes <= 0) return; // 0 = play until alarm
    _autoStopTimer = Timer(Duration(minutes: minutes), () => stop());
  }

  static Future<void> _cancelFade() async {
    _fadeTimer?.cancel();
    _fadeTimer = null;
  }

  static void dispose() {
    _autoStopTimer?.cancel();
    _fadeTimer?.cancel();
    _player.dispose();
  }
}
