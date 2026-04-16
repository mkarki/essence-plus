import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../core/constants/app_colors.dart';
import '../tanker.dart';
import 'hazard.dart';

/// Coast guard patrol vessel. Lethal unless the tanker has a flag of
/// convenience (or pays a bribe via the inspection check).
class CoastGuard extends Hazard with CollisionCallbacks {
  bool _resolved = false;
  double _siren = 0;

  CoastGuard({required Vector2 position})
      : super(position: position, size: Vector2(48, 70));

  @override
  HazardCategory get category => HazardCategory.political;

  @override
  bool get isLethal => true;

  @override
  double get scrollMultiplier => 0.95;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void updateBehavior(double dt) {
    _siren += dt * 6;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Tanker && !_resolved) {
      _resolved = true;
      if (game.shouldBeInspected()) {
        game.hitHazard(this);
      }
      // If covered by flag/bribe, the patrol simply lets us pass.
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Hull (white patrol boat)
    final hullPath = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.85, h * 0.2)
      ..lineTo(w * 0.85, h * 0.95)
      ..lineTo(w * 0.7, h)
      ..lineTo(w * 0.3, h)
      ..lineTo(w * 0.15, h * 0.95)
      ..lineTo(w * 0.15, h * 0.2)
      ..close();
    canvas.drawPath(hullPath, Paint()..color = const Color(0xFFEDEDED));

    // Hull stripe (politicalAmber for distinction)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.15, h * 0.45, w * 0.7, 5),
      Paint()..color = AppColors.politicalAmber,
    );

    // Bridge
    canvas.drawRect(
      Rect.fromLTWH(w * 0.3, h * 0.55, w * 0.4, h * 0.2),
      Paint()..color = AppColors.civilianGray,
    );

    // Flashing siren
    final on = sin(_siren) > 0;
    final sirenPaint = Paint()
      ..color = (on ? const Color(0xFF3050FF) : AppColors.hazardRed)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(w / 2, h * 0.35), 4, sirenPaint);
  }
}
