import 'package:flutter_test/flutter_test.dart';
import 'package:essence_plus/core/constants/game_config.dart';
import 'package:essence_plus/game/managers/powerup_manager.dart';

void main() {
  group('PowerupManager', () {
    test('flag activates with the right duration', () {
      var changes = 0;
      final manager = PowerupManager(onChanged: () => changes++);
      manager.activate(PowerupType.flag);
      expect(manager.isActive(PowerupType.flag), true);
      expect(manager.remaining(PowerupType.flag), GameConfig.flagDuration);
      expect(changes, 1);
    });

    test('tick decrements timers and removes expired powerups', () {
      var changes = 0;
      final manager = PowerupManager(onChanged: () => changes++);
      manager.activate(PowerupType.coffee);
      changes = 0;

      manager.tick(GameConfig.coffeeDuration / 2);
      expect(manager.isActive(PowerupType.coffee), true);

      manager.tick(GameConfig.coffeeDuration);
      expect(manager.isActive(PowerupType.coffee), false);
      expect(changes, 1, reason: 'one onChanged when removed');
    });

    test('bribe is single-use and survives until consumed', () {
      var changes = 0;
      final manager = PowerupManager(onChanged: () => changes++);
      manager.activate(PowerupType.bribe);
      expect(manager.bribeReady, true);

      // Bribe is not in the timer map
      expect(manager.isActive(PowerupType.bribe), false);

      // Tick a long time — bribe persists
      manager.tick(60);
      expect(manager.bribeReady, true);

      expect(manager.consumeBribe(), true);
      expect(manager.bribeReady, false);
      expect(manager.consumeBribe(), false, reason: 'second consume returns false');
    });

    test('reset clears everything', () {
      final manager = PowerupManager(onChanged: () {});
      manager.activate(PowerupType.flag);
      manager.activate(PowerupType.bribe);
      manager.reset();
      expect(manager.isActive(PowerupType.flag), false);
      expect(manager.bribeReady, false);
    });
  });
}
