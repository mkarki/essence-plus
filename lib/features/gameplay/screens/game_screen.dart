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
import '../../../services/voucher_service.dart';
import '../../../services/ad_service.dart';
import '../../../services/player_progression.dart';
import '../../../providers/voucher_provider.dart';
import '../../vouchers/screens/voucher_detail_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late HormuzGame _game;
  final VhfRadioService _radio = VhfRadioService();
  final AdService _ads = AdService();
  final GameSessionService _sessionService = GameSessionService();
  final VoucherService _voucherService = VoucherService();

  int _displayScore = 0;
  int _displayBarrels = 0;
  int _displayCombo = 1;
  int _displayNitro = GameConfig.nitroStartCharges;
  bool _displayAnchorReady = true;
  bool _isGameOver = false;
  bool _isSubmitting = false;

  String? _submittedSessionId;
  String? _sessionError;
  bool _lotteryTried = false;
  PostRunReport? _postRunReport;
  bool _revived = false;

  String? _vhfMessage;
  double _vhfMessageRemaining = 0;

  // Lottery tuning - must stay in sync with server (vouchers.js)
  static const int lotteryMinScore = 500;

  void _deferredSetState(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  @override
  void initState() {
    super.initState();
    _game = HormuzGame();
    _game.onScoreChanged = () {
      _deferredSetState(() {
        _displayScore = _game.score;
        _displayCombo = _game.comboMultiplier;
        _displayNitro = _game.nitroCharges;
        _displayAnchorReady = _game.anchorReady;
        if (_vhfMessageRemaining > 0) {
          _vhfMessageRemaining -= 1 / 60; // approx
          if (_vhfMessageRemaining <= 0) _vhfMessage = null;
        }
      });
    };
    _game.onBarrelCollected = () {
      _deferredSetState(() {
        _displayBarrels = _game.barrelsDelivered;
        _displayCombo = _game.comboMultiplier;
      });
    };
    _game.onGameOver = () {
      _deferredSetState(() => _isGameOver = true);
      _submitSessionInBackground();
      _finalizeRunLocally();
    };
    _game.onPowerupChanged = () {
      _deferredSetState(() {});
    };
    _game.onVhfAnnouncement = (msg, audioKey) {
      _deferredSetState(() {
        _vhfMessage = msg;
        _vhfMessageRemaining = GameConfig.vhfBannerDuration;
      });
      // Fire-and-forget; swallow any async error so the game loop never freezes.
      _radio.announce(audioKey).catchError((_) {});
    };
  }

  Future<void> _submitSessionInBackground() async {
    if (_isSubmitting || _submittedSessionId != null) return;
    _isSubmitting = true;
    if (mounted) setState(() => _sessionError = null);

    // If the guest user hasn't been created yet (e.g. backend was offline
    // at launch), try to create it now. The request will no-op if the token
    // is already valid.
    var user = ref.read(currentUserProvider);
    if (user == null) {
      try {
        await ref.read(authServiceProvider).fetchCurrentUser();
        user = ref.read(currentUserProvider);
      } catch (_) {
        // ignore - we'll surface the error below
      }
    }

    if (user == null) {
      _isSubmitting = false;
      if (mounted) {
        setState(() => _sessionError =
            'Pas connecte au serveur - reessaie dans quelques secondes');
      }
      return;
    }

    final session = GameSession(
      userId: user.id,
      fuelCollected: _game.barrelsDelivered,
      score: _game.score,
      distanceMeters: _game.distanceTraveled.toInt(),
      durationSeconds: _game.elapsedTime.toInt(),
      obstaclesDodged: _game.hazardsDodged,
    );

    try {
      final result = await _sessionService.submitSession(session);
      if (!mounted) return;
      if (result != null) {
        ref
            .read(fuelBalanceProvider.notifier)
            .updateBalance(result.fuelBalance);
        setState(() {
          _submittedSessionId = result.sessionId;
          _sessionError = null;
        });
      }
    } on SessionSubmissionException catch (e) {
      if (mounted) {
        setState(() => _sessionError = e.message);
      }
    } finally {
      _isSubmitting = false;
    }
  }

  void _quitAndReturn() {
    context.pop({
      'score': _game.score,
      'barrels': _game.barrelsDelivered,
      'distance': _game.distanceTraveled.toInt(),
      'hazards': _game.hazardsDodged,
      'platforms': _game.platformsGrazed,
    });
  }

  Future<void> _finalizeRunLocally() async {
    final report = await PlayerProgression.instance.finalizeRun(
      score: _game.score,
      barrelsCollected: _game.barrelsDelivered,
      hazardsDodged: _game.hazardsDodged,
      platformsGrazed: _game.platformsGrazed,
      comboMax: _game.bestComboThisRun,
      nitrosUsed: _game.nitrosUsedThisRun,
      distanceMeters: _game.distanceTraveled.toInt(),
    );
    if (!mounted) return;
    setState(() => _postRunReport = report);
  }

  /// Watch a rewarded ad to revive in place. Only available once per run.
  Future<void> _reviveWithAd() async {
    if (_revived) return;
    final ok = await _ads.showRewardedAd(
      context,
      rewardLabel: 'Repartir en place avec ton score actuel',
    );
    if (!ok || !mounted) return;
    _revived = true;
    setState(() {
      _isGameOver = false;
    });
    _game.gameState = GameState.playing;
  }

  Future<void> _replayWithAd() async {
    // Show interstitial between games - merci au sponsor
    final watched = await _ads.showInterstitial(context);
    if (!mounted) return;
    setState(() {
      _isGameOver = false;
      _displayScore = 0;
      _displayBarrels = 0;
      _displayCombo = 1;
      _vhfMessage = null;
      _submittedSessionId = null;
      _sessionError = null;
      _lotteryTried = false;
      _postRunReport = null;
      _revived = false;
    });
    _game.restart();
    // We don't need `watched` - user already saw what they needed to
    // ignore: unused_local_variable
    final _ = watched;
  }

  Future<void> _openLottery({required bool withAdBoost}) async {
    // Try to finish the submission now if it hasn't landed yet.
    if (_submittedSessionId == null) {
      await _submitSessionInBackground();
      if (!mounted) return;
    }

    if (_submittedSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _sessionError ?? 'Score non envoye - reessaie dans quelques secondes',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // If user wants the ad boost, show rewarded ad first
    if (withAdBoost) {
      final ok = await _ads.showRewardedAd(
        context,
        rewardLabel: '+10% de chance de gagner un bon essence',
      );
      if (!mounted || !ok) return;
    }

    // Call lottery endpoint
    setState(() => _lotteryTried = true);

    final result = await _voucherService.rollLottery(
      sessionId: _submittedSessionId!,
      adWatched: withAdBoost,
    );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => _LotteryResultDialog(
        result: result,
        onViewVoucher: () {
          Navigator.of(ctx).pop();
          ref.invalidate(myVouchersProvider);
          if (result.voucher != null) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => VoucherDetailScreen(voucher: result.voucher!),
              ),
            );
          }
        },
      ),
    );
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
          // Tap left/right to switch lanes (in addition to the in-game
          // PanDetector). GestureDetector uses HitTestBehavior.translucent
          // so pan events still reach the Flame detector beneath.
          GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTapDown: (details) {
              _game.handleTapAtX(details.localPosition.dx);
            },
            child: GameWidget(game: _game),
          ),

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
                  if (_displayCombo > 1) ...[
                    const SizedBox(height: 8),
                    _ComboBadge(multiplier: _displayCombo),
                  ],
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

          // Bottom controls: frein / ancre on the left, nitro / boost right.
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        _ControlTap(
                          icon: Icons.anchor,
                          label: 'ANCRE',
                          color: AppColors.oceanFoam,
                          enabled: _displayAnchorReady,
                          onTap: () => _game.dropAnchor(),
                        ),
                        const SizedBox(height: 10),
                        _ControlPedal(
                          icon: Icons.remove_circle_outline,
                          label: 'FREIN',
                          color: AppColors.hazardRed,
                          onPressedChanged: (down) => _game.setBraking(down),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        _ControlTap(
                          icon: Icons.rocket_launch,
                          label: 'NITRO x$_displayNitro',
                          color: AppColors.neonGreen,
                          enabled: _displayNitro > 0,
                          onTap: () => _game.fireNitro(),
                        ),
                        const SizedBox(height: 10),
                        _ControlPedal(
                          icon: Icons.bolt,
                          label: 'BOOST',
                          color: AppColors.amberGold,
                          onPressedChanged: (down) => _game.setBoosting(down),
                        ),
                      ],
                    ),
                  ],
                ),
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
                      if (_postRunReport != null)
                        _PostRunReportWidget(report: _postRunReport!),
                      const SizedBox(height: 20),

                      // Revive via rewarded ad - one shot per run.
                      if (!_revived) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _reviveWithAd,
                            icon: const Icon(
                              Icons.favorite,
                              color: AppColors.neonGreen,
                            ),
                            label: const Text(
                              'REGARDE UNE PUB POUR REVIVRE',
                              style: TextStyle(color: AppColors.neonGreen),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.neonGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Lottery CTA
                      if (_game.score >= lotteryMinScore) ...[
                        _LotteryCta(
                          scored: _game.score,
                          submitting: _submittedSessionId == null &&
                              _sessionError == null,
                          errorMessage: _sessionError,
                          triedAlready: _lotteryTried,
                          onTry: () => _openLottery(withAdBoost: false),
                          onTryWithAd: () => _openLottery(withAdBoost: true),
                          onRetrySubmit: _submitSessionInBackground,
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Atteins $lotteryMinScore points pour tenter de gagner un bon essence',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _quitAndReturn,
                              child: const Text('QUITTER'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _replayWithAd,
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

class _LotteryCta extends StatelessWidget {
  final int scored;
  final bool submitting;
  final String? errorMessage;
  final bool triedAlready;
  final VoidCallback onTry;
  final VoidCallback onTryWithAd;
  final VoidCallback onRetrySubmit;

  const _LotteryCta({
    required this.scored,
    required this.submitting,
    required this.errorMessage,
    required this.triedAlready,
    required this.onTry,
    required this.onTryWithAd,
    required this.onRetrySubmit,
  });

  int get _baseChance {
    final base = (scored / 100).floor();
    return base.clamp(1, 15);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.amberGold.withValues(alpha: 0.2),
            AppColors.tankerOrange.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.amberGold.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.card_giftcard,
                color: AppColors.amberGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  triedAlready
                      ? 'Deja tente pour cette partie'
                      : 'Tirage au sort : $_baseChance% de chance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.amberGold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Gagne un bon d\'achat essence reel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (!triedAlready) ...[
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.hazardRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.hazardRed,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: AppColors.hazardRed,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRetrySubmit,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('REESSAYER L\'ENVOI'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.hazardRed,
                    side: const BorderSide(color: AppColors.hazardRed),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: submitting ? null : onTry,
                  icon: submitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.casino, size: 18),
                  label: Text(
                    submitting
                        ? 'Envoi du score...'
                        : 'Tenter ($_baseChance%)',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.amberGold,
                    side: const BorderSide(color: AppColors.amberGold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: submitting ? null : onTryWithAd,
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label:
                      Text('Regarde une pub (+10%) : ${_baseChance + 10}%'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amberGold,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _LotteryResultDialog extends StatelessWidget {
  final LotteryResult result;
  final VoidCallback onViewVoucher;

  const _LotteryResultDialog({
    required this.result,
    required this.onViewVoucher,
  });

  @override
  Widget build(BuildContext context) {
    final won = result.won && result.voucher != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (won ? AppColors.neonGreen : AppColors.hazardRed)
                    .withValues(alpha: 0.15),
              ),
              child: Icon(
                won ? Icons.celebration : Icons.sentiment_neutral,
                color: won ? AppColors.neonGreen : AppColors.hazardRed,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              won ? 'Jackpot !' : 'Pas cette fois',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: won ? AppColors.neonGreen : AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              won
                  ? 'Tu viens de gagner un bon essence ${result.voucher!.displayValue} chez ${result.voucher!.stationPartner} !'
                  : (result.error == 'network'
                      ? 'Probleme de connexion, reessaie.'
                      : 'Chance: ${result.chancePercent}%. Reessaie a la prochaine partie !'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            if (won)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onViewVoucher,
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('VOIR MON BON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amberGold,
                    foregroundColor: Colors.black,
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PostRunReportWidget extends StatelessWidget {
  final PostRunReport report;
  const _PostRunReportWidget({required this.report});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.walletBarrelsEarned > 0)
            Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: AppColors.amberGold, size: 18),
                const SizedBox(width: 8),
                Text(
                  '+${report.walletBarrelsEarned} barils au portefeuille',
                  style: const TextStyle(
                    color: AppColors.amberGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          for (final m in report.missionsCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.task_alt,
                      color: AppColors.neonGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mission : $m',
                      style: const TextStyle(color: AppColors.neonGreen),
                    ),
                  ),
                ],
              ),
            ),
          for (final a in report.achievementsUnlocked)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: AppColors.amberGold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trophée : $a',
                      style: const TextStyle(color: AppColors.amberGold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ComboBadge extends StatelessWidget {
  final int multiplier;
  const _ComboBadge({required this.multiplier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.amberGold, AppColors.tankerOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.amberGold.withValues(alpha: 0.45),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.whatshot, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text(
            'COMBO x$multiplier',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlTap extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ControlTap({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 84,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: enabled ? 0.85 : 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: enabled ? 0.9 : 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: enabled ? color : color.withValues(alpha: 0.35),
            ),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : color.withValues(alpha: 0.35),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlPedal extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final void Function(bool down) onPressedChanged;

  const _ControlPedal({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressedChanged,
  });

  @override
  State<_ControlPedal> createState() => _ControlPedalState();
}

class _ControlPedalState extends State<_ControlPedal> {
  bool _down = false;

  void _setDown(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    widget.onPressedChanged(v);
  }

  @override
  void dispose() {
    if (_down) widget.onPressedChanged(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) => _setDown(false),
      onTapCancel: () => _setDown(false),
      onPanDown: (_) => _setDown(true),
      onPanEnd: (_) => _setDown(false),
      onPanCancel: () => _setDown(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _down
              ? widget.color.withValues(alpha: 0.85)
              : AppColors.surface.withValues(alpha: 0.75),
          border: Border.all(
            color: widget.color.withValues(alpha: _down ? 1.0 : 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _down ? 0.45 : 0.15),
              blurRadius: _down ? 24 : 10,
              spreadRadius: _down ? 2 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 30,
              color: _down ? Colors.white : widget.color,
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _down ? Colors.white : widget.color,
                letterSpacing: 1,
              ),
            ),
          ],
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
