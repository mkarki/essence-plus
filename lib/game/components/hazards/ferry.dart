import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_config.dart';
import '../tanker.dart';
import 'hazard.dart';

/// Ferry that drifts laterally between adjacent lanes (zigzag).
class Ferry extends Hazard with CollisionCallbacks {
  final double _baseX;
  double _phase = 0;

  Ferry({required Vector2 position})
      : _baseX = position.x,
        super(position: position, size: Vector2(60, 90));

  @override
  HazardCategory get category => HazardCategory.civilian;

  @override
  double get scrollMultiplier => 0.7;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void updateBehavior(double dt) {
    _phase += dt * 1.5;
    position.x = _baseX + sin(_phase) * (GameConfig.laneWidth * 0.55);
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

    // Hull (white ferry)
    final hullRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, 0, w * 0.8, h),
      const Radius.circular(8),
    );
    canvas.drawRRect(hullRect, Paint()..color = const Color(0xFFF1F1F1));

    // Hull stripe (blue)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.1, h * 0.45, w * 0.8, 6),
      Paint()..color = AppColors.naturalTeal,
    );

    // Tourist dots (rows of windows)
    final windowPaint = Paint()..color = AppColors.amberGold;
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 5; c++) {
        canvas.drawCircle(
          Offset(w * 0.2 + c * (w * 0.15), h * 0.15 + r * (h * 0.18)),
          2.5,
          windowPaint,
        );
      }
    }

    // Flag at stern
    canvas.drawRect(
      Rect.fromLTWH(w * 0.45, h * 0.92, w * 0.1, h * 0.08),
      Paint()..color = AppColors.hazardRed,
    );
  }
}
