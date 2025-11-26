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

          // A lot of applied-jobs APIs nest the job data inside
          // m['job'] or m['jobProfile']['job']. Fall back to m itself.
          Map rawJob;
          if (m['job'] is Map) {
            rawJob = m['job'] as Map;
          } else if (m['jobProfile'] is Map &&
              (m['jobProfile']['job'] is Map)) {
            rawJob = m['jobProfile']['job'] as Map;
          } else if (m['jobProfile'] is Map) {
            rawJob = m['jobProfile'] as Map;
          } else {
            rawJob = m;
          }

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

          final title = (rawJob['jobTitle'] ??
                  rawJob['title'] ??
                  rawJob['jobRole'] ??
                  rawJob['role'] ??
                  rawJob['position'])
              ?.toString()
              .trim();

          final org = (rawJob['healthcareName'] ??
                  rawJob['hospitalName'] ??
                  rawJob['healthcareOrganization'] ??
                  rawJob['organisation'] ??
                  rawJob['organization'])
              ?.toString()
              .trim();

          final desc = (rawJob['aboutRole'] ??
                  rawJob['description'] ??
                  rawJob['jobDescription'] ??
                  rawJob['roleDescription'])
              ?.toString()
              .trim();

          final statusValue = (m['status'] ??
                  m['applicationStatus'] ??
                  m['jobStatus'] ??
                  rawJob['status'])
              ?.toString()
              .trim();

          jobs.add({
            'title': title ?? '',
            'org': org ?? '',
            'location': rawJob['location']?.toString() ?? '',
            'date': dateLabel,
            'status': statusValue ?? '',
            'description': desc ?? '',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text("Applied Jobs"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Iconsax.close_circle,
                          color: Colors.redAccent,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadAppliedJobs,
                          icon: const Icon(Iconsax.refresh, size: 18),
                          label: const Text("Retry"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : appliedJobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.document,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No applied jobs yet 📝",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Start applying to jobs to see them here",
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: appliedJobs.length,
                      itemBuilder: (context, index) {
                        final job = appliedJobs[index];
                        final String status =
                            (job['status'] ?? 'Applied').toString();
                        final String description =
                            (job['description'] ?? '').toString();
                        final String date = (job['date'] ?? '').toString();

                        Color statusColor;
                        if (status.toLowerCase().contains('interview')) {
                          statusColor = Colors.green;
                        } else if (status.toLowerCase().contains('reject')) {
                          statusColor = Colors.redAccent;
                        } else {
                          statusColor = AppColors.primary;
                        }

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Top: icon + basic info
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          AppColors.primary.withOpacity(0.08),
                                      child: const Icon(
                                        Iconsax.briefcase,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job['title'] ?? 'Unknown Role',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            job['org'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(
                                                Iconsax.location,
                                                size: 14,
                                                color: Colors.black54,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  job['location'] ?? '',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                /// Middle: short description
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],

                                /// Bottom row: applied date (left) + status pill (right)
                                if (date.isNotEmpty || status.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (date.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Colors.green.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Iconsax.tick_circle,
                                                size: 14,
                                                color:
                                                    Colors.green.shade700,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "Applied on $date",
                                                style: TextStyle(
                                                  color:
                                                      Colors.green.shade700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (status.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                statusColor.withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
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
