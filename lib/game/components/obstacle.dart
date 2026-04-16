import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../core/constants/app_colors.dart';
import '../essence_game.dart';
import 'vehicle.dart';

enum ObstacleType { cone, barrier, pothole }

class Obstacle extends PositionComponent
    with HasGameReference<EssenceGame>, CollisionCallbacks {
  final ObstacleType type;
  bool _passed = false;

  Obstacle({
    required Vector2 position,
    required this.type,
  }) : super(
          position: position,
          size: _sizeForType(type),
          anchor: Anchor.center,
        );

  static Vector2 _sizeForType(ObstacleType type) {
    return switch (type) {
      ObstacleType.cone => Vector2(30, 40),
      ObstacleType.barrier => Vector2(60, 20),
      ObstacleType.pothole => Vector2(40, 25),
    };
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += game.currentSpeed * dt;

    // Check if vehicle has passed this obstacle
    if (!_passed && position.y > game.vehicle.position.y + 50) {
      _passed = true;
      game.dodgeObstacle();
    }

    // Remove if off screen
    if (position.y > game.size.y + 50) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Vehicle) {
      game.hitObstacle(this);
    }
  }

  @override
  void render(Canvas canvas) {
    switch (type) {
      case ObstacleType.cone:
        _renderCone(canvas);
      case ObstacleType.barrier:
        _renderBarrier(canvas);
      case ObstacleType.pothole:
        _renderPothole(canvas);
    }
  }

  void _renderCone(Canvas canvas) {
    // Orange traffic cone
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x - 4, size.y)
      ..lineTo(4, size.y)
      ..close();

    canvas.drawPath(path, Paint()..color = AppColors.electricOrange);

    // White stripes
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.3, size.y * 0.3, size.x * 0.4, 4),
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.2, size.y * 0.6, size.x * 0.6, 4),
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8),
    );
  }

  void _renderBarrier(Canvas canvas) {
    // Red/white striped barrier
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, Paint()..color = AppColors.hotRed);

    // White stripes
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * 20.0 + 5, 0, 8, size.y),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7),
      );
    }
  }

  void _renderPothole(Canvas canvas) {
    // Dark pothole
    canvas.drawOval(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF0D0D1A),
    );
    // Crack highlight
    canvas.drawOval(
      Rect.fromLTWH(4, 4, size.x - 8, size.y - 8),
      Paint()
        ..color = const Color(0xFF2A2A3E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
