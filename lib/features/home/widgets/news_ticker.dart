import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Satirical news ticker that scrolls across the top of the home screen.
/// Pure UI flavor - rotates through a hardcoded pool so the app always
/// feels alive even without a backend feed.
class NewsTicker extends StatefulWidget {
  const NewsTicker({super.key});

  @override
  State<NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<NewsTicker> {
  static const List<String> _headlines = [
    'BRENT +3,2% apres tensions dans le Golfe',
    'OPEC+ proroge les coupes : prix du baril a 94\$',
    'Un petrolier s\'immobilise dans le detroit - trafic perturbe',
    'Rumeurs de hausse de la TIC : les bons se vendent comme des petits pains',
    'Alerte meteo : tempete classe 6 au large de Doha',
    'Nouveaux controles douaniers a Bandar Abbas',
    'Afriquia annonce 500 bons carburants a gagner ce mois-ci',
    'Shell Morocco multiplie les distributions promo',
    'Un tanker doré apercu dans le detroit (collectionneurs en folie)',
    'Bakchich : le nouvel an du commerce maritime discret',
    'Prix du diesel en baisse de 0,50 DH a la pompe',
    'Fog bank signalee entre Qeshm et Lareh - redoublez de vigilance',
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _headlines.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.oceanDeep.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.electricOrange.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.hazardRed,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                _headlines[_index],
                key: ValueKey(_index),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
