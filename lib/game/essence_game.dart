import 'dart:ui';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Draggable;
import 'components/road.dart';
import 'components/vehicle.dart';
import 'components/fuel_drop.dart';
import 'components/obstacle.dart';
import 'managers/spawn_manager.dart';
import 'managers/difficulty_manager.dart';
import '../core/constants/game_config.dart';

enum GameState { playing, gameOver, paused }

class EssenceGame extends FlameGame
    with HasCollisionDetection, PanDetector {
  late Vehicle vehicle;
  late Road road;
  late SpawnManager spawnManager;
  late DifficultyManager difficultyManager;

  GameState gameState = GameState.playing;

  // Session stats
  int score = 0;
  int fuelCollected = 0;
  int obstaclesDodged = 0;
  double distanceTraveled = 0;
  double elapsedTime = 0;
  double currentSpeed = GameConfig.initialSpeed;

  // Lane system
  int currentLane = 1; // 0 = left, 1 = center, 2 = right

  double getLaneX(int lane) {
    final centerX = size.x / 2;
    final offset = (lane - 1) * GameConfig.laneWidth;
    return centerX + offset;
  }

  // Callbacks for Flutter overlay HUD
  VoidCallback? onScoreChanged;
  VoidCallback? onFuelCollected;
  VoidCallback? onGameOver;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    road = Road();
    await add(road);

    vehicle = Vehicle(
      position: Vector2(getLaneX(currentLane), size.y * 0.75),
    );
    await add(vehicle);

    difficultyManager = DifficultyManager();
    spawnManager = SpawnManager(game: this);
  }

  @override
  void update(double dt) {
    if (gameState != GameState.playing) return;
    super.update(dt);

    elapsedTime += dt;
    currentSpeed = difficultyManager.getSpeed(elapsedTime);
    distanceTraveled += currentSpeed * dt / 100; // convert to "meters"
    score = distanceTraveled.toInt() * GameConfig.scorePerMeter;

    spawnManager.update(dt);
    onScoreChanged?.call();
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (gameState != GameState.playing) return;

    final dx = info.delta.global.x;
    if (dx > 15 && currentLane < GameConfig.laneCount - 1) {
      currentLane++;
      vehicle.moveToLane(getLaneX(currentLane));
    } else if (dx < -15 && currentLane > 0) {
      currentLane--;
      vehicle.moveToLane(getLaneX(currentLane));
    }
  }

  void collectFuel(FuelDrop drop) {
    fuelCollected += GameConfig.fuelPerDrop;
    score += GameConfig.scorePerFuelDrop;
    drop.collect();
    onFuelCollected?.call();
  }

  void hitObstacle(Obstacle obstacle) {
    gameState = GameState.gameOver;
    onGameOver?.call();
  }

  void dodgeObstacle() {
    obstaclesDodged++;
    score += GameConfig.scorePerObstacleDodged;
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
    fuelCollected = 0;
    obstaclesDodged = 0;
    distanceTraveled = 0;
    elapsedTime = 0;
    currentSpeed = GameConfig.initialSpeed;
    currentLane = 1;
    gameState = GameState.playing;

    // Remove all fuel drops and obstacles
    children.whereType<FuelDrop>().toList().forEach((e) => e.removeFromParent());
    children.whereType<Obstacle>().toList().forEach((e) => e.removeFromParent());

    vehicle.position = Vector2(getLaneX(1), size.y * 0.75);
    spawnManager.reset();

    if (paused) resumeEngine();
  }

  @override
  Color backgroundColor() => const Color(0xFF0A1628);
}
