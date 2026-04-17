import 'dart:math';
import 'package:flame/components.dart';
import '../../core/constants/game_config.dart';
import '../hormuz_game.dart';
import '../components/collectibles/oil_barrel.dart';
import '../components/collectibles/oil_platform.dart';
import '../components/collectibles/powerup_drop.dart';
import '../components/hazards/civilian_ship.dart';
import '../components/hazards/coast_guard.dart';
import '../components/hazards/customs_checkpoint.dart';
import '../components/hazards/exclusion_zone.dart';
import '../components/hazards/ferry.dart';
import '../components/hazards/fishing_boats.dart';
import '../components/hazards/fog_bank.dart';
import '../components/hazards/hazard.dart';
import '../components/hazards/reef.dart';
import '../components/hazards/storm_wave.dart';
import 'powerup_manager.dart';

class SpawnManager {
  final HormuzGame game;
  final _random = Random();

  double _hazardTimer = 0;
  double _barrelTimer = 0;
  double _platformTimer = 0;
  double _powerupTimer = 0;
  double _nextHazardTime = 2.0;
  double _nextBarrelTime = 1.2;
  double _nextPlatformTime = 12.0;
  double _nextPowerupTime = 18.0;

  SpawnManager({required this.game});

  void update(double dt) {
    _hazardTimer += dt;
    _barrelTimer += dt;
    _platformTimer += dt;
    _powerupTimer += dt;

    if (_hazardTimer >= _nextHazardTime) {
      _spawnHazard();
      _hazardTimer = 0;
      _nextHazardTime = _randomBetween(
        GameConfig.minHazardInterval,
        GameConfig.maxHazardInterval,
      );
    }
    if (_barrelTimer >= _nextBarrelTime) {
      _spawnBarrel();
      _barrelTimer = 0;
      _nextBarrelTime = _randomBetween(
        GameConfig.minBarrelDropInterval,
        GameConfig.maxBarrelDropInterval,
      );
    }
    if (_platformTimer >= _nextPlatformTime) {
      _spawnPlatform();
      _platformTimer = 0;
      _nextPlatformTime = _randomBetween(
        GameConfig.minPlatformInterval,
        GameConfig.maxPlatformInterval,
      );
    }
    if (_powerupTimer >= _nextPowerupTime) {
      _spawnPowerup();
      _powerupTimer = 0;
      _nextPowerupTime = _randomBetween(
        GameConfig.minPowerupInterval,
        GameConfig.maxPowerupInterval,
      );
    }
  }

  // --- Hazards -------------------------------------------------------------

  void _spawnHazard() {
    final category = _pickCategory();
    switch (category) {
      case HazardCategory.civilian:
        _spawnCivilianHazard();
      case HazardCategory.natural:
        _spawnNaturalHazard();
      case HazardCategory.political:
        _spawnPoliticalHazard();
    }
  }

  HazardCategory _pickCategory() {
    final total = GameConfig.weightCivilian +
        GameConfig.weightNatural +
        GameConfig.weightPolitical;
    final roll = _random.nextInt(total);
    if (roll < GameConfig.weightCivilian) return HazardCategory.civilian;
    if (roll < GameConfig.weightCivilian + GameConfig.weightNatural) {
      return HazardCategory.natural;
    }
    return HazardCategory.political;
  }

  void _spawnCivilianHazard() {
    final lane = _random.nextInt(GameConfig.laneCount);
    final pos = Vector2(game.getLaneX(lane), -80);
    final pick = _random.nextInt(3);
    switch (pick) {
      case 0:
        game.add(CivilianShip(position: pos));
      case 1:
        game.add(Ferry(position: pos));
      default:
        game.add(FishingBoats(position: pos));
    }
  }

  void _spawnNaturalHazard() {
    final pick = _random.nextInt(3);
    switch (pick) {
      case 0:
        final lane = _random.nextInt(GameConfig.laneCount);
        game.add(Reef(
          position: Vector2(game.getLaneX(lane), -50),
          seed: _random.nextInt(1 << 16),
        ));
      case 1:
        // Fog bank centered on the channel
        game.add(FogBank(position: Vector2(game.size.x / 2, -80)));
      default:
        // Storm wave covers only 2 lanes - player can dodge by staying in
        // the opposite outside lane. Random left/right side + push dir.
        final onLeft = _random.nextBool();
        final direction = _random.nextBool() ? -1 : 1;
        final centerX = game.size.x / 2;
        // Left side covers lanes 0-1, right side covers lanes 1-2.
        final waveX = onLeft
            ? centerX - GameConfig.laneWidth * 0.5
            : centerX + GameConfig.laneWidth * 0.5;
        game.add(StormWave(
          position: Vector2(waveX, -20),
          direction: direction,
        ));
    }
  }

  void _spawnPoliticalHazard() {
    final lane = _random.nextInt(GameConfig.laneCount);
    final pick = _random.nextInt(3);
    switch (pick) {
      case 0:
        game.add(ExclusionZone(
          position: Vector2(game.getLaneX(lane), -120),
        ));
      case 1:
        game.add(CoastGuard(
          position: Vector2(game.getLaneX(lane), -60),
        ));
      default:
        game.add(CustomsCheckpoint(
          position: Vector2(game.getLaneX(lane), -30),
        ));
    }
  }

  // --- Collectibles --------------------------------------------------------

  void _spawnBarrel() {
    final lane = _random.nextInt(GameConfig.laneCount);
    game.add(OilBarrel(position: Vector2(game.getLaneX(lane), -50)));
  }

  void _spawnPlatform() {
    final leftSide = _random.nextBool();
    final x = game.getOffshoreX(leftSide);
    game.add(OilPlatform(
      position: Vector2(x, -120),
      leftSide: leftSide,
    ));
  }

  void _spawnPowerup() {
    final lane = _random.nextInt(GameConfig.laneCount);
    final type = PowerupType.values[_random.nextInt(PowerupType.values.length)];
    game.add(PowerupDrop(
      position: Vector2(game.getLaneX(lane), -50),
      powerupType: type,
    ));
  }

  void reset() {
    _hazardTimer = 0;
    _barrelTimer = 0;
    _platformTimer = 0;
    _powerupTimer = 0;
    _nextHazardTime = 2.0;
    _nextBarrelTime = 1.2;
    _nextPlatformTime = 12.0;
    _nextPowerupTime = 18.0;
  }

  double _randomBetween(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }
}
