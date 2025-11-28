import 'package:flutter/material.dart';

class HospitalSubscriptionActivatedPopup extends StatelessWidget {
  const HospitalSubscriptionActivatedPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [
          /// Dimmed Background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.30),
          ),

          /// Curved Bottom Popup
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(110),
                  topRight: Radius.circular(110),
                ),
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Icon
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE6F0FF),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 55,
                      color: Color(0xFF2D7DEB),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Title
                  const Text(
                    "Subscription Activated!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF005BD4),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Description
                  const Text(
                    "You now have full access to surgeon search,\n"
                    "job posting, and applicant management.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// Continue Button
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0072FF), Color(0xFF0053CC)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
