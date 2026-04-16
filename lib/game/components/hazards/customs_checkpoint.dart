import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_config.dart';
import '../tanker.dart';
import 'hazard.dart';

/// Customs checkpoint: lethal unless covered by flag or bribe.
class CustomsCheckpoint extends Hazard with CollisionCallbacks {
  bool _resolved = false;

  CustomsCheckpoint({required Vector2 position})
      : super(
          position: position,
          size: Vector2(GameConfig.laneWidth - 4, 30),
        );

  @override
  HazardCategory get category => HazardCategory.political;

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
    if (other is Tanker && !_resolved) {
      _resolved = true;
      if (game.shouldBeInspected()) {
        game.hitHazard(this);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Yellow/black striped barrier
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = AppColors.politicalAmber,
    );
    final stripePaint = Paint()..color = AppColors.oceanDeep;
    for (var x = -h.toInt(); x < w.toInt(); x += 14) {
      final p = Path()
        ..moveTo(x.toDouble(), 0)
        ..lineTo(x + 7, 0)
        ..lineTo(x + 7 + h, h)
        ..lineTo(x + h.toDouble(), h)
        ..close();
      canvas.drawPath(p, stripePaint);
    }

    // "DOUANE" plate at top
    final tp = TextPainter(
      text: const TextSpan(
        text: 'DOUANE',
        style: TextStyle(
          color: Color(0xFF000000),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((w - tp.width) / 2, (h - tp.height) / 2));
  }
}
