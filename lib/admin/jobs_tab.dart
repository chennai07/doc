import 'package:flutter/material.dart';

/// JobsTab displays the list of all jobs for admin management.
/// This is a placeholder that will be expanded with actual functionality.
class JobsTab extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const JobsTab({super.key, required this.adminData});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    
    // TODO: Implement API call to fetch jobs list
    // For now, using placeholder data
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _isLoading = false;
      _jobs = []; // Will be populated from API
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadJobs,
      color: const Color(0xFF1E3A5F),
      child: Column(
        children: [
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
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: Show filter options
                    },
                    icon: const Icon(
                      Icons.filter_list,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStatCard(
                  icon: Icons.work,
                  label: 'Total Jobs',
                  value: '0',
                  color: const Color(0xFF1E3A5F),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.check_circle,
                  label: 'Active',
                  value: '0',
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.pending,
                  label: 'Pending',
                  value: '0',
                  color: Colors.orange,
                ),
              ],
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
                : _jobs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _jobs.length,
                        itemBuilder: (context, index) {
                          return _buildJobCard(_jobs[index]);
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
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
          const Text(
            'Jobs Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor and manage all job postings.\nPull down to refresh.',
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
    final title = job['title'] ?? job['jobTitle'] ?? 'Untitled Job';
    final hospital = job['hospitalName'] ?? job['postedBy'] ?? '';
    final location = job['location'] ?? '';
    final status = job['status'] ?? 'active';
    final postedDate = job['createdAt'] ?? job['postedDate'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Job Icon
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.work,
                  color: Color(0xFF1976D2),
                  size: 22,
                ),
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
                    ),
                    if (hospital.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        hospital,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (postedDate.isNotEmpty) ...[
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    postedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return const Color(0xFF1E3A5F);
    }
  }
}
