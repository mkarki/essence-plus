import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.displayName ?? 'Joueur';

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFIL'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(displayName, style: Theme.of(context).textTheme.headlineMedium),

            if (user != null) ...[
              const SizedBox(height: 24),
              _StatTile(
                icon: Icons.local_gas_station,
                label: 'Essence totale',
                value: '${user.totalFuelCollected}',
              ),
              _StatTile(
                icon: Icons.videogame_asset,
                label: 'Parties jouees',
                value: '${user.gamesPlayed}',
              ),
              _StatTile(
                icon: Icons.card_giftcard,
                label: 'Bons gagnes',
                value: '${user.vouchersEarned}',
              ),
            ],

            const Spacer(),

            // Logout button - no-op pour l'instant (auth par email desactive)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.logout, color: AppColors.hotRed),
                label: const Text(
                  'DECONNEXION',
                  style: TextStyle(color: AppColors.hotRed),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.hotRed),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.electricOrange, size: 24),
          const SizedBox(width: 16),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.electricOrange,
                ),
          ),
        ],
      ),
    );
  }
}
