import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/session_manager.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:doc/profileprofile/surgeon_form.dart';

class Applicants extends StatefulWidget {
  final String? healthcareId;

  const Applicants({super.key, this.healthcareId});

  @override
  State<Applicants> createState() => _ApplicantsState();
}

class _ApplicantsState extends State<Applicants> {
  final TextEditingController jobTitleCtrl = TextEditingController();
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController aboutCtrl = TextEditingController();
  final TextEditingController responsibilitiesCtrl = TextEditingController();
  final TextEditingController qualificationCtrl = TextEditingController();
  final TextEditingController experienceCtrl = TextEditingController();

  final TextEditingController deadlineCtrl = TextEditingController();

  String? department;
  String? subSpeciality;
  String? jobType;
  String? interviewMode;
  String? salaryRange;

  bool agree = false;

  bool isSubmitting = false;

  // ------------------ DATE PICKER ------------------
  Future<void> pickDeadline() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4AB3F4)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Store in YYYY-MM-DD format so backend can parse it as a Date
        deadlineCtrl.text =
            "${picked.year.toString().padLeft(4, '0')}-"
            "${picked.month.toString().padLeft(2, '0')}-"
            "${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }
  // --------------------------------------------------

  Future<void> _submitJob() async {
    if (!agree || isSubmitting) return;

    final title = jobTitleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a job title')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // Get healthcare_id from multiple sources
      final storedHealthcareId = await SessionManager.getHealthcareId();
      final storedProfileId = await SessionManager.getProfileId();
      final storedUserId = await SessionManager.getUserId();
      
      print('🩺 Stored healthcare_id: $storedHealthcareId');
      print('🩺 Stored profile_id: $storedProfileId');
      print('🩺 Stored user_id: $storedUserId');
      print('🩺 Widget healthcare_id: ${widget.healthcareId}');

      // Priority: widget.healthcareId > storedHealthcareId > storedProfileId > storedUserId
      String? healthcareId;
      if (widget.healthcareId != null && widget.healthcareId!.isNotEmpty) {
        healthcareId = widget.healthcareId!;
        print('🩺 Using healthcare_id from widget: $healthcareId');
      } else if (storedHealthcareId != null && storedHealthcareId.isNotEmpty) {
        healthcareId = storedHealthcareId;
        print('🩺 Using healthcare_id from session: $healthcareId');
      } else if (storedProfileId != null && storedProfileId.isNotEmpty) {
        healthcareId = storedProfileId;
        print('🩺 Using profile_id as healthcare_id: $healthcareId');
      } else if (storedUserId != null && storedUserId.isNotEmpty) {
        healthcareId = storedUserId;
        print('🩺 Using user_id as healthcare_id: $healthcareId');
      }

      if (healthcareId == null || healthcareId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log out and log in again.'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isSubmitting = false);
        return;
      }

      final uri = Uri.parse('http://13.203.67.154:3000/api/healthcare/jobpost');

      final Map<String, String> payload = {
        'jobTitle': jobTitleCtrl.text.trim(),
        'department': department ?? '',
        'subSpeciality': subSpeciality ?? '',
        'jobType': jobType ?? '',
        'location': locationCtrl.text.trim(),
        'aboutRole': aboutCtrl.text.trim(),
        'keyResponsibilities': responsibilitiesCtrl.text.trim(),
        'preferredQualifications': qualificationCtrl.text.trim(),
        'minYearsOfExperience': experienceCtrl.text.trim(),
        'salaryRange': salaryRange ?? '',
        'interviewMode': interviewMode ?? '',
        'applicationDeadline': deadlineCtrl.text.trim(),
        'healthcare_id': healthcareId,
        'status': 'closed',
      };

      print('🩺 Final healthcare_id being sent: $healthcareId');
      print('🩺 Job post payload: ${jsonEncode(payload)}');

      // Get auth token
      final token = await SessionManager.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('🩺 Using auth token');
      }

      final resp = await http.post(uri, headers: headers, body: payload);

      print('🩺 Response status: ${resp.statusCode}');
      print('🩺 Response body: ${resp.body}');

      if (!mounted) return;

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Job posted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      } else {
        // Parse error message from backend
        String errorMsg = 'Failed to post job';
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map) {
            errorMsg = decoded['message']?.toString() ?? 
                      decoded['error']?.toString() ?? 
                      'Failed to post job (${resp.statusCode})';
          }
        } catch (_) {
          errorMsg = 'Failed to post job (${resp.statusCode})';
        }

        print('🩺 Error: $errorMsg');

        // Check if it's a healthcare_id issue
        if (errorMsg.toLowerCase().contains('healthcare') || 
            errorMsg.toLowerCase().contains('hospital') ||
            errorMsg.toLowerCase().contains('not found')) {
          
          // Try to fetch the profile to see what's wrong
          try {
            final profileUri = Uri.parse(
              'http://13.203.67.154:3000/api/healthcare/healthcare-profile/$healthcareId',
            );
            final profileResp = await http.get(profileUri).timeout(const Duration(seconds: 5));
            
            print('🩺 Profile check status: ${profileResp.statusCode}');
            print('🩺 Profile check body: ${profileResp.body}');
            
            if (profileResp.statusCode != 200) {
              errorMsg = 'Hospital profile not found. Please complete your hospital profile first.';
            } else {
              // Profile exists but job post failed - might be ID mismatch
              try {
                final profileData = jsonDecode(profileResp.body);
                final data = (profileData is Map && profileData['data'] != null) 
                    ? profileData['data'] 
                    : profileData;
                
                if (data is Map) {
                  final backendHealthcareId = data['healthcare_id']?.toString() ?? 
                                             data['healthcareId']?.toString() ?? 
                                             data['_id']?.toString() ?? '';
                  
                  print('🩺 Backend healthcare_id: $backendHealthcareId');
                  print('🩺 Sent healthcare_id: $healthcareId');
                  
                  if (backendHealthcareId.isNotEmpty && backendHealthcareId != healthcareId) {
                    // ID mismatch! Save the correct one and retry
                    await SessionManager.saveHealthcareId(backendHealthcareId);
                    errorMsg = 'ID mismatch detected. Please try posting the job again.';
                  }
                }
              } catch (e) {
                print('🩺 Error parsing profile: $e');
              }
            }
          } catch (e) {
            print('🩺 Error checking profile: $e');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('🩺 Exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Post a job opening",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Find the right surgeon for your team.\n"),

            _label("Job Title"),
            _input(jobTitleCtrl, "e.g., Consultant Orthopedic Surgeon"),

            _label("Speciality"),
            DropdownSearch<String>(
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search Speciality",
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              items: surgicalSpecialities.keys.toList(),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: "Select Speciality",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF4AB3F4)),
                  ),
                ),
              ),
              selectedItem: department,
              onChanged: (value) {
                setState(() {
                  department = value;
                  subSpeciality = null; // Reset sub-speciality
                });
              },
            ),

            if (department != null &&
                (surgicalSpecialities[department] ?? []).isNotEmpty) ...[
              _label("Sub-Speciality"),
              DropdownSearch<String>(
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "Search Sub-speciality",
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                items: surgicalSpecialities[department] ?? [],
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    hintText: "Select Sub-speciality",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF4AB3F4)),
                    ),
                  ),
                ),
                selectedItem: subSpeciality,
                onChanged: (value) {
                  setState(() {
                    subSpeciality = value;
                  });
                },
              ),
            ],

            _label("Job Type"),
            _dropdown(
              value: jobType,
              hint: "Job Type",
              items: ["Full Time", "Part Time", "Contract"],
              onChanged: (v) => setState(() => jobType = v),
            ),

            _label("Location"),
            _input(
              locationCtrl,
              "Job location",
              icon: Icons.location_on_outlined,
            ),

            _label("About the Role"),
            _input(aboutCtrl, "Brief description about the role", maxLines: 4),

            _label("Key Responsibilities"),
            _input(
              responsibilitiesCtrl,
              "Detailed responsibilities & expectations",
              maxLines: 4,
            ),

            _label("Preferred Qualifications"),
            _input(qualificationCtrl, "e.g., MS Orthopedics, MCh Neurosurgery"),

            _label("Minimum Years of Experience Required"),
            _input(experienceCtrl, "Experience in Years"),

            _label("Salary Range"),
            _dropdown(
              value: salaryRange,
              hint: "Select Salary Range",
              items: [
                "5 - 10 LPA",
                "10 - 15 LPA",
                "15 - 20 LPA",
                "20 - 25 LPA",
                "25 - 30 LPA",
                "30 - 35 LPA",
                "35 - 40 LPA",
                "40 - 45 LPA",
                "45 - 50 LPA",
                "50 - 60 LPA",
                "60 - 70 LPA",
                "70 - 80 LPA",
                "80 - 90 LPA",
                "90+ LPA"
              ],
              onChanged: (v) => setState(() => salaryRange = v),
            ),

            _label("Interview Mode"),
            _dropdown(
              value: interviewMode,
              hint: "Interview Mode",
              items: ["In-person", "Online"],
              onChanged: (v) => setState(() => interviewMode = v),
            ),

            _label("Application Deadline:"),
            TextField(
              controller: deadlineCtrl,
              readOnly: true,
              onTap: pickDeadline,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.calendar_today,
                  color: Colors.grey,
                ),
                hintText: "DD/MM/YYYY",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF4AB3F4)),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Checkbox(
                  value: agree,
                  onChanged: (v) => setState(() => agree = v ?? false),
                ),
                const Expanded(
                  child: Text(
                    "I confirm that the information provided is accurate and complies with the platform's posting guidelines.",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: agree && !isSubmitting ? _submitJob : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Post Job", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ---------------- Helper Widgets ----------------

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 18),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
  );

  Widget _input(
    TextEditingController c,
    String hint, {
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4AB3F4)),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      hint: Text(hint),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
