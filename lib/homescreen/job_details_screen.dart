import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:doc/utils/colors.dart';
import 'package:doc/utils/session_manager.dart';

void _showSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔵 Title Row (Clean & Identical to Screenshot)
              Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Application Submitted",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// ✨ Message Texts
              const Text(
                "Thank you for applying!",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your job has been saved under 'Applied Jobs'.",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),

              const SizedBox(height: 25),

              /// 🔘 OK Button (Right-aligned like screenshot)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class JobDetailsScreen extends StatefulWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _job;

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
  }

  Future<void> _fetchJobDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse(
          'http://13.203.67.154:3000/api/healthcare/job-profile/${widget.jobId}');
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

        Map<String, dynamic> jobMap = <String, dynamic>{};
        if (data is Map) {
          jobMap = Map<String, dynamic>.from(data as Map);
        }

        setState(() {
          _job = jobMap;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load job details (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading job details: $e';
        _isLoading = false;
      });
    }
  }

  Future<bool> _submitApplication({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String location,
    String? linkedIn,
    String? notes,
    PlatformFile? cvFile,
  }) async {
    try {
      final surgeonProfileId = await SessionManager.getProfileId();
      if (surgeonProfileId == null || surgeonProfileId.isEmpty) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile id not found. Please login again.'),
          ),
        );
        return false;
      }

      final job = _job ?? {};
      final healthcareId = (job['healthcare_id'] ??
              job['healthcareId'] ??
              job['healthcareProfileId'] ??
              '')
          .toString();

      final url =
          Uri.parse('http://13.203.67.154:3000/api/jobs/apply');
      final request = http.MultipartRequest('POST', url);

      request.fields['firstName'] = firstName;
      request.fields['lastName'] = lastName;
      request.fields['phone'] = phone;
      request.fields['email'] = email;
      request.fields['location'] = location;
      request.fields['linkedIn'] = linkedIn ?? '';
      request.fields['notes'] = notes ?? '';
      request.fields['healthcare_id'] = healthcareId;
      request.fields['surgeonprofile_id'] = surgeonProfileId;
      request.fields['job_id'] = widget.jobId;

      if (cvFile != null && cvFile.path != null && cvFile.path!.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('cv', cvFile.path!),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        if (!mounted) return false;
        String msg = 'Failed to submit application (${response.statusCode})';
        try {
          final body = response.body.trimLeft();
          final decoded = jsonDecode(body);
          if (decoded is Map && decoded['message'] != null) {
            msg = decoded['message'].toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting application: $e')),
      );
      return false;
    }
  }

  void _showApplyFormDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final linkedinController = TextEditingController();
    final notesController = TextEditingController();

    String selectedLocation = 'Bangalore, India';
    PlatformFile? selectedFile;
    String? selectedFileName;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Apply for this position',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: firstNameController,
                            decoration: const InputDecoration(
                              hintText: 'First name',
                              filled: true,
                              fillColor: Color(0xFFF8F8F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: lastNameController,
                            decoration: const InputDecoration(
                              hintText: 'Last name',
                              filled: true,
                              fillColor: Color(0xFFF8F8F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '(+91) 98765 43210',
                        filled: true,
                        fillColor: Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'yourname@example.com',
                        filled: true,
                        fillColor: Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedLocation,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Bangalore, India',
                          child: Text('Bangalore, India'),
                        ),
                        DropdownMenuItem(
                          value: 'Chennai, India',
                          child: Text('Chennai, India'),
                        ),
                        DropdownMenuItem(
                          value: 'Hyderabad, India',
                          child: Text('Hyderabad, India'),
                        ),
                        DropdownMenuItem(
                          value: 'Delhi, India',
                          child: Text('Delhi, India'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedLocation = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Upload CV/Resume',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'doc', 'docx'],
                        );
                        if (result != null && result.files.isNotEmpty) {
                          setState(() {
                            selectedFile = result.files.first;
                            selectedFileName = selectedFile!.name;
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: Text(selectedFileName ?? 'Choose File'),
                    ),
                    if (selectedFileName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Selected: $selectedFileName',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ],
                    const SizedBox(height: 16),

                    const Text(
                      'LinkedIn',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: linkedinController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.link, color: AppColors.primary),
                        hintText: 'LinkedIn Profile URL',
                        filled: true,
                        fillColor: Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Add Notes:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Type here...',
                        filled: true,
                        fillColor: Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final first = firstNameController.text.trim();
                              final phone = phoneController.text.trim();
                              final email = emailController.text.trim();

                              if (first.isEmpty ||
                                  phone.isEmpty ||
                                  email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please fill at least first name, phone and email.'),
                                  ),
                                );
                                return;
                              }

                              final ok = await _submitApplication(
                                firstName: first,
                                lastName: lastNameController.text.trim(),
                                phone: phone,
                                email: email,
                                location: selectedLocation,
                                linkedIn: linkedinController.text.trim(),
                                notes: notesController.text.trim(),
                                cvFile: selectedFile,
                              );

                              if (ok) {
                                if (Navigator.of(ctx).canPop()) {
                                  Navigator.of(ctx).pop();
                                }
                                _showSuccessDialog(context);
                              }
                            },
                            icon: const Icon(
                              Icons.send,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Submit Application',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.grey),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Job Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : _job == null
                  ? const Center(child: Text('Job not found'))
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_job!['jobTitle'] ?? '').toString(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (_job!['healthcareName'] ??
                                    _job!['hospitalName'] ??
                                    '')
                                .toString(),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (_job!['location'] ?? '').toString(),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),

                          // Meta info chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if ((_job!['jobType'] ?? '').toString().isNotEmpty)
                                _chip((_job!['jobType'] ?? '').toString()),
                              if ((_job!['department'] ?? '').toString().isNotEmpty)
                                _chip((_job!['department'] ?? '').toString()),
                              if ((_job!['subSpeciality'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                _chip((_job!['subSpeciality'] ?? '').toString()),
                              if ((_job!['salaryRange'] ?? '').toString().isNotEmpty)
                                _chip((_job!['salaryRange'] ?? '').toString()),
                            ],
                          ),

                          const SizedBox(height: 24),
                          _sectionTitle('About Role'),
                          _sectionBody(
                              (_job!['aboutRole'] ?? '').toString().trim()),

                          const SizedBox(height: 16),
                          _sectionTitle('Key Responsibilities'),
                          _sectionBody((_job!['keyResponsibilities'] ?? '')
                              .toString()
                              .trim()),

                          const SizedBox(height: 16),
                          _sectionTitle('Preferred Qualifications'),
                          _sectionBody((_job!['preferredQualifications'] ?? '')
                              .toString()
                              .trim()),

                          const SizedBox(height: 16),
                          _sectionTitle('Experience Required'),
                          _sectionBody(
                              'Minimum ${( _job!['minYearsOfExperience'] ?? '').toString()} years'),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => _showApplyFormDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Apply Now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD6EDFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _sectionBody(String text) {
    if (text.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(
          'Not specified',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }
}
