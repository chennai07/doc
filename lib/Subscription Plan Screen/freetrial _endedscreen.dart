import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/session_manager.dart';
import 'Subscription _activatedPopup.dart';

class FreeTrialEndedScreen extends StatefulWidget {
  const FreeTrialEndedScreen({super.key});

  @override
  State<FreeTrialEndedScreen> createState() => _FreeTrialEndedScreenState();
}

class _FreeTrialEndedScreenState extends State<FreeTrialEndedScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('✅ Payment Success!');
    print('Payment ID: ${response.paymentId}');
    print('Order ID: ${response.orderId}');
    print('Signature: ${response.signature}');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Payment Successful! Your subscription is now active.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    // Navigate to subscription activated screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const SubscriptionActivatedScreen(),
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Payment Error!');
    print('Code: ${response.code}');
    print('Message: ${response.message}');

    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Payment Failed: ${response.message ?? "Unknown error"}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('🔄 External Wallet: ${response.walletName}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet: ${response.walletName}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _initiatePayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Get user/profile ID from session
      final profileId = await SessionManager.getProfileId() ?? 
                       await SessionManager.getUserId() ?? '';

      if (profileId.isEmpty) {
        throw Exception('User ID not found. Please log in again.');
      }

      print('💳 Creating order for profile: $profileId');

      // Create order on backend
      final orderResponse = await _createOrder(profileId);

      if (orderResponse == null) {
        throw Exception('Failed to create order');
      }

      print('💳 Order created successfully');
      print('Order ID: ${orderResponse['orderId']}');

      // Open Razorpay checkout
      _openRazorpayCheckout(orderResponse);

    } catch (e) {
      print('❌ Error initiating payment: $e');
      
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _createOrder(String profileId) async {
    try {
      final url = Uri.parse('http://13.203.67.154:3000/api/payment/surgeonorder');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'success': true,
          'profileId': profileId,
          'amount': 600, // ₹600 for surgeon subscription
        }),
      );

      print('📋 Order API Response Status: ${response.statusCode}');
      print('📋 Order API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Extract order details from response
        // Adjust these based on your actual API response structure
        return {
          'orderId': data['orderId'] ?? data['id'] ?? data['order_id'],
          'amount': data['amount'] ?? 60000, // Amount in paise (600 * 100)
          'currency': data['currency'] ?? 'INR',
        };
      } else {
        print('❌ Order creation failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception creating order: $e');
      return null;
    }
  }

  void _openRazorpayCheckout(Map<String, dynamic> orderData) {
    var options = {
      'key': 'rzp_test_YOUR_KEY_HERE', // TODO: Replace with your Razorpay API key
      'amount': orderData['amount'], // Amount in paise
      'currency': orderData['currency'] ?? 'INR',
      'name': 'Surgeon Search',
      'description': 'Surgeon Plan - ₹600 for 6 months',
      'order_id': orderData['orderId'],
      'prefill': {
        'contact': '',
        'email': ''
      },
      'theme': {
        'color': '#0072FF'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('❌ Error opening Razorpay: $e');
      setState(() => _isProcessing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Dimmed Background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.withOpacity(0.4),
          ),

          // Bottom curved container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(120),
                  topRight: Radius.circular(120),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEFF6FF),
                    ),
                    child: const Icon(
                      Icons.sentiment_dissatisfied_rounded,
                      color: Color(0xFF2D7DEB),
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Title
                  const Text(
                    "Your free trial has ended!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF005BD4),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Message
                  const Text(
                    "To continue searching and applying for jobs,\nplease subscribe.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Plan box
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
                          "Surgeon Plan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 6),

                        /// Price
                        const Text(
                          "₹600 for 6 months",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// Features
                        _planFeature("Unlimited job search"),
                        _planFeature("Unlimited job applications"),
                        _planFeature("Direct contact with hospitals"),
                        _planFeature("Secure and private data handling"),

                        const SizedBox(height: 8),

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
                          onTap: _isProcessing ? null : _initiatePayment,
                          child: Container(
                            width: double.infinity,
                            height: 45,
                            decoration: BoxDecoration(
                              color: _isProcessing 
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0052CC),
                                      ),
                                    ),
                                  )
                                : const Text(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
