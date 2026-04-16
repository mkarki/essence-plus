import 'dart:math';
import '../../core/constants/game_config.dart';
import 'powerup_manager.dart';

enum VhfEvent {
  hazardSpotted,
  barrelGrabbed,
  platformGraze,
  fog,
  storm,
  customsAhead,
  exclusionZone,
  coastGuard,
  inspection,
  idle,
  powerupGrabbed,
}

class VhfLine {
  final String text;
  final String audioKey; // e.g. 'vhf_fog_01.mp3' (file under assets/audio/vhf/)
  const VhfLine(this.text, this.audioKey);
}

typedef VhfAnnounceCallback = void Function(String text, String audioKey);

class VhfNarrator {
  final VhfAnnounceCallback onAnnouncement;
  final _random = Random();
  double _cooldown = 0;
  double _idleTimer = 0;

  VhfNarrator({required this.onAnnouncement});

  static const Map<VhfEvent, List<VhfLine>> _lines = {
    VhfEvent.hazardSpotted: [
      VhfLine('Capitaine, trafic civil droit devant.', 'vhf_hazard_01'),
      VhfLine('Avis : embâcle dans le couloir.', 'vhf_hazard_02'),
    ],
    VhfEvent.barrelGrabbed: [
      VhfLine('Cargaison récupérée. Continuez.', 'vhf_barrel_01'),
      VhfLine('Plus un baril. La compagnie vous remercie.', 'vhf_barrel_02'),
    ],
    VhfEvent.platformGraze: [
      VhfLine('Plateforme à quai : transfert express réussi !', 'vhf_platform_01'),
      VhfLine('+50 barils, joli passage.', 'vhf_platform_02'),
    ],
    VhfEvent.fog: [
      VhfLine('Brouillard épais, réduisez la veille visuelle.', 'vhf_fog_01'),
      VhfLine('Visibilité nulle, on continue à l\'instinct.', 'vhf_fog_02'),
    ],
    VhfEvent.storm: [
      VhfLine('Vague oblique, accrochez-vous !', 'vhf_storm_01'),
      VhfLine('La tempête vous a poussé hors voie.', 'vhf_storm_02'),
    ],
    VhfEvent.customsAhead: [
      VhfLine('Douane signalée à 200 mètres.', 'vhf_customs_01'),
      VhfLine('Préparez les papiers, contrôle imminent.', 'vhf_customs_02'),
    ],
    VhfEvent.exclusionZone: [
      VhfLine('Zone d\'exclusion activée, voie fermée.', 'vhf_exclusion_01'),
      VhfLine('Décret ministériel : on dégage cette voie.', 'vhf_exclusion_02'),
    ],
    VhfEvent.coastGuard: [
      VhfLine('Garde-côtes en approche.', 'vhf_coastguard_01'),
      VhfLine('Vedette officielle à tribord.', 'vhf_coastguard_02'),
    ],
    VhfEvent.inspection: [
      VhfLine('Inspection sanitaire surprise. Joie.', 'vhf_inspection_01'),
      VhfLine('Contrôle de soute, ça va prendre un moment.', 'vhf_inspection_02'),
    ],
    VhfEvent.idle: [
      VhfLine('Tout est calme. Trop calme.', 'vhf_idle_01'),
      VhfLine('Café froid, mer plate, rien à signaler.', 'vhf_idle_02'),
      VhfLine('La compagnie vous remercie pour vos heures sup\'.', 'vhf_idle_03'),
    ],
    VhfEvent.powerupGrabbed: [
      VhfLine('Bonus à bord, profitez-en.', 'vhf_powerup_01'),
    ],
  };

  static const Map<PowerupType, VhfLine> _powerupLines = {
    PowerupType.flag: VhfLine(
      'Pavillon de complaisance hissé.',
      'vhf_pu_flag',
    ),
    PowerupType.coffee: VhfLine(
      'Double espresso. Plein gaz !',
      'vhf_pu_coffee',
    ),
    PowerupType.bribe: VhfLine(
      'Enveloppe prête pour le prochain contrôle.',
      'vhf_pu_bribe',
    ),
    PowerupType.weather: VhfLine(
      'Bulletin météo reçu, hazards révélés.',
      'vhf_pu_weather',
    ),
    PowerupType.foghorn: VhfLine(
      'Corne de brume engagée, dispersez-moi ces barques !',
      'vhf_pu_foghorn',
    ),
  };

  void tick(double dt) {
    if (_cooldown > 0) _cooldown -= dt;
    _idleTimer += dt;

    // After 12s of silence, drop a flavor line.
    if (_cooldown <= 0 && _idleTimer > 12) {
      _idleTimer = 0;
      trigger(VhfEvent.idle);
    }
  }

  void trigger(VhfEvent event) {
    if (_cooldown > 0) return;
    final lines = _lines[event];
    if (lines == null || lines.isEmpty) return;
    final line = lines[_random.nextInt(lines.length)];
    onAnnouncement(line.text, line.audioKey);
    _cooldown = GameConfig.vhfCooldownSeconds;
    _idleTimer = 0;
  }

  void triggerPowerup(PowerupType type) {
    if (_cooldown > 0) return;
    final line = _powerupLines[type];
    if (line == null) return;
    onAnnouncement(line.text, line.audioKey);
    _cooldown = GameConfig.vhfCooldownSeconds;
    _idleTimer = 0;
  }

  void reset() {
    _cooldown = 0;
    _idleTimer = 0;
  }
}
