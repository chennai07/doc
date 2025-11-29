import 'package:flutter/material.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/Subscription Plan Screen/freetrial _endedscreen.dart';

/// 🛡️ Subscription Guard
/// Controls access to premium features based on subscription status
class SubscriptionGuard {
  /// Check if user can access premium features
  /// Returns true if allowed, false if blocked
  /// Automatically shows payment screen if blocked
  static Future<bool> checkPremiumAccess(BuildContext context) async {
    final isTrialActive = await SessionManager.getFreeTrialFlag();
    
    // Trial is active or not set (new user) - allow access
    if (isTrialActive == true || isTrialActive == null) {
      return true;
    }
    
    // Trial has expired - block and show payment
    if (!context.mounted) return false;
    
    // Show payment screen as fullscreen dialog
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FreeTrialEndedScreen(),
        fullscreenDialog: true, // Makes it look like a modal
      ),
    );
    
    // User came back from payment screen
    // Re-check status in case they paid
    final statusAfterPayment = await SessionManager.getFreeTrialFlag();
    return statusAfterPayment == true;
  }
  
  /// Show a banner notification about trial expiry
  /// Use this on dashboard/home screens
  static Widget buildTrialExpiredBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.orange.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your free trial has ended. Subscribe to access all features.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FreeTrialEndedScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Subscribe',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Check subscription status without showing payment screen
  /// Use this for UI decisions (show/hide features)
  static Future<bool> hasActiveSubscription() async {
    final isTrialActive = await SessionManager.getFreeTrialFlag();
    return isTrialActive == true || isTrialActive == null;
  }
  
  /// Show a simple dialog about trial expiry
  /// Alternative to full payment screen
  static Future<void> showTrialExpiredDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Text('Trial Ended'),
          ],
        ),
        content: const Text(
          'Your 2-month free trial has ended. Subscribe now to continue searching and applying for jobs.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FreeTrialEndedScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Subscribe Now'),
          ),
        ],
      ),
    );
  }
}
