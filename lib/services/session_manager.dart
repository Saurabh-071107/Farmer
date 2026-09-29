import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SessionManager extends ChangeNotifier {
  static const String _keyToken = 'pashu_farmer_token';
  static const String _keyUser = 'pashu_farmer_user';
  static const String _keyLanguage = 'pashu_farmer_lang';
  static const String _keyIsLoggedIn = 'pashu_farmer_is_logged_in';

  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  String? _token;
  FarmerUser? _currentUser;
  String _language = 'en';
  bool _isInitialized = false;

  String? get token => _token;
  FarmerUser? get currentUser => _currentUser;
  String get language => _language;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty && _currentUser != null;
  bool get isInitialized => _isInitialized;

  Future<void>? _initFuture;

  /// Loads stored credentials and language preference from SharedPreferences on app launch
  Future<void> init() {
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_keyToken);
      _language = prefs.getString(_keyLanguage) ?? 'en';
      final userJson = prefs.getString(_keyUser);
      final hasLoginFlag = prefs.getBool(_keyIsLoggedIn) ?? false;

      if (userJson != null && userJson.isNotEmpty) {
        _currentUser = FarmerUser.fromJson(jsonDecode(userJson));
        debugPrint('[SessionManager] Restored active session for user: ${_currentUser?.name} (${_currentUser?.phone})');
      } else if (hasLoginFlag && _token != null && _token!.isNotEmpty) {
        // Fallback default user structure if JSON was not stored but token exists
        _currentUser = FarmerUser.fromJson({
          'id': 'usr-farmer-restored',
          'name': 'Farmer',
          'phone': '9876543210',
          'role': 'farmer',
        });
      }
    } catch (e) {
      debugPrint('Error initializing SessionManager: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Sets and persists app language, notifying listeners to rebuild app
  Future<void> setLanguage(String lang) async {
    _language = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, lang);
    } catch (_) {}
    notifyListeners();
  }

  /// Persists session upon successful login or registration
  Future<void> saveSession(String token, FarmerUser user) async {
    _token = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    notifyListeners();
  }

  /// Clears session on logout
  Future<void> clearSession() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    notifyListeners();
  }
}
