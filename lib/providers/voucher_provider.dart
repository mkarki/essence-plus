import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voucher.dart';
import '../services/voucher_service.dart';

final voucherServiceProvider = Provider<VoucherService>(
  (ref) => VoucherService(),
);

final myVouchersProvider = FutureProvider<List<Voucher>>((ref) async {
  final service = ref.watch(voucherServiceProvider);
  return service.getMyVouchers();
});
