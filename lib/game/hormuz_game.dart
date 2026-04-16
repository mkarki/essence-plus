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
    final baseSpeed = difficultyManager.getSpeed(elapsedTime);
    final coffeeMult = powerupManager.isActive(PowerupType.coffee)
        ? GameConfig.coffeeSpeedMultiplier
        : 1.0;
    currentSpeed = baseSpeed * coffeeMult;

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

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (gameState != GameState.playing) return;

    final dx = info.delta.global.x;
    if (dx > 15 && currentLane < GameConfig.laneCount - 1) {
      currentLane++;
      tanker.moveToLane(getLaneX(currentLane));
    } else if (dx < -15 && currentLane > 0) {
      currentLane--;
      tanker.moveToLane(getLaneX(currentLane));
    }
  }

  void collectBarrel(OilBarrel barrel) {
    barrelsDelivered += GameConfig.barrelsPerDrop;
    barrel.collect();
    onBarrelCollected?.call();
    vhfNarrator.trigger(VhfEvent.barrelGrabbed);
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
