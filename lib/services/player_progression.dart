import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for all meta-progression state stored locally:
/// barrel currency, tanker upgrades, unlocked skins, achievements progress,
/// and daily missions. Broadcasts updates through a stream so the UI can
/// react without plumbing changes everywhere.
class PlayerProgression {
  static final PlayerProgression instance = PlayerProgression._();
  PlayerProgression._();

  static const _kBarrels = 'prog.barrels';
  static const _kUpgrades = 'prog.upgrades';
  static const _kSelectedSkin = 'prog.selectedSkin';
  static const _kUnlockedSkins = 'prog.unlockedSkins';
  static const _kAchievements = 'prog.achievements';
  static const _kMissionsDay = 'prog.missionsDay';
  static const _kMissions = 'prog.missions';
  static const _kStats = 'prog.stats';

  final _controller = StreamController<void>.broadcast();
  Stream<void> get changes => _controller.stream;

  SharedPreferences? _prefs;
  SharedPreferences get _p => _prefs!;

  int _barrels = 0;
  Map<UpgradeAxis, int> _upgrades = {
    for (final a in UpgradeAxis.values) a: 0,
  };
  String _selectedSkin = 'classic';
  Set<String> _unlockedSkins = {'classic'};
  Map<String, bool> _achievements = {};
  DateTime? _missionsDay;
  List<Mission> _missions = [];
  Map<String, int> _stats = {};

  int get barrels => _barrels;
  Map<UpgradeAxis, int> get upgrades => Map.unmodifiable(_upgrades);
  String get selectedSkin => _selectedSkin;
  Set<String> get unlockedSkins => Set.unmodifiable(_unlockedSkins);
  Map<String, bool> get achievements => Map.unmodifiable(_achievements);
  List<Mission> get missions => List.unmodifiable(_missions);
  Map<String, int> get stats => Map.unmodifiable(_stats);

  // --- Lifecycle ----------------------------------------------------------

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _barrels = _p.getInt(_kBarrels) ?? 0;
    _loadUpgrades();
    _selectedSkin = _p.getString(_kSelectedSkin) ?? 'classic';
    _unlockedSkins = (_p.getStringList(_kUnlockedSkins) ?? ['classic']).toSet();
    _loadAchievements();
    _loadStats();
    _loadOrRollMissions();
  }

  void _emit() => _controller.add(null);

  // --- Barrel currency ----------------------------------------------------

  Future<void> addBarrels(int amount) async {
    if (amount <= 0) return;
    _barrels += amount;
    await _p.setInt(_kBarrels, _barrels);
    _emit();
  }

  Future<bool> spendBarrels(int amount) async {
    if (_barrels < amount) return false;
    _barrels -= amount;
    await _p.setInt(_kBarrels, _barrels);
    _emit();
    return true;
  }

  // --- Upgrades -----------------------------------------------------------

  void _loadUpgrades() {
    final raw = _p.getString(_kUpgrades);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final axis in UpgradeAxis.values) {
        _upgrades[axis] = (map[axis.name] as int?) ?? 0;
      }
    }
  }

  int upgradeLevel(UpgradeAxis axis) => _upgrades[axis] ?? 0;

  int upgradeNextCost(UpgradeAxis axis) {
    final level = upgradeLevel(axis);
    if (level >= axis.maxLevel) return -1;
    return axis.baseCost * (1 << level); // exponential: 100, 200, 400, 800
  }

  Future<bool> buyUpgrade(UpgradeAxis axis) async {
    final cost = upgradeNextCost(axis);
    if (cost < 0) return false;
    if (!await spendBarrels(cost)) return false;
    _upgrades[axis] = upgradeLevel(axis) + 1;
    await _p.setString(_kUpgrades, jsonEncode({
      for (final e in _upgrades.entries) e.key.name: e.value,
    }));
    _emit();
    return true;
  }

  // --- Skins --------------------------------------------------------------

  Future<bool> unlockSkin(String id) async {
    if (_unlockedSkins.contains(id)) return false;
    final skin = TankerSkin.byId(id);
    if (skin == null) return false;
    if (!await spendBarrels(skin.priceBarrels)) return false;
    _unlockedSkins.add(id);
    await _p.setStringList(_kUnlockedSkins, _unlockedSkins.toList());
    _emit();
    return true;
  }

  Future<void> selectSkin(String id) async {
    if (!_unlockedSkins.contains(id)) return;
    _selectedSkin = id;
    await _p.setString(_kSelectedSkin, id);
    _emit();
  }

  // --- Achievements -------------------------------------------------------

  void _loadAchievements() {
    final raw = _p.getString(_kAchievements);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _achievements = map.map((k, v) => MapEntry(k, v == true));
    }
  }

  bool isAchievementUnlocked(String id) => _achievements[id] == true;

  Future<bool> unlockAchievement(String id) async {
    if (_achievements[id] == true) return false;
    _achievements[id] = true;
    await _p.setString(_kAchievements, jsonEncode(_achievements));
    // Reward: 50 barrels per achievement
    _barrels += 50;
    await _p.setInt(_kBarrels, _barrels);
    _emit();
    return true;
  }

  // --- Stats (for achievement thresholds) --------------------------------

  void _loadStats() {
    final raw = _p.getString(_kStats);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _stats = map.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
  }

  Future<void> bumpStat(String key, int delta) async {
    _stats[key] = (_stats[key] ?? 0) + delta;
    await _p.setString(_kStats, jsonEncode(_stats));
  }

  int statValue(String key) => _stats[key] ?? 0;

  // --- Daily missions -----------------------------------------------------

  void _loadOrRollMissions() {
    final dayString = _p.getString(_kMissionsDay);
    final today = _todayUtc();
    if (dayString != null) {
      _missionsDay = DateTime.tryParse(dayString);
    }
    final rawMissions = _p.getString(_kMissions);
    if (rawMissions != null) {
      final list = jsonDecode(rawMissions) as List;
      _missions = list
          .map((e) => Mission.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (_missionsDay == null ||
        _missionsDay!.toUtc().difference(today).inDays != 0) {
      _rollMissions(today);
    }
  }

  void _rollMissions(DateTime day) {
    final rng = Random(day.millisecondsSinceEpoch);
    final pool = [
      MissionTemplate('Livrer 300 barils en 1 run', 'barrelsInRun', 300, 80),
      MissionTemplate('Score de 2000 en 1 run', 'scoreInRun', 2000, 80),
      MissionTemplate('Esquiver 25 hazards en 1 run', 'hazardsInRun', 25, 80),
      MissionTemplate('Atteindre un combo x4', 'comboReached', 4, 60),
      MissionTemplate('Fröler 2 plateformes', 'platformsInRun', 2, 100),
      MissionTemplate('Jouer 3 parties', 'runs', 3, 50),
      MissionTemplate(
        'Utiliser 5 nitros au total',
        'nitrosUsed',
        5,
        60,
      ),
    ];
    pool.shuffle(rng);
    _missions = pool.take(3).map((t) => Mission.fromTemplate(t)).toList();
    _missionsDay = day;
    _p.setString(_kMissionsDay, day.toIso8601String());
    _persistMissions();
  }

  void _persistMissions() {
    _p.setString(
      _kMissions,
      jsonEncode(_missions.map((m) => m.toJson()).toList()),
    );
  }

  /// Record progress on a mission metric. Completes the mission + credits
  /// barrels reward. Returns names of newly completed missions.
  Future<List<String>> recordMissionProgress(
    String metric,
    int value, {
    bool set = false,
  }) async {
    final completed = <String>[];
    for (final m in _missions) {
      if (m.metric != metric || m.completed) continue;
      if (set) {
        m.progress = max(m.progress, value);
      } else {
        m.progress += value;
      }
      if (m.progress >= m.goal) {
        m.completed = true;
        await addBarrels(m.rewardBarrels);
        completed.add(m.title);
      }
    }
    if (completed.isNotEmpty) _persistMissions();
    _emit();
    return completed;
  }

  // --- End-of-run aggregation --------------------------------------------

  /// Called at game-over. Aggregates stats, records mission progress,
  /// checks achievements. Returns a summary of unlocks for UI.
  Future<PostRunReport> finalizeRun({
    required int score,
    required int barrelsCollected,
    required int hazardsDodged,
    required int platformsGrazed,
    required int comboMax,
    required int nitrosUsed,
    required int distanceMeters,
  }) async {
    // Currency: half of in-run barrels go to the persistent wallet.
    final wallet = (barrelsCollected * 0.5).floor();
    await addBarrels(wallet);

    // Stats
    await bumpStat('runs', 1);
    await bumpStat('totalBarrels', barrelsCollected);
    await bumpStat('totalDistance', distanceMeters);
    await bumpStat('totalHazards', hazardsDodged);
    await bumpStat('totalNitros', nitrosUsed);
    await bumpStat('totalPlatforms', platformsGrazed);
    final best = statValue('bestScore');
    if (score > best) {
      _stats['bestScore'] = score;
      await _p.setString(_kStats, jsonEncode(_stats));
    }

    // Missions
    final completed = <String>[];
    completed.addAll(
        await recordMissionProgress('barrelsInRun', barrelsCollected, set: true));
    completed
        .addAll(await recordMissionProgress('scoreInRun', score, set: true));
    completed.addAll(
        await recordMissionProgress('hazardsInRun', hazardsDodged, set: true));
    completed.addAll(await recordMissionProgress('comboReached', comboMax,
        set: true));
    completed.addAll(await recordMissionProgress('platformsInRun', platformsGrazed,
        set: true));
    completed.addAll(await recordMissionProgress('runs', 1));
    completed.addAll(await recordMissionProgress('nitrosUsed', nitrosUsed));

    // Achievements
    final unlocked = <String>[];
    for (final a in AchievementCatalog.all) {
      if (isAchievementUnlocked(a.id)) continue;
      if (a.isSatisfied(this, lastRunScore: score, lastRunCombo: comboMax)) {
        await unlockAchievement(a.id);
        unlocked.add(a.title);
      }
    }

    return PostRunReport(
      walletBarrelsEarned: wallet,
      missionsCompleted: completed,
      achievementsUnlocked: unlocked,
    );
  }

  DateTime _todayUtc() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }
}

// === Models ==================================================================

enum UpgradeAxis {
  nitroCharges('Nitro', 'Charges nitro de depart', 5, 100),
  tankCapacity('Reservoir', 'Capacite du reservoir', 5, 100),
  lotteryLuck('Chance', 'Bonus chance lottery', 5, 150),
  speedControl('Maniabilite', 'Reactivite du tanker', 5, 100);

  final String label;
  final String description;
  final int maxLevel;
  final int baseCost;

  const UpgradeAxis(
    this.label,
    this.description,
    this.maxLevel,
    this.baseCost,
  );
}

class Mission {
  final String id;
  final String title;
  final String metric;
  final int goal;
  final int rewardBarrels;
  int progress;
  bool completed;

  Mission({
    required this.id,
    required this.title,
    required this.metric,
    required this.goal,
    required this.rewardBarrels,
    this.progress = 0,
    this.completed = false,
  });

  factory Mission.fromTemplate(MissionTemplate t) => Mission(
        id: '${t.metric}_${t.goal}',
        title: t.title,
        metric: t.metric,
        goal: t.goal,
        rewardBarrels: t.rewardBarrels,
      );

  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
        id: j['id'] as String,
        title: j['title'] as String,
        metric: j['metric'] as String,
        goal: j['goal'] as int,
        rewardBarrels: j['rewardBarrels'] as int,
        progress: (j['progress'] as num?)?.toInt() ?? 0,
        completed: j['completed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'metric': metric,
        'goal': goal,
        'rewardBarrels': rewardBarrels,
        'progress': progress,
        'completed': completed,
      };
}

class MissionTemplate {
  final String title;
  final String metric;
  final int goal;
  final int rewardBarrels;
  const MissionTemplate(
      this.title, this.metric, this.goal, this.rewardBarrels);
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final bool Function(PlayerProgression p,
      {required int lastRunScore,
      required int lastRunCombo}) isSatisfied;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.isSatisfied,
  });
}

class AchievementCatalog {
  static final List<Achievement> all = [
    Achievement(
      id: 'first_run',
      title: 'Prise en main',
      description: 'Jouer une premiere partie',
      isSatisfied: (p, {required lastRunScore, required lastRunCombo}) =>
          p.statValue('runs') >= 1,
    ),
    Achievement(
      id: 'veteran_10',
      title: 'Habitue du detroit',
      description: '10 parties jouees',
      isSatisfied: (p, {required lastRunScore, required lastRunCombo}) =>
          p.statValue('runs') >= 10,
    ),
    Achievement(
      id: 'veteran_100',
      title: 'Loup de mer',
      description: '100 parties jouees',
      isSatisfied: (p, {required lastRunScore, required lastRunCombo}) =>
          p.statValue('runs') >= 100,
    ),
    Achievement(
      id: 'combo_x3',
      title: 'Dans la zone',
      description: 'Atteindre un combo x3',
      isSatisfied: (p, {required lastRunScore, required lastRunCombo}) =>
          lastRunCombo >= 3,
    ),
    Achievement(
      id: 'combo_x5',
      title: 'En feu',
      description: 'Atteindre un combo x5',
      isSatisfied: (p, {required lastRunScore, required lastRunCombo}) =>
          lastRunCombo >= 5,
    ),
    Achievement(
      id: 'score_5k',
      title: 'Cap franchi',
      description: 'Score de 5000 en une partie',
      isSatisfied: (p, {required lastRunScore, required lastRunCombo}) =>
          lastRunScore >= 5000,
    ),
    Achievement(
      id: 'distance_10km',
      title: 'Globe-trotteur',
      description: '10 km parcourus au total',
      isSatisfied: (p, {required lastRunScore, required lastRunCombo}) =>
          p.statValue('totalDistance') >= 10000,
    ),
    Achievement(
      id: 'barrels_1k',
      title: 'Premier millier',
      description: '1000 barils collectes au total',
      isSatisfied: (p, {required lastRunScore, required lastRunCombo}) =>
          p.statValue('totalBarrels') >= 1000,
    ),
    Achievement(
      id: 'platform_5',
      title: 'Chasseur de plateformes',
      description: '5 plateformes fröllees au total',
      isSatisfied: (p, {required lastRunScore, required lastRunCombo}) =>
          p.statValue('totalPlatforms') >= 5,
    ),
  ];
}

class TankerSkin {
  final String id;
  final String name;
  final int priceBarrels;
  final int hullColor;
  final int deckColor;

  const TankerSkin({
    required this.id,
    required this.name,
    required this.priceBarrels,
    required this.hullColor,
    required this.deckColor,
  });

  static const List<TankerSkin> all = [
    TankerSkin(
      id: 'classic',
      name: 'Classique',
      priceBarrels: 0,
      hullColor: 0xFFE85A1A,
      deckColor: 0xFFCC4915,
    ),
    TankerSkin(
      id: 'stealth',
      name: 'Stealth',
      priceBarrels: 500,
      hullColor: 0xFF1A1A2E,
      deckColor: 0xFF0A1628,
    ),
    TankerSkin(
      id: 'golden',
      name: 'Doré du Koweit',
      priceBarrels: 1500,
      hullColor: 0xFFFFD700,
      deckColor: 0xFFCC9A00,
    ),
    TankerSkin(
      id: 'rust',
      name: 'Rouille',
      priceBarrels: 300,
      hullColor: 0xFF8B4513,
      deckColor: 0xFF5C2E0D,
    ),
    TankerSkin(
      id: 'solar',
      name: 'Solaire',
      priceBarrels: 2500,
      hullColor: 0xFF39FF14,
      deckColor: 0xFF2EC4B6,
    ),
  ];

  static TankerSkin? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}

class PostRunReport {
  final int walletBarrelsEarned;
  final List<String> missionsCompleted;
  final List<String> achievementsUnlocked;

  const PostRunReport({
    required this.walletBarrelsEarned,
    required this.missionsCompleted,
    required this.achievementsUnlocked,
  });

  bool get hasNews =>
      missionsCompleted.isNotEmpty || achievementsUnlocked.isNotEmpty;
}
