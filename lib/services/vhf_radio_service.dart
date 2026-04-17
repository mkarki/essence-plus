/// Plays pre-generated TTS clips for VHF announcements. No-op for now:
/// the text banner handles the UX until we bundle the real mp3 files.
///
/// When you ship audio, add the `flame_audio` dependency back, drop the
/// clips under `assets/audio/vhf/<key>.mp3`, declare the folder in
/// pubspec, and restore the `FlameAudio.play` calls below.
class VhfRadioService {
  bool _muted = false;

  Future<void> announce(String audioKey) async {
    if (_muted || audioKey.isEmpty) return;
    // Intentionally no-op until real assets are shipped.
    // Silently succeeds so callers can fire-and-forget.
    return;
  }

  void setMuted(bool muted) => _muted = muted;
}
