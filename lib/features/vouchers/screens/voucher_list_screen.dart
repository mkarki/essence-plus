import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/voucher.dart';
import '../../../providers/voucher_provider.dart';

class VoucherListScreen extends ConsumerWidget {
  const VoucherListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouchersAsync = ref.watch(myVouchersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MES BONS'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: vouchersAsync.when(
        data: (vouchers) {
          if (vouchers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.card_giftcard,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pas encore de bon',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Remplis ton reservoir pour gagner\nun bon carburant !',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              final voucher = vouchers[index];
              return _VoucherCard(
                voucher: voucher,
                onTap: () => context.push('/vouchers/${voucher.id}'),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.electricOrange),
        ),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final Voucher voucher;
  final VoidCallback onTap;

  const _VoucherCard({required this.voucher, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUsable = voucher.canBeRedeemed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUsable
                ? AppColors.neonGreen.withValues(alpha: 0.3)
                : AppColors.textSecondary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Station icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isUsable
                    ? AppColors.neonGreen.withValues(alpha: 0.15)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_gas_station,
                color: isUsable ? AppColors.neonGreen : AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher.stationPartner,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    voucher.displayValue,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.amberGold,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Color get _statusColor => switch (voucher.status) {
        VoucherStatus.claimed => AppColors.neonGreen,
        VoucherStatus.redeemed => AppColors.textSecondary,
        VoucherStatus.expired => AppColors.hotRed,
        VoucherStatus.available => AppColors.electricOrange,
      };

  String get _statusLabel => switch (voucher.status) {
        VoucherStatus.claimed => 'A utiliser',
        VoucherStatus.redeemed => 'Utilise',
        VoucherStatus.expired => 'Expire',
        VoucherStatus.available => 'Disponible',
      };
}
