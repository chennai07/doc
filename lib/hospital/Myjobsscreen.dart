import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/session_manager.dart';
import 'package:doc/hospital/applicantcard.dart';
import 'package:doc/hospital/JobDetailsScreen.dart';

class MyJobsPage extends StatefulWidget {
  final VoidCallback? onHospitalNameTap;
  final String? healthcareId;

  const MyJobsPage({super.key, this.onHospitalNameTap, this.healthcareId});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  int bottomIndex = 0;
  int tabIndex = 0; // 0 = Active, 1 = Closed

  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  String? _error;

  // Added for filtering and ID tracking
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _resolvedHealthcareId;
  String _hospitalName = ''; // Added

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fromWidgetId = widget.healthcareId;
      final storedId =
          (await SessionManager.getHealthcareId()) ?? await SessionManager.getProfileId() ?? '';
      var healthcareId =
          (fromWidgetId != null && fromWidgetId.isNotEmpty) ? fromWidgetId : storedId;

      if (healthcareId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = 'Healthcare id not found';
          _isLoading = false;
        });
        return;
      }

      // Resolve the correct healthcare_id from the profile
      try {
        final profileUri = Uri.parse(
            'http://13.203.67.154:3000/api/healthcare/healthcare-profile/$healthcareId');
        final profileRes = await http.get(profileUri);
        if (profileRes.statusCode == 200) {
          final body = jsonDecode(profileRes.body);
          final data =
              body is Map && body['data'] != null ? body['data'] : body;
          if (data is Map) {
            final realId = data['healthcare_id']?.toString();
            if (realId != null && realId.isNotEmpty) {
              healthcareId = realId;
            }
            // Extract hospital name
            final name = data['hospitalName'] ?? data['name'] ?? data['organizationName'];
            if (name != null) {
              _hospitalName = name.toString();
            }
          }
        }
      } catch (e) {
        debugPrint('Error resolving healthcare_id: $e');
      }

      // Store the resolved ID for future use (e.g. filters)
      _resolvedHealthcareId = healthcareId;

      final uri = Uri.parse(
          'http://13.203.67.154:3000/api/healthcare/joblist-healthcare/$healthcareId');
      final response = await http.get(uri);

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
          if (item is Map) {
            jobs.add(Map<String, dynamic>.from(item as Map));
          }
        }

        if (!mounted) return;
        setState(() {
          _jobs = jobs;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // No jobs found for this healthcare id – treat as empty list, not an error
        if (!mounted) return;
        setState(() {
          _jobs = [];
          _error = null;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = 'Failed to load jobs (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading jobs: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredJobs {
    return _jobs.where((job) {
      // 1. Filter by Tab (Active vs Closed)
      final status = (job['status']?.toString() ?? 'Active').toLowerCase();
      final isActiveTab = tabIndex == 0;
      
      // If tab is Active, show everything EXCEPT 'closed'
      // If tab is Closed, show ONLY 'closed'
      if (isActiveTab) {
        if (status == 'closed') return false;
      } else {
        if (status != 'closed') return false;
      }

      // 2. Filter by Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = (job['jobTitle']?.toString() ?? '').toLowerCase();
        final dept = (job['department']?.toString() ?? '').toLowerCase();
        final loc = (job['location']?.toString() ?? '').toLowerCase();
        
        return title.contains(query) || dept.contains(query) || loc.contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayJobs = _filteredJobs;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- HEADER CARD ----------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Hospital Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        "assets/logo.png",
                        height: 40,
                        width: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Hospital Name (tappable to go to profile)
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onHospitalNameTap,
                        child: Text(
                          _hospitalName.isNotEmpty ? _hospitalName : "Hospital",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    // Notification Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Colors.blue,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------- SEARCH BAR ----------
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: "Search",
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---------- FILTER + ACTIVE/CLOSED ----------
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.filter_alt, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => tabIndex = 0),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: tabIndex == 0
                                    ? Colors.blue
                                    : const Color(0xffe8f1ff),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Active",
                                style: TextStyle(
                                  color: tabIndex == 0
                                      ? Colors.white
                                      : Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => tabIndex = 1),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: tabIndex == 1
                                    ? Colors.blue
                                    : const Color(0xffe8f1ff),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Closed",
                                style: TextStyle(
                                  color: tabIndex == 1
                                      ? Colors.white
                                      : Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                "${displayJobs.length} Results",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              else if (displayJobs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No jobs found',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              else
                Column(
                  children: displayJobs.map(_buildJobCard).toList(),
                ),
            ],
          ),
        ),
      ),

      // ---------- BOTTOM NAVIGATION ----------
    );
  }

  Future<void> _viewApplicantsForJob(Map<String, dynamic> job) async {
    final rawId = job['_id'] ?? job['id'] ?? '';
    final jobId = rawId.toString();
    final jobTitle = (job['jobTitle'] ?? job['title'] ?? '').toString();
    if (jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job id not found for this listing.')),
      );
      return;
    }

    try {
      final uri = Uri.parse(
        'http://13.203.67.154:3000/api/jobs/applied-jobs/specific-jobs/$jobId',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = response.body.trimLeft();
        dynamic decoded;
        try {
          decoded = jsonDecode(body);
        } catch (_) {
          decoded = [];
        }

        final data = decoded is Map && decoded['data'] != null
            ? decoded['data']
            : decoded;
        final list = data is List
            ? data
            : (data is Map && data['applications'] is List
                ? data['applications']
                : <dynamic>[]);

        final applicants = <Map<String, dynamic>>[];
        for (final item in list) {
          if (item is! Map) continue;
          final m = item;
          final rawApplicant =
              m['applicant'] is Map ? m['applicant'] as Map : m;
          applicants.add(Map<String, dynamic>.from(rawApplicant as Map));
        }

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApplicantsListPage(
              jobId: jobId,
              jobTitle: jobTitle,
              applicants: applicants,
            ),
          ),
        );
      } else if (response.statusCode == 404) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No applicants found for this job.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load applicants (${response.statusCode})',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading applicants: $e')),
      );
    }
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final title = job['jobTitle']?.toString() ?? '';
    final department = job['department']?.toString() ?? '';
    final subSpeciality = job['subSpeciality']?.toString() ?? '';
    final location = job['location']?.toString() ?? '';
    final qualifications = job['qualifications']?.toString() ?? '';
    final aboutRole = job['aboutRole']?.toString() ?? '';
    final status = job['status']?.toString() ?? 'Active';

    Color tagColor;
    switch (status.toLowerCase()) {
      case 'closed':
        tagColor = Colors.redAccent;
        break;
      case 'draft':
        tagColor = Colors.orangeAccent;
        break;
      default:
        tagColor = Colors.green;
    }

    return ApplicantCard(
      name: title.isNotEmpty ? title : 'Job',
      role: department.isNotEmpty ? department : subSpeciality,
      location: location,
      qualification: qualifications.isNotEmpty ? qualifications : subSpeciality,
      currentRole: aboutRole,
      tag: status,
      tagColor: tagColor,
      imagePath: 'assets/logo.png',
      onReviewTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailScreen(
              job: job,
              onEdit: (updatedJob) {},
              onClose: () {},
              onDelete: () {},
              onViewApplicants: () {
                _viewApplicantsForJob(job);
              },
            ),
          ),
        );
      },
      onViewProfileTap: () {},
    );
  }
}