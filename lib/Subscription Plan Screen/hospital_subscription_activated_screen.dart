import 'dart:async';
import 'package:flutter/material.dart';
import 'package:doc/Navbar.dart';
import 'package:doc/utils/session_manager.dart';

class HospitalSubscriptionActivatedPopup extends StatefulWidget {
  final Map<String, dynamic> hospitalData;

  const HospitalSubscriptionActivatedPopup({
    super.key,
    required this.hospitalData,
  });

  @override
  State<HospitalSubscriptionActivatedPopup> createState() => _HospitalSubscriptionActivatedPopupState();
}

class _HospitalSubscriptionActivatedPopupState extends State<HospitalSubscriptionActivatedPopup> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    print("🏥 HospitalSubscriptionActivatedPopup INIT");
    _startAutoRedirect();
  }

  void _startAutoRedirect() {
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Navbar(hospitalData: widget.hospitalData),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Make scaffold transparent
      body: Stack(
        children: [
          /// Dimmed background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.35),
          ),

          /// Bottom curved popup
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50), // Adjusted to match design
                  topRight: Radius.circular(50),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEFF6FF),
                    ),
                    child: const Icon(
                      Icons.check_rounded, // Changed to simple check as per design
                      size: 40,
                      color: Color(0xFF0062FF),
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// Header text
                  const Text(
                    "Subscription Activated!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0062FF),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// Description
                  const Text(
                    "You now have full access to job listings and applications.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 25),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
