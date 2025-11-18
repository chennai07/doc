import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/utils/colors.dart';
import 'package:doc/homescreen/SearchjobScreen.dart';
import 'package:doc/profileprofile/surgeon_profile.dart';

class AppliedJobsScreen extends StatefulWidget {
  const AppliedJobsScreen({super.key});

  @override
  State<AppliedJobsScreen> createState() => _AppliedJobsScreenState();
}

class _AppliedJobsScreenState extends State<AppliedJobsScreen> {
  List<Map<String, dynamic>> appliedJobs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppliedJobs();
  }

  /// 🔹 Load applied jobs from backend for current user/profile
  Future<void> _loadAppliedJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileId = await SessionManager.getProfileId();
      if (profileId == null || profileId.isEmpty) {
        setState(() {
          _error = 'Profile id not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse(
          'http://13.203.67.154:3000/api/jobs/applied-jobs/$profileId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = response.body.trimLeft();
        dynamic decoded;
        try {
          decoded = jsonDecode(body);
        } catch (_) {
          decoded = {};
        }

        final data = decoded is Map && decoded['data'] != null
            ? decoded['data']
            : decoded;
        final list = data is List
            ? data
            : (data is Map && data['jobs'] is List ? data['jobs'] : <dynamic>[]);

        final jobs = <Map<String, dynamic>>[];
        for (final item in list) {
          if (item is! Map) continue;
          final m = item;

          // A lot of applied-jobs APIs nest the job data inside a 'job' or 'jobProfile' key.
          final rawJob = m['job'] is Map
              ? m['job'] as Map
              : (m['jobProfile'] is Map
                  ? m['jobProfile'] as Map
                  : m);

          // Try to derive a readable applied date from the wrapper object
          final rawDate = m['appliedAt'] ?? m['createdAt'] ?? m['updatedAt'] ?? '';
          String dateLabel = '';
          if (rawDate is String && rawDate.isNotEmpty) {
            try {
              final dt = DateTime.parse(rawDate);
              dateLabel = dt.toLocal().toString().split(' ').first;
            } catch (_) {
              dateLabel = rawDate.toString();
            }
          }

          jobs.add({
            'title': rawJob['jobTitle']?.toString() ??
                rawJob['title']?.toString() ??
                rawJob['role']?.toString() ??
                rawJob['position']?.toString() ??
                '',
            'org': rawJob['healthcareName']?.toString() ??
                rawJob['hospitalName']?.toString() ??
                rawJob['healthcareOrganization']?.toString() ??
                '',
            'location': rawJob['location']?.toString() ?? '',
            'date': dateLabel,
          });
        }

        setState(() {
          appliedJobs = jobs;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // No applied jobs found for this user/profile
        setState(() {
          appliedJobs = [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load applied jobs (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading applied jobs: $e';
        _isLoading = false;
      });
    }
  }

  /// 🔹 Delete a specific job
  Future<void> _deleteJob(int index) async {
    // For now, just remove from the local list (no backend delete endpoint provided)
    setState(() {
      appliedJobs.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text("Applied Jobs"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.redAccent, fontSize: 14),
                    ),
                  ),
                )
              : appliedJobs.isEmpty
                  ? const Center(
                      child: Text(
                        "No applied jobs yet 📝",
                        style:
                            TextStyle(color: Colors.black54, fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: appliedJobs.length,
                      itemBuilder: (context, index) {
                        final job = appliedJobs[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 14),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              child: const Icon(
                                Iconsax.briefcase,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              job['title'] ?? 'Unknown Role',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  job['org'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  job['location'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  job['date'] != null &&
                                          job['date'].toString().isNotEmpty
                                      ? "Applied on: ${job['date']}"
                                      : "Applied date not available",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Iconsax.trash,
                                  color: Colors.redAccent),
                              onPressed: () => _deleteJob(index),
                            ),
                          ),
                        );
                      },
                    ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomNavItem(Iconsax.search_normal, "Search", false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchScreen(),
                ),
              );
            }),
            _bottomNavItem(Iconsax.document, "Applied Jobs", true, () {
              // Already on applied jobs; no action
            }),
            _bottomNavItem(Iconsax.user, "Profile", false, () async {
              final profileId = await SessionManager.getProfileId();
              if (!mounted) return;
              if (profileId == null || profileId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Profile not found. Please complete your profile.'),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfessionalProfileViewPage(
                    profileId: profileId,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Bottom Navigation Item (same visual style as other screens)
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
