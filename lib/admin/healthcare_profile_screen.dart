import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// HealthcareProfileScreen displays detailed information about a hospital/healthcare.
class HealthcareProfileScreen extends StatefulWidget {
  final String healthcareId;
  final Map<String, dynamic>? initialData;

  const HealthcareProfileScreen({
    super.key,
    required this.healthcareId,
    this.initialData,
  });

  @override
  State<HealthcareProfileScreen> createState() => _HealthcareProfileScreenState();
}

class _HealthcareProfileScreenState extends State<HealthcareProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _profileData = Map<String, dynamic>.from(widget.initialData!);
    }
    _loadProfileDetails();
  }

  Future<void> _loadProfileDetails() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
          'http://13.203.67.154:3000/api/healthcare/healthcare-profile/${widget.healthcareId}');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? body['profile'] ?? body;

        setState(() {
          if (data is Map) {
            _profileData = Map<String, dynamic>.from(data);
          }
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load hospital profile';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading profile: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Profile Header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
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
                onPressed: _loadProfileDetails,
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
              background: _buildProfileHeader(),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: _isLoading && _profileData.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  )
                : _errorMessage != null && _profileData.isEmpty
                    ? _buildErrorState()
                    : _buildProfileDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _profileData['hospitalName'] ?? _profileData['name'] ?? 'Loading...';
    final category = _profileData['facilityCategory'] ?? '';
    final logo = _profileData['hospitalLogo'] ?? '';
    final isKYCVerified = _profileData['isKYCVerified'] == true;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF43A047),
            Color(0xFF66BB6A),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Hospital Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
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
                      Icons.local_hospital,
                      color: Color(0xFF2E7D32),
                      size: 45,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            // Hospital Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (category.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (isKYCVerified) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'KYC Verified',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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
              onPressed: _loadProfileDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
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

  Widget _buildProfileDetails() {
    final email = _profileData['email'] ?? '';
    final phone = _profileData['phoneNumber'] ?? '';
    final location = _profileData['location'] ?? '';
    final overview = _profileData['hospitalOverview'] ?? '';
    final website = _profileData['hospitalWebsite'] ?? '';
    final departments = _profileData['departmentsAvailable'] ?? [];
    final hrContact = _profileData['hrContact'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Information Card
          _buildSectionCard(
            title: 'Contact Information',
            icon: Icons.contact_phone,
            iconColor: const Color(0xFF2E7D32),
            children: [
              if (email.isNotEmpty)
                _buildInfoRow(Icons.email_outlined, 'Email', email),
              if (phone.toString().isNotEmpty)
                _buildInfoRow(Icons.phone_outlined, 'Phone', phone.toString()),
              if (location.isNotEmpty)
                _buildInfoRow(Icons.location_on_outlined, 'Location', location),
              if (website.isNotEmpty)
                _buildInfoRow(Icons.language_outlined, 'Website', website),
            ],
          ),
          const SizedBox(height: 16),

          // Departments Card
          if (departments is List && departments.isNotEmpty) ...[
            _buildSectionCard(
              title: 'Departments Available',
              icon: Icons.medical_services,
              iconColor: const Color(0xFF1976D2),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: departments.map<Widget>((dept) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1976D2).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        dept.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Hospital Overview Card
          if (overview.isNotEmpty) ...[
            _buildSectionCard(
              title: 'Hospital Overview',
              icon: Icons.info_outline,
              iconColor: const Color(0xFF7B1FA2),
              children: [
                Text(
                  overview,
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

          // HR Contact Card
          if (hrContact != null && hrContact is Map) ...[
            _buildSectionCard(
              title: 'HR Contact',
              icon: Icons.person_outline,
              iconColor: const Color(0xFFE65100),
              children: [
                if ((hrContact['fullName'] ?? '').toString().isNotEmpty)
                  _buildInfoRow(Icons.person, 'Name', hrContact['fullName']),
                if ((hrContact['designation'] ?? '').toString().isNotEmpty)
                  _buildInfoRow(Icons.badge_outlined, 'Designation', hrContact['designation']),
                if ((hrContact['mobileNumber'] ?? '').toString().isNotEmpty)
                  _buildInfoRow(Icons.phone_outlined, 'Mobile', hrContact['mobileNumber']),
                if ((hrContact['email'] ?? '').toString().isNotEmpty)
                  _buildInfoRow(Icons.email_outlined, 'Email', hrContact['email']),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Account Information Card
          _buildSectionCard(
            title: 'Account Information',
            icon: Icons.settings_outlined,
            iconColor: Colors.grey.shade600,
            children: [
              _buildInfoRow(
                Icons.verified_user_outlined,
                'KYC Status',
                _profileData['isKYCVerified'] == true ? 'Verified' : 'Pending Verification',
              ),
              if (_profileData['healthcare_id'] != null)
                _buildInfoRow(Icons.tag, 'Healthcare ID', _profileData['healthcare_id'].toString()),
              if (_profileData['createdAt'] != null)
                _buildInfoRow(Icons.calendar_today_outlined, 'Registered On', _formatDate(_profileData['createdAt'])),
            ],
          ),
          const SizedBox(height: 20),
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
