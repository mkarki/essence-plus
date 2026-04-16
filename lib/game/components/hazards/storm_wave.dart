import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../core/constants/app_colors.dart';
import '../tanker.dart';
import 'hazard.dart';

/// A horizontal wave that pushes the tanker laterally one lane on contact.
class StormWave extends Hazard with CollisionCallbacks {
  final int _direction; // -1 = push left, +1 = push right
  bool _triggered = false;

  StormWave({required Vector2 position, required int direction})
      : _direction = direction,
        super(position: position, size: Vector2(360, 24));

  @override
  HazardCategory get category => HazardCategory.natural;

  @override
  bool get isLethal => false;

  @override
  double get scrollMultiplier => 1.1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Tanker && !_triggered) {
      _triggered = true;
      game.applyStormPush(_direction);
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Foam crest line
    final crestPaint = Paint()
      ..color = AppColors.oceanFoam.withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(0, h / 2);
    for (var x = 0.0; x <= w; x += 14) {
      path.lineTo(x, h / 2 + sin(x / 18) * 6);
    }
    canvas.drawPath(path, crestPaint);

    // Direction arrow
    final arrowPaint = Paint()..color = AppColors.hazardRed;
    final cx = w / 2;
    final cy = h / 2;
    final tip = Offset(cx + _direction * 14, cy);
    final back1 = Offset(cx - _direction * 6, cy - 6);
    final back2 = Offset(cx - _direction * 6, cy + 6);
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(back1.dx, back1.dy)
      ..lineTo(back2.dx, back2.dy)
      ..close();
    canvas.drawPath(arrow, arrowPaint);
  }
}
