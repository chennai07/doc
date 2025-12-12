import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/admin/job_details_screen.dart';

/// JobsTab displays the list of all jobs for admin management.
class JobsTab extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const JobsTab({super.key, required this.adminData});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _filteredJobs = [];
  int _totalCount = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filter options
  String _selectedStatus = 'All';
  String _selectedJobType = 'All';
  final List<String> _statuses = ['All', 'active', 'closed', 'expired'];
  final List<String> _jobTypes = ['All', 'Full Time', 'Part Time', 'Contract', 'Locum'];

  // Stats
  int _activeCount = 0;
  int _closedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://13.203.67.154:3000/api/admin/joblist');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        final total = body['total'] ?? 0;

        setState(() {
          if (data is List) {
            _jobs = data.map((e) => Map<String, dynamic>.from(e)).toList();
            // Calculate all stats from actual data in frontend
            _totalCount = _jobs.length;
            _activeCount = _jobs.where((j) => j['status']?.toString().toLowerCase() == 'active').length;
            _closedCount = _jobs.where((j) {
              final status = j['status']?.toString().toLowerCase() ?? '';
              return status == 'closed' || status == 'job filled';
            }).length;
          } else {
            _jobs = [];
            _totalCount = 0;
            _activeCount = 0;
            _closedCount = 0;
          }
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _jobs = [];
          _filteredJobs = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load jobs')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading jobs: $e');
      setState(() {
        _isLoading = false;
        _jobs = [];
        _filteredJobs = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredJobs = _jobs.where((job) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final title = (job['jobTitle'] ?? '').toString().toLowerCase();
          final hospital = (job['hospitalName'] ?? '').toString().toLowerCase();
          final department = (job['department'] ?? '').toString().toLowerCase();
          final state = (job['state'] ?? '').toString().toLowerCase();
          final district = (job['district'] ?? '').toString().toLowerCase();

          final matchesSearch = title.contains(_searchQuery) ||
              hospital.contains(_searchQuery) ||
              department.contains(_searchQuery) ||
              state.contains(_searchQuery) ||
              district.contains(_searchQuery);

          if (!matchesSearch) return false;
        }

        // Status filter
        if (_selectedStatus != 'All') {
          final status = (job['status'] ?? '').toString().toLowerCase();
          if (status != _selectedStatus.toLowerCase()) return false;
        }

        // Job Type filter
        if (_selectedJobType != 'All') {
          final jobType = (job['jobType'] ?? '').toString();
          if (jobType != _selectedJobType) return false;
        }

        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Filter Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedStatus = 'All';
                          _selectedJobType = 'All';
                        });
                        Navigator.pop(context);
                        setState(() {});
                        _applyFilters();
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Filter
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _statuses.map((status) {
                          final isSelected = _selectedStatus == status;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => _selectedStatus = status);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _getStatusColor(status)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? _getStatusColor(status)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                status == 'All' ? 'All' : status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Job Type Filter
                      const Text(
                        'Job Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _jobTypes.map((type) {
                          final isSelected = _selectedJobType == type;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => _selectedJobType = type);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1E3A5F)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1E3A5F)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              // Apply Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                      _applyFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
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
        return const Color(0xFF1E3A5F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _selectedStatus != 'All' || _selectedJobType != 'All';

    return RefreshIndicator(
      onRefresh: _loadJobs,
      color: const Color(0xFF1E3A5F),
      child: Column(
        children: [
          // Stats Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                _buildStatCard(
                  icon: Icons.work,
                  label: 'Total Jobs',
                  value: _isLoading ? '...' : _totalCount.toString(),
                  color: const Color(0xFF1E3A5F),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.check_circle,
                  label: 'Active',
                  value: _isLoading ? '...' : _activeCount.toString(),
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.cancel,
                  label: 'Closed',
                  value: _isLoading ? '...' : _closedCount.toString(),
                  color: Colors.red,
                ),
              ],
            ),
          ),
          // Search and Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search jobs...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade500,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: hasActiveFilters
                        ? Colors.green
                        : const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      IconButton(
                        onPressed: _showFilterDialog,
                        icon: const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      if (hasActiveFilters)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Results count
          if (!_isLoading && _jobs.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                _searchQuery.isEmpty && !hasActiveFilters
                    ? 'Showing ${_filteredJobs.length} jobs'
                    : 'Found ${_filteredJobs.length} of ${_jobs.length} jobs',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // Content Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E3A5F),
                    ),
                  )
                : _filteredJobs.isEmpty
                    ? _buildEmptyState(hasActiveFilters)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredJobs.length,
                        itemBuilder: (context, index) {
                          return _buildJobCard(_filteredJobs[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState(bool hasFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.work_outline,
              size: 60,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || hasFilters
                ? 'No Results Found'
                : 'No Jobs Found',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || hasFilters
                ? 'Try adjusting your filters'
                : 'Pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final title = job['jobTitle'] ?? 'Untitled Job';
    final hospital = job['hospitalName'] ?? '';
    
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
      location = job['location'] ?? ''; // Fallback for old jobs
    }
    
    final department = job['department'] ?? '';
    final jobType = job['jobType'] ?? '';
    final status = (job['status'] ?? 'active').toString().toLowerCase();
    final salary = job['salaryRange'] ?? '';
    final deadline = job['applicationDeadline'] ?? '';
    final logo = job['hospitalLogo'] ?? '';
    final experience = job['minYearsOfExperience'];

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
          onTap: () => _navigateToJobDetails(job),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Hospital Logo
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
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
                              size: 24,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Job Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A5F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hospital.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              hospital,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Status Badge
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
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Tags Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (department.isNotEmpty)
                      _buildTag(Icons.medical_services_outlined, department),
                    if (jobType.isNotEmpty)
                      _buildTag(Icons.schedule_outlined, jobType),
                    if (experience != null)
                      _buildTag(Icons.timeline, '$experience+ years'),
                  ],
                ),
                const SizedBox(height: 12),
                // Bottom Row
                Row(
                  children: [
                    if (location.isNotEmpty) ...[
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (salary.isNotEmpty) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          salary,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (deadline.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Deadline: ${_formatDate(deadline)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: const Color(0xFF1E3A5F),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF1E3A5F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return date.toString();
    }
  }

  void _navigateToJobDetails(Map<String, dynamic> job) {
    final jobId = (job['_id'] ?? job['id'] ?? '').toString();

    if (jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load job details')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminJobDetailsScreen(
          jobId: jobId,
          initialData: job,
        ),
      ),
    );
  }
}
