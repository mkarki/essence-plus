import 'dart:math';
import 'package:flame/components.dart';
import '../../core/constants/game_config.dart';
import '../essence_game.dart';
import '../components/fuel_drop.dart';
import '../components/obstacle.dart';

class SpawnManager {
  final EssenceGame game;
  final _random = Random();

  double _obstacleTimer = 0;
  double _fuelDropTimer = 0;
  double _nextObstacleTime = 2.0; // initial delay
  double _nextFuelDropTime = 1.0;

  SpawnManager({required this.game});

  void update(double dt) {
    _obstacleTimer += dt;
    _fuelDropTimer += dt;

    if (_obstacleTimer >= _nextObstacleTime) {
      _spawnObstacle();
      _obstacleTimer = 0;
      _nextObstacleTime = _randomBetween(
        GameConfig.minObstacleInterval,
        GameConfig.maxObstacleInterval,
      );
    }

    if (_fuelDropTimer >= _nextFuelDropTime) {
      _spawnFuelDrop();
      _fuelDropTimer = 0;
      _nextFuelDropTime = _randomBetween(
        GameConfig.minFuelDropInterval,
        GameConfig.maxFuelDropInterval,
      );
    }
  }

  void _spawnObstacle() {
    final lane = _random.nextInt(GameConfig.laneCount);
    final type = ObstacleType.values[_random.nextInt(ObstacleType.values.length)];

    game.add(
      Obstacle(
        position: Vector2(game.getLaneX(lane), -50),
        type: type,
      ),
    );
  }

  void _spawnFuelDrop() {
    final lane = _random.nextInt(GameConfig.laneCount);

    game.add(
      FuelDrop(
        position: Vector2(game.getLaneX(lane), -50),
      ),
    );
  }

  void reset() {
    _obstacleTimer = 0;
    _fuelDropTimer = 0;
    _nextObstacleTime = 2.0;
    _nextFuelDropTime = 1.0;
  }

  double _randomBetween(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }
}
