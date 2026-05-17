import 'dart:io';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class VoiceMemoService {
  static final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  static final AudioPlayer _player = AudioPlayer();
  static bool _recorderOpen = false;

  static Future<void> _ensureRecorderOpen() async {
    if (!_recorderOpen) {
      await _recorder.openRecorder();
      _recorderOpen = true;
    }
  }

  static Future<String> startRecording() async {
    await _ensureRecorderOpen();
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/memo_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(toFile: path, codec: Codec.aacADTS);
    return path;
  }

  static Future<String?> stopRecording() async {
    return _recorder.stopRecorder();
  }

  static Future<void> playMemo(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  static Future<void> stopPlayback() async {
    await _player.stop();
  }

  static Future<void> deleteMemo(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  static bool get isRecording => _recorder.isRecording;
  static bool get isPlaying => _player.playing;
}
