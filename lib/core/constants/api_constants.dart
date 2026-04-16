abstract final class ApiConstants {
  // Base URL - switch via --dart-define=API_URL=...
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://essence-plus.onrender.com/api',
  );

  // Endpoints
  static const signup = '$baseUrl/auth/signup';
  static const login = '$baseUrl/auth/login';
  static const me = '$baseUrl/auth/me';
  static const submitSession = '$baseUrl/game/session';
  static const fuelBalance = '$baseUrl/game/balance';
  static const gameSessions = '$baseUrl/game/sessions';
  static const leaderboard = '$baseUrl/game/leaderboard';
  static const claimVoucher = '$baseUrl/vouchers/claim';
  static const lotteryVoucher = '$baseUrl/vouchers/lottery';
  static const myVouchers = '$baseUrl/vouchers';
  static const profile = '$baseUrl/profile';
}
