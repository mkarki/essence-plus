import '../../core/constants/game_config.dart';

enum PowerupType {
  flag,     // pavillon de complaisance — ignored by political checks
  coffee,   // boost vitesse temporaire
  bribe,    // single-use, consumed on next political check
  weather,  // bulletin météo — reveals upcoming hazards
  foghorn,  // disperse light civilian hazards (fishing boats)
}

class PowerupManager {
  final Map<PowerupType, double> _activeTimers = {};
  bool _bribeReady = false;
  final void Function() onChanged;

  PowerupManager({required this.onChanged});

  void activate(PowerupType type) {
    final duration = _durationFor(type);
    if (type == PowerupType.bribe) {
      _bribeReady = true;
    } else if (duration != null) {
      _activeTimers[type] = duration;
    }
    onChanged();
  }

  void tick(double dt) {
    if (_activeTimers.isEmpty) return;
    var changed = false;
    final toRemove = <PowerupType>[];
    for (final entry in _activeTimers.entries) {
      final remaining = entry.value - dt;
      if (remaining <= 0) {
        toRemove.add(entry.key);
        changed = true;
      } else {
        _activeTimers[entry.key] = remaining;
      }
    }
    for (final t in toRemove) {
      _activeTimers.remove(t);
    }
    if (changed) onChanged();
  }

  bool isActive(PowerupType type) => _activeTimers.containsKey(type);

  double remaining(PowerupType type) => _activeTimers[type] ?? 0;

  bool get bribeReady => _bribeReady;

  /// Consume the bribe charge (one-shot). Returns true if the bribe was used.
  bool consumeBribe() {
    if (!_bribeReady) return false;
    _bribeReady = false;
    onChanged();
    return true;
  }

  Map<PowerupType, double> get activeSnapshot =>
      Map.unmodifiable(_activeTimers);

  void reset() {
    _activeTimers.clear();
    _bribeReady = false;
    onChanged();
  }

  static double? _durationFor(PowerupType type) {
    switch (type) {
      case PowerupType.flag:
        return GameConfig.flagDuration;
      case PowerupType.coffee:
        return GameConfig.coffeeDuration;
      case PowerupType.weather:
        return GameConfig.weatherDuration;
      case PowerupType.foghorn:
        return GameConfig.foghornDuration;
      case PowerupType.bribe:
        return null;
    }
  }
}
