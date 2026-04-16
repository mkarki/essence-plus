import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../core/constants/app_colors.dart';
import '../../hormuz_game.dart';
import '../tanker.dart';

class OilPlatform extends PositionComponent
    with HasGameReference<HormuzGame>, CollisionCallbacks {
  static const double platformWidth = 90.0;
  static const double platformHeight = 110.0;

  final bool leftSide;
  bool _grazed = false;
  double _flarePhase = 0;

  OilPlatform({required Vector2 position, required this.leftSide})
      : super(
          position: position,
          size: Vector2(platformWidth, platformHeight),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Wide hitbox so the tanker can graze it from the adjacent outer lane.
    add(RectangleHitbox(
      size: Vector2(platformWidth * 0.85, platformHeight * 0.9),
      position: Vector2(platformWidth * 0.075, platformHeight * 0.05),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += game.currentSpeed * dt * 0.95;
    _flarePhase += dt * 6;

    if (position.y > game.size.y + platformHeight) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Tanker && !_grazed) {
      game.grazePlatform(this);
    }
  }

  void markGrazed() {
    _grazed = true;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Pylons (4 legs)
    final legPaint = Paint()..color = const Color(0xFF3A3A45);
    for (final lx in [w * 0.18, w * 0.4, w * 0.6, w * 0.82]) {
      canvas.drawRect(Rect.fromLTWH(lx - 2, h * 0.15, 4, h * 0.7), legPaint);
    }

    // Main deck
    final deckRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.1, w * 0.84, h * 0.32),
      const Radius.circular(4),
    );
    canvas.drawRRect(deckRect, Paint()..color = const Color(0xFF5A5A65));

    // Helipad circle
    canvas.drawCircle(
      Offset(w / 2, h * 0.26),
      w * 0.16,
      Paint()..color = AppColors.amberGold.withValues(alpha: 0.6),
    );
    canvas.drawCircle(
      Offset(w / 2, h * 0.26),
      w * 0.16,
      Paint()
        ..color = AppColors.tankerOrange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Derrick tower
    final towerPath = Path()
      ..moveTo(w * 0.42, h * 0.1)
      ..lineTo(w / 2, h * 0)
      ..lineTo(w * 0.58, h * 0.1)
      ..close();
    canvas.drawPath(towerPath, Paint()..color = const Color(0xFF6E6E78));

    // Gas flare (animated)
    final flareIntensity = 0.6 + sin(_flarePhase) * 0.3;
    canvas.drawCircle(
      Offset(w * 0.18, h * 0.1),
      8 * flareIntensity,
      Paint()
        ..color = AppColors.electricOrange.withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Submerged base shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.95),
        width: w * 0.95,
        height: 14,
      ),
      Paint()..color = AppColors.oceanDeep.withValues(alpha: 0.6),
    );

    // Indicator if already grazed (dimmed)
    if (_grazed) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = AppColors.oceanDeep.withValues(alpha: 0.5),
      );
    }
  }
}
