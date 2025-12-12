import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/session_manager.dart';
import 'package:doc/hospital/JobDetailsScreen.dart';
import 'package:doc/hospital/applicantcard.dart';
import 'package:doc/healthcare/hospital_profile.dart';
import 'package:doc/widgets/skeleton_loader.dart';
import 'package:shimmer/shimmer.dart';

class ManageJobListings extends StatefulWidget {
  final Map<String, dynamic>? hospitalData;
  
  const ManageJobListings({super.key, this.hospitalData});

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

  // Header State
  bool _isHeaderLoading = true;
  String _hospitalName = '';
  String? _hospitalLogoUrl;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _initHospitalHeader();
  }

  void _initHospitalHeader() {
    // Use passed data as initial placeholder if available
    if (widget.hospitalData != null) {
       var logo = widget.hospitalData?['hospitalLogo']?.toString() ?? '';
       // Add base URL if logo is a relative path
       if (logo.isNotEmpty && !logo.startsWith('http')) {
         logo = 'http://13.203.67.154:3000/$logo';
       }
       setState(() {
         _hospitalName = widget.hospitalData?['hospitalName']?.toString() ?? 
                         widget.hospitalData?['name']?.toString() ?? 
                         'Hospital';
         _hospitalLogoUrl = logo.isNotEmpty ? logo : null;
       });
    }
    _fetchHospitalProfile();
  }

  Future<void> _fetchHospitalProfile() async {
    try {
      String? id = await SessionManager.getHealthcareId();
      if (id == null || id.isEmpty) {
        id = await SessionManager.getProfileId();
      }

      if (id != null && id.isNotEmpty) {
        final uri = Uri.parse('http://13.203.67.154:3000/api/healthcare/healthcare-profile/$id');
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final data = body is Map && body['data'] != null ? body['data'] : body;
          if (data is Map) {
             final name = data['hospitalName'] ?? data['name'] ?? data['organizationName'];
             var logo = data['hospitalLogo']?.toString() ?? '';
             // Add base URL if logo is a relative path
             if (logo.isNotEmpty && !logo.startsWith('http')) {
               logo = 'http://13.203.67.154:3000/$logo';
             }
             if (mounted) {
               setState(() {
                 if (name != null) _hospitalName = name.toString();
                 if (logo.isNotEmpty) _hospitalLogoUrl = logo;
                 _isHeaderLoading = false;
               });
             }
          }
        } else {
           if (mounted) setState(() => _isHeaderLoading = false);
        }
      } else {
         if (mounted) setState(() => _isHeaderLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching hospital name: $e');
      if (mounted) setState(() => _isHeaderLoading = false);
    }
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

      print('👥 Fetching applicants for healthcare_id: $storedId');
      await _fetchOverallApplicants(storedId);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('👥 Error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Error loading applicants: $e';
        _isLoading = false;
      });
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchOverallApplicants(String initialHealthcareId) async {
    try {
      // Collect all possible IDs
      final sessionHealthcareId = await SessionManager.getHealthcareId();
      final sessionProfileId = await SessionManager.getProfileId();
      final sessionUserId = await SessionManager.getUserId();

      final List<String> candidates = [
        if (initialHealthcareId.isNotEmpty) initialHealthcareId,
        if (sessionHealthcareId != null && sessionHealthcareId.isNotEmpty) sessionHealthcareId,
        if (sessionProfileId != null && sessionProfileId.isNotEmpty) sessionProfileId,
        if (sessionUserId != null && sessionUserId.isNotEmpty) sessionUserId,
      ];

      final uniqueCandidates = candidates.toSet().toList();
      print('👥 Fetching applicants. Candidates: $uniqueCandidates');

      List<Map<String, dynamic>> foundApplicants = [];
      bool success = false;

      for (final id in uniqueCandidates) {
        print('👥 Trying ID: $id');
        final uri = Uri.parse(
          'http://13.203.67.154:3000/api/jobs/applied-jobs/overall-jobs-healthcare/$id',
        );
        
        try {
          final response = await http.get(uri);
          print('👥 Response for $id: ${response.statusCode}');

          if (response.statusCode == 200) {
            final body = response.body.trimLeft();
            dynamic decoded;
            try {
              decoded = jsonDecode(body);
            } catch (e) {
              print('👥 Error decoding JSON: $e');
              decoded = {};
            }

            final data = decoded is Map && decoded['data'] != null
                ? decoded['data']
                : decoded;
            
            final list = data is List
                ? data
                : (data is Map && data['applications'] is List
                    ? data['applications']
                    : <dynamic>[]);
            
            print('👥 Found ${list.length} raw items for ID $id');

            final aggregated = <Map<String, dynamic>>[];

            for (final item in list) {
              if (item is! Map) continue;
              
              final m = item as Map<String, dynamic>;
              
              // Extract Job Details
              var jobObj = m['jobId'];
              if (jobObj is! Map) {
                 jobObj = m['job'];
              }
              if (jobObj is! Map) {
                 jobObj = m; 
              }

              final jobTitle = (jobObj['jobTitle'] ?? jobObj['title'] ?? m['jobTitle'] ?? '').toString();
              final jobStatus = (jobObj['status'] ?? m['status'] ?? 'Active').toString();
              final jobId = (jobObj['_id'] ?? jobObj['id'] ?? m['jobId'] ?? '').toString();

              // Extract Applicant Details
              var applicantObj = m['applicantId'];
              if (applicantObj is! Map) {
                applicantObj = m['applicant'];
              }
              if (applicantObj is! Map) {
                applicantObj = m;
              }
              
              print('👥 Applicant Object: $applicantObj'); // Added logging

              final firstName = (applicantObj['firstName'] ?? applicantObj['name'] ?? '').toString();
              final lastName = (applicantObj['lastName'] ?? '').toString();
              final name = [firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();
              final location = (applicantObj['location'] ?? '').toString();
              final profilePic = (applicantObj['profilePicture'] ?? applicantObj['profilePic'] ?? applicantObj['profileImage'] ?? '').toString();
              
              // Extract Application Details
              final status = (m['status'] ?? 'Applied').toString();
              final createdRaw = (m['createdAt'] ?? m['appliedOn'] ?? '').toString();
              
              final applicantMap = Map<String, dynamic>.from(m);
              applicantMap['jobTitle'] = jobTitle;
              applicantMap['jobStatus'] = jobStatus;
              applicantMap['jobId'] = jobId;
              applicantMap['applicantName'] = name;
              applicantMap['applicantLocation'] = location;
              applicantMap['profilePic'] = profilePic;
              applicantMap['status'] = status;
              applicantMap['appliedOn'] = createdRaw;

              aggregated.add(applicantMap);
            }

            foundApplicants = aggregated;
            success = true;
            break; // Stop if we found a valid 200 response
          }
        } catch (e) {
          print('👥 Error fetching for $id: $e');
        }
      }

      if (!mounted) return;
      
      if (success) {
        setState(() {
          _applicants = foundApplicants;
        });
      } else {
        // All attempts failed or returned 404
        setState(() {
           _applicants = [];
           // Optional: set error if you want to show it
           // _error = 'Failed to load applicants';
        });
      }

    } catch (e) {
      print('👥 Error fetching overall applicants: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get hospital name from hospitalData or fetched state
    // (Variables now managed in state)

    print('👥 BUILD: Total applicants: ${_applicants.length}');
    print('👥 BUILD: Current tab: $tabIndex (0=Active, 1=Closed)');
    
    // Log applicant details for debugging
    for (var i = 0; i < _applicants.length; i++) {
      final a = _applicants[i];
      print('👥 Applicant $i: jobStatus="${a['jobStatus']}", jobTitle="${a['jobTitle']}"');
    }

    // Filter applicants by tab (Active / Closed) based on parent job status
    final List<Map<String, dynamic>> filteredApplicants = _applicants
        .where(
          (a) {
            final status =
                (a['jobStatus'] ?? 'Active').toString().toLowerCase();
            final matches = tabIndex == 0
                ? status != 'closed'
                : status == 'closed';
            print('👥 Filter: status="$status", tabIndex=$tabIndex, matches=$matches');
            return matches;
          },
        )
        .toList();

    print('👥 BUILD: Filtered applicants: ${filteredApplicants.length}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- TOP HEADER ----------
              if (_isHeaderLoading && _hospitalName.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: ProfileHeaderSkeleton(),
                )
              else
                GestureDetector(
                onTap: () {
                  // Navigate to hospital profile
                  if (widget.hospitalData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HospitalProfile(
                          data: widget.hospitalData!,
                          showBottomBar: false,
                        ),
                      ),
                    );
                  }
                },
                child: Container(
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
                      // Hospital Logo
                      ClipOval(
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: (_hospitalLogoUrl != null && _hospitalLogoUrl!.isNotEmpty)
                              ? Image.network(
                                  _hospitalLogoUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(color: Colors.white),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      "assets/logo2.png",
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  "assets/logo2.png",
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _hospitalName.isNotEmpty ? _hospitalName : "Hospital",
                          style: const TextStyle(
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: SkeletonLoader(itemCount: 4, height: 120),
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
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No applicants found in ${tabIndex == 0 ? "Active" : "Closed"} jobs',
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
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
    final jobStatus = (job['status'] ?? '').toString();
    
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
              jobStatus: jobStatus,
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
    
    // Build location from state and district
    final jobState = (job['state'] ?? '').toString();
    final jobDistrict = (job['district'] ?? '').toString();
    String location;
    if (jobDistrict.isNotEmpty && jobState.isNotEmpty) {
      location = '$jobDistrict, $jobState';
    } else if (jobState.isNotEmpty) {
      location = jobState;
    } else if (jobDistrict.isNotEmpty) {
      location = jobDistrict;
    } else {
      location = (job['location'] ?? '').toString(); // Fallback for old jobs
    }
    
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
    var profilePic = (a['profilePic'] ?? '').toString();
    if (profilePic.isNotEmpty && !profilePic.startsWith('http')) {
       profilePic = 'http://13.203.67.154:3000/$profilePic';
    }

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
      role: '', // Role is now empty or can be used for something else, as Job Title is separate
      location: location,
      qualification: appliedOn.isNotEmpty ? 'Applied on $appliedOn' : 'Applied date N/A',
      currentRole: '', // You can map this to something else if needed
      tag: status.isNotEmpty ? status : 'N/A',
      tagColor: tagColor,
      imagePath: profilePic,
      jobTitle: jobTitle.isNotEmpty ? jobTitle : 'Applied Position',
      onReviewTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApplicantProfilePage(
              applicant: a,
              jobId: (a['jobId'] ?? '').toString(),
              viewOnly: true, // Only view profile and status, no actions from main Applicants screen
            ),
          ),
        );
      },
      onViewProfileTap: () {},
    );
  }
}
