import 'package:doc/profileprofile/professional_profile_page.dart';
import 'package:doc/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2)); // small logo delay

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final expiry = prefs.getInt('token_expiry');

    if (token != null &&
        expiry != null &&
        DateTime.now().millisecondsSinceEpoch < expiry) {
      // ✅ Token valid
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfessionalProfileFormPage()),
      );
    } else {
      // ❌ No token or expired
      await prefs.clear(); // clean old data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 80),
            SizedBox(height: 20),
            Text(
              "Surgeon Search",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
