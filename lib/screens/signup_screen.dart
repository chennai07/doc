// ignore_for_file: unused_import

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/screens/signin_screen.dart';
import 'package:doc/screens/otp_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedRole;
  bool _obscurePassword = true;
  bool isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ✅ Two roles only
  final List<String> roles = ["Healthcare Organizations", "Surgeon"];

  /// ✅ SIGNUP API FUNCTION
  Future<void> signUpUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a role")));
      return;
    }

    setState(() => isLoading = true);

    const String apiUrl = "http://13.203.67.154:3000/api/signup";

    // ✅ Send all key variants for compatibility
    final Map<String, dynamic> requestBody = {
      "fullname": nameController.text.trim(),
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "mobilenumber": phoneController.text.trim(),
      "mobile": phoneController.text.trim(),
      "password": passwordController.text.trim(),
      "type": selectedRole,
    };

    try {
      debugPrint("📤 Sending Signup Data: $requestBody");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      debugPrint("📥 Response: ${response.statusCode}");
      debugPrint("📄 Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Signup Successful: ${responseData['message'] ?? 'Welcome!'}",
            ),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ Navigate to OTP screen
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(email: emailController.text.trim()),
            ),
          );
        });
      } else {
        // Show specific backend error
        String errorMessage = "Signup failed";
        try {
          final error = jsonDecode(response.body);
          errorMessage =
              error['error'] ??
              error['message'] ??
              "Server Error (${response.statusCode})";
        } catch (_) {
          errorMessage = "Unexpected response (${response.statusCode})";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network Error: ${e.toString()}"),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// ✅ UI DESIGN
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "Let’s ",
                style: TextStyle(color: Colors.black, fontSize: 22),
              ),
              TextSpan(
                text: "Sign up",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Dropdown (Role Selector)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A5DB2), Color(0xFF3BA7F5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                    hint: const Text(
                      "Sign Up As",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    onChanged: (value) {
                      setState(() => selectedRole = value);
                    },
                    items: roles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Row(
                              children: [
                                Icon(
                                  role == "Healthcare Organizations"
                                      ? Icons.local_hospital
                                      : Icons.person,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  role,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // 🔹 Input Fields
              _buildField(
                label: "Full Name",
                hint: "Full name",
                controller: nameController,
                icon: Icons.person_outline,
              ),
              _buildField(
                label: "Phone number",
                hint: "Your number",
                controller: phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                isRequired: false,
              ),
              _buildField(
                label: "Email",
                hint: "Your email",
                controller: emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              // 🔹 Password Field
              const Text(
                "Password",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Your password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter password" : null,
              ),
              const SizedBox(height: 25),

              // 🔹 Signup Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : signUpUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFADE1FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Sign up",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Sign In link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Reusable Input Builder
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: isRequired
              ? (value) => value!.isEmpty ? "Please enter $label" : null
              : null,
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
