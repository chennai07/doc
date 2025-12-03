import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doc/model/doctor_profile_data.dart';
import 'package:doc/model/api_service.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/screens/signin_screen.dart';
import 'package:doc/homescreen/SearchjobScreen.dart';
import 'package:doc/homescreen/Applied_Jobs.dart';

import 'package:doc/utils/subscription_guard.dart';

class ProfessionalProfileViewPage extends StatefulWidget {
  final String profileId;
  const ProfessionalProfileViewPage({super.key, required this.profileId});

  @override
  State<ProfessionalProfileViewPage> createState() =>
      _ProfessionalProfileViewPageState();
}

class _ProfessionalProfileViewPageState
    extends State<ProfessionalProfileViewPage> {
  bool _isLoading = true;
  DoctorProfileData? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ApiService.fetchProfileInfo(widget.profileId);
      if (result['success'] == true) {
        setState(() {
          _profile = DoctorProfileData.fromMap(result['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await SessionManager.clearAll();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Doctor Profile", style: TextStyle(color: Colors.black)),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Profile not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _logout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    // Display the doctor profile directly in this widget
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Doctor Profile",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [

          IconButton(
            icon: const Icon(Iconsax.logout, color: Colors.redAccent),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Show trial expiry banner if subscription expired
          FutureBuilder<bool?>(
            future: SessionManager.getFreeTrialFlag(),
            builder: (context, snapshot) {
              if (snapshot.data == false) {
                // Trial expired - show warning banner
                return SubscriptionGuard.buildTrialExpiredBanner(context);
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Main profile content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(0.1),
                ),
                child: ClipOval(
                  child: _profile!.profilePicture.isNotEmpty
                      ? Image.network(
                          _profile!.profilePicture,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Iconsax.user,
                                size: 50, color: Colors.grey);
                          },
                        )
                      : const Icon(Iconsax.user, size: 50, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Column(
                children: [
                  Text(
                    _profile!.name.isNotEmpty
                        ? _profile!.name
                        : 'Surgeon Name',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _profile!.speciality.isNotEmpty
                        ? _profile!.speciality
                        : 'Speciality not provided',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),

            _infoHeader("Personal Information"),
            _infoTile(Iconsax.call, "Phone", _profile!.phone),
            _infoTile(Iconsax.sms, "Email", _profile!.email),
            _infoTile(Iconsax.location, "Location", _profile!.location),

            const SizedBox(height: 10),
            _infoHeader("Professional Details"),
            _infoTile(Iconsax.book, "Degree", _profile!.degree),
            _infoTile(
                Iconsax.activity, "Sub-Speciality", _profile!.subSpeciality),
            _infoTile(Iconsax.hospital, "Organization", _profile!.organization),
            _infoTile(Iconsax.briefcase, "Designation", _profile!.designation),
            _infoTile(Iconsax.location, "Work Location", _profile!.workLocation),
            _infoTile(Iconsax.calendar, "Experience", _profile!.period),
            _infoTile(Iconsax.link, "Portfolio", _profile!.portfolio),

            const SizedBox(height: 16),
            _infoHeader("Summary"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _profile!.summary.isNotEmpty
                    ? _profile!.summary
                    : "No summary provided",
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Iconsax.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
          ),
        ],
      ),

      // Bottom Navigation Bar (same style as HospitalProfile)
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomNavItem(
              Iconsax.search_normal,
              "Search",
              false,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchScreen(),
                  ),
                );
              },
            ),
            _bottomNavItem(
              Iconsax.document,
              "Applied Jobs",
              false,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AppliedJobsScreen(),
                  ),
                );
              },
            ),
            _bottomNavItem(
              Iconsax.user,
              "Profile",
              true,
              () {
                // Already on profile; no action
              },
            ),
          ],
        ),
      ),
    );
  }

  //  Section Header Widget
  Widget _infoHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  // Info Row Widget
  Widget _infoTile(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Item (same visual style, but tappable)
  Widget _bottomNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.blue : Colors.grey, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isActive ? Colors.blue : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
