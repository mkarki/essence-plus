import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../core/constants/app_colors.dart';
import '../tanker.dart';
import 'hazard.dart';

/// Slow container ship blocking a single lane.
class CivilianShip extends Hazard with CollisionCallbacks {
  CivilianShip({required Vector2 position})
      : super(position: position, size: Vector2(70, 130));

  @override
  HazardCategory get category => HazardCategory.civilian;

  /// Cargo ships move slower than the tanker (we go faster, hence we catch up).
  @override
  double get scrollMultiplier => 0.55;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(
      size: Vector2(size.x * 0.85, size.y * 0.95),
      position: Vector2(size.x * 0.075, size.y * 0.025),
    ));
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

    // Hull (gray cargo ship, top-down)
    final hullPath = Path()
      ..moveTo(w / 2, 0)
      ..quadraticBezierTo(w * 0.95, h * 0.12, w * 0.92, h * 0.25)
      ..lineTo(w * 0.92, h)
      ..lineTo(w * 0.08, h)
      ..lineTo(w * 0.08, h * 0.25)
      ..quadraticBezierTo(w * 0.05, h * 0.12, w / 2, 0)
      ..close();
    canvas.drawPath(hullPath, Paint()..color = AppColors.civilianGray);

    // Container stacks (rows of colored squares)
    const colors = [
      Color(0xFFC83C3C),
      Color(0xFF3C7BB8),
      Color(0xFFD4A52E),
      Color(0xFF4A8E58),
    ];
    for (var row = 0; row < 6; row++) {
      for (var col = 0; col < 4; col++) {
        final color = colors[(row + col) % colors.length];
        canvas.drawRect(
          Rect.fromLTWH(
            w * 0.15 + col * (w * 0.18),
            h * 0.18 + row * (h * 0.11),
            w * 0.16,
            h * 0.09,
          ),
          Paint()..color = color,
        );
      }
    }

    // Bridge at stern (white)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.2, h * 0.85, w * 0.6, h * 0.1),
      Paint()..color = const Color(0xFFEAEAEA),
    );
  }
}
