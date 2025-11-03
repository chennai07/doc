import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileView extends StatefulWidget {
  final String profileId;
  const ProfileView({super.key, required this.profileId});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool isLoading = true;
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    fetchProfileInfo();
  }

  // --- Utility for Date Formatting ---
  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${months[date.month - 1]} ${date.year}";
    } catch (_) {
      // Fallback to showing only the date part if parsing fails
      return isoDate.split("T").first;
    }
  }
  // ------------------------------------

  Future<void> fetchProfileInfo() async {
    final String apiUrl =
        "https://surgeon-search.onrender.com/api/sugeon/profile-info/${widget.profileId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      debugPrint("Profile API status: ${response.statusCode}");
      debugPrint("Profile API body: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['data'] != null) {
          setState(() {
            profileData = json['data'] as Map<String, dynamic>;
            isLoading = false;
          });
        } else {
          // Profile exists but no data, or data structure is unexpected
          setState(() {
            profileData = {};
            isLoading = false;
          });
        }
      } else {
        // Explicitly handle non-200 status codes (like 404) by setting data to empty
        setState(() {
          profileData = {};
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("fetchProfileInfo error: $e");
      setState(() {
        profileData = {}; // Explicitly handle network/parsing errors
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profileData == null || profileData!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Profile Not Found"),
          backgroundColor: Colors.lightBlueAccent,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 20),
              Text(
                "Profile with ID: ${widget.profileId} not found.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Safely extract data
    final name = profileData!["fullName"] ?? "Unknown Surgeon";
    final location = profileData!["location"] ?? "N/A";
    final speciality = profileData!["speciality"] ?? "N/A";
    final subSpeciality = profileData!["subSpeciality"] ?? "N/A";
    final degree = profileData!["degree"] ?? "N/A";
    final summary = profileData!["summaryProfile"] ?? "No summary provided.";
    final email = profileData!["email"] ?? "N/A";
    final phone = profileData!["phoneNumber"] ?? "N/A";
    final portfolio = profileData!["portfolioLinks"] ?? "";
    final experiences = (profileData!["workExperience"] ?? []) as List<dynamic>;

    // Placeholder image URL for demonstration (replace with actual field later)
    final profileImageUrl =
        profileData!["profilePicture"] ??
        "https://placehold.co/100x100/ADD8E6/000000?text=Dr";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Surgeon Profile"),
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Card (Name, Speciality, Image) ---
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.lightBlueAccent.withOpacity(0.5),
                      backgroundImage: profileImageUrl.startsWith('http')
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl.startsWith('http')
                          ? null
                          : const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$speciality ($subSpeciality)",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Degree: $degree",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Contact & Links Card ---
            _buildSectionCard(
              title: "Contact & Location",
              icon: Icons.contact_mail,
              children: [
                _buildInfoTile("Location", location, Icons.location_on),
                _buildInfoTile("Email", email, Icons.email),
                _buildInfoTile("Phone", phone, Icons.phone),
                if (portfolio.isNotEmpty)
                  _buildInfoTile(
                    "Portfolio",
                    portfolio,
                    Icons.link,
                    isLink: true,
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Summary/About Card ---
            _buildSectionCard(
              title: "Professional Summary",
              icon: Icons.info,
              children: [
                Text(
                  summary,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Experience Card ---
            _buildSectionCard(
              title: "Work Experience",
              icon: Icons.work,
              children: [
                if (experiences.isEmpty)
                  const Text("No work experience added.")
                else
                  ...experiences.map((e) => _buildExperienceCard(e)).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Section Card (Contact, Summary, Experience)
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.lightBlueAccent),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // Helper for contact/info rows
  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon, {
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: isLink ? Colors.lightBlueAccent : Colors.black54,
                    decoration: isLink
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for displaying a single Work Experience entry
  Widget _buildExperienceCard(dynamic experience) {
    final title = experience['designation'] ?? 'N/A';
    final org = experience['healthcareOrganization'] ?? 'N/A';
    final loc = experience['location'] ?? 'N/A';
    final from = _formatDate(experience['from']);
    final to = _formatDate(experience['to']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              org,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            Text(
              loc,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              "$from - $to",
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.lightBlueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
