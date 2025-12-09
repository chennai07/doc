import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/hospital/JobDetailsScreen.dart';
import 'package:doc/admin/surgeon_profile_screen.dart';

/// AdminJobDetailsScreen displays detailed information about a job posting.
class AdminJobDetailsScreen extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic>? initialData;

  const AdminJobDetailsScreen({
    super.key,
    required this.jobId,
    this.initialData,
  });

  @override
  State<AdminJobDetailsScreen> createState() => _AdminJobDetailsScreenState();
}

class _AdminJobDetailsScreenState extends State<AdminJobDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _jobData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _jobData = Map<String, dynamic>.from(widget.initialData!);
    }
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
          'http://13.203.67.154:3000/api/healthcare/job-profile/${widget.jobId}');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? body['job'] ?? body;

        setState(() {
          if (data is Map) {
            _jobData = Map<String, dynamic>.from(data);
          }
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load job details';
        });
      }
    } catch (e) {
      debugPrint('Error loading job details: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading job details: $e';
      });
    }
  }

  void _navigateToApplicants() {
    final jobId = _jobData['_id'] ?? widget.jobId;
    final jobTitle = _jobData['jobTitle'] ?? 'Job';
    final jobStatus = _jobData['status'] ?? 'active';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminApplicantsListPage(
          jobId: jobId,
          jobTitle: jobTitle,
          jobStatus: jobStatus,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Job Header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF1976D2),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _loadJobDetails,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildJobHeader(),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: _isLoading && _jobData.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  )
                : _errorMessage != null && _jobData.isEmpty
                    ? _buildErrorState()
                    : _buildJobDetails(),
          ),
        ],
      ),
      // Sticky View Applicants Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _navigateToApplicants,
              icon: const Icon(Icons.people, size: 22),
              label: const Text(
                'View Applicants',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobHeader() {
    final title = _jobData['jobTitle'] ?? 'Loading...';
    final hospital = _jobData['hospitalName'] ?? '';
    final status = (_jobData['status'] ?? 'active').toString().toLowerCase();
    final logo = _jobData['hospitalLogo'] ?? '';
    final jobType = _jobData['jobType'] ?? '';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1976D2),
            Color(0xFF2196F3),
            Color(0xFF42A5F5),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Hospital Logo
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: logo.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(logo),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                child: logo.isEmpty
                    ? const Icon(
                        Icons.work,
                        color: Color(0xFF1976D2),
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              // Job Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (hospital.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  hospital,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 12),
              // Status and Job Type Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (jobType.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        jobType,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'closed':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadJobDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetails() {
    final department = _jobData['department'] ?? '';
    final subSpeciality = _jobData['subSpeciality'] ?? '';
    final location = _jobData['location'] ?? '';
    final aboutRole = _jobData['aboutRole'] ?? '';
    final keyResponsibilities = _jobData['keyResponsibilities'] ?? '';
    final preferredQualifications = _jobData['preferredQualifications'] ?? '';
    final minExperience = _jobData['minYearsOfExperience'];
    final salaryRange = _jobData['salaryRange'] ?? '';
    final interviewMode = _jobData['interviewMode'] ?? '';
    final deadline = _jobData['applicationDeadline'] ?? '';
    final healthcareId = _jobData['healthcare_id'] ?? '';
    final createdAt = _jobData['createdAt'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Info Card
          _buildSectionCard(
            title: 'Job Information',
            icon: Icons.info_outline,
            iconColor: const Color(0xFF1976D2),
            children: [
              if (department.isNotEmpty)
                _buildInfoRow(Icons.medical_services_outlined, 'Department', department),
              if (subSpeciality.isNotEmpty)
                _buildInfoRow(Icons.category_outlined, 'Sub-Speciality', subSpeciality),
              if (location.isNotEmpty)
                _buildInfoRow(Icons.location_on_outlined, 'Location', location),
              if (minExperience != null)
                _buildInfoRow(Icons.timeline, 'Min. Experience', '$minExperience years'),
              if (salaryRange.isNotEmpty)
                _buildInfoRow(Icons.payments_outlined, 'Salary Range', salaryRange),
              if (interviewMode.isNotEmpty)
                _buildInfoRow(Icons.video_camera_front_outlined, 'Interview Mode', interviewMode),
            ],
          ),
          const SizedBox(height: 16),

          // Deadline Card
          if (deadline.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDeadlinePassed(deadline)
                    ? Colors.red.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isDeadlinePassed(deadline)
                      ? Colors.red.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isDeadlinePassed(deadline)
                          ? Colors.red.withOpacity(0.15)
                          : Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: _isDeadlinePassed(deadline) ? Colors.red : Colors.orange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application Deadline',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(deadline),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isDeadlinePassed(deadline) ? Colors.red : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_isDeadlinePassed(deadline))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'EXPIRED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // About Role Card
          if (aboutRole.isNotEmpty) ...[
            _buildSectionCard(
              title: 'About the Role',
              icon: Icons.description_outlined,
              iconColor: const Color(0xFF7B1FA2),
              children: [
                Text(
                  aboutRole,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Key Responsibilities Card
          if (keyResponsibilities.isNotEmpty) ...[
            _buildSectionCard(
              title: 'Key Responsibilities',
              icon: Icons.checklist_outlined,
              iconColor: const Color(0xFF2E7D32),
              children: [
                Text(
                  keyResponsibilities,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Qualifications Card
          if (preferredQualifications.isNotEmpty) ...[
            _buildSectionCard(
              title: 'Preferred Qualifications',
              icon: Icons.school_outlined,
              iconColor: const Color(0xFFE65100),
              children: [
                Text(
                  preferredQualifications,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Meta Information Card
          _buildSectionCard(
            title: 'Additional Information',
            icon: Icons.settings_outlined,
            iconColor: Colors.grey.shade600,
            children: [
              if (createdAt.isNotEmpty)
                _buildInfoRow(Icons.calendar_today_outlined, 'Posted On', _formatDate(createdAt)),
            ],
          ),
          const SizedBox(height: 100), // Extra space for bottom button
        ],
      ),
    );
  }

  bool _isDeadlinePassed(String deadline) {
    try {
      final dt = DateTime.parse(deadline);
      return dt.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return date.toString();
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final filteredChildren = children.where((w) => w is! SizedBox || (w as SizedBox).height != 0).toList();

    if (filteredChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...filteredChildren,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1E3A5F),
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

/// AdminApplicantsListPage displays the list of applicants for a job in admin view.
class AdminApplicantsListPage extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String? jobStatus;

  const AdminApplicantsListPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
    this.jobStatus,
  });

  @override
  State<AdminApplicantsListPage> createState() => _AdminApplicantsListPageState();
}

class _AdminApplicantsListPageState extends State<AdminApplicantsListPage> {
  List<Map<String, dynamic>> _applicants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchApplicants();
  }

  Future<void> _fetchApplicants() async {
    setState(() => _isLoading = true);
    
    try {
      final uri = Uri.parse(
        'http://13.203.67.154:3000/api/jobs/applied-jobs/specific-jobs/${widget.jobId}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

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
          
          // Extract profile data
          final profileData = m['applicant'] is Map 
              ? m['applicant'] as Map 
              : (m['applicant'] == null ? m : <String, dynamic>{});
          
          // Create a mutable map starting with profile data
          final merged = Map<String, dynamic>.from(profileData);
          
          // Add application-level fields
          if (m.containsKey('status')) merged['status'] = m['status'];
          if (m.containsKey('createdAt')) merged['appliedOn'] = m['createdAt'];
          if (m.containsKey('_id')) merged['applicationId'] = m['_id'];
          
          // Capture surgeonprofile_id for navigation to surgeon profile
          if (m.containsKey('surgeonprofile_id')) {
            merged['surgeonprofile_id'] = m['surgeonprofile_id'];
          } else if (m.containsKey('surgeonProfileId')) {
            merged['surgeonprofile_id'] = m['surgeonProfileId'];
          } else if (profileData is Map && profileData.containsKey('_id')) {
            merged['surgeonprofile_id'] = profileData['_id'];
          }
          
          applicants.add(merged);
        }

        if (mounted) {
          setState(() {
            _applicants = applicants;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No job applicants found';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching applicants: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  void _navigateToSurgeonProfile(Map<String, dynamic> applicant) {
    final surgeonProfileId = (applicant['surgeonprofile_id'] ?? '').toString().trim();
    
    if (surgeonProfileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Surgeon profile ID not found')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurgeonProfileScreen(
          profileId: surgeonProfileId,
          initialData: applicant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Applicants',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.jobTitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchApplicants,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A5F),
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _applicants.isEmpty
                  ? _buildEmptyState()
                  : _buildApplicantsList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchApplicants,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 50,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Applicants Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantsList() {
    return RefreshIndicator(
      onRefresh: _fetchApplicants,
      color: const Color(0xFF1E3A5F),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _applicants.length,
        itemBuilder: (context, index) {
          return _buildApplicantCard(_applicants[index]);
        },
      ),
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> applicant) {
    // Extract name fields
    final firstName = (applicant['firstName'] ?? applicant['fullName'] ?? applicant['name'] ?? '').toString();
    final lastName = (applicant['lastName'] ?? '').toString();
    final name = [firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();
    
    final email = (applicant['email'] ?? '').toString();
    final phone = (applicant['phoneNumber'] ?? '').toString();
    final speciality = (applicant['speciality'] ?? '').toString();
    final experience = applicant['yearsOfExperience'];
    final status = (applicant['status'] ?? 'Applied').toString();
    final profilePic = (applicant['profilePicture'] ?? applicant['profilePic'] ?? '').toString();
    final appliedOn = (applicant['appliedOn'] ?? '').toString();
    
    // Format applied date
    String formattedDate = '';
    if (appliedOn.isNotEmpty && appliedOn.contains('T')) {
      formattedDate = appliedOn.split('T').first;
    } else {
      formattedDate = appliedOn;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToSurgeonProfile(applicant),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Picture
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F).withOpacity(0.1),
                    shape: BoxShape.circle,
                    image: profilePic.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(profilePic),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                  ),
                  child: profilePic.isEmpty
                      ? Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Color(0xFF1E3A5F),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Unknown Applicant',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      if (speciality.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          speciality,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (formattedDate.isNotEmpty) ...[
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Applied: $formattedDate',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                          if (experience != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.work_outline,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$experience yrs',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return Colors.blue;
      case 'shortlisted':
        return Colors.orange;
      case 'interview scheduled':
        return Colors.purple;
      case 'selected':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
