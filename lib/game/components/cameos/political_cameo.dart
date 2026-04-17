import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show TextPainter, TextSpan, TextStyle, TextDirection, FontWeight;
import '../../../core/constants/app_colors.dart';
import '../../hormuz_game.dart';

/// Non-interactive political figures drifting on the banks of the strait.
/// They're pure flavor: no collisions, no scoring - just a satirical wink
/// and a VHF line when the tanker passes them.
enum Cameo { trump, macron, xi, putin, mbs, biden }

extension CameoData on Cameo {
  String get displayName {
    switch (this) {
      case Cameo.trump:
        return 'Trump';
      case Cameo.macron:
        return 'Macron';
      case Cameo.xi:
        return 'Xi';
      case Cameo.putin:
        return 'Poutine';
      case Cameo.mbs:
        return 'MBS';
      case Cameo.biden:
        return 'Biden';
    }
  }

  /// (skin, suit/outfit, hair/accent).
  List<Color> get palette {
    switch (this) {
      case Cameo.trump:
        return const [Color(0xFFF5B88A), Color(0xFFC62828), Color(0xFFFFD54F)];
      case Cameo.macron:
        return const [Color(0xFFF1D5B8), Color(0xFF1F3A63), Color(0xFF5D4037)];
      case Cameo.xi:
        return const [Color(0xFFF4DDB6), Color(0xFF611818), Color(0xFF1A1A1A)];
      case Cameo.putin:
        return const [Color(0xFFF0E0D0), Color(0xFF1F1F1F), Color(0xFFAAAAAA)];
      case Cameo.mbs:
        return const [Color(0xFFE3C29A), Color(0xFFF5F5F5), Color(0xFFC62828)];
      case Cameo.biden:
        return const [Color(0xFFF4D7B6), Color(0xFF1F3A63), Color(0xFFEEEEEE)];
    }
  }

  String get vhfLine {
    switch (this) {
      case Cameo.trump:
        return '📻 Trump : "Very bad deal, this Hormuz. TREMENDOUS traffic!"';
      case Cameo.macron:
        return '📻 Macron : "En même temps, il faut protéger le détroit."';
      case Cameo.xi:
        return '📻 Xi : "一带一路 — la route de la soie passe par ici."';
      case Cameo.putin:
        return '📻 Poutine : "Le pétrole russe cherche un ami fiable."';
      case Cameo.mbs:
        return '📻 MBS : "Vision 2030. Le baril reste chez nous."';
      case Cameo.biden:
        return '📻 Biden : "Folks, we need to keep this strait open, c\'mon man."';
    }
  }

  String get vhfAudioKey => 'cameo_$name';
}

class PoliticalCameo extends PositionComponent
    with HasGameReference<HormuzGame> {
  final Cameo figure;
  final bool leftBank;
  bool _announced = false;

  PoliticalCameo({
    required this.figure,
    required this.leftBank,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(46, 70),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    position.y += game.currentSpeed * dt * 0.85; // slightly slower than lanes
    if (!_announced && position.y > game.tanker.position.y - 40) {
      _announced = true;
      game.triggerCameo(this);
    }
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final palette = figure.palette;
    final w = size.x;
    final h = size.y;

    // Small boat / platform beneath the figure so it looks anchored at the
    // bank rather than floating in void.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.78, w * 0.9, h * 0.16),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.tankerDeck.withValues(alpha: 0.8),
    );

    // Body / suit
    final bodyPath = Path()
      ..moveTo(w * 0.25, h * 0.80)
      ..lineTo(w * 0.25, h * 0.45)
      ..quadraticBezierTo(w * 0.5, h * 0.35, w * 0.75, h * 0.45)
      ..lineTo(w * 0.75, h * 0.80)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = palette[1]);

    // Head
    canvas.drawCircle(
      Offset(w / 2, h * 0.36),
      w * 0.18,
      Paint()..color = palette[0],
    );

    // Hair / hat
    canvas.drawCircle(
      Offset(w / 2, h * 0.28),
      w * 0.2,
      Paint()..color = palette[2],
    );

    // Name label above the head
    final tp = TextPainter(
      text: TextSpan(
        text: figure.displayName,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(w / 2 - tp.width / 2, -tp.height - 2),
    );
  }
}
