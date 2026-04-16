import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_config.dart';
import '../../../game/hormuz_game.dart';
import '../../../game/managers/powerup_manager.dart';
import '../../../models/game_session.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fuel_balance_provider.dart';
import '../../../services/game_session_service.dart';
import '../../../services/vhf_radio_service.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late HormuzGame _game;
  final VhfRadioService _radio = VhfRadioService();
  int _displayScore = 0;
  int _displayBarrels = 0;
  bool _isGameOver = false;
  bool _isSubmitting = false;

  String? _vhfMessage;
  double _vhfMessageRemaining = 0;

  @override
  void initState() {
    super.initState();
    _game = HormuzGame();
    _game.onScoreChanged = () {
      if (mounted) {
        setState(() {
          _displayScore = _game.score;
          if (_vhfMessageRemaining > 0) {
            _vhfMessageRemaining -= 1 / 60; // approx
            if (_vhfMessageRemaining <= 0) _vhfMessage = null;
          }
        });
      }
    };
    _game.onBarrelCollected = () {
      if (mounted) setState(() => _displayBarrels = _game.barrelsDelivered);
    };
    _game.onGameOver = () {
      if (mounted) setState(() => _isGameOver = true);
    };
    _game.onPowerupChanged = () {
      if (mounted) setState(() {});
    };
    _game.onVhfAnnouncement = (msg, audioKey) {
      if (mounted) {
        setState(() {
          _vhfMessage = msg;
          _vhfMessageRemaining = GameConfig.vhfBannerDuration;
        });
        _radio.announce(audioKey);
      }
    };
  }

  Future<void> _submitAndReturn() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final user = ref.read(currentUserProvider);
    if (user != null) {
      final session = GameSession(
        userId: user.id,
        fuelCollected: _game.barrelsDelivered,
        score: _game.score,
        distanceMeters: _game.distanceTraveled.toInt(),
        durationSeconds: _game.elapsedTime.toInt(),
        obstaclesDodged: _game.hazardsDodged,
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
        'barrels': _game.barrelsDelivered,
        'distance': _game.distanceTraveled.toInt(),
        'hazards': _game.hazardsDodged,
        'platforms': _game.platformsGrazed,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final powerups = _game.isLoaded
        ? _game.powerupManager.activeSnapshot
        : <PowerupType, double>{};
    final bribeReady = _game.isLoaded ? _game.powerupManager.bribeReady : false;

    return Scaffold(
      body: Stack(
        children: [
          // Game
          GameWidget(game: _game),

          // HUD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _HudBadge(
                        icon: Icons.speed,
                        value: '$_displayScore',
                        color: AppColors.electricOrange,
                      ),
                      _HudBadge(
                        icon: Icons.local_drink,
                        value: '+$_displayBarrels brl',
                        color: AppColors.tankerOrange,
                      ),
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
                  const SizedBox(height: 12),
                  if (powerups.isNotEmpty || bribeReady)
                    _PowerupRow(
                      active: powerups,
                      bribeReady: bribeReady,
                    ),
                  if (_vhfMessage != null) ...[
                    const SizedBox(height: 12),
                    _VhfBanner(message: _vhfMessage!),
                  ],
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
                      color: AppColors.tankerOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NAUFRAGE',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(color: AppColors.hazardRed),
                      ),
                      const SizedBox(height: 24),
                      _StatRow(
                        label: 'Score',
                        value: '$_displayScore',
                        icon: Icons.speed,
                      ),
                      _StatRow(
                        label: 'Barils livrés',
                        value: '+$_displayBarrels',
                        icon: Icons.local_drink,
                      ),
                      _StatRow(
                        label: 'Distance',
                        value: '${_game.distanceTraveled.toInt()}m',
                        icon: Icons.straighten,
                      ),
                      _StatRow(
                        label: 'Hazards esquivés',
                        value: '${_game.hazardsDodged}',
                        icon: Icons.shield_outlined,
                      ),
                      _StatRow(
                        label: 'Plateformes frôlées',
                        value: '${_game.platformsGrazed}',
                        icon: Icons.factory_outlined,
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
                                  _displayBarrels = 0;
                                  _vhfMessage = null;
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
                  color: AppColors.tankerOrange,
                ),
          ),
        ],
      ),
    );
  }
}

class _PowerupRow extends StatelessWidget {
  final Map<PowerupType, double> active;
  final bool bribeReady;

  const _PowerupRow({required this.active, required this.bribeReady});

  @override
  Widget build(BuildContext context) {
    final entries = <Widget>[];
    for (final entry in active.entries) {
      entries.add(_PowerupChip(
        type: entry.key,
        secondsLeft: entry.value,
      ));
    }
    if (bribeReady) {
      entries.add(const _PowerupChip(type: PowerupType.bribe, secondsLeft: 0));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: entries,
    );
  }
}

class _PowerupChip extends StatelessWidget {
  final PowerupType type;
  final double secondsLeft;

  const _PowerupChip({required this.type, required this.secondsLeft});

  String get _label {
    switch (type) {
      case PowerupType.flag:
        return 'Pavillon';
      case PowerupType.coffee:
        return 'Café';
      case PowerupType.bribe:
        return 'Bakchich';
      case PowerupType.weather:
        return 'Météo';
      case PowerupType.foghorn:
        return 'Corne';
    }
  }

  Color get _color {
    switch (type) {
      case PowerupType.flag:
        return Colors.blueAccent;
      case PowerupType.coffee:
        return const Color(0xFFD4A26B);
      case PowerupType.bribe:
        return AppColors.amberGold;
      case PowerupType.weather:
        return AppColors.naturalTeal;
      case PowerupType.foghorn:
        return AppColors.civilianGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showTimer = secondsLeft > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        showTimer
            ? '$_label · ${secondsLeft.toStringAsFixed(1)}s'
            : '$_label · prêt',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _VhfBanner extends StatelessWidget {
  final String message;
  const _VhfBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.oceanDeep.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.tankerOrange.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.radio,
            color: AppColors.tankerOrange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
