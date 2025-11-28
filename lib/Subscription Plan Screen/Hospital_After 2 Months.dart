import 'package:doc/Subscription Plan Screen/subscription_active.dart';
import 'package:flutter/material.dart';

import 'Subscription _activatedPopup.dart';

class HospitalFreeTrialEndedPopup extends StatelessWidget {
  final String planTitle;
  final String planPrice;

  const HospitalFreeTrialEndedPopup({
    super.key,
    required this.planTitle,
    required this.planPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Dimmed background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.25),
          ),

          /// Curved popup at bottom
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
                  /// Sad icon
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE6F0FF),
                    ),
                    child: const Icon(
                      Icons.sentiment_dissatisfied_rounded,
                      size: 45,
                      color: Color(0xFF005BCF),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Title
                  const Text(
                    "Your free trial has ended!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF005BD4),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  /// Subtitle
                  const Text(
                    "Subscribe to continue posting jobs and accessing surgeons.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  /// You have chosen
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "You have chosen,",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Selected Plan Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0072FF), Color(0xFF0053CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Title
                        const Text(
                          "Medium Hospital (50–100 beds)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 6),

                        /// Price
                        const Text(
                          "₹Y,000 for 6 months",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// Bullet items
                        Text(
                          "•  Auto-renews every 6 months\n•  Cancel anytime",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 18),

                        /// Subscribe Button
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const HospitalSubscriptionActivatedPopup(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "Subscribe Now",
                              style: TextStyle(
                                color: Color(0xFF0052CC),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Change plan
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Change",
                      style: TextStyle(
                        color: Color(0xFF005BD4),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// Footer note
                  const Text(
                    "Your subscription will be activated only after verification is completed.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
