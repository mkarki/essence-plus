import 'dart:async';
import '../core/constants/api_constants.dart';
import '../models/user_profile.dart';
import 'api_client.dart';

class AuthService {
  final _api = ApiClient();
  final _authController = StreamController<AuthEvent>.broadcast();

  UserProfile? _currentUser;

  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _api.isLoggedIn && _currentUser != null;
  Stream<AuthEvent> get authStateChanges => _authController.stream;

  Future<void> init() async {
    await _api.init();
    if (_api.isLoggedIn) {
      try {
        await fetchCurrentUser();
        _authController.add(AuthEvent.signedIn);
      } catch (_) {
        await _api.clearToken();
        _authController.add(AuthEvent.signedOut);
      }
    }
  }

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final data = await _api.post(ApiConstants.signup, body: {
      'email': email,
      'password': password,
      'displayName': displayName,
    });

    await _api.setToken(data['token'] as String);
    _currentUser = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    _authController.add(AuthEvent.signedIn);
    return _currentUser!;
  }

  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(ApiConstants.login, body: {
      'email': email,
      'password': password,
    });

    await _api.setToken(data['token'] as String);
    _currentUser = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    _authController.add(AuthEvent.signedIn);
    return _currentUser!;
  }

  Future<void> signOut() async {
    await _api.clearToken();
    _currentUser = null;
    _authController.add(AuthEvent.signedOut);
  }

  Future<UserProfile> fetchCurrentUser() async {
    final data = await _api.get(ApiConstants.me);
    _currentUser = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    return _currentUser!;
  }

  void dispose() {
    _authController.close();
  }
}

enum AuthEvent { signedIn, signedOut }
