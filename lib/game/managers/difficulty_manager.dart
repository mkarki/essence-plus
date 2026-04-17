import '../../core/constants/game_config.dart';

/// Phases of the run. Each one bumps speed curve + hazard density + chance
/// of double/triple simultaneous spawns.
enum DifficultyPhase { warmup, normal, hot, intense, chaos }

class DifficultyManager {
  /// Returns the current game speed based on elapsed time.
  /// Curve is quadratic-ish so early game stays welcoming but late game
  /// becomes genuinely tough.
  double getSpeed(double elapsedSeconds) {
    final base = GameConfig.initialSpeed +
        elapsedSeconds * GameConfig.speedIncrementPerSecond;
    // Extra boost kicks in after 90s to push veterans.
    final bonus = elapsedSeconds > 90
        ? (elapsedSeconds - 90) * 1.5
        : 0.0;
    return (base + bonus).clamp(GameConfig.initialSpeed, GameConfig.maxSpeed);
  }

  DifficultyPhase phaseFor(double elapsedSeconds) {
    if (elapsedSeconds < 15) return DifficultyPhase.warmup;
    if (elapsedSeconds < 60) return DifficultyPhase.normal;
    if (elapsedSeconds < 120) return DifficultyPhase.hot;
    if (elapsedSeconds < 180) return DifficultyPhase.intense;
    return DifficultyPhase.chaos;
  }

  /// Hazard interval shrinks with time: from the full range down to ~40%
  /// of it in chaos mode. Applied by SpawnManager.
  double hazardIntervalMultiplier(double elapsedSeconds) {
    final phase = phaseFor(elapsedSeconds);
    return switch (phase) {
      DifficultyPhase.warmup => 1.4,
      DifficultyPhase.normal => 1.0,
      DifficultyPhase.hot => 0.78,
      DifficultyPhase.intense => 0.6,
      DifficultyPhase.chaos => 0.45,
    };
  }

  /// How many hazards can spawn at once. >1 means double or triple threats.
  int simultaneousHazards(double elapsedSeconds, double rng01) {
    final phase = phaseFor(elapsedSeconds);
    return switch (phase) {
      DifficultyPhase.warmup || DifficultyPhase.normal => 1,
      DifficultyPhase.hot => rng01 < 0.25 ? 2 : 1,
      DifficultyPhase.intense => rng01 < 0.45 ? 2 : 1,
      DifficultyPhase.chaos => rng01 < 0.35 ? 3 : (rng01 < 0.75 ? 2 : 1),
    };
  }

  /// Legacy modifier kept for backward compatibility.
  double getHazardIntervalModifier(double elapsedSeconds) =>
      hazardIntervalMultiplier(elapsedSeconds);
}
