import '../models/voucher.dart';
import '../core/constants/api_constants.dart';
import 'api_client.dart';

class VoucherService {
  final _api = ApiClient();

  /// Claims a voucher when the tank is full.
  Future<Voucher?> claimVoucher() async {
    try {
      final data = await _api.post(ApiConstants.claimVoucher);

      if (data['success'] == true && data['voucher'] != null) {
        return Voucher.fromJson(data['voucher'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetches all vouchers claimed by the current user.
  Future<List<Voucher>> getMyVouchers() async {
    try {
      final data = await _api.get(ApiConstants.myVouchers);
      final vouchers = data['vouchers'] as List;
      return vouchers
          .map((json) => Voucher.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
