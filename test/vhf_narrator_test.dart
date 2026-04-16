import 'package:flutter_test/flutter_test.dart';
import 'package:essence_plus/core/constants/game_config.dart';
import 'package:essence_plus/game/managers/powerup_manager.dart';
import 'package:essence_plus/game/managers/vhf_narrator.dart';

void main() {
  group('VhfNarrator', () {
    test('emits an announcement immediately on first trigger', () {
      final messages = <String>[];
      final narrator = VhfNarrator(
        onAnnouncement: (text, _) => messages.add(text),
      );
      narrator.trigger(VhfEvent.fog);
      expect(messages.length, 1);
      expect(messages.first, isNotEmpty);
    });

    test('throttles repeated triggers via cooldown', () {
      final messages = <String>[];
      final narrator = VhfNarrator(
        onAnnouncement: (text, _) => messages.add(text),
      );
      narrator.trigger(VhfEvent.fog);
      narrator.trigger(VhfEvent.fog);
      narrator.trigger(VhfEvent.coastGuard);
      expect(messages.length, 1);

      narrator.tick(GameConfig.vhfCooldownSeconds + 0.1);
      narrator.trigger(VhfEvent.coastGuard);
      expect(messages.length, 2);
    });

    test('drops an idle line if silent long enough', () {
      final messages = <String>[];
      final narrator = VhfNarrator(
        onAnnouncement: (text, _) => messages.add(text),
      );
      narrator.tick(13.0);
      expect(messages.length, 1);
    });

    test('triggerPowerup uses the dedicated powerup line', () {
      final messages = <String>[];
      final narrator = VhfNarrator(
        onAnnouncement: (text, _) => messages.add(text),
      );
      narrator.triggerPowerup(PowerupType.coffee);
      expect(messages.length, 1);
      expect(messages.first.toLowerCase(), contains('espresso'));
    });
  });
}
