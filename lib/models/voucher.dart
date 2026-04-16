enum VoucherStatus { available, claimed, redeemed, expired }

class Voucher {
  final String id;
  final String code;
  final double valueAmount;
  final String currency;
  final String stationPartner;
  final VoucherStatus status;
  final String? claimedBy;
  final DateTime? claimedAt;
  final DateTime expiresAt;
  final DateTime createdAt;

  const Voucher({
    required this.id,
    required this.code,
    required this.valueAmount,
    this.currency = 'MAD',
    required this.stationPartner,
    this.status = VoucherStatus.available,
    this.claimedBy,
    this.claimedAt,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canBeRedeemed => status == VoucherStatus.claimed && !isExpired;

  String get displayValue => '${valueAmount.toStringAsFixed(0)} $currency';

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] as String,
      code: json['code'] as String,
      valueAmount: (json['value_amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MAD',
      stationPartner: json['station_partner'] as String,
      status: VoucherStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => VoucherStatus.available,
      ),
      claimedBy: json['claimed_by'] as String?,
      claimedAt: json['claimed_at'] != null
          ? DateTime.parse(json['claimed_at'] as String)
          : null,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
