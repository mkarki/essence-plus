import 'package:flame_audio/flame_audio.dart';

/// Plays pre-generated TTS clips for VHF announcements. Falls back silently
/// if the audio asset is missing (so the text banner still works in dev).
///
/// Asset layout: place mp3 files under `assets/audio/vhf/<key>.mp3` and
/// declare the directory in `pubspec.yaml`. A short radio chirp can be added
/// by playing `vhf_chirp.mp3` before each announcement.
class VhfRadioService {
  static const String _basePath = 'vhf/';
  static const String _chirpKey = 'vhf_chirp';

  bool _muted = false;

  Future<void> announce(String audioKey) async {
    if (_muted || audioKey.isEmpty) return;
    try {
      // Optional radio chirp before the line. Best-effort; if absent we skip.
      try {
        await FlameAudio.play('${_basePath}$_chirpKey.mp3', volume: 0.5);
      } catch (_) {
        // chirp not bundled yet — ignore
      }
      await FlameAudio.play('$_basePath$audioKey.mp3', volume: 0.9);
    } catch (_) {
      // Asset not available — text banner will still display.
    }
  }

  void setMuted(bool muted) => _muted = muted;
}
