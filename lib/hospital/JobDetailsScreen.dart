import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:doc/model/doctor_profile_data.dart';
import 'package:doc/model/api_service.dart';
import 'package:doc/hospital/Interviewpage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  final void Function(Map<String, dynamic>) onEdit;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onViewApplicants;
  final void Function(String candidateId)? onScheduleInterview;

  const JobDetailScreen({
    super.key,
    required this.job,
    required this.onEdit,
    required this.onClose,
    required this.onDelete,
    required this.onViewApplicants,
    this.onScheduleInterview,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Map<String, dynamic> _jobData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _jobData = widget.job;
    _fetchJobDetails();
  }

  Future<void> _fetchJobDetails() async {
    final rawId = _jobData['_id'] ?? _jobData['id'];
    if (rawId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final jobId = rawId.toString();

    try {
      final uri = Uri.parse('http://13.203.67.154:3000/api/healthcare/job-profile/$jobId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body is Map && body['data'] != null ? body['data'] : body;
        if (data is Map<String, dynamic>) {
          if (mounted) {
            setState(() {
              _jobData = data;
              _isLoading = false;
            });
          }
        }
      } else {
        debugPrint('Failed to fetch job details: ${response.statusCode}');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching job details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _jobData;
    // Use fetched data or fallbacks
    final title = job['jobTitle'] ?? job['title'] ?? 'Job Title';
    final postedOn = job['postedOn'] ?? ''; // You might need to format this date
    final location = job['location'] ?? 'Location';
    final experience = job['minYearsOfExperience'] != null ? '${job['minYearsOfExperience']} Years' : 'Experience';
    final jobType = job['jobType'] ?? 'Full Time';
    final salary = job['salaryRange'] ?? 'Salary';
    final department = job['department'] ?? 'N/A';
    final subSpeciality = job['subSpeciality'] ?? 'N/A';
    final interviewMode = job['interviewMode'] ?? 'In-person';
    final aboutRole = job['aboutRole'] ?? 'N/A';
    final responsibilities = job['keyResponsibilities'] ?? '';
    final qualifications = job['preferredQualifications'] ?? '';
    String deadline = job['applicationDeadline'] ?? 'N/A';
    if (deadline != 'N/A' && deadline.contains('T')) {
      deadline = deadline.split('T')[0];
    }
    
    // Hospital Name - try to get from healthcare_id if populated, otherwise hardcoded fallback or from job map
    // The API might return healthcare_id as an object if populated, or just an ID string.
    // For now, we'll check if it's a map and has a name.
    String hospitalName = "Hospital"; 
    if (job['healthcare_id'] is Map) {
       hospitalName = job['healthcare_id']['hospitalName'] ?? job['healthcare_id']['name'] ?? "Hospital";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            // Top bar + posted date + action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios, size: 16),
                        SizedBox(width: 6),
                        Text("Back", style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (postedOn.isNotEmpty)
                        Text(
                          "Posted on $postedOn",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
            ),
            // Take Action dropdown mock
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _showTakeActionMenu(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Take Action",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),
                    Center(child: Image.asset("assets/logo.png", height: 90)),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _iconText(Icons.local_hospital, hospitalName),
                        const SizedBox(width: 18),
                        _iconText(
                          Icons.location_on_outlined,
                          location,
                        ),
                        const SizedBox(width: 18),
                        _iconText(Icons.school, experience),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // full-time + salary pill
                    // ---------- FULL TIME + SALARY BOX (Exact UI) ----------
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0062FF), Color(0xFF3E8BFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          // ---------- LEFT SIDE ----------
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.work,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  jobType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ---------- DIVIDER ----------
                          Container(
                            width: 1,
                            height: 45,
                            color: Colors.white.withOpacity(0.45),
                          ),

                          // ---------- RIGHT SIDE ----------
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.currency_rupee, // Changed to Rupee
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  salary,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    _sectionTitle("Department:"),
                    _sectionText(department),
                    _sectionTitle("Sub-Speciality:"),
                    _sectionText(subSpeciality),
                    _sectionTitle("Interview Mode:"),
                    _sectionText(interviewMode),
                    _sectionTitle("About the Role:"),
                    _sectionText(aboutRole),
                    _sectionTitle("Key Responsibilities:"),
                    _sectionText(responsibilities), // Displaying as text
                    _sectionTitle("Preferred Qualifications:"),
                    _sectionText(qualifications), // Displaying as text
                    _sectionTitle("Application Deadline:"),
                    _sectionText(deadline),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0062FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: widget.onViewApplicants,
                        child: const Text(
                          "View Applicants",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillItem({required IconData icon, required String label}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _iconText(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _sectionTitle(String text) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
  );

  Widget _sectionText(String text) => Container(
    width: double.infinity,
    child: Text(
      text,
      textAlign: TextAlign.left,
      style: const TextStyle(fontSize: 14, height: 1.6),
    ),
  );

  Widget _bulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("•  ", style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // Take Action menu: shows Job filled / Extended / Closed
  void _showTakeActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text("Job filled"),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateJobStatus("job filled");
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.orange),
                title: const Text("Extended"),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleExtendJob(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: const Text("Closed"),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateJobStatus("closed");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleExtendJob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      // Format date as YYYY-MM-DD
      final formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      _updateJobStatus("extended", deadline: formattedDate);
    }
  }

  Future<void> _updateJobStatus(String status, {String? deadline}) async {
    final jobId = (_jobData['_id'] ?? _jobData['id'] ?? '').toString();
    if (jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job id not found')),
      );
      return;
    }

    // Use the endpoint provided by the user
    final uri = Uri.parse(
      'http://13.203.67.154:3000/api/healthcare/job-edit/$jobId',
    );

    final Map<String, dynamic> payload = {
      'status': status,
    };

    if (deadline != null) {
      payload['applicationDeadline'] = deadline;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            _jobData['status'] = status;
            if (deadline != null) {
              _jobData['applicationDeadline'] = deadline;
            }
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Job marked as $status')),
          );
          // If extended, we might want to refresh the UI to show the new deadline immediately
          // The setState above updates the local map, so the UI should rebuild.
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update job: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating job: $e')),
        );
      }
    }
  }

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(
      text: (_jobData['jobTitle'] ?? _jobData['title'] ?? '').toString(),
    );
    final deadlineController = TextEditingController(
      text: (_jobData['deadline'] ?? '').toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(labelText: 'Deadline'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final jobId = (_jobData['_id'] ?? _jobData['id'] ?? '').toString();
              if (jobId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job id not found')), 
                );
                Navigator.pop(ctx);
                return;
              }

              final uri = Uri.parse(
                'http://13.203.67.154:3000/api/jobs/applied-jobs/jobs-edit/$jobId',
              );

              final payload = {
                'jobTitle': titleController.text,
                'deadline': deadlineController.text,
              };

              try {
                final response = await http.put(
                  uri,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload),
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  widget.onEdit({
                    'jobTitle': titleController.text,
                    'title': titleController.text,
                    'deadline': deadlineController.text,
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job updated')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to update job $jobId (${response.statusCode})',
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating job: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('This action cannot be undone. Delete the job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.onDelete();
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job deleted (mock)')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ----------------- ApplicantsListPage -----------------
class ApplicantsListPage extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final List<Map<String, dynamic>> applicants;

  const ApplicantsListPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.applicants,
  });

  @override
  State<ApplicantsListPage> createState() => _ApplicantsListPageState();
}

class _ApplicantsListPageState extends State<ApplicantsListPage> {
  late List<Map<String, dynamic>> _applicants;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _applicants = widget.applicants;
  }

  Future<void> _fetchApplicants() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse(
        'http://13.203.67.154:3000/api/jobs/applied-jobs/specific-jobs/${widget.jobId}',
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

        if (mounted) {
          setState(() {
            _applicants = applicants;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInitials(String name) {
    return Container(
      width: 50,
      height: 50,
      color: const Color(0xFFE0F0FF),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0062FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Applicants",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applicants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.people, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "No applicants yet",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _applicants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final a = _applicants[index];
                    final firstName =
                        (a['firstName'] ?? a['name'] ?? '').toString();
                    final lastName = (a['lastName'] ?? '').toString();
                    final name = [firstName, lastName]
                        .where((s) => s.isNotEmpty)
                        .join(' ')
                        .trim();
                    final createdRaw =
                        (a['createdAt'] ?? a['appliedOn'] ?? '').toString();
                    final appliedOn = createdRaw.contains('T')
                        ? createdRaw.split('T').first
                        : createdRaw;
                    final status = (a['status'] ?? 'Pending').toString();
                    final isShortlisted = status.toLowerCase() == 'shortlisted';

                    final profilePic =
                        (a['profilePic'] ?? a['profileImage'] ?? '').toString();

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ApplicantProfilePage(
                                  applicant: a,
                                  jobId: widget.jobId,
                                ),
                              ),
                            );
                            if (result == true) {
                              _fetchApplicants();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: profilePic.isNotEmpty
                                      ? (profilePic.startsWith('http')
                                          ? Image.network(
                                              profilePic,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return _buildInitials(name);
                                              },
                                            )
                                          : Image.asset(
                                              profilePic,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return _buildInitials(name);
                                              },
                                            ))
                                      : _buildInitials(name),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name.isNotEmpty
                                            ? name
                                            : 'Unknown Candidate',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Iconsax.calendar_1,
                                              size: 14,
                                              color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            appliedOn.isNotEmpty
                                                ? appliedOn
                                                : "N/A",
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isShortlisted
                                        ? const Color(0xFFE8F5E9)
                                        : const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.isNotEmpty ? status : 'Pending',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isShortlisted
                                          ? Colors.green[700]
                                          : Colors.orange[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ----------------- ApplicantProfilePage -----------------
class ApplicantProfilePage extends StatefulWidget {
  final Map<String, dynamic> applicant;
  final String? jobId;

  const ApplicantProfilePage({
    super.key,
    required this.applicant,
    this.jobId,
  });

  @override
  State<ApplicantProfilePage> createState() => _ApplicantProfilePageState();
}

class _ApplicantProfilePageState extends State<ApplicantProfilePage> {
  bool _isLoadingProfile = true;
  DoctorProfileData? _profile;
  String? _error;

  bool _isRejecting = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profileId =
          (widget.applicant['surgeonprofile_id'] ?? '').toString().trim();
      if (profileId.isEmpty) {
        setState(() {
          _isLoadingProfile = false;
        });
        return;
      }

      final result = await ApiService.fetchProfileInfo(profileId);
      if (result['success'] == true) {
        setState(() {
          _profile = DoctorProfileData.fromMap(result['data']);
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load profile';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading profile: $e';
        _isLoadingProfile = false;
      });
    }
  }

  void _confirmReject() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: const Text(
            'Are you sure you want to reject this application? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _rejectApplication();
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectApplication() async {
    final applicationId = widget.applicant['_id']?.toString() ??
        widget.applicant['id']?.toString() ??
        '';
    final healthcareId = widget.applicant['healthcare_id']?.toString() ?? '';
    
    print('------------------------------------------------');
    print('🔴 Rejecting Application');
    print('🔴 Applicant Data: ${widget.applicant}');
    print('🔴 Application ID: $applicationId');
    print('🔴 Healthcare ID: $healthcareId');
    print('------------------------------------------------');

    if (applicationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application ID not found')),
      );
      return;
    }

    setState(() => _isRejecting = true);

    try {
      // User hint: "end params - healthcare_id"
      // Attempting to use healthcare_id in URL if available, otherwise fallback to applicationId (though that failed with 404)
      final idToUse = healthcareId.isNotEmpty ? healthcareId : applicationId;
      
      final uri = Uri.parse(
          'http://13.203.67.154:3000/api/jobs/applied-jobs/jobs-edit/$idToUse');
      
      print('🔴 Request URL: $uri');

      final body = {
        'status': 'rejected',
        'applicationId': applicationId, // Sending applicationId in body just in case
      };
      
      print('🔴 Request Body: $body');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('🔴 Response Status: ${response.statusCode}');
      print('🔴 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application rejected')),
          );
          Navigator.pop(context, true); // Go back to list with success flag
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject: ${response.statusCode}')),
          );
          setState(() => _isRejecting = false);
        }
      }
    } catch (e) {
      print('🔴 Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isRejecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        (widget.applicant['firstName'] ?? widget.applicant['name'] ?? '')
            .toString();
    final lastName = (widget.applicant['lastName'] ?? '').toString();
    final fullNameFromApp = [firstName, lastName]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();

    final createdRaw =
        (widget.applicant['createdAt'] ?? widget.applicant['appliedOn'] ?? '')
            .toString();
    final appliedOn = createdRaw.contains('T')
        ? createdRaw.split('T').first
        : createdRaw;
    final status = (widget.applicant['status'] ?? '').toString();
    print('🔍 Hospital Side - Applicant Raw: ${widget.applicant}');
    print('🔍 Hospital Side - isCvFromProfile Raw: ${widget.applicant['isCvFromProfile']}');
    
    final isCvFromProfile = (widget.applicant['isCvFromProfile'] ?? 'false').toString().toLowerCase() == 'true';
    print('🔍 Hospital Side - isCvFromProfile Parsed: $isCvFromProfile');
    
    final manualCv = (widget.applicant['cvResume'] ?? widget.applicant['resume'] ?? widget.applicant['cv'] ?? '').toString();
    print('🔍 Hospital Side - manualCv: $manualCv');
    
    final profileCv = _profile?.cv ?? '';
    print('🔍 Hospital Side - profileCv: $profileCv');

    final resume = isCvFromProfile ? profileCv : manualCv;
    final location = (widget.applicant['location'] ?? '').toString();
    final notes = (widget.applicant['notes'] ?? '').toString();

    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text("Applicant Profile",
              style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.warning_2, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Profile not found', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      );
    }

    final profile = _profile;
    final displayName =
        profile != null && profile.name.isNotEmpty ? profile.name : fullNameFromApp;
    final speciality = profile?.speciality ?? '';

    final profilePic = (profile?.profilePicture ?? widget.applicant['profilePic'] ?? widget.applicant['profileImage'] ?? '').toString();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Applicant Profile",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipOval(
                child: Container(
                  width: 100,
                  height: 100,
                  color: const Color(0xFFE0F0FF),
                  child: profilePic.isNotEmpty
                      ? (profilePic.startsWith('http')
                          ? Image.network(
                              profilePic,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0062FF),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              profilePic,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0062FF),
                                    ),
                                  ),
                                );
                              },
                            ))
                      : Center(
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: GoogleFonts.poppins(
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0062FF),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Column(
                children: [
                  Text(
                    displayName.isNotEmpty ? displayName : 'Applicant Name',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    speciality.isNotEmpty ? speciality : 'Speciality not provided',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            _infoHeader("Personal Information"),
            _infoTile(Iconsax.call, "Phone", profile?.phone),
            _infoTile(Iconsax.sms, "Email", profile?.email),
            _infoTile(Iconsax.location, "Location",
                profile?.location.isNotEmpty == true ? profile!.location : location),

            const SizedBox(height: 10),
            _infoHeader("Professional Details"),
            _infoTile(Iconsax.teacher, "Degree", profile?.degree),
            _infoTile(Iconsax.briefcase, "Sub-Speciality", profile?.subSpeciality),
            _infoTile(Iconsax.building, "Organization", profile?.organization),
            _infoTile(Iconsax.verify, "Designation", profile?.designation),
            _infoTile(Iconsax.map, "Work Location", profile?.workLocation),
            _infoTile(Iconsax.clock, "Experience", profile?.period),
            _infoTile(Iconsax.link, "Portfolio", profile?.portfolio),

            const SizedBox(height: 16),
            _infoHeader("Summary"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                profile != null && profile.summary.isNotEmpty
                    ? profile.summary
                    : "No summary provided",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),
            _infoHeader("Application Details"),
            _infoTile(Iconsax.calendar_1, "Applied On",
                appliedOn.isNotEmpty ? appliedOn : 'N/A'),
            _infoTile(Iconsax.info_circle, "Status",
                status.isNotEmpty ? status : 'N/A'),
            _infoTile(Iconsax.note, "Notes", notes.isNotEmpty ? notes : null),

            const SizedBox(height: 20),
            Text("Resume",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.document_text,
                      color: Colors.redAccent),
                ),
                title: Text(
                  resume.isNotEmpty
                      ? resume.split('/').last
                      : 'No resume uploaded',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  resume.isNotEmpty ? 'Tap to view' : 'No file available',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                onTap: () async {
                  if (resume.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening resume...')),
                    );
                    
                    String url = resume;
                    if (!url.startsWith('http')) {
                       url = 'http://13.203.67.154:3000/$url';
                    }

                    try {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        throw 'Could not launch $url';
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error opening resume: $e')),
                      );
                    }
                  }
                },
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _isRejecting ? null : _confirmReject,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isRejecting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : Text(
                        'Reject Application',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScheduleInterviewPage(
                        jobId: widget.jobId,
                        candidateId:
                            (widget.applicant['surgeonprofile_id'] ?? '')
                                .toString(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0062FF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Schedule Interview',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0062FF),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.grey[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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
}

// ----------------- ApplicantsOverview (simple) -----------------
class ApplicantsOverview extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> applicantsByJobId;
  const ApplicantsOverview({super.key, required this.applicantsByJobId});

  @override
  Widget build(BuildContext context) {
    final total = applicantsByJobId.values.fold<int>(0, (p, e) => p + e.length);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Applicants",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Total applicants across jobs: $total",
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: applicantsByJobId.entries
                    .map(
                      (e) => Card(
                        child: ListTile(
                          title: Text(e.key),
                          subtitle: Text("${e.value.length} applicants"),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ApplicantsListPage(
                                  jobId: e.key,
                                  jobTitle: e.key,
                                  applicants: e.value,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- PostJobPlaceholder -----------------
class PostJobPlaceholder extends StatelessWidget {
  const PostJobPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text("Post Job (placeholder)")));
  }
}

// ----------------- InterviewsPlaceholder -----------------
class InterviewsPlaceholder extends StatelessWidget {
  final void Function(BuildContext) onScheduleInterview;
  const InterviewsPlaceholder({super.key, required this.onScheduleInterview});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Text(
            "Interviews",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => onScheduleInterview(context),
            child: const Text("Schedule Interview (global)"),
          ),
        ],
      ),
    );
  }
}
                                    