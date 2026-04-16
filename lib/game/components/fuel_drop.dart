import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import '../../core/constants/app_colors.dart';
import '../essence_game.dart';
import 'vehicle.dart';

class FuelDrop extends PositionComponent
    with HasGameReference<EssenceGame>, CollisionCallbacks {
  static const double dropSize = 30.0;
  bool _collected = false;
  double _pulseTime = 0;

  FuelDrop({required Vector2 position})
      : super(
          position: position,
          size: Vector2(dropSize, dropSize),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;

    // Move downward
    position.y += game.currentSpeed * dt;
    _pulseTime += dt * 3;

    // Remove if off screen
    if (position.y > game.size.y + 50) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Vehicle && !_collected) {
      game.collectFuel(this);
    }
  }

  void collect() {
    _collected = true;
    // Scale up and fade out animation
    add(
      ScaleEffect.to(
        Vector2.all(2.0),
        EffectController(duration: 0.3),
      ),
    );
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.3),
        onComplete: removeFromParent,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    if (_collected) return;

    final pulse = 0.9 + sin(_pulseTime) * 0.1;
    final center = Offset(size.x / 2, size.y / 2);
    final radius = (size.x / 2) * pulse;

    // Outer glow
    canvas.drawCircle(
      center,
      radius + 6,
      Paint()
        ..color = AppColors.neonGreen.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Drop shape (teardrop)
    final path = Path();
    final dropRadius = radius * 0.7;
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(
      center.dx + dropRadius,
      center.dy - dropRadius * 0.3,
      center.dx,
      center.dy + dropRadius * 0.6,
    );
    path.quadraticBezierTo(
      center.dx - dropRadius,
      center.dy - dropRadius * 0.3,
      center.dx,
      center.dy - radius,
    );

    canvas.drawPath(
      path,
      Paint()..color = AppColors.neonGreen,
    );

    // Inner highlight
    canvas.drawCircle(
      Offset(center.dx - 2, center.dy - 4),
      3,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5),
    );
  }
}
