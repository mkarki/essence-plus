import 'package:flame/components.dart';
import '../../hormuz_game.dart';

enum HazardCategory { civilian, natural, political }

/// Base class for every hazard component. Subclasses scroll downward at game
/// speed by default and self-remove when off-screen. They can override
/// [updateBehavior] for custom motion (zigzag, swarm drift, etc.).
abstract class Hazard extends PositionComponent
    with HasGameReference<HormuzGame> {
  HazardCategory get category;
  bool get isLethal => true;
  double get scrollMultiplier => 1.0;

  bool _passed = false;

  Hazard({required Vector2 position, required Vector2 size})
      : super(position: position, size: size, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    position.y += game.currentSpeed * dt * scrollMultiplier;
    updateBehavior(dt);

    if (!_passed && position.y > game.tanker.position.y + 60) {
      _passed = true;
      game.dodgeHazard();
    }
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }

  /// Override to implement zigzag, swarm motion, etc.
  void updateBehavior(double dt) {}
}
