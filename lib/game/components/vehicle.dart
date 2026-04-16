import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import '../../core/constants/game_config.dart';
import '../../core/constants/app_colors.dart';
import '../essence_game.dart';

class Vehicle extends PositionComponent with HasGameReference<EssenceGame> {
  Vehicle({required Vector2 position})
      : super(
          position: position,
          size: Vector2(GameConfig.vehicleWidth, GameConfig.vehicleHeight),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  void moveToLane(double targetX) {
    add(
      MoveToEffect(
        Vector2(targetX, position.y),
        EffectController(duration: GameConfig.laneSwitchDuration),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // Vehicle body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()..color = AppColors.electricOrange,
    );

    // Windshield
    final windshieldRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 10, size.x - 12, 20),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      windshieldRect,
      Paint()..color = AppColors.petroleumBlue.withValues(alpha: 0.8),
    );

    // Headlights glow
    final glowPaint = Paint()
      ..color = AppColors.amberGold.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(Offset(8, 2), 4, glowPaint);
    canvas.drawCircle(Offset(size.x - 8, 2), 4, glowPaint);

    // Tail lights
    final tailPaint = Paint()
      ..color = AppColors.hotRed
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawRect(
      Rect.fromLTWH(4, size.y - 6, 10, 4),
      tailPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x - 14, size.y - 6, 10, 4),
      tailPaint,
    );
  }
}
