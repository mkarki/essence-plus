class UserProfile {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final int totalFuelCollected;
  final int gamesPlayed;
  final int vouchersEarned;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.totalFuelCollected = 0,
    this.gamesPlayed = 0,
    this.vouchersEarned = 0,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      totalFuelCollected: json['total_fuel_collected'] as int? ?? 0,
      gamesPlayed: json['games_played'] as int? ?? 0,
      vouchersEarned: json['vouchers_earned'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'total_fuel_collected': totalFuelCollected,
        'games_played': gamesPlayed,
        'vouchers_earned': vouchersEarned,
      };
}
