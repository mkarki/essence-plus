import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/player_progression.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A1628),
  ));

  await ApiClient().init();
  await PlayerProgression.instance.init();
  await _ensureGuestAccount();

  runApp(
    const ProviderScope(
      child: EssencePlusApp(),
    ),
  );
}

/// Cree silencieusement un compte invite au premier lancement.
/// Pas de login/signup UI - l'utilisateur saute directement sur le jeu.
Future<void> _ensureGuestAccount() async {
  final auth = AuthService();
  if (ApiClient().isLoggedIn) {
    try {
      await auth.fetchCurrentUser();
      return;
    } catch (_) {
      await ApiClient().clearToken();
    }
  }

  final unique = DateTime.now().microsecondsSinceEpoch.toString();
  final email = 'guest-$unique@hormuz.local';
  final password = 'pw-$unique';
  final name = 'Joueur ${unique.substring(unique.length - 4)}';

  try {
    await auth.signUp(email: email, password: password, displayName: name);
  } catch (_) {
    // Backend offline - l'app ouvrira quand meme, les features online
    // echoueront silencieusement (lottery, leaderboard, etc.).
  }
}
