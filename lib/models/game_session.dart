class GameSession {
  final String? id;
  final String userId;
  final int fuelCollected;
  final int score;
  final int distanceMeters;
  final int durationSeconds;
  final int obstaclesDodged;
  final bool serverValidated;
  final DateTime? createdAt;

  const GameSession({
    this.id,
    required this.userId,
    required this.fuelCollected,
    required this.score,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.obstaclesDodged,
    this.serverValidated = false,
    this.createdAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      fuelCollected: json['fuel_collected'] as int,
      score: json['score'] as int,
      distanceMeters: json['distance_meters'] as int,
      durationSeconds: json['duration_seconds'] as int,
      obstaclesDodged: json['obstacles_dodged'] as int,
      serverValidated: json['server_validated'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'fuel_collected': fuelCollected,
        'score': score,
        'distance_meters': distanceMeters,
        'duration_seconds': durationSeconds,
        'obstacles_dodged': obstaclesDodged,
      };
}
