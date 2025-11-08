import 'package:flutter/material.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/screens/signin_screen.dart';

class ProfessionalProfileViewPage extends StatefulWidget {
  final String profileId;
  const ProfessionalProfileViewPage({super.key, required this.profileId});

  @override
  State<ProfessionalProfileViewPage> createState() =>
      _ProfessionalProfileViewPageState();
}

class _ProfessionalProfileViewPageState
    extends State<ProfessionalProfileViewPage> {
  bool _isLoggingOut = false;

  /// 🚪 Logout function
  Future<void> _logoutUser() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      await SessionManager.clearAll();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚪 Logged out successfully.')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Error logging out: $e')));
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileId = widget.profileId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Professional Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoggingOut ? null : _logoutUser,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.person, size: 60, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Profile ID: $profileId",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(thickness: 1),

            // 👇 Add more profile fields here (name, email, specialty, etc.)
            const SizedBox(height: 20),
            const Text(
              "  Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              "This is where you can display details fetched from the API — "
              "such as name, specialization, email, and other data tied to your profile ID.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),

            const Spacer(),

            // 🔘 Logout Button (Bottom)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: _isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                onPressed: _isLoggingOut ? null : _logoutUser,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
