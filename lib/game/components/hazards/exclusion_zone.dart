import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_config.dart';
import '../tanker.dart';
import 'hazard.dart';

/// A flashing red zone that closes off one entire lane.
class ExclusionZone extends Hazard with CollisionCallbacks {
  double _flashPhase = 0;

  ExclusionZone({required Vector2 position})
      : super(position: position, size: Vector2(GameConfig.laneWidth - 6, 220));

  @override
  HazardCategory get category => HazardCategory.political;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void updateBehavior(double dt) {
    _flashPhase += dt * 4;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Tanker) game.hitHazard(this);
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final flash = 0.4 + (sin(_flashPhase).abs()) * 0.4;

    // Hatched red zone
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = AppColors.hazardRed.withValues(alpha: flash * 0.55),
    );

    // Diagonal hatching
    final hatchPaint = Paint()
      ..color = AppColors.hazardRed.withValues(alpha: 0.7)
      ..strokeWidth = 2;
    for (var y = -h; y < h; y += 16) {
      canvas.drawLine(
        Offset(0, y.toDouble()),
        Offset(w, y + w),
        hatchPaint,
      );
    }

    // Buoy lights at corners (blinking)
    final buoyPaint = Paint()
      ..color = AppColors.hazardRed
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    if (sin(_flashPhase) > 0) {
      canvas.drawCircle(const Offset(6, 6), 5, buoyPaint);
      canvas.drawCircle(Offset(w - 6, 6), 5, buoyPaint);
    }
  }
}
