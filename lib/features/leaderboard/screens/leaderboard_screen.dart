import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../services/api_client.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Future<List<_Entry>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_Entry>> _load() async {
    final data = await ApiClient().get(ApiConstants.leaderboard);
    final list = (data['leaderboard'] as List?) ?? const [];
    return list
        .map<_Entry>((e) => _Entry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('CLASSEMENT'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<List<_Entry>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.electricOrange,
                ),
              );
            }
            if (snap.hasError) {
              return Center(
                child: Text(
                  'Erreur: ${snap.error}',
                  style: const TextStyle(color: AppColors.hazardRed),
                ),
              );
            }
            final list = snap.data ?? const <_Entry>[];
            if (list.isEmpty) {
              return const Center(
                child: Text('Pas encore de classement'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final e = list[i];
                final podium = i < 3;
                final colors = [
                  AppColors.amberGold,
                  AppColors.oceanFoam,
                  const Color(0xFFCD7F32), // bronze
                ];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: podium
                        ? Border.all(color: colors[i], width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '#${i + 1}',
                          style: TextStyle(
                            color: podium ? colors[i] : AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.displayName,
                              style: Theme.of(ctx).textTheme.titleMedium,
                            ),
                            Text(
                              '${e.gamesPlayed} parties · ${e.vouchersEarned} bons',
                              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${e.totalFuelCollected}',
                        style: const TextStyle(
                          color: AppColors.amberGold,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.local_drink,
                        color: AppColors.amberGold,
                        size: 14,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Entry {
  final String displayName;
  final int totalFuelCollected;
  final int gamesPlayed;
  final int vouchersEarned;

  const _Entry({
    required this.displayName,
    required this.totalFuelCollected,
    required this.gamesPlayed,
    required this.vouchersEarned,
  });

  factory _Entry.fromJson(Map<String, dynamic> j) => _Entry(
        displayName: (j['displayName'] ?? j['display_name'] ?? 'Joueur')
            as String,
        totalFuelCollected:
            (j['totalFuelCollected'] ?? j['total_fuel_collected'] ?? 0) as int,
        gamesPlayed: (j['gamesPlayed'] ?? j['games_played'] ?? 0) as int,
        vouchersEarned:
            (j['vouchersEarned'] ?? j['vouchers_earned'] ?? 0) as int,
      );
}
