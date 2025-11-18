import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/session_manager.dart';

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
  final TextEditingController salaryCtrl = TextEditingController();
  final TextEditingController deadlineCtrl = TextEditingController();

  String? department;
  String? subSpeciality;
  String? jobType;
  String? interviewMode;

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
      final storedId =
          (await SessionManager.getHealthcareId()) ?? await SessionManager.getProfileId() ?? '';
      final healthcareId = (widget.healthcareId != null && widget.healthcareId!.isNotEmpty)
          ? widget.healthcareId!
          : storedId;

      if (healthcareId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Healthcare id not found. Please login or create hospital profile.'),
          ),
        );
        return;
      }

      final uri = Uri.parse(
        'http://13.203.67.154:3000/api/healthcare/jobpost',
      );

      final payload = {
        'healthcare_id': healthcareId,
        'jobTitle': jobTitleCtrl.text.trim(),
        'department': department ?? '',
        'subSpeciality': subSpeciality ?? '',
        'jobType': jobType ?? '',
        'location': locationCtrl.text.trim(),
        'aboutRole': aboutCtrl.text.trim(),
        'responsibilities': responsibilitiesCtrl.text.trim(),
        'qualifications': qualificationCtrl.text.trim(),
        'experience': experienceCtrl.text.trim(),
        'salaryRange': salaryCtrl.text.trim(),
        'interviewMode': interviewMode ?? '',
        'applicationDeadline': deadlineCtrl.text.trim(),
      };

      print('🩺 jobpost healthcareId = ' + healthcareId);
      print('🩺 jobpost payload = ' + jsonEncode(payload));

      final resp = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('🩺 jobpost response status = ' + resp.statusCode.toString());
      print('🩺 jobpost response body = ' + resp.body.toString());

      if (!mounted) return;

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully')),
        );
        Navigator.pop(context);
      } else {
        String msg = 'Failed to post job (${resp.statusCode})';
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map && decoded['message'] != null) {
            msg = decoded['message'].toString();
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting job: $e')),
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

            _label("Department"),
            _dropdown(
              value: department,
              hint: "Department",
              items: ["Cardiology", "Neurosurgery", "Orthopedics", "Urology"],
              onChanged: (v) => setState(() => department = v),
            ),

            _label("Sub-Speciality"),
            _dropdown(
              value: subSpeciality,
              hint: "Sub-Speciality",
              items: [
                "Spine Surgery",
                "Pediatric Cardiology",
                "Brain Surgery",
                "Neo Surgery",
              ],
              onChanged: (v) => setState(() => subSpeciality = v),
            ),

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
            _input(salaryCtrl, "Salary Range in LPA"),

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
