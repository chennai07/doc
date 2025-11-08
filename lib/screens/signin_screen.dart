import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:doc/healthcare/hospial_form.dart';
import 'package:doc/healthcare/hospital_profile.dart';
import 'package:doc/profileprofile/surgeon_form.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/screens/signup_screen.dart';

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

  /// Wake up backend (Render) to prevent cold start delay
  Future<void> _prewarmServer() async {
    try {
      // Use root path which always exists and still wakes the instance
      await http
          .get(Uri.parse('https://surgeon-search.onrender.com/'))
          .timeout(const Duration(seconds: 8));
      debugPrint(' Server is awake');
    } catch (_) {
      debugPrint(' Could not prewarm server.');
    }
  }

  /// Helper: POST with retries/backoff to tolerate cold starts or transient TLS drops
  Future<http.Response> _postWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int attempts = 3,
  }) async {
    final delays = <Duration>[
      Duration.zero,
      const Duration(seconds: 2),
      const Duration(seconds: 5),
    ];

    for (var i = 0; i < attempts; i++) {
      try {
        return await http
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 30));
      } on TimeoutException catch (_) {
        if (i == attempts - 1) rethrow;
      } on SocketException catch (_) {
        if (i == attempts - 1) rethrow;
      } on HandshakeException catch (_) {
        if (i == attempts - 1) rethrow;
      }
      // Backoff before next try
      await Future.delayed(delays[i]);
    }
    // Should never reach here
    throw Exception('Request failed after retries');
  }

  /// LOGIN FUNCTION
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
    const uuid = Uuid();

    try {
      final response = await _postWithRetry(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final root = jsonDecode(response.body);
        final data = root is Map && root['data'] != null ? root['data'] : root;
        debugPrint(' Login successful: $data');

        final token = (data is Map) ? data['token'] : null;
        final userData = (data is Map)
            ? (data['user'] ?? data['profile'] ?? data)
            : data;

        String? role = (userData is Map)
            ? (userData['type'] ?? userData['role'] ?? (data is Map ? (data['type'] ?? data['role']) : null))?.toString()
            : null;

        // Extract or create profile ID (prefer deep extraction, fallback to fields/uuid)
        final extractedProfileId = _extractProfileId(userData) ??
            (data is Map ? _extractProfileId(data['profile']) : null) ??
            _extractProfileId(data);
        String profileId =
            ((extractedProfileId ??
                        (userData is Map ? userData['_id']?.toString() : null) ??
                        (userData is Map ? userData['profile_id']?.toString() : null) ??
                        (userData is Map ? userData['id']?.toString() : null) ??
                        '') as String)
                    .trim();
        if (profileId.isEmpty) profileId = uuid.v4();

        // Save session
        await SessionManager.saveUserId(profileId);
        await SessionManager.saveProfileId(profileId);
        await SessionManager.saveToken(token ?? '');
        if (role != null && role.isNotEmpty) {
          await SessionManager.saveRole(role);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(' Login Successful!')));

        final rl = (role ?? '').toLowerCase().trim();
        if (rl.contains('hospital') || rl.contains('health') || rl.contains('org')) {
          // Prefer previously saved healthcare_id; fallback to profileId for fetch only
          final existingHid = await SessionManager.getHealthcareId();
          final hid = (existingHid == null || existingHid.isEmpty) ? profileId : existingHid;
          try {
            final url = Uri.parse('https://surgeon-search.onrender.com/api/healthcare/healthcare-profile/$hid');
            final resp = await http.get(url).timeout(const Duration(seconds: 15));
            if (resp.statusCode == 200) {
              final body = resp.body.trimLeft();
              dynamic parsed;
              try { parsed = jsonDecode(body); } catch (_) { parsed = {}; }
              final payload = (parsed is Map && parsed['data'] != null) ? parsed['data'] : parsed;
              final mapPayload = (payload is Map<String, dynamic>) ? payload : <String, dynamic>{};
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HospitalProfile(data: mapPayload)),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HospitalForm(healthcareId: profileId)),
              );
            }
          } catch (_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HospitalForm(healthcareId: profileId)),
            );
          }
        } else if (rl.contains('surgeon') || rl.contains('doctor')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SurgeonForm(
                profileId: profileId,
                existingData: const {},
              ),
            ),
          );
        } else {
          // Default to Surgeon profile flow if role is unknown
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SurgeonForm(
                profileId: profileId,
                existingData: const {},
              ),
            ),
          );
        }
      } else {
        String message = 'Invalid credentials';
        try {
          final error = jsonDecode(response.body);
          if (error is Map && error['message'] != null) {
            message = error['message'];
          }
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ $message')));
      }
    } on TimeoutException catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⏳ Server is taking too long to respond. Please try again.')));
    } on HandshakeException catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('🔒 Secure connection failed. Check date/time, VPN/proxy, or try a different network.')));
    } on SocketException catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('📡 Network error. Check your internet connection and try again.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Unexpected error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

                  // 📨 Email Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
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

                  // 🔒 Password Field
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

                  // 🔘 Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
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

                  // 🔗 Sign Up Link
                  Row(
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
                ],
              ),
            ),

            // ⏳ Loading Overlay
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