abstract final class GameConfig {
  // Tank / Economy
  static const int tankCapacity = 1000;
  static const int barrelsPerDrop = 5;
  static const int bonusBarrelsPerDrop = 2; // extra for streaks
  static const int platformBonusBarrels = 50;

  // Gameplay
  static const double initialSpeed = 200.0; // pixels per second
  static const double maxSpeed = 600.0;
  static const double speedIncrementPerSecond = 2.0;
  static const int laneCount = 3;
  static const double laneWidth = 80.0;

  // Spawning - hazards (general)
  static const double minHazardInterval = 0.8; // seconds
  static const double maxHazardInterval = 2.5;

  // Spawning - oil barrel drops
  static const double minBarrelDropInterval = 1.0;
  static const double maxBarrelDropInterval = 3.0;

  // Spawning - oil platforms (offshore bonus)
  static const double minPlatformInterval = 22.0;
  static const double maxPlatformInterval = 40.0;

  // Spawning - power-ups (rare)
  static const double minPowerupInterval = 14.0;
  static const double maxPowerupInterval = 28.0;

  // Hazard category weights (out of 100)
  static const int weightCivilian = 35;
  static const int weightNatural = 35;
  static const int weightPolitical = 30;

  // Tanker
  static const double tankerWidth = 56.0;
  static const double tankerHeight = 110.0;
  static const double laneSwitchDuration = 0.32; // seconds
  static const double tankerBoostMultiplier = 1.5; // hold-to-accelerate
  static const double tankerBrakeMultiplier = 0.5; // hold-to-brake

  // Controls
  static const double panLaneThreshold = 45.0; // px of drag to switch lane
  static const double tapCooldownSeconds = 0.15; // debounce between taps

  // Power-up durations (seconds)
  static const double flagDuration = 5.0;
  static const double coffeeDuration = 3.0;
  static const double weatherDuration = 5.0;
  static const double foghornDuration = 2.5;
  static const double coffeeSpeedMultiplier = 1.6;

  // Fog effect
  static const double fogDuration = 3.0;
  static const double fogOpacity = 0.55;

  // VHF narrator
  static const double vhfCooldownSeconds = 6.0;
  static const double vhfBannerDuration = 4.5;

  // Anti-cheat thresholds
  static const double maxBarrelsPerSecond = 8.0; // raised for platform bonuses
  static const int maxSessionsPerDay = 50;
  static const int minSessionDurationSeconds = 10;
  static const int voucherCooldownHours = 48;

  // Scoring
  static const int scorePerMeter = 1;
  static const int scorePerBarrel = 10;
  static const int scorePerPlatformGraze = 50;
  static const int scorePerHazardDodged = 5;

  // Combo system
  static const double comboWindowSeconds = 3.5; // time to grab next barrel
  static const int comboMaxMultiplier = 5;

  // Nitro (instant boost, limited charges)
  static const int nitroStartCharges = 3;
  static const double nitroDuration = 1.5;
  static const double nitroSpeedMultiplier = 2.2;

  // Anchor (emergency stop)
  static const double anchorDuration = 2.0;
  static const double anchorCooldown = 12.0;

  // Radar preview (power-up)
  static const double radarDuration = 6.0;
}
