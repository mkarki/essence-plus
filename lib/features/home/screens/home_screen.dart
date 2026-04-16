import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fuel_balance_provider.dart';
import '../widgets/tank_gauge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelBalanceAsync = ref.watch(fuelBalanceProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salut !',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        user?.displayName ?? 'Joueur',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.push('/vouchers'),
                        icon: const Icon(
                          Icons.card_giftcard,
                          color: AppColors.amberGold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/profile'),
                        icon: const Icon(
                          Icons.person_outline,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Tank gauge
              Expanded(
                child: fuelBalanceAsync.when(
                  data: (balance) {
                    final fuel = balance?.currentFuel ?? 0;
                    final capacity = balance?.tankCapacity ?? 1000;
                    final percentage = fuel / capacity;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'MON RESERVOIR',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                    letterSpacing: 3,
                                  ),
                        ),
                        const SizedBox(height: 24),
                        TankGauge(
                          fillPercentage: percentage,
                          currentFuel: fuel,
                          tankCapacity: capacity,
                        ),
                        const SizedBox(height: 24),
                        if (percentage >= 1.0)
                          ElevatedButton.icon(
                            onPressed: () => context.push('/vouchers/claim'),
                            icon: const Icon(Icons.card_giftcard),
                            label: const Text('RECLAMER MON BON'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.amberGold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.electricOrange,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Erreur de chargement',
                      style: TextStyle(color: AppColors.hotRed),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Play button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () => context.push('/play'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, size: 32),
                          const SizedBox(width: 8),
                          Text(
                            'JOUER',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bottom nav row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavButton(
                    icon: Icons.leaderboard_outlined,
                    label: 'Classement',
                    onTap: () => context.push('/leaderboard'),
                  ),
                  _NavButton(
                    icon: Icons.history,
                    label: 'Historique',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
