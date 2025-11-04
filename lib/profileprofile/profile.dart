import 'dart:convert';
import 'package:doc/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorProfilePage extends StatefulWidget {
  final String? initialProfileJson;
  const DoctorProfilePage({super.key, this.initialProfileJson});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  Map<String, dynamic>? profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      if (widget.initialProfileJson != null) {
        final decoded = jsonDecode(widget.initialProfileJson!);
        // Handle both cases: data has 'profile' or not
        setState(() {
          profile = decoded['profile'] ?? decoded;
          _isLoading = false;
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('profile_id');

      setState(() {
        profile = {'_id': savedId};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        profile = {};
      });
    }
  }

  Future<void> _logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_id');
    await prefs.remove('token');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = profile ?? {};
    final experiences = (data['workExperience'] ?? []) as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Doctor Profile",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.logout, color: Colors.black),
            onPressed: _logoutUser,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          children: [
            // 👤 Profile photo + name + speciality
            Column(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: data["imageUrl"] != null
                      ? NetworkImage(data["imageUrl"])
                      : const AssetImage("assets/profile_placeholder.png")
                            as ImageProvider,
                ),
                const SizedBox(height: 10),
                Text(
                  data['fullName'] ?? "Doctor Name",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  data['speciality'] ?? "Speciality",
                  style: const TextStyle(fontSize: 15, color: Colors.blue),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // 🧠 About section
            _sectionTitle("About :"),
            Text(
              data['summaryProfile'] ?? "No summary added yet.",
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Text(
                  "Speciality: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(data['speciality'] ?? "N/A"),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  "Sub-Speciality: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(data['subSpeciality'] ?? "N/A"),
              ],
            ),
            const SizedBox(height: 25),

            // 🏥 Experience section
            _sectionTitle("Experiences"),
            const SizedBox(height: 8),

            if (experiences.isEmpty)
              const Text("No experience details available."),
            for (final exp in experiences)
              _experienceTile(
                title: exp['designation'] ?? "Designation",
                hospital: exp['healthcareOrganization'] ?? "Hospital",
                location: exp['location'] ?? "Location",
                period: "${exp['from'] ?? ''} - ${exp['to'] ?? 'Present'}",
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  Widget _experienceTile({
    required String title,
    required String hospital,
    required String location,
    required String period,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.buildings, color: Colors.blue, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  "$hospital | $location",
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                Text(period, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
