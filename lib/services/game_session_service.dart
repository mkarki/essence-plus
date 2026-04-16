import '../models/game_session.dart';
import '../models/fuel_balance.dart';
import '../core/constants/api_constants.dart';
import 'api_client.dart';

class GameSessionService {
  final _api = ApiClient();

  /// Submits a game session to the server for validation.
  /// Returns the updated fuel balance if valid, null if rejected.
  Future<FuelBalance?> submitSession(GameSession session) async {
    try {
      final data = await _api.post(
        ApiConstants.submitSession,
        body: session.toJson(),
      );

      if (data['valid'] == true && data['fuelBalance'] != null) {
        return FuelBalance.fromJson(
          data['fuelBalance'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetches the current fuel balance for the logged-in user.
  Future<FuelBalance?> getFuelBalance() async {
    try {
      final data = await _api.get(ApiConstants.fuelBalance);
      return FuelBalance.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Fetches recent game sessions for the current user.
  Future<List<GameSession>> getRecentSessions({int limit = 20}) async {
    try {
      final data = await _api.get('${ApiConstants.gameSessions}?limit=$limit');
      final sessions = data['sessions'] as List;
      return sessions
          .map((json) => GameSession.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
