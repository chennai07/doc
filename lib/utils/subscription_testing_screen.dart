import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/Subscription Plan Screen/subscription_planScreen.dart';
import 'package:doc/Subscription Plan Screen/freetrial _endedscreen.dart';

/// 🧪 TESTING UTILITY FOR SUBSCRIPTION FLOW
/// This screen allows you to test the payment flow without waiting 2 months
class SubscriptionTestingScreen extends StatefulWidget {
  const SubscriptionTestingScreen({super.key});

  @override
  State<SubscriptionTestingScreen> createState() =>
      _SubscriptionTestingScreenState();
}

class _SubscriptionTestingScreenState extends State<SubscriptionTestingScreen> {
  bool? currentFreeTrialStatus;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    final status = await SessionManager.getFreeTrialFlag();
    if (mounted) {
      setState(() {
        currentFreeTrialStatus = status;
        isLoading = false;
      });
    }
  }

  Future<void> _setFreeTrialActive() async {
    await SessionManager.saveFreeTrialFlag(true);
    await _loadCurrentStatus();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Free Trial Set to ACTIVE (true)'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _setFreeTrialExpired() async {
    await SessionManager.saveFreeTrialFlag(false);
    await _loadCurrentStatus();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Free Trial Set to EXPIRED (false)'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearFreeTrialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('free_trial_flag');
    await _loadCurrentStatus();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Free Trial Status Cleared (null)'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _testSubscriptionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionPlanScreen(),
      ),
    );
  }

  void _testPaymentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FreeTrialEndedScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          '🧪 Subscription Testing',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Status Card
                  _statusCard(),

                  const SizedBox(height: 30),

                  // Instructions
                  _instructionsCard(),

                  const SizedBox(height: 30),

                  // Control Buttons
                  const Text(
                    'Set Free Trial Status:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Set Active Button
                  _actionButton(
                    icon: Icons.check_circle,
                    label: 'Set Free Trial ACTIVE (true)',
                    subtitle: 'User is in 2-month trial period',
                    color: Colors.green,
                    onTap: _setFreeTrialActive,
                  ),

                  const SizedBox(height: 12),

                  // Set Expired Button
                  _actionButton(
                    icon: Icons.cancel,
                    label: 'Set Free Trial EXPIRED (false)',
                    subtitle: 'User needs to pay ₹600 to continue',
                    color: Colors.red,
                    onTap: _setFreeTrialExpired,
                  ),

                  const SizedBox(height: 12),

                  // Clear Status Button
                  _actionButton(
                    icon: Icons.delete_outline,
                    label: 'Clear Status (null)',
                    subtitle: 'Reset to default state',
                    color: Colors.orange,
                    onTap: _clearFreeTrialStatus,
                  ),

                  const SizedBox(height: 30),

                  // Test Screens
                  const Text(
                    'Test Screens:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  _testButton(
                    icon: Icons.visibility,
                    label: 'View Subscription Plan Screen',
                    subtitle: 'Shows based on current status',
                    onTap: _testSubscriptionScreen,
                  ),

                  const SizedBox(height: 12),

                  _testButton(
                    icon: Icons.payment,
                    label: 'View Payment Screen Directly',
                    subtitle: 'Test Razorpay integration',
                    onTap: _testPaymentScreen,
                  ),

                  const SizedBox(height: 30),

                  // Tips Card
                  _tipsCard(),
                ],
              ),
            ),
    );
  }

  Widget _statusCard() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (currentFreeTrialStatus == true) {
      statusText = 'FREE TRIAL ACTIVE';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (currentFreeTrialStatus == false) {
      statusText = 'FREE TRIAL EXPIRED';
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else {
      statusText = 'NOT SET (null)';
      statusColor = Colors.orange;
      statusIcon = Icons.help_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 50, color: statusColor),
          const SizedBox(height: 12),
          const Text(
            'Current Status:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Value: ${currentFreeTrialStatus?.toString() ?? "null"}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black45,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'How to Test:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _instructionBullet('Set trial to EXPIRED (false) to test payment'),
          _instructionBullet('Set trial to ACTIVE (true) to test free access'),
          _instructionBullet('View screens to see different states'),
          _instructionBullet('Test Razorpay payment when trial is expired'),
        ],
      ),
    );
  }

  Widget _instructionBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _testButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0072FF), Color(0xFF0053CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _tipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Text(
                'Testing Tips:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _tipBullet('New users get freetrail2month: true by default'),
          _tipBullet('After 2 months, backend sets it to false'),
          _tipBullet('Use this screen to simulate the 2-month expiry'),
          _tipBullet('Update Razorpay key before testing payment'),
          _tipBullet('Use test cards for payment testing'),
        ],
      ),
    );
  }

  Widget _tipBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline,
              size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
