import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Stub pour l'integration AdMob future.
/// Affiche un dialog simulant la lecture d'une pub.
/// Quand on integrera google_mobile_ads, on remplacera le corps de ces methodes.
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  /// Pub interstitielle entre deux parties. Retourne true quand vue.
  Future<bool> showInterstitial(BuildContext context) {
    return _showStub(
      context,
      title: 'Pub interstitielle',
      subtitle: 'Merci de patienter',
      duration: const Duration(seconds: 5),
      skippable: true,
    );
  }

  /// Pub rewardee - l'utilisateur doit la regarder en entier.
  Future<bool> showRewardedAd(
    BuildContext context, {
    required String rewardLabel,
  }) {
    return _showStub(
      context,
      title: 'Regarde une pub',
      subtitle: rewardLabel,
      duration: const Duration(seconds: 5),
      skippable: false,
    );
  }

  Future<bool> _showStub(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Duration duration,
    required bool skippable,
  }) {
    final completer = Completer<bool>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AdDialog(
        title: title,
        subtitle: subtitle,
        duration: duration,
        skippable: skippable,
        onFinished: (completed) {
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (!completer.isCompleted) completer.complete(completed);
        },
      ),
    );

    return completer.future;
  }
}

class _AdDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Duration duration;
  final bool skippable;
  final void Function(bool completed) onFinished;

  const _AdDialog({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.skippable,
    required this.onFinished,
  });

  @override
  State<_AdDialog> createState() => _AdDialogState();
}

class _AdDialogState extends State<_AdDialog> {
  double _progress = 0;
  Timer? _timer;
  late DateTime _start;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_start);
      final p = (elapsed.inMilliseconds / widget.duration.inMilliseconds)
          .clamp(0.0, 1.0);
      setState(() => _progress = p);
      if (p >= 1.0) {
        _timer?.cancel();
        widget.onFinished(true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        ((1.0 - _progress) * widget.duration.inSeconds).ceil();
    final canSkip = widget.skippable && _progress >= 0.6;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceLight,
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.electricOrange,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${remaining}s',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (canSkip) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => widget.onFinished(true),
                child: const Text('Passer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
