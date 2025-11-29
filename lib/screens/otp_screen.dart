import 'dart:async';
import 'dart:convert';
import 'package:doc/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  List<TextEditingController> controllers =
      List.generate(4, (_) => TextEditingController());

  int counter = 30;
  bool canResend = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    counter = 30;
    canResend = false;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (counter == 0) {
        setState(() => canResend = true);
        timer.cancel();
      } else {
        setState(() => counter--);
      }
    });
  }

  Future<void> _verifyOtp() async {
    String otp = controllers.map((c) => c.text).join();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 4-digit OTP")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://13.203.67.154:3000/api/otp/verify');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": widget.email,
          "otp": otp,
        }),
      );

      if (response.statusCode == 200) {
        // Success
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP Verified Successfully!")),
        );
        
        // Navigate to Login Screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        // Failure
        if (!mounted) return;
        String message = "Verification failed";
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['message'] != null) {
            message = body['message'];
          }
        } catch (_) {}
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, size: 28),
              ),

              const SizedBox(height: 15),

              // Title
              RichText(
                text: const TextSpan(
                  text: "Let’s ",
                  style: TextStyle(fontSize: 28, color: Colors.black),
                  children: [
                    TextSpan(
                      text: "Sign up",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Text(
                "We send an OTP code to your email,",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 5),

              Text(
                widget.email,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 40),

              // OTP Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return SizedBox(
                    height: 65,
                    width: 65,
                    child: TextField(
                      controller: controllers[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.lightBlueAccent),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          FocusScope.of(context).nextFocus();
                        } else if (value.isEmpty && index > 0) {
                          FocusScope.of(context).previousFocus();
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Resend Timer
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Not receiving OTP code? Send it back in ",
                    style: TextStyle(color: Colors.grey.shade600),
                    children: [
                      TextSpan(
                        text: canResend ? "Resend" : "00:${counter.toString().padLeft(2, '0')}",
                        style: TextStyle(
                            color: canResend ? Colors.blue : Colors.grey.shade600,
                            fontWeight: FontWeight.bold),
                        // Add tap handler for resend if needed
                        // recognizer: TapGestureRecognizer()..onTap = () { ... }
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text(
                    "Sign up",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Terms and Conditions
              const Center(
                child: Column(
                  children: [
                    Text("By Signin up, you agree to our",
                        style: TextStyle(color: Colors.black87)),
                    SizedBox(height: 4),
                    Text(
                      "Term and Conditions",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
