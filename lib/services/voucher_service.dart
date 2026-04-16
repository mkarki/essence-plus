import '../models/voucher.dart';
import '../core/constants/api_constants.dart';
import 'api_client.dart';

class VoucherService {
  final _api = ApiClient();

  /// Tirage au sort apres une partie. Le serveur calcule la chance
  /// d'apres le score de la session et l'eventuelle pub vue.
  Future<LotteryResult> rollLottery({
    required String sessionId,
    bool adWatched = false,
  }) async {
    try {
      final data = await _api.post(ApiConstants.lotteryVoucher, body: {
        'sessionId': sessionId,
        'adWatched': adWatched,
      });
      return LotteryResult(
        won: data['won'] == true,
        chancePercent: (data['chancePercent'] as num?)?.toInt() ?? 0,
        voucher: data['voucher'] != null
            ? Voucher.fromJson(data['voucher'] as Map<String, dynamic>)
            : null,
        reason: data['reason'] as String?,
      );
    } catch (e) {
      return const LotteryResult(
        won: false,
        chancePercent: 0,
        error: 'network',
      );
    }
  }

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

class LotteryResult {
  final bool won;
  final int chancePercent;
  final Voucher? voucher;
  final String? reason;
  final String? error;

  const LotteryResult({
    required this.won,
    required this.chancePercent,
    this.voucher,
    this.reason,
    this.error,
  });

  bool get eligible => chancePercent > 0;
}
