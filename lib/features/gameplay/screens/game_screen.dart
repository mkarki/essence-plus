import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../game/essence_game.dart';
import '../../../models/game_session.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fuel_balance_provider.dart';
import '../../../services/game_session_service.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late EssenceGame _game;
  int _displayScore = 0;
  int _displayFuel = 0;
  bool _isGameOver = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _game = EssenceGame();
    _game.onScoreChanged = () {
      if (mounted) setState(() => _displayScore = _game.score);
    };
    _game.onFuelCollected = () {
      if (mounted) setState(() => _displayFuel = _game.fuelCollected);
    };
    _game.onGameOver = () {
      if (mounted) setState(() => _isGameOver = true);
    };
  }

  Future<void> _submitAndReturn() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final user = ref.read(currentUserProvider);
    if (user != null) {
      final session = GameSession(
        userId: user.id,
        fuelCollected: _game.fuelCollected,
        score: _game.score,
        distanceMeters: _game.distanceTraveled.toInt(),
        durationSeconds: _game.elapsedTime.toInt(),
        obstaclesDodged: _game.obstaclesDodged,
      );

      final service = GameSessionService();
      final balance = await service.submitSession(session);

      if (balance != null) {
        ref.read(fuelBalanceProvider.notifier).updateBalance(balance);
      }
    }

    if (mounted) {
      context.pop({
        'score': _game.score,
        'fuel': _game.fuelCollected,
        'distance': _game.distanceTraveled.toInt(),
        'obstacles': _game.obstaclesDodged,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game
          GameWidget(game: _game),

          // HUD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Score
                  _HudBadge(
                    icon: Icons.speed,
                    value: '$_displayScore',
                    color: AppColors.electricOrange,
                  ),

                  // Fuel collected
                  _HudBadge(
                    icon: Icons.local_gas_station,
                    value: '+$_displayFuel',
                    color: AppColors.neonGreen,
                  ),

                  // Pause button
                  GestureDetector(
                    onTap: () => _game.togglePause(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pause,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Game Over overlay
          if (_isGameOver)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.electricOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'GAME OVER',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(color: AppColors.hotRed),
                      ),
                      const SizedBox(height: 24),
                      _StatRow(
                        label: 'Score',
                        value: '$_displayScore',
                        icon: Icons.speed,
                      ),
                      _StatRow(
                        label: 'Essence',
                        value: '+$_displayFuel',
                        icon: Icons.local_gas_station,
                      ),
                      _StatRow(
                        label: 'Distance',
                        value: '${_game.distanceTraveled.toInt()}m',
                        icon: Icons.straighten,
                      ),
                      _StatRow(
                        label: 'Obstacles',
                        value: '${_game.obstaclesDodged}',
                        icon: Icons.shield_outlined,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting ? null : _submitAndReturn,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('QUITTER'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isGameOver = false;
                                  _displayScore = 0;
                                  _displayFuel = 0;
                                });
                                _game.restart();
                              },
                              child: const Text('REJOUER'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HudBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _HudBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.electricOrange,
                ),
          ),
        ],
      ),
    );
  }
}
