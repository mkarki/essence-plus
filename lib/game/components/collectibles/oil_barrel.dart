import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import '../../../core/constants/app_colors.dart';
import '../../hormuz_game.dart';
import '../tanker.dart';

class OilBarrel extends PositionComponent
    with HasGameReference<HormuzGame>, CollisionCallbacks {
  static const double barrelSize = 32.0;
  bool _collected = false;
  double _bobPhase = 0;

  OilBarrel({required Vector2 position})
      : super(
          position: position,
          size: Vector2(barrelSize, barrelSize),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    _bobPhase = position.x; // desync animation per barrel
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;

    position.y += game.currentSpeed * dt;
    _bobPhase += dt * 4;

    if (position.y > game.size.y + 50) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Tanker && !_collected) {
      _collected = true; // flip guard first to prevent re-entrance
      game.collectBarrel(this);
    }
  }

  void collect() {
    _collected = true;
    // Small pop animation then remove. No OpacityEffect — PositionComponent
    // without HasPaint does not expose an `opacity` and the effect throws,
    // which would freeze the game loop the first time a barrel is grabbed.
    add(
      ScaleEffect.to(
        Vector2.all(1.8),
        EffectController(duration: 0.25),
        onComplete: removeFromParent,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    if (_collected) return;

    final center = Offset(size.x / 2, size.y / 2);
    final bob = sin(_bobPhase) * 1.2;
    final radius = size.x / 2;

    // Foam ring under the barrel
    canvas.drawCircle(
      center.translate(0, 4 + bob),
      radius * 1.1,
      Paint()..color = AppColors.oceanFoam.withValues(alpha: 0.25),
    );

    // Barrel body (top-down: dark cylinder with rim band)
    canvas.drawCircle(
      center.translate(0, bob),
      radius,
      Paint()..color = const Color(0xFF2A2A2E),
    );
    canvas.drawCircle(
      center.translate(0, bob),
      radius,
      Paint()
        ..color = AppColors.electricOrange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      center.translate(0, bob),
      radius * 0.65,
      Paint()
        ..color = AppColors.electricOrange.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Bung hole top
    canvas.drawCircle(
      center.translate(0, bob),
      3,
      Paint()..color = AppColors.amberGold,
    );

    // Subtle outer glow
    canvas.drawCircle(
      center.translate(0, bob),
      radius + 4,
      Paint()
        ..color = AppColors.electricOrange.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }
}
