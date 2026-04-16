import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/voucher.dart';

class VoucherDetailScreen extends StatelessWidget {
  final Voucher voucher;

  const VoucherDetailScreen({super.key, required this.voucher});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MON BON'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            // Station name
            Text(
              voucher.stationPartner,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),

            // Value
            Text(
              voucher.displayValue,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.amberGold,
                  ),
            ),

            const SizedBox(height: 32),

            // QR Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: '${voucher.id}:${voucher.code}',
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Presentez ce QR code a la station',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),

            const SizedBox(height: 8),

            // Code text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                voucher.code,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                    ),
              ),
            ),

            const SizedBox(height: 24),

            // Expiry
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: voucher.isExpired
                      ? AppColors.hotRed
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  voucher.isExpired
                      ? 'Expire'
                      : 'Expire le ${_formatDate(voucher.expiresAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: voucher.isExpired
                            ? AppColors.hotRed
                            : AppColors.textSecondary,
                      ),
                ),
              ],
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
