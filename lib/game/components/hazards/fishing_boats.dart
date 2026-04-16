import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../core/constants/app_colors.dart';
import '../../managers/powerup_manager.dart';
import '../tanker.dart';
import 'hazard.dart';

/// Cluster of fishing boats. Disperses (gets removed) if foghorn is active.
class FishingBoats extends Hazard with CollisionCallbacks {
  final _random = Random();
  bool _dispersed = false;

  FishingBoats({required Vector2 position})
      : super(position: position, size: Vector2(80, 60));

  @override
  HazardCategory get category => HazardCategory.civilian;

  @override
  double get scrollMultiplier => 0.85;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void updateBehavior(double dt) {
    // If foghorn is active, the cluster scatters and despawns.
    if (!_dispersed && game.powerupManager.isActive(PowerupType.foghorn)) {
      _dispersed = true;
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Tanker && !_dispersed) game.hitHazard(this);
  }

  @override
  void render(Canvas canvas) {
    if (_dispersed) return;
    final w = size.x;
    final h = size.y;

    // Draw 4 small wooden boats clustered
    final positions = [
      Offset(w * 0.2, h * 0.25),
      Offset(w * 0.65, h * 0.3),
      Offset(w * 0.4, h * 0.6),
      Offset(w * 0.8, h * 0.7),
    ];

    final hullPaint = Paint()..color = const Color(0xFF6B4423);
    final cabinPaint = Paint()..color = const Color(0xFFA0633A);
    final foamPaint = Paint()..color = AppColors.oceanFoam.withValues(alpha: 0.4);

    for (final p in positions) {
      // Foam under boat
      canvas.drawOval(
        Rect.fromCenter(center: p.translate(0, 6), width: 22, height: 6),
        foamPaint,
      );
      // Hull
      final hullPath = Path()
        ..moveTo(p.dx - 10, p.dy)
        ..quadraticBezierTo(p.dx, p.dy + 8, p.dx + 10, p.dy)
        ..lineTo(p.dx + 8, p.dy - 4)
        ..lineTo(p.dx - 8, p.dy - 4)
        ..close();
      canvas.drawPath(hullPath, hullPaint);
      // Cabin
      canvas.drawRect(
        Rect.fromLTWH(p.dx - 4, p.dy - 8, 8, 5),
        cabinPaint,
      );
    }
  }
}
