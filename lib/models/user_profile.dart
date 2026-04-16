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
    T? pick<T>(String camel, String snake) =>
        (json[camel] ?? json[snake]) as T?;

    final createdAtRaw = pick<String>('createdAt', 'created_at');

    return UserProfile(
      id: json['id'] as String,
      displayName:
          pick<String>('displayName', 'display_name') ?? 'Joueur',
      avatarUrl: pick<String>('avatarUrl', 'avatar_url'),
      totalFuelCollected:
          pick<int>('totalFuelCollected', 'total_fuel_collected') ?? 0,
      gamesPlayed: pick<int>('gamesPlayed', 'games_played') ?? 0,
      vouchersEarned:
          pick<int>('vouchersEarned', 'vouchers_earned') ?? 0,
      createdAt: createdAtRaw != null
          ? DateTime.parse(createdAtRaw)
          : DateTime.now(),
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
