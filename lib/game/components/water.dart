import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show RadialGradient;
import '../hormuz_game.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_config.dart';

class Water extends Component with HasGameReference<HormuzGame> {
  static const double dashHeight = 18.0;
  static const double dashGap = 22.0;
  static const double waveSpacing = 70.0;

  double _scrollOffset = 0;
  double _wavePhase = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _scrollOffset += game.currentSpeed * dt;
    _scrollOffset %= (dashHeight + dashGap);
    _wavePhase += dt * 1.4;
  }

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final centerX = size.x / 2;

    // Deep water gradient background (darker at edges)
    final bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.oceanMid, AppColors.oceanDeep],
        radius: 0.9,
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // Procedural wave caps drifting downward
    final wavePaint = Paint()
      ..color = AppColors.oceanFoam.withValues(alpha: 0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final waveOffset = (_scrollOffset * 0.4) % waveSpacing;
    for (var y = -waveSpacing + waveOffset; y < size.y; y += waveSpacing) {
      final path = Path();
      path.moveTo(0, y);
      for (var x = 0.0; x <= size.x; x += 12) {
        final dy = sin((x / 40) + _wavePhase + y * 0.02) * 4;
        path.lineTo(x, y + dy);
      }
      canvas.drawPath(path, wavePaint);
    }

    // Shipping channel (slightly lighter band where the lanes are)
    final channelWidth = GameConfig.laneWidth * 3 + 30;
    final channelRect = Rect.fromCenter(
      center: Offset(centerX, size.y / 2),
      width: channelWidth,
      height: size.y,
    );
    canvas.drawRect(
      channelRect,
      Paint()..color = AppColors.petroleumBlue.withValues(alpha: 0.25),
    );

    // Channel edges (AIS marker buoys glow)
    final edgePaint = Paint()
      ..color = AppColors.amberGold.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(centerX - channelWidth / 2, 0),
      Offset(centerX - channelWidth / 2, size.y),
      edgePaint,
    );
    canvas.drawLine(
      Offset(centerX + channelWidth / 2, 0),
      Offset(centerX + channelWidth / 2, size.y),
      edgePaint,
    );

    // AIS lane separators (dashed white)
    final lanePaint = Paint()
      ..color = AppColors.oceanFoam.withValues(alpha: 0.35)
      ..strokeWidth = 2.5;

    for (var lane = 0; lane < 2; lane++) {
      final x = centerX + (lane - 0.5) * GameConfig.laneWidth;
      var y = -_scrollOffset;
      while (y < size.y) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + dashHeight),
          lanePaint,
        );
        y += dashHeight + dashGap;
      }
    }
  }
}
