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
  static const _keyHealthcareId = 'healthcare_id';
  static const _keyHealthProfileFlag = 'health_profile_flag';
  static const _keyFreeTrialFlag = 'free_trial_flag';

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

  static Future<void> saveHealthcareId(String healthcareId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHealthcareId, healthcareId);
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

  static Future<String?> getHealthcareId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHealthcareId);
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
    await prefs.remove(_keyHealthProfileFlag);
  }

  static Future<void> saveHealthProfileFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHealthProfileFlag, value);
  }

  static Future<bool?> getHealthProfileFlag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHealthProfileFlag);
  }

  static Future<void> saveFreeTrialFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFreeTrialFlag, value);
  }

  static Future<bool?> getFreeTrialFlag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFreeTrialFlag);
  }

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  /// ✅ Save profile ID for a specific user (by email)
  /// This maps user email -> their profile's actual _id
  static Future<void> saveUserProfileMapping(String email, String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_map_$email', profileId);
  }

  /// ✅ Get stored profile ID for a specific user (by email)
  static Future<String?> getUserProfileMapping(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_map_$email');
  }

  /// ✅ Save current user's email
  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  /// ✅ Get current user's email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }
}
