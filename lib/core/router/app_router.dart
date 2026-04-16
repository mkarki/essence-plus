import 'package:go_router/go_router.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/gameplay/screens/game_screen.dart';
import '../../features/vouchers/screens/voucher_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
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
