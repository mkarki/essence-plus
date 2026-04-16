import '../../core/constants/game_config.dart';

class DifficultyManager {
  /// Returns the current game speed based on elapsed time.
  double getSpeed(double elapsedSeconds) {
    final speed =
        GameConfig.initialSpeed + elapsedSeconds * GameConfig.speedIncrementPerSecond;
    return speed.clamp(GameConfig.initialSpeed, GameConfig.maxSpeed);
  }

  /// Returns the obstacle spawn interval modifier (lower = more frequent).
  double getObstacleIntervalModifier(double elapsedSeconds) {
    // Gradually decrease interval (more obstacles over time)
    final modifier = 1.0 - (elapsedSeconds / 300).clamp(0.0, 0.5);
    return modifier;
  }
}
