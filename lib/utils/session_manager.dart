// lib/utils/session_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------
/// 🧠 Session Manager
/// ---------------------------------------------------------
/// Handles user session data such as userId, profileId, token, etc.
/// Works safely with null-safety and async calls.
/// ---------------------------------------------------------
class SessionManager {
  static const _keyUserId = 'user_id';
  static const _keyProfileId = 'profile_id';
  static const _keyToken = 'auth_token';
  static const _keyLoginId = 'login_id';
  static const _keyRole = 'user_role';

  /// ✅ Save the logged-in user's ID
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  /// ✅ Save the profile ID (if your app differentiates it)
  static Future<void> saveProfileId(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileId, profileId);
  }

  /// ✅ Save auth token (for API authorization)
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  /// ✅ Save unique login session ID
  static Future<void> saveLoginId(String loginId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLoginId, loginId);
  }

  /// ✅ Retrieve the stored userId
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// ✅ Retrieve stored profileId
  static Future<String?> getProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProfileId);
  }

  /// ✅ Retrieve stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// ✅ Retrieve login ID
  static Future<String?> getLoginId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLoginId);
  }

  /// ✅ Check if a user is logged in (returns true/false)
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    final token = prefs.getString(_keyToken);
    return userId != null &&
        userId.isNotEmpty &&
        token != null &&
        token.isNotEmpty;
  }

  /// 🚪 Log out and clear all stored data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyProfileId);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyLoginId);
    await prefs.remove(_keyRole);
  }

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }
}
