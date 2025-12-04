import 'dart:async';
import 'package:flutter/material.dart';
import 'package:doc/profileprofile/surgeon_profile.dart';
import 'package:doc/utils/session_manager.dart';

class SubscriptionActivatedScreen extends StatefulWidget {
  const SubscriptionActivatedScreen({super.key});

  @override
  State<SubscriptionActivatedScreen> createState() => _SubscriptionActivatedScreenState();
}

class _SubscriptionActivatedScreenState extends State<SubscriptionActivatedScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    print("👨‍⚕️ SubscriptionActivatedScreen INIT");
    _startAutoRedirect();
  }

  void _startAutoRedirect() {
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateToDashboard();
      }
    });
  }

  Future<void> _navigateToDashboard() async {
    final profileId = await SessionManager.getProfileId();
    if (mounted && profileId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfessionalProfileViewPage(profileId: profileId),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          /// Dimmed background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
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
                  topLeft: Radius.circular(50),
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
                      Icons.check_rounded,
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
