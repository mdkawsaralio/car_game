import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDataService {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  SharedPreferences? _prefs;
  String? _currentUserId;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _updateUserId();
  }

  void _updateUserId() {
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid;
  }

  String _getKey(String key) {
    return '${_currentUserId ?? 'guest'}_$key';
  }

  Future<int> getCoins() async {
    _updateUserId();
    return _prefs?.getInt(_getKey('total_coins')) ?? 0;
  }

  Future<int> getHighScore() async {
    _updateUserId();
    return _prefs?.getInt(_getKey('high_score')) ?? 0;
  }

  Future<void> saveCoins(int coins) async {
    _updateUserId();
    await _prefs?.setInt(_getKey('total_coins'), coins);
  }

  Future<void> saveHighScore(int score) async {
    _updateUserId();
    await _prefs?.setInt(_getKey('high_score'), score);
  }

  Future<void> clearUserData() async {
    _updateUserId();
    await _prefs?.remove(_getKey('total_coins'));
    await _prefs?.remove(_getKey('high_score'));
  }
}
