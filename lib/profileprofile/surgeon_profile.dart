import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:doc/model/doctor_profile_data.dart';
import 'package:doc/model/api_service.dart';
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Doctor Profile", style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundImage: AssetImage("assets/profile.png"),
                    child: Icon(Icons.person, size: 60, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(_profile!.name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                  Text(_profile!.speciality,
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("About", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(_profile!.summary.isNotEmpty ? _profile!.summary : "No summary available", 
                style: const TextStyle(height: 1.4)),

            const SizedBox(height: 20),
            const Divider(),

            const Text("Education", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text("${_profile!.degree}${_profile!.subSpeciality.isNotEmpty ? ' - ${_profile!.subSpeciality}' : ''}",
                style: const TextStyle(color: Colors.black87)),

            const SizedBox(height: 20),
            const Divider(),

            const Text("Experience", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (_profile!.designation.isNotEmpty && _profile!.organization.isNotEmpty) ...[
              Text("${_profile!.designation} at ${_profile!.organization}",
                  style: const TextStyle(color: Colors.black87)),
              if (_profile!.period.isNotEmpty || _profile!.workLocation.isNotEmpty)
                Text("${_profile!.period}${_profile!.workLocation.isNotEmpty ? ' | ${_profile!.workLocation}' : ''}",
                    style: const TextStyle(color: Colors.grey)),
            ] else
              const Text("No work experience added", style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 20),
            const Divider(),

            const Text("Contact", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (_profile!.phone.isNotEmpty) Text("📞 ${_profile!.phone}"),
            if (_profile!.email.isNotEmpty) Text("✉️ ${_profile!.email}"),
            if (_profile!.location.isNotEmpty) Text("📍 ${_profile!.location}"),

            const SizedBox(height: 20),
            if (_profile!.portfolio.isNotEmpty)
              Text("🔗 Portfolio: ${_profile!.portfolio}",
                  style: const TextStyle(color: Colors.blueAccent)),
          ],
        ),
      ),
    );
  }
}
