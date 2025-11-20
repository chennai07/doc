import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/session_manager.dart';
import 'package:doc/hospital/JobDetailsScreen.dart';
import 'package:doc/hospital/applicantcard.dart';

class ManageJobListings extends StatefulWidget {
  const ManageJobListings({super.key});

  @override
  State<ManageJobListings> createState() => _ManageJobListingsState();
}

class _ManageJobListingsState extends State<ManageJobListings> {
  int tabIndex = 0;
  // ---------- JOBS (mock data) ----------
  List<Map<String, dynamic>> jobs = [];

  // ---------- APPLICANTS BY JOB ID (mock data) ----------
  final Map<String, List<Map<String, dynamic>>> applicantsByJobId = {};

  // Aggregated applicants across all jobs for this healthcare
  List<Map<String, dynamic>> _applicants = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storedId =
          (await SessionManager.getHealthcareId()) ?? await SessionManager.getProfileId() ?? '';

      if (storedId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = 'Healthcare id not found';
          _isLoading = false;
        });
        return;
      }

      final uri = Uri.parse(
          'http://13.203.67.154:3000/api/healthcare/joblist-healthcare/$storedId');
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

        final fetchedJobs = <Map<String, dynamic>>[];
        for (final item in list) {
          if (item is Map) {
            fetchedJobs.add(Map<String, dynamic>.from(item as Map));
          }
        }

        if (!mounted) return;
        // First store jobs, then fetch applicants for all jobs
        setState(() {
          jobs = fetchedJobs;
        });

        await _fetchApplicantsForAllJobs();

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // No jobs found – treat as empty list, not an error
        if (!mounted) return;
        setState(() {
          jobs = [];
          _applicants = [];
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

  Future<void> _fetchApplicantsForAllJobs() async {
    final aggregated = <Map<String, dynamic>>[];

    for (final job in jobs) {
      final rawId = job['_id'] ?? job['id'] ?? '';
      final jobId = rawId.toString();
      if (jobId.isEmpty) continue;

      final jobTitle = (job['jobTitle'] ?? job['title'] ?? '').toString();
      final jobStatus = (job['status'] ?? 'Active').toString();

      try {
        final uri = Uri.parse(
          'http://13.203.67.154:3000/api/jobs/applied-jobs/specific-jobs/$jobId',
        );
        final response = await http.get(uri);

        if (response.statusCode != 200) continue;

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

        for (final item in list) {
          if (item is! Map) continue;
          final m = item;
          final rawApplicant = m['applicant'] is Map
              ? m['applicant'] as Map
              : m;
          final applicantMap =
              Map<String, dynamic>.from(rawApplicant as Map);
          applicantMap['jobId'] = jobId;
          applicantMap['jobTitle'] = jobTitle;
          applicantMap['jobStatus'] = jobStatus;
          aggregated.add(applicantMap);
        }
      } catch (_) {
        // Ignore errors per job; other jobs may still have applicants
        continue;
      }
    }

    if (!mounted) return;
    setState(() {
      _applicants = aggregated;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter applicants by tab (Active / Closed) based on parent job status
    final List<Map<String, dynamic>> filteredApplicants = _applicants
        .where(
          (a) {
            final status =
                (a['jobStatus'] ?? 'Active').toString().toLowerCase();
            return tabIndex == 0
                ? status != 'closed'
                : status == 'closed';
          },
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- TOP HEADER ----------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // keep asset image path same as yours
                    Image.asset(
                      "assets/logo.png",
                      height: 40,
                      width: 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Apollo Hospitals",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------- SEARCH BAR ----------
              TextField(
                onChanged: (val) {
                  // For brevity, search is not implemented in this example.
                  // You can filter `jobs` based on `val` here.
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
                        _tabButton(index: 0, text: "Active"),
                        const SizedBox(width: 10),
                        _tabButton(index: 1, text: "Closed"),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                "${filteredApplicants.length} Results",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
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
              else if (filteredApplicants.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No applicants found',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              else
                // ---------- APPLICANTS LIST ----------
                Column(
                  children:
                      filteredApplicants.map((app) => _buildApplicantCard(app)).toList(),
                ),
            ],
          ),
        ),
      ),
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
          final rawApplicant = m['applicant'] is Map
              ? m['applicant'] as Map
              : m;
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

  // ----------- Active / Closed Tab Button ----------
  Widget _tabButton({required int index, required String text}) {
    final bool isSelected = tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tabIndex = index),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : const Color(0xffe8f1ff),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ----------- JOB CARD ----------
  Widget _jobCard(Map<String, dynamic> job) {
    final jobId = (job['_id'] ?? job['id'] ?? '').toString();
    final title = (job['jobTitle'] ?? job['title'] ?? '').toString();
    final department = (job['department'] ?? '').toString();
    final specialization = (job['subSpeciality'] ?? job['specialization'] ?? '').toString();
    final experience = (job['experience'] ?? '').toString();
    final deadline = (job['deadline'] ?? '').toString();
    final status = (job['status'] ?? 'Active').toString();
    final type = (job['jobType'] ?? job['type'] ?? '').toString();
    final location = (job['location'] ?? '').toString();
    final createdRaw = (job['createdAt'] ?? job['postedOn'] ?? '').toString();
    final ago = createdRaw.contains('T')
        ? createdRaw.split('T').first
        : createdRaw;
    final applicantsCount = (job['applicants'] ?? job['applicationsCount'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        // navigate to detail and pass callbacks to modify state
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailScreen(
              job: job,
              onEdit: (updatedJob) {
                // update job in list
                setState(() {
                  final idx = jobs.indexWhere((j) => j['_id'] == job['_id']);
                  if (idx != -1) jobs[idx] = {...jobs[idx], ...updatedJob};
                });
              },
              onClose: () {
                setState(() {
                  final idx = jobs.indexWhere((j) => j['_id'] == job['_id']);
                  if (idx != -1) jobs[idx]['status'] = 'Closed';
                });
              },
              onDelete: () {
                setState(() {
                  jobs.removeWhere((j) => j['_id'] == job['_id']);
                });
                Navigator.pop(context); // close detail page after delete
              },
              onViewApplicants: () {
                _viewApplicantsForJob(job);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: "Job ID: ",
                    style: const TextStyle(color: Colors.black87),
                    children: [
                      TextSpan(
                        text: jobId,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(ago, style: const TextStyle(color: Colors.black54)),
              ],
            ),

            const SizedBox(height: 10),

            // Logo + Title + Status
            Row(
              children: [
                Image.asset("assets/logo.png", height: 36, width: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 13,
                          color: status.toLowerCase() == "active"
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text("Department: $department"),
            Text("Specialization: $specialization"),
            Text("Experience: $experience"),

            const SizedBox(height: 8),

            Text(
              "Application Deadline: $deadline",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                _chip(Icons.group,
                    applicantsCount.isNotEmpty ? "$applicantsCount Applicants" : "Applicants"),
                const SizedBox(width: 10),
                _chip(Icons.access_time_filled, type.isNotEmpty ? type : 'Full time'),
                const SizedBox(width: 10),
                _chip(Icons.location_on, location),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----------- BOTTOM TAGS (APPLICANTS / FULL TIME / LOCATION) ----------
  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xffe8f1ff),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.blue, fontSize: 13)),
        ],
      ),
    );
  }

  // ----------- APPLICANT CARD BUILDER ----------
  Widget _buildApplicantCard(Map<String, dynamic> a) {
    final firstName = (a['firstName'] ?? a['name'] ?? '').toString();
    final lastName = (a['lastName'] ?? '').toString();
    final name = [firstName, lastName]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();

    final jobTitle = (a['jobTitle'] ?? '').toString();
    final location = (a['location'] ?? '').toString();
    final status = (a['status'] ?? '').toString();
    final createdRaw = (a['createdAt'] ?? a['appliedOn'] ?? '').toString();
    final appliedOn = createdRaw.contains('T')
        ? createdRaw.split('T').first
        : createdRaw;

    Color tagColor;
    switch (status.toLowerCase()) {
      case 'shortlisted':
        tagColor = Colors.green;
        break;
      case 'rejected':
        tagColor = Colors.redAccent;
        break;
      default:
        tagColor = Colors.blue;
    }

    return ApplicantCard(
      name: name.isNotEmpty ? name : 'Unknown',
      role: jobTitle.isNotEmpty ? jobTitle : 'Applied Position',
      location: location,
      qualification:
          appliedOn.isNotEmpty ? 'Applied on $appliedOn' : 'Applied date N/A',
      currentRole: '',
      tag: status.isNotEmpty ? status : 'N/A',
      tagColor: tagColor,
      imagePath: '',
      onReviewTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApplicantProfilePage(
              applicant: a,
              jobId: (a['jobId'] ?? '').toString(),
            ),
          ),
        );
      },
      onViewProfileTap: () {},
    );
  }
}
