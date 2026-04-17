import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import '../../core/constants/game_config.dart';
import '../../core/constants/app_colors.dart';
import '../../services/player_progression.dart';
import '../hormuz_game.dart';

class Tanker extends PositionComponent with HasGameReference<HormuzGame> {
  double _wakePhase = 0;

  Tanker({required Vector2 position})
      : super(
          position: position,
          size: Vector2(GameConfig.tankerWidth, GameConfig.tankerHeight),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(
      size: Vector2(size.x * 0.8, size.y * 0.92),
      position: Vector2(size.x * 0.1, size.y * 0.04),
    ));
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
  void update(double dt) {
    super.update(dt);
    _wakePhase += dt * 4;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Wake (foam trail behind the ship)
    final wakePaint = Paint()
      ..color = AppColors.oceanFoam.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final wakeWidth = w * (0.55 + 0.1 * sin(_wakePhase));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h + 8),
        width: wakeWidth,
        height: 22,
      ),
      wakePaint,
    );

    // Hull (top-down silhouette: pointed bow up, flat stern down)
    final hullPath = Path()
      ..moveTo(w / 2, 0) // bow tip
      ..quadraticBezierTo(w * 0.95, h * 0.18, w * 0.92, h * 0.32)
      ..lineTo(w * 0.92, h * 0.95)
      ..quadraticBezierTo(w * 0.85, h, w * 0.7, h)
      ..lineTo(w * 0.3, h)
      ..quadraticBezierTo(w * 0.15, h, w * 0.08, h * 0.95)
      ..lineTo(w * 0.08, h * 0.32)
      ..quadraticBezierTo(w * 0.05, h * 0.18, w / 2, 0)
      ..close();

    // Apply selected skin (falls back to classic colors if unknown).
    final skin = TankerSkin.byId(
          PlayerProgression.instance.selectedSkin,
        ) ??
        TankerSkin.byId('classic')!;
    final hullColor = Color(skin.hullColor);
    final deckColor = Color(skin.deckColor);

    canvas.drawPath(hullPath, Paint()..color = hullColor);

    // Deck cargo area (darker)
    final deckRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.22, w * 0.64, h * 0.5),
      const Radius.circular(4),
    );
    canvas.drawRRect(deckRect, Paint()..color = deckColor);

    // Cargo tank circles (3 circular hatches)
    final hatchPaint = Paint()..color = AppColors.oceanDeep.withValues(alpha: 0.6);
    for (var i = 0; i < 3; i++) {
      final cy = h * 0.3 + i * (h * 0.16);
      canvas.drawCircle(Offset(w / 2, cy), w * 0.1, hatchPaint);
    }

    // Superstructure (white block at the stern)
    final superRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.74, w * 0.56, h * 0.18),
      const Radius.circular(3),
    );
    canvas.drawRRect(superRect, Paint()..color = const Color(0xFFE8E8E8));

    // Bridge windows (small dark line)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.28, h * 0.78, w * 0.44, 4),
      Paint()..color = AppColors.petroleumBlue,
    );

    // Bow navigation light
    canvas.drawCircle(
      Offset(w / 2, h * 0.06),
      3,
      Paint()
        ..color = AppColors.amberGold
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }
}
