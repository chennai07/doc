import 'dart:convert'; // ✅ For JSON encoding/decoding
import 'package:doc/profileprofile/professional_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // ✅ API CALL FUNCTION
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse('https://surgeon-search.onrender.com/api/signin');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Login Response: $data');

        // ✅ Extract token and profile/user id
        final token = data['token'];
        final userData = data['user'] ?? data['profile'] ?? data;
        final profileId = userData['_id'] ?? userData['profile_id'];

        if (profileId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_id', profileId.toString());
          print('✅ Saved profile_id: $profileId');
        } else {
          print('⚠️ No profile_id found in response.');
        }

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token.toString());
          print('🔑 Token saved: $token');
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Login Successful!')));

        // ✅ Navigate to ProfessionalProfilePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfessionalProfileFormPage(),
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${error['message'] ?? 'Invalid credentials'}'),
          ),
        );
        print('❌ Login failed: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print('⚠️ Exception during login: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text.rich(
                TextSpan(
                  text: "Let’s ",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
                  children: [
                    TextSpan(
                      text: "Sign In",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // ✅ Logo
              Center(child: Image.asset('assets/logo2.png', height: 150)),
              const SizedBox(height: 60),

              // ✅ Email Field
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

              // ✅ Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Iconsax.lock, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Iconsax.eye_slash : Iconsax.eye),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
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
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
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
              const SizedBox(height: 15),

              // ✅ Forgot password & Sign up
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        "Don’t have an account?",
                        style: TextStyle(color: Colors.black87, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to Sign Up Page
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF003366),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
