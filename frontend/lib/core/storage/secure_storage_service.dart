import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _guestKey = 'is_guest_mode';

  // [PERF] In-memory Cache tránh đọc I/O đĩa và Platform Channel liên tục trên từng Request
  static String? _cachedToken;
  static String? _cachedUserData;
  static String? _cachedMssv;
  static bool? _cachedGuestMode;
  static String? _cachedServerUrl;

  static void _extractAndCacheMssv(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      _cachedMssv = null;
      return;
    }
    try {
      final match = RegExp(r'"(?:student_id|mssv)"\s*:\s*"?([^",\s}]+)"?').firstMatch(jsonString);
      _cachedMssv = match?.group(1);
    } catch (_) {
      _cachedMssv = null;
    }
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _secureStorage.read(key: _tokenKey);
    return _cachedToken;
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<void> saveUserData(String jsonString) async {
    _cachedUserData = jsonString;
    _extractAndCacheMssv(jsonString);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonString);
  }

  Future<String?> getUserData() async {
    if (_cachedUserData != null) return _cachedUserData;
    final prefs = await SharedPreferences.getInstance();
    _cachedUserData = prefs.getString(_userKey);
    _extractAndCacheMssv(_cachedUserData);
    return _cachedUserData;
  }

  Future<String?> getMssv() async {
    if (_cachedMssv != null) return _cachedMssv;
    await getUserData();
    return _cachedMssv;
  }

  Future<void> setGuestMode(bool isGuest) async {
    _cachedGuestMode = isGuest;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, isGuest);
  }

  Future<bool> isGuestMode() async {
    if (_cachedGuestMode != null) return _cachedGuestMode!;
    final prefs = await SharedPreferences.getInstance();
    _cachedGuestMode = prefs.getBool(_guestKey) ?? false;
    return _cachedGuestMode!;
  }

  static const String _serverUrlKey = 'custom_server_url';

  Future<void> saveServerUrl(String url) async {
    _cachedServerUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url);
  }

  Future<String?> getServerUrl() async {
    if (_cachedServerUrl != null) return _cachedServerUrl;
    final prefs = await SharedPreferences.getInstance();
    _cachedServerUrl = prefs.getString(_serverUrlKey);
    return _cachedServerUrl;
  }

  // ─── OFFLINE DATA CACHING (Tin tức, Thời khóa biểu, Bảng điểm) ───
  Future<void> saveCache(String key, String jsonString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_$key', jsonString);
    } catch (_) {}
  }

  Future<String?> getCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('cache_$key');
    } catch (_) {
      return null;
    }
  }

  Future<void> removeCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_$key');
    } catch (_) {}
  }

  Future<void> clearAll() async {
    _cachedToken = null;
    _cachedUserData = null;
    _cachedMssv = null;
    _cachedGuestMode = null;
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_guestKey);
  }
}

