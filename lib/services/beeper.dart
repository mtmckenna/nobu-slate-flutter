import 'package:just_audio/just_audio.dart';

class Beeper {
  final AudioPlayer _beep = AudioPlayer();
  final AudioPlayer _beepFinal = AudioPlayer();
  bool _ready = false;

  Future<void> preload() async {
    if (_ready) return;
    await Future.wait([
      _beep.setAsset('assets/audio/beep.wav'),
      _beepFinal.setAsset('assets/audio/beep_final.wav'),
    ]);
    _ready = true;
  }

  Future<void> beep() async {
    await _beep.seek(Duration.zero);
    _beep.play();
  }

  Future<void> beepFinal() async {
    await _beepFinal.seek(Duration.zero);
    _beepFinal.play();
  }

  Future<void> dispose() async {
    await _beep.dispose();
    await _beepFinal.dispose();
  }
}
