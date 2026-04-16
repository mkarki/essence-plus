import 'dart:ui';
import 'package:flame/components.dart';
import '../essence_game.dart';
import '../../core/constants/app_colors.dart';

class Road extends Component with HasGameReference<EssenceGame> {
  static const double lineWidth = 3.0;
  static const double lineHeight = 40.0;
  static const double lineGap = 30.0;

  double _scrollOffset = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _scrollOffset += game.currentSpeed * dt;
    _scrollOffset %= (lineHeight + lineGap);
  }

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final centerX = size.x / 2;

    // Draw road background
    final roadWidth = 80.0 * 3 + 40; // 3 lanes + margins
    final roadRect = Rect.fromCenter(
      center: Offset(centerX, size.y / 2),
      width: roadWidth,
      height: size.y,
    );
    canvas.drawRect(
      roadRect,
      Paint()..color = const Color(0xFF1A1A2E),
    );

    // Draw road edges (neon glow effect)
    final edgePaint = Paint()
      ..color = AppColors.electricOrange.withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX - roadWidth / 2, 0),
      Offset(centerX - roadWidth / 2, size.y),
      edgePaint,
    );
    canvas.drawLine(
      Offset(centerX + roadWidth / 2, 0),
      Offset(centerX + roadWidth / 2, size.y),
      edgePaint,
    );

    // Draw lane dividers (dashed lines)
    final lanePaint = Paint()
      ..color = const Color(0xFF8892A0).withValues(alpha: 0.3)
      ..strokeWidth = lineWidth;

    for (var lane = 0; lane < 2; lane++) {
      final x = centerX + (lane - 0.5) * 80.0;
      var y = -_scrollOffset;
      while (y < size.y) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + lineHeight),
          lanePaint,
        );
        y += lineHeight + lineGap;
      }
    }
  }
}
