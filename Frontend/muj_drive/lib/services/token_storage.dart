import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _key = 'jwt';

  /// Persist the JWT in SharedPreferences
  static Future<void> writeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
    print('🔐 TokenStorage: wrote token=$token');
  }

  /// Read the JWT from SharedPreferences (or null if not set)
  static Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_key);
    print('🔍 TokenStorage: read token=$token');
    return token;
  }

  /// Remove the JWT
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    print('🗑️ TokenStorage: cleared token');
  }
}
