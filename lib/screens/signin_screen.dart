import 'dart:convert';
import 'package:doc/profileprofile/professional_profile_page.dart';
import 'package:doc/screens/signup_screen.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  String? _extractProfileId(dynamic source) {
    if (source == null) return null;

    String? normalize(dynamic value) {
      if (value == null) return null;
      if (value is Map && value.containsKey(r'$oid')) {
        final oidValue = value[r'$oid'];
        final oidString = oidValue?.toString().trim();
        if (oidString != null && oidString.isNotEmpty) return oidString;
      }
      final stringValue = value.toString().trim();
      return stringValue.isEmpty ? null : stringValue;
    }

    final keysToCheck = const {
      'profile_id',
      'profileId',
      'profileID',
      '_id',
      'id',
      'user_id',
      'userId',
      'doctor_id',
      'doctorId',
    };

    if (source is Map) {
      for (final entry in source.entries) {
        if (keysToCheck.contains(entry.key)) {
          final normalized = normalize(entry.value);
          if (normalized != null) return normalized;
        }

        if (entry.value is Map || entry.value is Iterable) {
          final nested = _extractProfileId(entry.value);
          if (nested != null) return nested;
        } else {
          final normalized = normalize(entry.value);
          if (normalized != null && keysToCheck.any(entry.key.toLowerCase().contains)) {
            return normalized;
          }
        }
      }
    } else if (source is Iterable) {
      for (final item in source) {
        final nested = _extractProfileId(item);
        if (nested != null) return nested;
      }
    } else {
      final normalized = normalize(source);
      if (normalized != null) return normalized;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _prewarmServer();
  }

  /// 🌐 Prewarm the backend server to avoid first-time delay
  Future<void> _prewarmServer() async {
    try {
      final stopwatch = Stopwatch()..start();
      await http
          .get(Uri.parse('https://surgeon-search.onrender.com/api/ping'))
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();
      print('🌐 Server awake in ${stopwatch.elapsedMilliseconds} ms');
    } catch (e) {
      print('⚠️ Prewarm failed: $e');
    }
  }

  /// ✅ LOGIN FUNCTION (with unique local ID + token storage)
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    final url = Uri.parse('https://surgeon-search.onrender.com/api/signin');
    final prefs = await SharedPreferences.getInstance();
    final uuid = Uuid();

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () =>
                throw Exception('Server timeout. Please try again.'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Login successful. Response: $data');

        final token = data['token'];
        final userData = data['user'] ?? data['profile'] ?? data;
        final profileId = _extractProfileId(userData) ??
            _extractProfileId(data['profile']) ??
            _extractProfileId(data);

        // Generate unique local login ID (not sent to API)
        final newLoginId = uuid.v4();
        await prefs.setString('login_id', newLoginId);
        print('🆕 Generated local login ID: $newLoginId');

        // Save user info (shared helper)
        await saveLoginInfo(profileId, token?.toString() ?? '');

        // Also save profileId specifically for use in profile forms
        if (profileId != null) {
          await prefs.setString('profile_id', profileId);
          print('💾 Profile ID saved for profile forms: $profileId');
        } else {
          print('⚠️ No profile ID present in login response.');
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Login Successful!')));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfessionalProfileFormPage(),
            ),
          );
        }
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${error['message'] ?? 'Invalid credentials'}'),
          ),
        );
      }
    } catch (e) {
      print('⚠️ Exception during login: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🚪 LOGOUT FUNCTION — Deletes local login ID and stored user data
  Future<void> _logoutUser() async {
    await logout();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🚪 Logged out successfully.')),
    );

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  /// 🧠 CHECK LOGIN STATUS — used in splash or auto-login scenarios
  Future<void> _checkLoginStatus() async {
    final loginInfo = await getLoginInfo();
    if (loginInfo['userId'] != null && loginInfo['token'] != null) {
      print('✅ Already logged in. UserID: ${loginInfo['userId']}');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfessionalProfileFormPage(),
          ),
        );
      }
    } else {
      print('⚠️ No active session found. Redirecting to login.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text.rich(
                    TextSpan(
                      text: "Let’s ",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: "Sign In",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  Center(child: Image.asset('assets/logo2.png', height: 150)),
                  const SizedBox(height: 60),

                  // ✅ Email Input
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Iconsax.sms, size: 20),
                      hintText: 'Your email',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Password Input
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Iconsax.lock, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Iconsax.eye_slash : Iconsax.eye,
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                      ),
                      hintText: 'Your password',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ✅ Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB3E5FC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _signIn,
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Sign Up Navigation
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don’t have an account?",
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF003366),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🌀 Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}