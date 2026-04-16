import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' show Colors, TextPainter, TextSpan, TextStyle, TextDirection, FontWeight;
import '../../../core/constants/app_colors.dart';
import '../../hormuz_game.dart';
import '../../managers/powerup_manager.dart';
import '../tanker.dart';

class PowerupDrop extends PositionComponent
    with HasGameReference<HormuzGame>, CollisionCallbacks {
  static const double dropSize = 36.0;

  final PowerupType powerupType;
  bool _consumed = false;
  double _spinPhase = 0;

  PowerupDrop({required Vector2 position, required this.powerupType})
      : super(
          position: position,
          size: Vector2(dropSize, dropSize),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_consumed) return;
    position.y += game.currentSpeed * dt * 0.95;
    _spinPhase += dt * 2;

    if (position.y > game.size.y + 50) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Tanker && !_consumed) {
      game.collectPowerup(this);
    }
  }

  void consume() {
    _consumed = true;
    add(
      ScaleEffect.to(
        Vector2.all(1.6),
        EffectController(duration: 0.25),
      ),
    );
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.25),
        onComplete: removeFromParent,
      ),
    );
  }

  Color get _color {
    switch (powerupType) {
      case PowerupType.flag:
        return Colors.blueAccent;
      case PowerupType.coffee:
        return const Color(0xFF8B5A2B);
      case PowerupType.bribe:
        return AppColors.amberGold;
      case PowerupType.weather:
        return AppColors.naturalTeal;
      case PowerupType.foghorn:
        return AppColors.civilianGray;
    }
  }

  String get _label {
    switch (powerupType) {
      case PowerupType.flag:
        return 'F';
      case PowerupType.coffee:
        return '☕';
      case PowerupType.bribe:
        return '\$';
      case PowerupType.weather:
        return '~';
      case PowerupType.foghorn:
        return '♪';
    }
  }

  @override
  void render(Canvas canvas) {
    if (_consumed) return;

    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;
    final pulse = 1.0 + sin(_spinPhase * 2) * 0.06;

    // Outer halo
    canvas.drawCircle(
      center,
      radius * 1.4 * pulse,
      Paint()
        ..color = _color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Capsule body
    canvas.drawCircle(
      center,
      radius * pulse,
      Paint()..color = _color,
    );
    canvas.drawCircle(
      center,
      radius * pulse,
      Paint()
        ..color = AppColors.oceanFoam
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Label glyph (rendered as a TextPainter equivalent via simple shape)
    final tp = TextPainter(
      text: TextSpan(
        text: _label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center.translate(-tp.width / 2, -tp.height / 2));
  }
}
