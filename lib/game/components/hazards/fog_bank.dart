import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../core/constants/app_colors.dart';
import '../tanker.dart';
import 'hazard.dart';

/// Fog bank: not lethal on contact, but triggers a visibility drop on the game.
class FogBank extends Hazard with CollisionCallbacks {
  bool _triggered = false;

  FogBank({required Vector2 position})
      : super(position: position, size: Vector2(220, 120));

  @override
  HazardCategory get category => HazardCategory.natural;

  @override
  bool get isLethal => false;

  @override
  double get scrollMultiplier => 0.9;

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
      game.enterFog();
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Soft layered ovals (semi-transparent fog)
    final fogPaint = Paint()
      ..color = AppColors.oceanFoam.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(Rect.fromLTWH(0, h * 0.2, w, h * 0.6), fogPaint);
    canvas.drawOval(Rect.fromLTWH(w * 0.15, 0, w * 0.7, h * 0.7), fogPaint);
    canvas.drawOval(Rect.fromLTWH(w * 0.05, h * 0.3, w * 0.6, h * 0.6), fogPaint);
  }
}
