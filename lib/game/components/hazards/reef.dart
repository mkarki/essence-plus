import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../core/constants/app_colors.dart';
import '../tanker.dart';
import 'hazard.dart';

/// Static rocky reef. Always lethal.
class Reef extends Hazard with CollisionCallbacks {
  final int _seed;

  Reef({required Vector2 position, int seed = 0})
      : _seed = seed,
        super(position: position, size: Vector2(50, 40));

  @override
  HazardCategory get category => HazardCategory.natural;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
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
    final rng = Random(_seed);
    final center = Offset(w / 2, h / 2);

    // White surf around the rock (warning ring)
    canvas.drawCircle(
      center,
      w * 0.55,
      Paint()..color = AppColors.oceanFoam.withValues(alpha: 0.45),
    );

    // Three jagged rocks
    final rockPaint = Paint()..color = const Color(0xFF2A2418);
    for (var i = 0; i < 3; i++) {
      final cx = w * (0.25 + i * 0.25);
      final cy = h * (0.4 + (rng.nextDouble() - 0.5) * 0.3);
      final r = h * 0.25 + rng.nextDouble() * 6;
      final path = Path()
        ..moveTo(cx, cy - r)
        ..lineTo(cx + r * 0.7, cy + r * 0.4)
        ..lineTo(cx, cy + r)
        ..lineTo(cx - r * 0.7, cy + r * 0.4)
        ..close();
      canvas.drawPath(path, rockPaint);
    }

    // Highlight glints
    final glintPaint = Paint()..color = const Color(0xFF4A4030);
    canvas.drawCircle(Offset(w * 0.3, h * 0.35), 2, glintPaint);
    canvas.drawCircle(Offset(w * 0.7, h * 0.4), 1.5, glintPaint);
  }
}
