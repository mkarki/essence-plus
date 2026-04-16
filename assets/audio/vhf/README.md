# VHF radio clips

Pre-generate one mp3 per audio key referenced in
`lib/game/managers/vhf_narrator.dart` (e.g. `vhf_fog_01.mp3`).

The `VhfRadioService` falls back silently when files are missing, so the
text banner still works during development without any audio assets.

## Suggested generation pipeline

```bash
# macOS example with the Thomas voice + ffmpeg radio filter
say -v Thomas "Brouillard épais, réduisez la veille visuelle." \
    -o /tmp/vhf_fog_01.aiff
ffmpeg -i /tmp/vhf_fog_01.aiff \
    -af "highpass=f=300,lowpass=f=3000,acompressor=threshold=-15dB" \
    -ar 22050 -ac 1 -b:a 64k \
    assets/audio/vhf/vhf_fog_01.mp3
```

A short `vhf_chirp.mp3` (~150ms beep) is played before each line if present.
