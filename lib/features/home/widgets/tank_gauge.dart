import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TankGauge extends StatelessWidget {
  final double fillPercentage; // 0.0 to 1.0
  final int currentFuel;
  final int tankCapacity;

  const TankGauge({
    super.key,
    required this.fillPercentage,
    required this.currentFuel,
    required this.tankCapacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.electricOrange.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricOrange.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.surface,
            ),
          ),

          // Fuel fill level
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              height: 276 * fillPercentage.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    _fillColor.withValues(alpha: 0.9),
                    _fillColor.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),

          // Gauge markings
          ...List.generate(4, (i) {
            final y = 276.0 * (1 - (i + 1) / 5);
            return Positioned(
              left: 8,
              right: 8,
              top: y,
              child: Container(
                height: 1,
                color: AppColors.textSecondary.withValues(alpha: 0.2),
              ),
            );
          }),

          // Percentage text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(fillPercentage * 100).toInt()}%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          const Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currentFuel / $tankCapacity',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        shadows: [
                          const Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                ),
              ],
            ),
          ),

          // "FULL" badge when tank is full
          if (fillPercentage >= 1.0)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.amberGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PLEIN !',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color get _fillColor {
    if (fillPercentage >= 0.8) return AppColors.neonGreen;
    if (fillPercentage >= 0.4) return AppColors.electricOrange;
    return AppColors.hotRed;
  }
}
