class FuelBalance {
  final String userId;
  final int currentFuel;
  final int tankCapacity;
  final DateTime lastUpdated;

  const FuelBalance({
    required this.userId,
    this.currentFuel = 0,
    this.tankCapacity = 1000,
    required this.lastUpdated,
  });

  double get fillPercentage => currentFuel / tankCapacity;
  bool get isTankFull => currentFuel >= tankCapacity;
  int get fuelRemaining => tankCapacity - currentFuel;

  factory FuelBalance.fromJson(Map<String, dynamic> json) {
    return FuelBalance(
      userId: json['user_id'] as String,
      currentFuel: json['current_fuel'] as int? ?? 0,
      tankCapacity: json['tank_capacity'] as int? ?? 1000,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }
}
