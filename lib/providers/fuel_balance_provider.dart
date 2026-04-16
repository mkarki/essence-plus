import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fuel_balance.dart';
import '../services/game_session_service.dart';

final gameSessionServiceProvider = Provider<GameSessionService>(
  (ref) => GameSessionService(),
);

final fuelBalanceProvider =
    AsyncNotifierProvider<FuelBalanceNotifier, FuelBalance?>(
  FuelBalanceNotifier.new,
);

class FuelBalanceNotifier extends AsyncNotifier<FuelBalance?> {
  @override
  Future<FuelBalance?> build() async {
    final service = ref.watch(gameSessionServiceProvider);
    return service.getFuelBalance();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final service = ref.read(gameSessionServiceProvider);
    state = AsyncData(await service.getFuelBalance());
  }

  void updateBalance(FuelBalance balance) {
    state = AsyncData(balance);
  }
}
