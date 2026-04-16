import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/gameplay/screens/game_screen.dart';
import '../../features/vouchers/screens/voucher_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../services/api_client.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = ApiClient().isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/play',
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: '/vouchers',
        builder: (context, state) => const VoucherListScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
