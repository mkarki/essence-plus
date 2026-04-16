abstract final class GameConfig {
  // Tank / Economy
  static const int tankCapacity = 1000;
  static const int fuelPerDrop = 5;
  static const int bonusFuelPerDrop = 2; // extra for streaks

  // Gameplay
  static const double initialSpeed = 200.0; // pixels per second
  static const double maxSpeed = 600.0;
  static const double speedIncrementPerSecond = 2.0;
  static const int laneCount = 3;
  static const double laneWidth = 80.0;

  // Spawning
  static const double minObstacleInterval = 0.8; // seconds
  static const double maxObstacleInterval = 2.5;
  static const double minFuelDropInterval = 1.0;
  static const double maxFuelDropInterval = 3.0;

  // Vehicle
  static const double vehicleWidth = 50.0;
  static const double vehicleHeight = 80.0;
  static const double laneSwitchDuration = 0.2; // seconds

  // Anti-cheat thresholds
  static const double maxFuelPerSecond = 3.0;
  static const int maxSessionsPerDay = 50;
  static const int minSessionDurationSeconds = 10;
  static const int voucherCooldownHours = 48;

  // Scoring
  static const int scorePerMeter = 1;
  static const int scorePerFuelDrop = 10;
  static const int scorePerObstacleDodged = 5;
}
