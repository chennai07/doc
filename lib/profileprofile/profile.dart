// ✅ lib/screens/doctor_profile_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doc/profileprofile/professional_profile_page.dart';
import '../model/doctor_profile_model.dart';

class DoctorProfilePage extends StatefulWidget {
  final String? initialProfileJson; // ✅ Accept preloaded profile JSON

  const DoctorProfilePage({super.key, this.initialProfileJson});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  DoctorProfile? profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // ✅ If profile data is passed, load instantly
    if (widget.initialProfileJson != null) {
      try {
        profile = doctorProfileFromJson(widget.initialProfileJson!);
        _isLoading = false;
        print('✅ Loaded profile directly from navigation');
      } catch (e) {
        print('⚠️ Failed to parse initial JSON: $e');
        _loadProfile();
      }
    } else {
      _loadProfile(); // fallback to fetch from API
    }
  }

  /// ✅ Load saved profile_id from SharedPreferences
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileId = prefs.getString('profile_id'); // correct key

    if (profileId == null || profileId.isEmpty) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No profile ID found. Please log in again.'),
          ),
        );

        // Redirect to profile creation
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfessionalProfilePage()),
          );
        });
      }
      return;
    }

    print('✅ Loaded saved profile_id: $profileId');
    await _fetchProfile(profileId);
  }

  /// ✅ Fetch doctor profile by ID
  Future<void> _fetchProfile(String id) async {
    try {
      final url = Uri.parse(
        'https://surgeon-search.onrender.com/api/sugeon/profile-info/$id',
      );
      print('🌐 Fetching profile from: $url');

      final response = await http.get(url);
      print('📩 Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          profile = DoctorProfile.fromJson(decoded);
          _isLoading = false;
        });
        print('✅ Profile loaded successfully!');
      } else {
        setState(() => _isLoading = false);
        final decoded = jsonDecode(response.body);
        final message = decoded['message'] ?? 'Unknown error';

        if (response.statusCode == 404 ||
            message.toLowerCase().contains('not found')) {
          print('🆕 Redirecting to create new profile...');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🆕 No profile found. Please create one.'),
              ),
            );
            Future.delayed(const Duration(seconds: 1), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfessionalProfilePage(),
                ),
              );
            });
          }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('❌ Failed: $message')));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('⚠️ Error fetching profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profile == null) {
      return const Scaffold(body: Center(child: Text('No profile data found')));
    }

    final doctor = profile!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ Profile Picture
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage:
                    doctor.profilePicture != null &&
                        doctor.profilePicture!.isNotEmpty
                    ? NetworkImage(doctor.profilePicture!)
                    : const AssetImage('assets/doctor_placeholder.png')
                          as ImageProvider,
              ),
            ),
            const SizedBox(height: 15),

            // ✅ Name and speciality
            Text(
              doctor.fullName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              doctor.speciality,
              style: const TextStyle(
                color: Color(0xFF0077CC),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 25),

            // ✅ About section
            _buildSectionTitle("About"),
            Text(
              doctor.summaryProfile.isNotEmpty
                  ? doctor.summaryProfile
                  : "No summary available.",
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 25),

            // ✅ Experience Section
            _buildSectionTitle("Experiences"),
            const SizedBox(height: 10),
            if (doctor.workExperience.isEmpty)
              const Text("No experiences added."),
            for (var exp in doctor.workExperience) _buildExperienceItem(exp),
          ],
        ),
      ),
    );
  }

  // ✅ Helper Widgets
  Widget _buildSectionTitle(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildExperienceItem(WorkExperience exp) => Container(
    margin: const EdgeInsets.only(bottom: 15),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Iconsax.hospital, size: 22, color: Colors.blue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exp.designation,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                "${exp.healthcareOrganization} | ${exp.location}",
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Text(
                "${exp.from} - ${exp.to}",
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ✅ Logout Function
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_id');

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }
}
