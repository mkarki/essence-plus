import 'dart:ui';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Draggable;
import 'components/tanker.dart';
import 'components/water.dart';
import 'components/collectibles/oil_barrel.dart';
import 'components/collectibles/oil_platform.dart';
import 'components/collectibles/powerup_drop.dart';
import 'components/hazards/hazard.dart';
import 'managers/spawn_manager.dart';
import 'managers/difficulty_manager.dart';
import 'managers/powerup_manager.dart';
import 'managers/vhf_narrator.dart';
import '../core/constants/game_config.dart';
import '../core/constants/app_colors.dart';
import '../services/player_progression.dart';

enum GameState { playing, gameOver, paused }

typedef VhfAnnouncementCallback = void Function(String message, String audioKey);
typedef PowerupChangedCallback = void Function();

class HormuzGame extends FlameGame
    with HasCollisionDetection, PanDetector {
  late Tanker tanker;
  late Water water;
  late SpawnManager spawnManager;
  late DifficultyManager difficultyManager;
  late PowerupManager powerupManager;
  late VhfNarrator vhfNarrator;

  GameState gameState = GameState.playing;

  // Session stats
  int score = 0;
  int barrelsDelivered = 0;
  int hazardsDodged = 0;
  int platformsGrazed = 0;
  double distanceTraveled = 0;
  double elapsedTime = 0;
  double currentSpeed = GameConfig.initialSpeed;

  // Combo streak
  int comboMultiplier = 1;
  double _comboTimer = 0;
  double get comboFraction =>
      _comboTimer / GameConfig.comboWindowSeconds;
  bool get comboActive => comboMultiplier > 1;

  // Nitro charges
  int nitroCharges = GameConfig.nitroStartCharges;
  int nitrosUsedThisRun = 0;
  int bestComboThisRun = 1;
  double _nitroTimer = 0;
  bool get nitroActive => _nitroTimer > 0;

  // Anchor
  double _anchorTimer = 0;
  double _anchorCooldown = 0;
  bool get anchorActive => _anchorTimer > 0;
  bool get anchorReady => _anchorCooldown <= 0 && !anchorActive;
  double get anchorCooldownFraction =>
      (_anchorCooldown / GameConfig.anchorCooldown).clamp(0.0, 1.0);

  // Radar (extendable via power-up pickups later)
  double _radarTimer = 0;
  bool get radarActive => _radarTimer > 0;

  // Fog overlay (0 = clear, 1 = thick)
  double fogIntensity = 0;
  double _fogTimer = 0;

  // Lane system
  int currentLane = 1; // 0 = left, 1 = center, 2 = right

  double getLaneX(int lane) {
    final centerX = size.x / 2;
    final offset = (lane - 1) * GameConfig.laneWidth;
    return centerX + offset;
  }

  /// X position for offshore platforms (just outside the lanes).
  double getOffshoreX(bool leftSide) {
    final centerX = size.x / 2;
    final outerLane = leftSide ? -1.5 : 1.5;
    return centerX + outerLane * GameConfig.laneWidth;
  }

  // Callbacks for Flutter overlay HUD
  VoidCallback? onScoreChanged;
  VoidCallback? onBarrelCollected;
  VoidCallback? onGameOver;
  PowerupChangedCallback? onPowerupChanged;
  VhfAnnouncementCallback? onVhfAnnouncement;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Apply persisted upgrades to the starting state.
    final prog = PlayerProgression.instance;
    nitroCharges = GameConfig.nitroStartCharges +
        prog.upgradeLevel(UpgradeAxis.nitroCharges);

    water = Water();
    await add(water);

    tanker = Tanker(
      position: Vector2(getLaneX(currentLane), size.y * 0.78),
    );
    await add(tanker);

    difficultyManager = DifficultyManager();
    powerupManager = PowerupManager(
      onChanged: () => onPowerupChanged?.call(),
    );
    vhfNarrator = VhfNarrator(
      onAnnouncement: (msg, key) => onVhfAnnouncement?.call(msg, key),
    );
    spawnManager = SpawnManager(game: this);
  }

  @override
  void update(double dt) {
    if (gameState != GameState.playing) return;
    super.update(dt);

    elapsedTime += dt;
    if (_tapCooldown > 0) _tapCooldown -= dt;

    // Combo timer
    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        comboMultiplier = 1;
        onScoreChanged?.call();
      }
    }

    // Nitro decay
    if (_nitroTimer > 0) _nitroTimer -= dt;

    // Anchor state
    if (_anchorTimer > 0) {
      _anchorTimer -= dt;
    } else if (_anchorCooldown > 0) {
      _anchorCooldown -= dt;
    }

    // Radar
    if (_radarTimer > 0) _radarTimer -= dt;

    final baseSpeed = difficultyManager.getSpeed(elapsedTime);
    final coffeeMult = powerupManager.isActive(PowerupType.coffee)
        ? GameConfig.coffeeSpeedMultiplier
        : 1.0;
    final controlMult = _boosting
        ? GameConfig.tankerBoostMultiplier
        : (_braking ? GameConfig.tankerBrakeMultiplier : 1.0);
    final nitroMult = nitroActive ? GameConfig.nitroSpeedMultiplier : 1.0;
    final anchorMult = anchorActive ? 0.0 : 1.0;
    currentSpeed =
        baseSpeed * coffeeMult * controlMult * nitroMult * anchorMult;

    distanceTraveled += currentSpeed * dt / 100; // convert to "meters"
    score = distanceTraveled.toInt() * GameConfig.scorePerMeter
        + (barrelsDelivered ~/ GameConfig.barrelsPerDrop) * GameConfig.scorePerBarrel
        + hazardsDodged * GameConfig.scorePerHazardDodged
        + platformsGrazed * GameConfig.scorePerPlatformGraze;

    powerupManager.tick(dt);
    vhfNarrator.tick(dt);
    spawnManager.update(dt);

    if (_fogTimer > 0) {
      _fogTimer -= dt;
      fogIntensity = (_fogTimer / GameConfig.fogDuration).clamp(0.0, 1.0);
    } else {
      fogIntensity = 0;
    }

    onScoreChanged?.call();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (fogIntensity > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()
          ..color = AppColors.oceanFoam.withValues(
            alpha: fogIntensity * GameConfig.fogOpacity,
          ),
      );
    }
  }

  // Pan state - accumulate delta since last lane change so small movements
  // still register and rapid swipes can cross multiple lanes smoothly.
  double _panAccumulator = 0;
  static double get _panThreshold => GameConfig.panLaneThreshold;

  // Tap debounce so accidental double-taps don't over-steer.
  double _tapCooldown = 0;

  // Boost / brake held from HUD buttons.
  bool _boosting = false;
  bool _braking = false;
  bool get isBoosting => _boosting;
  bool get isBraking => _braking;

  void setBoosting(bool on) => _boosting = on;
  void setBraking(bool on) => _braking = on;

  @override
  void onPanStart(DragStartInfo info) {
    _panAccumulator = 0;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (gameState != GameState.playing) return;
    _panAccumulator += info.delta.global.x;
    while (_panAccumulator >= _panThreshold &&
        currentLane < GameConfig.laneCount - 1) {
      currentLane++;
      tanker.moveToLane(getLaneX(currentLane));
      _panAccumulator -= _panThreshold;
    }
    while (_panAccumulator <= -_panThreshold && currentLane > 0) {
      currentLane--;
      tanker.moveToLane(getLaneX(currentLane));
      _panAccumulator += _panThreshold;
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _panAccumulator = 0;
  }

  /// Called from the Flutter-level GestureDetector in game_screen. Tapping
  /// left/right half of the screen switches one lane - much more reactive
  /// than dragging on a small phone screen.
  void handleTapAtX(double globalX) {
    if (gameState != GameState.playing) return;
    if (_tapCooldown > 0) return;
    _tapCooldown = GameConfig.tapCooldownSeconds;
    if (globalX < size.x / 2 && currentLane > 0) {
      currentLane--;
      tanker.moveToLane(getLaneX(currentLane));
    } else if (globalX >= size.x / 2 &&
        currentLane < GameConfig.laneCount - 1) {
      currentLane++;
      tanker.moveToLane(getLaneX(currentLane));
    }
  }

  void collectBarrel(OilBarrel barrel) {
    // Combo: chained grabs within the window increase the multiplier.
    if (_comboTimer > 0) {
      comboMultiplier = (comboMultiplier + 1)
          .clamp(1, GameConfig.comboMaxMultiplier);
    } else {
      comboMultiplier = 1;
    }
    _comboTimer = GameConfig.comboWindowSeconds;
    if (comboMultiplier > bestComboThisRun) {
      bestComboThisRun = comboMultiplier;
    }

    barrelsDelivered += GameConfig.barrelsPerDrop * comboMultiplier;
    barrel.collect();
    onBarrelCollected?.call();
    vhfNarrator.trigger(VhfEvent.barrelGrabbed);
  }

  void breakCombo() {
    if (comboMultiplier > 1) {
      comboMultiplier = 1;
      _comboTimer = 0;
      onScoreChanged?.call();
    }
  }

  /// Fire a nitro charge. Returns false if no charges left.
  bool fireNitro() {
    if (gameState != GameState.playing || nitroCharges <= 0 || nitroActive) {
      return false;
    }
    nitroCharges--;
    nitrosUsedThisRun++;
    _nitroTimer = GameConfig.nitroDuration;
    return true;
  }

  /// Drop anchor - emergency stop. Returns false if on cooldown.
  bool dropAnchor() {
    if (gameState != GameState.playing || !anchorReady) return false;
    _anchorTimer = GameConfig.anchorDuration;
    _anchorCooldown = GameConfig.anchorCooldown;
    return true;
  }

  void activateRadar([double duration = GameConfig.radarDuration]) {
    _radarTimer = duration;
  }

  void grazePlatform(OilPlatform platform) {
    platformsGrazed++;
    barrelsDelivered += GameConfig.platformBonusBarrels;
    platform.markGrazed();
    onBarrelCollected?.call();
    vhfNarrator.trigger(VhfEvent.platformGraze);
  }

  void collectPowerup(PowerupDrop drop) {
    powerupManager.activate(drop.powerupType);
    drop.consume();
    vhfNarrator.triggerPowerup(drop.powerupType);
  }

  void hitHazard(Hazard hazard) {
    if (hazard.isLethal) {
      gameState = GameState.gameOver;
      breakCombo();
      onGameOver?.call();
    }
  }

  void applyStormPush(int direction) {
    final target = (currentLane + direction).clamp(0, GameConfig.laneCount - 1);
    if (target != currentLane) {
      currentLane = target;
      tanker.moveToLane(getLaneX(currentLane));
      vhfNarrator.trigger(VhfEvent.storm);
    }
  }

  void enterFog([double duration = GameConfig.fogDuration]) {
    _fogTimer = duration;
    vhfNarrator.trigger(VhfEvent.fog);
  }

  void dodgeHazard() {
    hazardsDodged++;
  }

  /// Customs/coast guard interaction. Returns true if the tanker should be
  /// inspected (slowed/penalised). Flag of convenience or bribe skips it.
  bool shouldBeInspected() {
    if (powerupManager.isActive(PowerupType.flag)) return false;
    if (powerupManager.consumeBribe()) return false;
    return true;
  }

  void togglePause() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
      pauseEngine();
    } else if (gameState == GameState.paused) {
      gameState = GameState.playing;
      resumeEngine();
    }
  }

  void restart() {
    score = 0;
    barrelsDelivered = 0;
    hazardsDodged = 0;
    platformsGrazed = 0;
    distanceTraveled = 0;
    elapsedTime = 0;
    currentSpeed = GameConfig.initialSpeed;
    currentLane = 1;
    fogIntensity = 0;
    _fogTimer = 0;
    comboMultiplier = 1;
    _comboTimer = 0;
    bestComboThisRun = 1;
    nitrosUsedThisRun = 0;
    nitroCharges = GameConfig.nitroStartCharges +
        PlayerProgression.instance.upgradeLevel(UpgradeAxis.nitroCharges);
    _nitroTimer = 0;
    _anchorTimer = 0;
    _anchorCooldown = 0;
    _radarTimer = 0;
    gameState = GameState.playing;

    children.whereType<OilBarrel>().toList().forEach((e) => e.removeFromParent());
    children.whereType<OilPlatform>().toList().forEach((e) => e.removeFromParent());
    children.whereType<PowerupDrop>().toList().forEach((e) => e.removeFromParent());
    children.whereType<Hazard>().toList().forEach((e) => e.removeFromParent());

    tanker.position = Vector2(getLaneX(1), size.y * 0.78);
    spawnManager.reset();
    powerupManager.reset();
    vhfNarrator.reset();

    if (paused) resumeEngine();
  }

  @override
  Color backgroundColor() => AppColors.oceanDeep;
}
