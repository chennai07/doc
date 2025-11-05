// lib/utils/session_manager.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:doc/profileprofile/professional_profile_page.dart';
import 'package:doc/screens/signin_screen.dart';

/// -----------------------------
/// 🔐 Session Management Helpers
/// -----------------------------

/// ✅ Save user info (generate new user ID if not exists)
Future<void> saveLoginInfo(String? userId, String token) async {
  final prefs = await SharedPreferences.getInstance();
  final uuid = const Uuid();

  // Generate new userId if null or empty
  final newUserId = (userId == null || userId.isEmpty) ? uuid.v4() : userId;

  await prefs.setString('userId', newUserId);
  await prefs.setString('token', token);

  print('💾 Saved userId=$newUserId, token=$token');
}

/// ✅ Retrieve userId and token
Future<Map<String, String?>> getLoginInfo() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'userId': prefs.getString('userId'),
    'token': prefs.getString('token'),
  };
}

/// 🚪 Logout — clears all stored login data
Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('userId');
  await prefs.remove('token');
  await prefs.remove('login_id');
  print('🗑️ All login data cleared.');
}

/// 🧭 Check login status — navigate automatically
Future<void> checkLoginStatus(BuildContext context) async {
  final loginInfo = await getLoginInfo();

  if (loginInfo['userId'] != null && loginInfo['token'] != null) {
    print('✅ User already logged in: ${loginInfo['userId']}');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProfessionalProfileFormPage()),
    );
  } else {
    print('⚠️ No user session found. Redirecting to login.');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}
