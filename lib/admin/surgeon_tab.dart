import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/admin/surgeon_profile_screen.dart';

/// SurgeonTab displays the list of surgeons for admin management.
class SurgeonTab extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const SurgeonTab({super.key, required this.adminData});

  @override
  State<SurgeonTab> createState() => _SurgeonTabState();
}

class _SurgeonTabState extends State<SurgeonTab> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _surgeons = [];
  List<Map<String, dynamic>> _filteredSurgeons = [];
  int _totalCount = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filter options
  String _selectedSpeciality = 'All';
  String _selectedState = 'All';
  final List<String> _specialities = [
    'All',
    'General Surgery',
    'Neurosurgery',
    'Cardiothoracic Surgery',
    'Orthopedic Surgery',
    'Plastic Surgery',
    'Pediatric Surgery',
    'Urology',
    'Oncology Surgery',
  ];
  List<String> _states = ['All'];

  @override
  void initState() {
    super.initState();
    _loadSurgeons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSurgeons() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://13.203.67.154:3000/api/admin/surgeons');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        final total = body['total'] ?? 0;

        setState(() {
          _totalCount = total is int ? total : int.tryParse(total.toString()) ?? 0;
          if (data is List) {
            _surgeons = data.map((e) => Map<String, dynamic>.from(e)).toList();
            // Extract unique states for filter
            final statesSet = <String>{'All'};
            for (var surgeon in _surgeons) {
              final state = (surgeon['state'] ?? '').toString();
              if (state.isNotEmpty) statesSet.add(state);
            }
            _states = statesSet.toList()..sort();
            if (_states.first != 'All') {
              _states.remove('All');
              _states.insert(0, 'All');
            }
          } else {
            _surgeons = [];
          }
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _surgeons = [];
          _filteredSurgeons = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load surgeons')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading surgeons: $e');
      setState(() {
        _isLoading = false;
        _surgeons = [];
        _filteredSurgeons = [];
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
      _filteredSurgeons = _surgeons.where((surgeon) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final name = (surgeon['fullName'] ?? surgeon['name'] ?? '').toString().toLowerCase();
          final email = (surgeon['email'] ?? '').toString().toLowerCase();
          final speciality = (surgeon['speciality'] ?? '').toString().toLowerCase();
          final phone = (surgeon['phoneNumber'] ?? '').toString().toLowerCase();
          final state = (surgeon['state'] ?? '').toString().toLowerCase();
          final district = (surgeon['district'] ?? '').toString().toLowerCase();

          final matchesSearch = name.contains(_searchQuery) ||
              email.contains(_searchQuery) ||
              speciality.contains(_searchQuery) ||
              phone.contains(_searchQuery) ||
              state.contains(_searchQuery) ||
              district.contains(_searchQuery);

          if (!matchesSearch) return false;
        }

        // Speciality filter
        if (_selectedSpeciality != 'All') {
          final speciality = (surgeon['speciality'] ?? '').toString();
          if (speciality != _selectedSpeciality) return false;
        }

        // State filter
        if (_selectedState != 'All') {
          final state = (surgeon['state'] ?? '').toString();
          if (state != _selectedState) return false;
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
          height: MediaQuery.of(context).size.height * 0.6,
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
                          _selectedSpeciality = 'All';
                          _selectedState = 'All';
                        });
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
                      // Speciality Filter
                      const Text(
                        'Speciality',
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
                        children: _specialities.map((speciality) {
                          final isSelected = _selectedSpeciality == speciality;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => _selectedSpeciality = speciality);
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
                                speciality,
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
                      // State Filter
                      const Text(
                        'State',
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
                        children: _states.map((state) {
                          final isSelected = _selectedState == state;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => _selectedState = state);
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
                                state,
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

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _selectedSpeciality != 'All' || _selectedState != 'All';
    
    return RefreshIndicator(
      onRefresh: _loadSurgeons,
      color: const Color(0xFF1E3A5F),
      child: Column(
        children: [
          // Stats Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                // Total Surgeons Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1E3A5F),
                          Color(0xFF2E5077),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A5F).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.medical_services,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Surgeons',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLoading ? '...' : _totalCount.toString(),
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                        hintText: 'Search surgeons...',
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
                        ? const Color(0xFF2E7D32)
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
          if (!_isLoading && _surgeons.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                _searchQuery.isEmpty && !hasActiveFilters
                    ? 'Showing ${_filteredSurgeons.length} surgeons'
                    : 'Found ${_filteredSurgeons.length} of ${_surgeons.length} surgeons',
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
                : _filteredSurgeons.isEmpty
                    ? _buildEmptyState(hasActiveFilters)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSurgeons.length,
                        itemBuilder: (context, index) {
                          return _buildSurgeonCard(_filteredSurgeons[index]);
                        },
                      ),
          ),
        ],
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
              Icons.medical_services_outlined,
              size: 60,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || hasFilters
                ? 'No Results Found'
                : 'No Surgeons Found',
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

  Widget _buildSurgeonCard(Map<String, dynamic> surgeon) {
    final name = surgeon['fullName'] ?? surgeon['name'] ?? 'Unknown';
    final email = surgeon['email'] ?? '';
    final phone = surgeon['phoneNumber'] ?? '';
    final speciality = surgeon['speciality'] ?? '';
    final subSpeciality = surgeon['subSpeciality'] ?? '';
    final degree = surgeon['degree'] ?? '';
    final state = surgeon['state'] ?? '';
    final district = surgeon['district'] ?? '';
    final profilePicture = surgeon['profilePicture'] ?? '';
    final experience = surgeon['yearsOfExperience'];

    String locationText = '';
    if (district.isNotEmpty && state.isNotEmpty) {
      locationText = '$district, $state';
    } else if (state.isNotEmpty) {
      locationText = state;
    } else if (district.isNotEmpty) {
      locationText = district;
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
          onTap: () => _showSurgeonDetails(surgeon),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F).withOpacity(0.1),
                        shape: BoxShape.circle,
                        image: profilePicture.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(profilePicture),
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                      ),
                      child: profilePicture.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Color(0xFF1E3A5F),
                              size: 28,
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
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          if (degree.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              degree,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (speciality.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subSpeciality.isNotEmpty
                                  ? '$speciality • $subSpeciality'
                                  : speciality,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Experience badge
                    if (experience != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A5F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$experience yrs',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1E3A5F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Contact Info Row
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (email.isNotEmpty)
                      _buildInfoChip(Icons.email_outlined, email),
                    if (phone.toString().isNotEmpty)
                      _buildInfoChip(Icons.phone_outlined, phone.toString()),
                    if (locationText.isNotEmpty)
                      _buildInfoChip(Icons.location_on_outlined, locationText),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showSurgeonDetails(Map<String, dynamic> surgeon) {
    final profileId = (surgeon['profile_id'] ??
            surgeon['profileId'] ??
            surgeon['_id'] ??
            surgeon['id'] ??
            '')
        .toString();

    if (profileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load surgeon profile')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurgeonProfileScreen(
          profileId: profileId,
          initialData: surgeon,
        ),
      ),
    );
  }
}
