import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/player_progression.dart';

/// Garage = meta-progression hub: wallet, upgrades, skins, missions, trophies.
class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final Stream<void> _changes;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _changes = PlayerProgression.instance.changes;
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _changes,
      builder: (context, _) {
        final prog = PlayerProgression.instance;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('GARAGE'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: _WalletChip(barrels: prog.barrels),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              labelColor: AppColors.amberGold,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.amberGold,
              tabs: const [
                Tab(text: 'Missions'),
                Tab(text: 'Upgrades'),
                Tab(text: 'Skins'),
                Tab(text: 'Trophées'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: const [
              _MissionsTab(),
              _UpgradesTab(),
              _SkinsTab(),
              _AchievementsTab(),
            ],
          ),
        );
      },
    );
  }
}

class _WalletChip extends StatelessWidget {
  final int barrels;
  const _WalletChip({required this.barrels});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.amberGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amberGold.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_drink, color: AppColors.amberGold, size: 16),
          const SizedBox(width: 6),
          Text(
            '$barrels',
            style: const TextStyle(
              color: AppColors.amberGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionsTab extends StatelessWidget {
  const _MissionsTab();

  @override
  Widget build(BuildContext context) {
    final missions = PlayerProgression.instance.missions;
    if (missions.isEmpty) {
      return const Center(child: Text('Aucune mission aujourd\'hui'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: missions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final m = missions[i];
        final progress =
            (m.progress / m.goal).clamp(0.0, 1.0);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: m.completed
                  ? AppColors.neonGreen.withValues(alpha: 0.6)
                  : AppColors.textSecondary.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    m.completed ? Icons.task_alt : Icons.flag,
                    color: m.completed
                        ? AppColors.neonGreen
                        : AppColors.electricOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      m.title,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '+${m.rewardBarrels}',
                    style: const TextStyle(
                      color: AppColors.amberGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation(
                    m.completed
                        ? AppColors.neonGreen
                        : AppColors.electricOrange,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${m.progress.clamp(0, m.goal)} / ${m.goal}',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UpgradesTab extends StatelessWidget {
  const _UpgradesTab();

  @override
  Widget build(BuildContext context) {
    final prog = PlayerProgression.instance;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: UpgradeAxis.values.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final axis = UpgradeAxis.values[i];
        final level = prog.upgradeLevel(axis);
        final cost = prog.upgradeNextCost(axis);
        final maxed = cost < 0;
        final canAfford = cost > 0 && prog.barrels >= cost;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(axis.label,
                            style:
                                Theme.of(ctx).textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          axis.description,
                          style: Theme.of(ctx)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Niv $level/${axis.maxLevel}',
                    style: const TextStyle(
                      color: AppColors.electricOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var k = 0; k < axis.maxLevel; k++)
                    Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(
                            right: k == axis.maxLevel - 1 ? 0 : 4),
                        decoration: BoxDecoration(
                          color: k < level
                              ? AppColors.electricOrange
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: maxed || !canAfford
                      ? null
                      : () async {
                          final ok = await prog.buyUpgrade(axis);
                          if (!ok && ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Pas assez de barils'),
                              ),
                            );
                          }
                        },
                  child: Text(
                    maxed
                        ? 'MAX'
                        : canAfford
                            ? 'AMELIORER · $cost brl'
                            : 'Manque ${cost - prog.barrels} brl',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkinsTab extends StatelessWidget {
  const _SkinsTab();

  @override
  Widget build(BuildContext context) {
    final prog = PlayerProgression.instance;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: TankerSkin.all.length,
      itemBuilder: (ctx, i) {
        final skin = TankerSkin.all[i];
        final owned = prog.unlockedSkins.contains(skin.id);
        final selected = prog.selectedSkin == skin.id;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.amberGold
                  : AppColors.textSecondary.withValues(alpha: 0.15),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(skin.hullColor),
                        Color(skin.deckColor),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_boat,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(skin.name,
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: owned
                    ? OutlinedButton(
                        onPressed: selected
                            ? null
                            : () => prog.selectSkin(skin.id),
                        child: Text(selected ? 'EQUIPE' : 'EQUIPER'),
                      )
                    : ElevatedButton(
                        onPressed: prog.barrels >= skin.priceBarrels
                            ? () => prog.unlockSkin(skin.id)
                            : null,
                        child: Text('${skin.priceBarrels} brl'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context) {
    final prog = PlayerProgression.instance;
    final list = AchievementCatalog.all;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final a = list[i];
        final unlocked = prog.isAchievementUnlocked(a.id);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unlocked
                  ? AppColors.amberGold.withValues(alpha: 0.6)
                  : AppColors.textSecondary.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                unlocked ? Icons.emoji_events : Icons.lock_outline,
                color: unlocked
                    ? AppColors.amberGold
                    : AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: TextStyle(
                        color: unlocked
                            ? AppColors.amberGold
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.description,
                      style: Theme.of(ctx)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (unlocked)
                const Icon(Icons.check_circle,
                    color: AppColors.neonGreen),
            ],
          ),
        );
      },
    );
  }
}
