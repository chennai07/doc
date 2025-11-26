import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:doc/profileprofile/surgeon_profile.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/homescreen/job_details_screen.dart';
import 'package:doc/homescreen/Applied_Jobs.dart';
import '../utils/colors.dart';
import '../widgets/job_card.dart';
import '../widgets/section_header.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _filteredJobs = [];

  bool _isLoading = true;
  String? _error;

  // Active filters
  String? selectedLocation;
  String? selectedSpeciality;
  List<String> selectedTypes = [];
  double minSalary = 10;
  double maxSalary = 70;

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
      final url = Uri.parse(
          'http://13.203.67.154:3000/api/healthcare/joblist-surgeons');
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

          final salaryRange = m['salaryRange']?.toString() ?? '';
          double salaryValue = 0;
          final match = RegExp(r'(\d[\d,]*)').firstMatch(salaryRange);
          if (match != null) {
            final cleaned = match.group(1)!.replaceAll(',', '');
            final parsed = double.tryParse(cleaned);
            if (parsed != null) {
              salaryValue = parsed / 100000;
            }
          }

          final rawApplicants = m['applicants'] ?? m['applicationsCount'];
          final applicantsLabel = rawApplicants == null
              ? ''
              : '${rawApplicants.toString()} Applicants';

          final rawExperience =
              m['experience'] ?? m['minYearsOfExperience'];
          String experienceLabel = '';
          if (rawExperience != null) {
            final value = rawExperience.toString().trim();
            if (value.isNotEmpty) {
              // e.g. "5" -> "5 Years"
              experienceLabel =
                  value.contains('year') ? value : '$value Years';
            }
          }

          jobs.add({
            'id': (m['_id'] ?? m['id'] ?? '').toString(),
            'title': m['jobTitle']?.toString() ?? '',
            'org': m['healthcareName']?.toString() ??
                m['hospitalName']?.toString() ??
                m['healthcareOrganization']?.toString() ??
                '',
            'location': m['location']?.toString() ?? '',
            'applicants': applicantsLabel,
            'logo': 'assets/logo2.png',
            'type': m['jobType']?.toString() ?? '',
            'speciality': m['department']?.toString() ??
                m['subSpeciality']?.toString() ??
                '',
            // Nicely formatted experience text for JobCard chip
            'experience': experienceLabel,
            'description': m['aboutRole']?.toString() ??
                m['description']?.toString() ??
                '',
            'salary': salaryValue,
          });
        }

        setState(() {
          _jobs = jobs;
          _filteredJobs = jobs;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load jobs (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading jobs: $e';
        _isLoading = false;
      });
    }
  }

  /// 🔍 Search bar filter
  void _filterJobs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredJobs = _jobs;
      } else {
        _filteredJobs = _jobs
            .where(
              (job) =>
                  job["title"].toLowerCase().contains(query.toLowerCase()) ||
                  job["org"].toLowerCase().contains(query.toLowerCase()) ||
                  job["location"].toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  /// 🎯 Apply filters
  void _applyFilters({
    String? location,
    String? speciality,
    List<String>? types,
    double? minSalary,
    double? maxSalary,
  }) {
    setState(() {
      selectedLocation = location;
      selectedSpeciality = speciality;
      selectedTypes = types ?? [];
      this.minSalary = minSalary ?? this.minSalary;
      this.maxSalary = maxSalary ?? this.maxSalary;

      _filteredJobs = _jobs.where((job) {
        final locMatch = location == null || location.isEmpty
            ? true
            : job["location"] == location;
        final specMatch = speciality == null || speciality.isEmpty
            ? true
            : job["speciality"] == speciality;
        final typeMatch = types == null || types.isEmpty
            ? true
            : types.contains(job["type"]);
        final salaryMatch =
            job["salary"] >= this.minSalary && job["salary"] <= this.maxSalary;
        return locMatch && specMatch && typeMatch && salaryMatch;
      }).toList();
    });
  }

  /// 🧠 Open popup
  void _showFilterDialog() async {
    final filters = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => FilterDialogContent(
        currentLocation: selectedLocation,
        currentSpeciality: selectedSpeciality,
        currentTypes: selectedTypes,
        currentMinSalary: minSalary,
        currentMaxSalary: maxSalary,
      ),
    );

    if (filters != null) {
      _applyFilters(
        location: filters['location'],
        speciality: filters['speciality'],
        types: filters['types'],
        minSalary: filters['minSalary'],
        maxSalary: filters['maxSalary'],
      );
    }
  }

  /// 🧹 Clear all filters
  void _clearAllFilters() {
    setState(() {
      selectedLocation = null;
      selectedSpeciality = null;
      selectedTypes.clear();
      minSalary = 10;
      maxSalary = 70;
      _filteredJobs = _jobs;
    });
  }

  bool _hasActiveFilters() {
    return selectedLocation != null ||
        selectedSpeciality != null ||
        selectedTypes.isNotEmpty ||
        minSalary > 10 ||
        maxSalary < 70;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            /// ✅ Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Image.asset('assets/logo.png', height: 80)),
                    const SizedBox(height: 10),
                    _buildSearchBar(),
                    const SizedBox(height: 15),
                    _buildFilterRow(),
                    const SizedBox(height: 15),

                    if (_hasActiveFilters()) _buildFilterChips(),
                    const SizedBox(height: 25),

                    SectionHeader(title: "${_filteredJobs.length} Results"),
                    const SizedBox(height: 10),

                    _filteredJobs.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(
                              child: Text(
                                "No jobs found",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: _filteredJobs.map((job) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: JobCard(
                                  title: job["title"],
                                  org: job["org"],
                                  location: job["location"],
                                  applicants: job["applicants"],
                                  logo: job["logo"],
                                  speciality: job["speciality"] ?? '',
                                  jobType: job["type"] ?? '',
                                  experience: job["experience"] ?? '',
                                  description: job["description"] ?? '',
                                  onTap: () {
                                    final id = (job['id'] ?? '').toString();
                                    if (id.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Job id missing. Please try another job.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => JobDetailsScreen(
                                          jobId: id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 100), // space for sticky button
                  ],
                ),
              ),
            ),

            /// 🧲 Sticky "Clear All Filters" Button
            if (_hasActiveFilters())
              Positioned(
                bottom: 15,
                left: 20,
                right: 20,
                child: ElevatedButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(
                    Iconsax.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    "Clear All Filters",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                ),
              ),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (_error != null && !_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
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
            _bottomNavItem(Iconsax.search_normal, "Search", true, () {}),
            _bottomNavItem(Iconsax.document, "Applied Jobs", false, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppliedJobsScreen(),
                ),
              );
            }),
            _bottomNavItem(Iconsax.user, "Profile", false, () async {
              final profileId = await SessionManager.getProfileId();
              if (!mounted) return;
              if (profileId == null || profileId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile not found. Please complete your profile.'),
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

  /// 🌟 Filter Chips Row
  Widget _buildFilterChips() {
    final List<Widget> chips = [];

    if (selectedLocation != null) {
      chips.add(
        _filterChip(selectedLocation!, () {
          setState(() => selectedLocation = null);
          _applyFilters(
            location: null,
            speciality: selectedSpeciality,
            types: selectedTypes,
            minSalary: minSalary,
            maxSalary: maxSalary,
          );
        }),
      );
    }

    if (selectedSpeciality != null) {
      chips.add(
        _filterChip(selectedSpeciality!, () {
          setState(() => selectedSpeciality = null);
          _applyFilters(
            location: selectedLocation,
            speciality: null,
            types: selectedTypes,
            minSalary: minSalary,
            maxSalary: maxSalary,
          );
        }),
      );
    }

    for (final type in selectedTypes) {
      chips.add(
        _filterChip(type, () {
          setState(() => selectedTypes.remove(type));
          _applyFilters(
            location: selectedLocation,
            speciality: selectedSpeciality,
            types: selectedTypes,
            minSalary: minSalary,
            maxSalary: maxSalary,
          );
        }),
      );
    }

    chips.add(
      _filterChip("₹${minSalary.toInt()}L - ₹${maxSalary.toInt()}L", () {
        setState(() {
          minSalary = 10;
          maxSalary = 70;
        });
        _applyFilters(
          location: selectedLocation,
          speciality: selectedSpeciality,
          types: selectedTypes,
          minSalary: minSalary,
          maxSalary: maxSalary,
        );
      }),
    );

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      backgroundColor: AppColors.primary,
      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
      onDeleted: onRemove,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          hintText: "Search",
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.lightBlue, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: _filterJobs,
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: _showFilterDialog,
          child: Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.filter, color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _showFilterDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD6EDFF),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Modify Filter",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

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

/// 🧠 Filter Dialog
class FilterDialogContent extends StatefulWidget {
  final String? currentLocation;
  final String? currentSpeciality;
  final List<String> currentTypes;
  final double currentMinSalary;
  final double currentMaxSalary;

  const FilterDialogContent({
    super.key,
    this.currentLocation,
    this.currentSpeciality,
    required this.currentTypes,
    required this.currentMinSalary,
    required this.currentMaxSalary,
  });

  @override
  State<FilterDialogContent> createState() => _FilterDialogContentState();
}

class _FilterDialogContentState extends State<FilterDialogContent> {
  final List<String> locations = ["Bangalore", "Chennai", "Delhi", "Hyderabad"];
  final List<String> specialities = ["Neuro Surgery", "Orthopedic"];
  final List<String> positions = [
    "Full Time",
    "Part Time",
    "Internship",
    "Remote",
    "Contract",
  ];

  String? selectedLocation;
  String? selectedSpeciality;
  List<String> selectedTypes = [];
  double minSalary = 10;
  double maxSalary = 70;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.currentLocation;
    selectedSpeciality = widget.currentSpeciality;
    selectedTypes = List.from(widget.currentTypes);
    minSalary = widget.currentMinSalary;
    maxSalary = widget.currentMaxSalary;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white, // ✅ Added white background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter by:",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 10),

              /// 📍 Location Filters
              Wrap(
                spacing: 8,
                children: locations.map((loc) {
                  final sel = selectedLocation == loc;
                  return ChoiceChip(
                    label: Text(loc),
                    selected: sel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.white,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : Colors.black87,
                    ),
                    onSelected: (_) =>
                        setState(() => selectedLocation = sel ? null : loc),
                    shape: StadiumBorder(
                      side: BorderSide(color: AppColors.primary),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              /// 🩺 Speciality Dropdown
              _buildDropdown(
                "Speciality",
                selectedSpeciality,
                specialities,
                (val) => setState(() => selectedSpeciality = val),
              ),
              const SizedBox(height: 12),

              /// 🧬 Sub-speciality Dropdown
              _buildDropdown(
                "Sub-speciality",
                selectedSpeciality,
                specialities,
                (val) => setState(() => selectedSpeciality = val),
              ),
              const SizedBox(height: 12),

              /// 🧩 Position Type
              const Text(
                "Position Type",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: positions.map((type) {
                  final selected = selectedTypes.contains(type);
                  return ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          selectedTypes.add(type);
                        } else {
                          selectedTypes.remove(type);
                        }
                      });
                    },
                    shape: StadiumBorder(
                      side: BorderSide(color: AppColors.primary),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              /// 💰 Salary Range
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("₹${minSalary.toInt()}L"),
                  Text("₹${maxSalary.toInt()}L PA"),
                ],
              ),
              RangeSlider(
                activeColor: AppColors.primary,
                inactiveColor: Colors.grey.shade300,
                values: RangeValues(minSalary, maxSalary),
                min: 0,
                max: 100,
                divisions: 20,
                onChanged: (values) {
                  setState(() {
                    minSalary = values.start;
                    maxSalary = values.end;
                  });
                },
              ),
              const SizedBox(height: 18),

              /// Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedLocation = null;
                          selectedSpeciality = null;
                          selectedTypes.clear();
                          minSalary = 10;
                          maxSalary = 70;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Reset All",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'location': selectedLocation,
                          'speciality': selectedSpeciality,
                          'types': selectedTypes,
                          'minSalary': minSalary,
                          'maxSalary': maxSalary,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Apply Filters",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🩺 Dropdown Widget
  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    final bool hasValue = value != null && value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🏷️ Label + Reset
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: hasValue ? 1.0 : 0.45,
              child: TextButton(
                onPressed: hasValue ? () => onChanged(null) : null,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                ),
                child: Text(
                  "Reset",
                  style: TextStyle(
                    color: hasValue ? const Color(0xFF00AFF4) : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        /// 🔽 Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
