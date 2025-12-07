import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:doc/model/api_service.dart';
import 'package:doc/healthcare/hospital_profile.dart';
import 'package:doc/Navbar.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/session_manager.dart';
import 'package:doc/Subscription Plan Screen/hospital_free_trial_screen.dart';

class HospitalForm extends StatefulWidget {
  final String healthcareId;
  final Map<String, dynamic>? existingData;
  const HospitalForm({super.key, required this.healthcareId, this.existingData});

  @override
  State<HospitalForm> createState() => _HospitalFormState();
}

// Inline helpers to avoid missing ApiService methods during build
Future<Map<String, dynamic>> _addHealthcareProfile({
  required String healthcareId,
  required String hospitalName,
  required String phoneNumber,
  required String email,
  required String location,
  required String facilityCategory,
  String? hospitalType,
  required List<String> departmentsAvailable,
  required String hospitalOverview,
  required Map<String, String> hrContact,
  required String hospitalWebsite,
  required bool termsAccepted,
  File? logoFile,
}) async {
  try {
    final uri = Uri.parse('http://13.203.67.154:3000/api/healthcare/add');
    final req = http.MultipartRequest('POST', uri);

    print('🏥 Creating hospital profile with healthcare_id: $healthcareId');

    req.fields.addAll({
      'hospitalName': hospitalName,
      'phoneNumber': phoneNumber,
      'email': email,
      'location': location,
      'facilityCategory': facilityCategory,
      'hospitalOverview': hospitalOverview,
      'hrContact[fullName]': hrContact['fullName'] ?? '',
      'hrContact[designation]': hrContact['designation'] ?? '',
      'hrContact[mobileNumber]': hrContact['mobileNumber'] ?? '',
      'hrContact[email]': hrContact['email'] ?? '',
      'hospitalWebsite': hospitalWebsite,
      'termsAccepted': termsAccepted.toString(),
      'healthcare_id': healthcareId,
    });

    if (hospitalType != null && hospitalType.isNotEmpty) {
      req.fields['hospitalType'] = hospitalType;
    }

    for (int i = 0; i < departmentsAvailable.length; i++) {
      req.fields['departmentsAvailable[$i]'] = departmentsAvailable[i];
    }

    if (logoFile != null) {
      print('🏥 Adding hospital logo to create request: ${logoFile.path}');
      req.files.add(await http.MultipartFile.fromPath('hospitalLogo', logoFile.path));
    } else {
      print('🏥 No logo file provided in create request');
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    final body = res.body;
    final ct = res.headers['content-type'] ?? '';
    final trimmed = body.trimLeft();
    final isJson = ct.contains('application/json') || trimmed.startsWith('{') || trimmed.startsWith('[');

    if (res.statusCode == 200 || res.statusCode == 201) {
      if (isJson) {
        try {
          return {'success': true, 'data': jsonDecode(body)};
        } catch (_) {
          return {'success': true, 'data': {'raw': body}};
        }
      } else {
        return {'success': true, 'data': {'raw': body}};
      }
    }
    if (isJson) {
      try {
        final err = jsonDecode(body);
        return {'success': false, 'message': err['message'] ?? body};
      } catch (_) {
        return {'success': false, 'message': body};
      }
    }
    final snippet = body.length > 200 ? body.substring(0, 200) : body;
    return {'success': false, 'message': 'HTTP ${res.statusCode}: $snippet'};
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

Future<Map<String, dynamic>> _updateHealthcareProfile({
  required String healthcareId,
  required String hospitalName,
  required String phoneNumber,
  required String email,
  required String location,
  required String facilityCategory,
  String? hospitalType,
  required List<String> departmentsAvailable,
  required String hospitalOverview,
  required Map<String, String> hrContact,
  required String hospitalWebsite,
  File? logoFile,
}) async {
  try {
    // Use the edit endpoint provided by the user
    // NOTE: Although the URL suggests an "edit" action and typically uses PUT, 
    // some backends express updates via POST. The user explicitly requested ensuring
    // the API call works, and sometimes "not found" issues are due to missing body parameters
    // or method mismatches.
    
    // We will stick to PUT as per standard, BUT we MUST ensure 'healthcare_id' is 
    // also sent IN THE BODY, as the backend likely looks for it there too.
    // If PUT fails repeatedly, switching to POST might be the next debugging step,
    // but first let's ensure the ID is in the body.
    final uri = Uri.parse('http://13.203.67.154:3000/api/healthcare/edit/$healthcareId');
    final req = http.MultipartRequest('PUT', uri);

    print('🏥 Updating hospital profile for healthcare_id: $healthcareId');

    req.fields.addAll({
      'healthcare_id': healthcareId, // Explicitly adding this as requested
      'hospitalName': hospitalName,
      'phoneNumber': phoneNumber,
      'email': email,
      'location': location,
      'facilityCategory': facilityCategory,
      'hospitalOverview': hospitalOverview,
      'hrContact[fullName]': hrContact['fullName'] ?? '',
      'hrContact[designation]': hrContact['designation'] ?? '',
      'hrContact[mobileNumber]': hrContact['mobileNumber'] ?? '',
      'hrContact[email]': hrContact['email'] ?? '',
      'hospitalWebsite': hospitalWebsite,
    });

    if (hospitalType != null && hospitalType.isNotEmpty) {
      req.fields['hospitalType'] = hospitalType;
    }

    for (int i = 0; i < departmentsAvailable.length; i++) {
      req.fields['departmentsAvailable[$i]'] = departmentsAvailable[i];
    }

    if (logoFile != null) {
      print('🏥 Adding hospital logo to update request: ${logoFile.path}');
      req.files.add(await http.MultipartFile.fromPath('hospitalLogo', logoFile.path));
    } else {
      print('🏥 No new logo file provided in update request (keeping existing logo)');
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    print('🏥 Update Response Status: ${res.statusCode}');
    print('🏥 Update Response Headers: ${res.headers}');
    print('🏥 Update Response Body: ${res.body}');

    final body = res.body;
    final ct = res.headers['content-type'] ?? '';
    final trimmed = body.trimLeft();
    final isJson = ct.contains('application/json') || trimmed.startsWith('{') || trimmed.startsWith('[');

    if (res.statusCode == 200 || res.statusCode == 201) {
      if (isJson) {
        try {
          final decoded = jsonDecode(body);
          print('🏥 Update Success - Decoded Response: $decoded');
          return {'success': true, 'data': decoded};
        } catch (_) {
          print('🏥 Update Success - Raw Response: $body');
          return {'success': true, 'data': {'raw': body}};
        }
      } else {
        print('🏥 Update Success - Non-JSON Response: $body');
        return {'success': true, 'data': {'raw': body}};
      }
    }
    if (isJson) {
      try {
        final err = jsonDecode(body);
        print('🏥 Update Failed - Error Response: $err');
        return {'success': false, 'message': err['message'] ?? body};
      } catch (_) {
        print('🏥 Update Failed - Raw Error: $body');
        return {'success': false, 'message': body};
      }
    }
    final snippet = body.length > 200 ? body.substring(0, 200) : body;
    print('🏥 Update Failed - HTTP ${res.statusCode}: $snippet');
    return {'success': false, 'message': 'HTTP ${res.statusCode}: $snippet'};
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

Future<Map<String, dynamic>> _fetchHealthcareProfile(String healthcareId) async {
  try {
    final url = Uri.parse('http://13.203.67.154:3000/api/healthcare/healthcare-profile/$healthcareId');
    final res = await http.get(url);
    final body = res.body;
    final ct = res.headers['content-type'] ?? '';
    final trimmed = body.trimLeft();
    final isJson = ct.contains('application/json') || trimmed.startsWith('{') || trimmed.startsWith('[');
    if (res.statusCode == 200) {
      if (isJson) {
        try {
          return {'success': true, 'data': jsonDecode(body)};
        } catch (_) {
          return {'success': true, 'data': {'raw': body}};
        }
      } else {
        return {'success': true, 'data': {'raw': body}};
      }
    }
    if (isJson) {
      try {
        final err = jsonDecode(body);
        return {'success': false, 'message': err['message'] ?? body};
      } catch (_) {
        return {'success': false, 'message': body};
      }
    }
    final snippet = body.length > 200 ? body.substring(0, 200) : body;
    return {'success': false, 'message': 'HTTP ${res.statusCode}: $snippet'};
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

class _HospitalFormState extends State<HospitalForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _prefillData();
    } else {
      _redirectIfProfileExists();
      _autoPopulateEmail();
    }
  }

  void _prefillData() {
    final d = widget.existingData!;
    print("🏥 HospitalForm: Prefilling data: $d");
    
    hospitalNameController.text = d['hospitalName']?.toString() ?? '';
    phoneController.text = d['phoneNumber']?.toString() ?? '';
    emailController.text = d['email']?.toString() ?? '';
    locationController.text = d['location']?.toString() ?? '';
    overviewController.text = d['hospitalOverview']?.toString() ?? '';
    websiteController.text = d['hospitalWebsite']?.toString() ?? '';
    hospitalLogoUrl = d['hospitalLogo']?.toString();
    
    print("🏥 Hospital Name: ${hospitalNameController.text}");
    print("🏥 Hospital Logo URL: $hospitalLogoUrl");
    
    // HR Contact
    if (d['hrContact'] is Map) {
      final hr = d['hrContact'];
      hrNameController.text = hr['fullName']?.toString() ?? '';
      hrDesignationController.text = hr['designation']?.toString() ?? '';
      hrMobileController.text = hr['mobileNumber']?.toString() ?? '';
      hrEmailController.text = hr['email']?.toString() ?? '';
    }

    // Dropdowns
    if (d['facilityCategory'] != null && facilityCategories.contains(d['facilityCategory'])) {
      selectedFacilityCategory = d['facilityCategory'];
    }
    if (d['hospitalType'] != null && hospitalSizes.contains(d['hospitalType'])) {
      selectedHospitalSize = d['hospitalType'];
    }

    // Departments
    if (d['departmentsAvailable'] is List) {
      for (var dept in d['departmentsAvailable']) {
        if (departments.contains(dept)) {
          selectedDepartments.add(dept.toString());
        }
      }
    }
    
    // Terms assumed accepted for existing profile
    agreeTerms = true;
    
    // Trigger UI update
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _autoPopulateEmail() async {
    final email = await SessionManager.getUserEmail();
    if (email != null && email.isNotEmpty) {
      if (mounted) {
        setState(() {
          emailController.text = email;
        });
      }
    }
  }

  Future<void> _redirectIfProfileExists() async {
    print('🏥 Checking if profile already exists for healthcareId: ${widget.healthcareId}');
    
    try {
      // First, try the main ID lookup
      final res = await _fetchHealthcareProfile(widget.healthcareId);
      if (!mounted) return;
      
      if (res['success'] == true) {
        final payload = res['data'];
        final normalized = (payload is Map<String, dynamic>)
            ? (payload['data'] is Map<String, dynamic> ? payload['data'] : payload)
            : <String, dynamic>{};
        
        // Check if the profile has meaningful data (not just empty or minimal data)
        final hasValidProfile = normalized.isNotEmpty && 
            (normalized['hospitalName']?.toString().trim().isNotEmpty == true ||
             normalized['email']?.toString().trim().isNotEmpty == true ||
             normalized['phoneNumber']?.toString().trim().isNotEmpty == true);
        
        if (hasValidProfile) {
          print('🏥 ✅ Valid profile found! Redirecting to dashboard');
          print('🏥 Profile data: Hospital=${normalized['hospitalName']}, Email=${normalized['email']}');
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Navbar(hospitalData: normalized)),
          );
          return; // Exit early
        } else {
          print('🏥 ⚠️ Profile exists but has no valid data');
        }
      } else {
        print('🏥 ⚠️ Profile fetch failed with ID lookup');
      }
      
      // If ID lookup failed, try email lookup as fallback
      // Get user email from session
      final userEmail = await SessionManager.getUserEmail();
      if (userEmail != null && userEmail.isNotEmpty) {
        print('🏥 Trying email-based profile lookup for: $userEmail');
        
        try {
          final emailUrl = Uri.parse('http://13.203.67.154:3000/api/healthcare/healthcare-profile/email/$userEmail');
          final emailResp = await http.get(emailUrl).timeout(const Duration(seconds: 10));
          
          if (emailResp.statusCode == 200) {
            final emailBody = jsonDecode(emailResp.body);
            final emailPayload = (emailBody is Map && emailBody['data'] != null) ? emailBody['data'] : emailBody;
            final emailMapPayload = (emailPayload is Map<String, dynamic>) ? emailPayload : <String, dynamic>{};
            
            final hasValidEmailProfile = emailMapPayload.isNotEmpty && 
                emailMapPayload['hospitalName']?.toString().trim().isNotEmpty == true;
            
            if (hasValidEmailProfile) {
              print('🏥 ✅ Profile found by email! Redirecting to dashboard');
              
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => Navbar(hospitalData: emailMapPayload)),
              );
              return; // Exit early
            }
          }
        } catch (e) {
          print('🏥 ⚠️ Email-based lookup failed: $e');
        }
      } else {
        print('🏥 ⚠️ No user email in session for fallback lookup');
      }
      
      // If we reach here, no existing profile was found
      print('🏥 ℹ️ No existing profile found. User can fill the form.');
      
    } catch (e) {
      print('🏥 ❌ Error during profile check: $e');
      // Allow form to be shown if there's an error
    }
  }

  // Controllers
  final TextEditingController hospitalNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController overviewController = TextEditingController();
  final TextEditingController hrNameController = TextEditingController();
  final TextEditingController hrDesignationController = TextEditingController();
  final TextEditingController hrMobileController = TextEditingController();
  final TextEditingController hrEmailController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();

  // Dropdown & Selections
  String? selectedFacilityCategory;
  String? selectedHospitalSize;

  File? hospitalLogo;
  String? hospitalLogoUrl;
  bool agreeTerms = false;
  String searchQuery = ""; // For search functionality

  final List<String> facilityCategories = [
    "Medical Colleges",
    "Hospitals / Government-Aided Hospitals",
    "Corporate",
    "Group Practice",
  ];

  final List<String> hospitalSizes = [
    "Small (< 50 beds)",
    "Medium (50-100 beds)",
    "Large (> 100 beds)",
  ];

  final List<String> departments = [
    "Cardiology",
    "Orthopedics",
    "Surgical Oncology",
    "Neurosurgery",
    "Pediatric Surgery",
    "Urology",
    "General Medicine",
    "ENT",
    "Dermatology",
    "Radiology",
    "Gastroenterology",
    "Interventionists",
  ];

  final List<String> selectedDepartments = [];

  // Image Picker
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => hospitalLogo = File(picked.path));
    }
  }

  // Submit handler
  void handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please agree to the terms first")),
      );
      return;
    }

    // Check if updating
    if (widget.existingData != null) {
      _handleUpdate();
      return;
    }

    print('🏥 Submitting hospital profile with healthcare_id: ${widget.healthcareId}');

    // Submit to backend (inline to avoid missing ApiService helpers)
    final res = await _addHealthcareProfile(
      healthcareId: widget.healthcareId,
      hospitalName: hospitalNameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      email: emailController.text.trim(),
      location: locationController.text.trim(),
      facilityCategory: selectedFacilityCategory ?? '',
      hospitalType: selectedHospitalSize,
      departmentsAvailable: List<String>.from(selectedDepartments),
      hospitalOverview: overviewController.text.trim(),
      hrContact: {
        'fullName': hrNameController.text.trim(),
        'designation': hrDesignationController.text.trim(),
        'mobileNumber': hrMobileController.text.trim(),
        'email': hrEmailController.text.trim(),
      },
      hospitalWebsite: websiteController.text.trim(),
      termsAccepted: agreeTerms,
      logoFile: hospitalLogo,
    );

    print('🏥 Hospital profile creation response: ${res['success']}');
    if (res['data'] != null) {
      print('🏥 Response data: ${res['data']}');
    }

    if (res['success'] == true) {
      // Extract the actual ID from backend response
      // CRITICAL: Backend uses MongoDB _id as the primary identifier
      // We must use this _id for all subsequent operations (job posting, etc.)
      String finalHealthcareId = widget.healthcareId;
      
      if (res['data'] != null) {
        final responseData = res['data'];
        if (responseData is Map) {
          // PRIORITY ORDER: _id (MongoDB primary key) > healthcare_id > healthcareId
          // The backend likely uses _id to look up hospitals, not healthcare_id
          final extractedId = responseData['_id'] ??
                             (responseData['data'] is Map ? responseData['data']['_id'] : null) ??
                             responseData['healthcare_id'] ?? 
                             responseData['healthcareId'] ?? 
                             (responseData['data'] is Map ? 
                               (responseData['data']['healthcare_id'] ?? 
                                responseData['data']['healthcareId']) : null);
          
          if (extractedId != null && extractedId.toString().trim().isNotEmpty) {
            finalHealthcareId = extractedId.toString().trim();
            print('🏥 ✅ Extracted ID from backend response: $finalHealthcareId');
          } else {
            print('🏥 ⚠️ No ID found in response, using original: $finalHealthcareId');
          }
        }
      }

      // Save this as the canonical healthcare_id for all future operations
      await SessionManager.saveHealthcareId(finalHealthcareId);
      print('🏥 💾 Saved healthcare_id to session: $finalHealthcareId');

      // 🔥 CRITICAL: Save email→profile_id mapping for future logins
      // This allows us to find the profile even with backend ID mismatch
      final userEmail = emailController.text.trim();
      await SessionManager.saveUserProfileMapping(userEmail, finalHealthcareId);
      print('🏥 💾 Saved profile mapping: $userEmail → $finalHealthcareId');

      // Skip fetching profile immediately to avoid consistency delays.
      // We have the ID and the data we just submitted.
      
      Map<String, dynamic> finalHospitalData = {};
      
      // Try to use returned data
      if (res['data'] is Map) {
         final payload = res['data'];
         final normalized = (payload['data'] is Map ? payload['data'] : payload);
         if (normalized is Map) {
           finalHospitalData = Map<String, dynamic>.from(normalized);
         }
      }
      
      // Ensure essential fields are present (fallback to form inputs)
      finalHospitalData['healthcare_id'] = finalHealthcareId;
      if (finalHospitalData['hospitalName'] == null) finalHospitalData['hospitalName'] = hospitalNameController.text.trim();
      if (finalHospitalData['email'] == null) finalHospitalData['email'] = emailController.text.trim();
      if (finalHospitalData['location'] == null) finalHospitalData['location'] = locationController.text.trim();
      
      print('🏥 Navigating to Free Trial Screen with healthcare_id: $finalHealthcareId');

      // Extract payment info from the INITIAL response (res['data'])
      int paymentAmount = 0;
      String facilityCategory = selectedFacilityCategory ?? "Corporate";

      if (res['data'] != null) {
        final rData = res['data'];
        if (rData is Map) {
          // Check top level or inside 'data'
          if (rData.containsKey('paymentAmount')) {
            paymentAmount = int.tryParse(rData['paymentAmount'].toString()) ?? 0;
          } else if (rData['data'] is Map && rData['data'].containsKey('paymentAmount')) {
            paymentAmount = int.tryParse(rData['data']['paymentAmount'].toString()) ?? 0;
          }

          // Also try to get facilityCategory from response if available, otherwise use selected
          if (rData.containsKey('facilityCategory')) {
            facilityCategory = rData['facilityCategory'].toString();
          } else if (rData['data'] is Map && rData['data'].containsKey('facilityCategory')) {
            facilityCategory = rData['data']['facilityCategory'].toString();
          }
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HospitalFreeTrialScreen(
            paymentAmount: paymentAmount,
            facilityCategory: facilityCategory,
            healthcareId: finalHealthcareId,
            hospitalData: finalHospitalData,
          ),
        ),
      );
    } else {
      Get.snackbar(
        'Submit Failed', 
        res['message']?.toString() ?? 'Error creating hospital profile',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handleUpdate() async {
    // Determine the best ID to use for the update
    // Based on the Postman example: PUT /api/healthcare/edit/693230f143caad12d8805c9c
    // The URL expects healthcare_id
    String idToUse = widget.healthcareId;
    
    if (widget.existingData != null) {
      // Priority: healthcare_id > _id > id (based on Postman example)
      if (widget.existingData!.containsKey('healthcare_id') && 
          widget.existingData!['healthcare_id'] != null &&
          widget.existingData!['healthcare_id'].toString().isNotEmpty) {
        idToUse = widget.existingData!['healthcare_id'].toString();
      } else if (widget.existingData!.containsKey('_id') && 
          widget.existingData!['_id'] != null &&
          widget.existingData!['_id'].toString().isNotEmpty) {
        idToUse = widget.existingData!['_id'].toString();
      } else if (widget.existingData!.containsKey('id') && 
          widget.existingData!['id'] != null &&
          widget.existingData!['id'].toString().isNotEmpty) {
        idToUse = widget.existingData!['id'].toString();
      }
    }

    print('🏥 Updating hospital profile using ID: $idToUse');
    print('🏥 Widget healthcare_id: ${widget.healthcareId}');
    print('🏥 Existing data keys: ${widget.existingData?.keys.toList()}');
    print('🏥 Logo file to upload: ${hospitalLogo != null ? hospitalLogo!.path : "No new logo selected"}');
    print('🏥 Existing logo URL: $hospitalLogoUrl');

    final res = await _updateHealthcareProfile(
      healthcareId: idToUse,
      hospitalName: hospitalNameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      email: emailController.text.trim(),
      location: locationController.text.trim(),
      facilityCategory: selectedFacilityCategory ?? '',
      hospitalType: selectedHospitalSize,
      departmentsAvailable: List<String>.from(selectedDepartments),
      hospitalOverview: overviewController.text.trim(),
      hrContact: {
        'fullName': hrNameController.text.trim(),
        'designation': hrDesignationController.text.trim(),
        'mobileNumber': hrMobileController.text.trim(),
        'email': hrEmailController.text.trim(),
      },
      hospitalWebsite: websiteController.text.trim(),
      logoFile: hospitalLogo,
    );

    if (res['success'] == true) {
      print('🏥 ✅ Profile update successful!');
      
      // Fetch the updated profile to get the new logo URL
      try {
        final fetchRes = await _fetchHealthcareProfile(idToUse);
        if (fetchRes['success'] == true && fetchRes['data'] != null) {
          final updatedData = fetchRes['data'] is Map ? fetchRes['data'] : {};
          print('🏥 Updated logo URL: ${updatedData['hospitalLogo']}');
        }
      } catch (e) {
        print('🏥 ⚠️ Could not fetch updated profile: $e');
      }
      
      Get.snackbar(
        'Success', 
        'Profile updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Navigator.pop(context, true); // Go back to profile with refresh signal
    } else {
      print('🏥 ❌ Profile update failed: ${res['message']}');
      Get.snackbar(
        'Update Failed', 
        res['message']?.toString() ?? 'Error updating profile',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w500,
      color: Colors.black,
    );

    InputDecoration fieldDecoration(String hint, IconData? icon) {
      return InputDecoration(
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text.rich(
          TextSpan(
            text: "Hospital ",
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(
                text: "profile",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Connect with top surgeons and grow your medical team.",
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              // Hospital Name
              Text("Hospital Name", style: labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: hospitalNameController,
                decoration: fieldDecoration(
                  "Enter your hospital's name",
                  Iconsax.hospital,
                ),
                validator: (v) =>
                    v!.isEmpty ? "Please enter hospital name" : null,
              ),
              const SizedBox(height: 15),

              // Phone Number
              Text("Phone number", style: labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: fieldDecoration(
                  "Official contact number",
                  Iconsax.call,
                ),
                validator: (v) =>
                    v!.isEmpty ? "Please enter phone number" : null,
              ),
              const SizedBox(height: 15),

              // Email
              Text("Email Address", style: labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: fieldDecoration(
                  "HR or recruitment email",
                  Iconsax.sms,
                ),
                validator: (v) => v!.isEmpty ? "Please enter email" : null,
              ),
              const SizedBox(height: 15),

              // Location
              Text("Location", style: labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: locationController,
                decoration: fieldDecoration("Your location", Iconsax.location),
              ),
              const SizedBox(height: 15),

              // Upload Logo
              Text("Upload Hospital Logo", style: labelStyle),
              const SizedBox(height: 8),
              hospitalLogo != null
                  ? Center(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              hospitalLogo!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  hospitalLogo = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : (hospitalLogoUrl != null && hospitalLogoUrl!.isNotEmpty
                      ? Center(
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  hospitalLogoUrl!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Iconsax.image, size: 50, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: pickImage,
                                child: const Text("Change Logo"),
                              )
                            ],
                          ),
                        )
                      : SizedBox(
                          height: 45,
                          child: OutlinedButton.icon(
                            onPressed: pickImage,
                            icon: const Icon(Icons.upload_file),
                            label: Text(
                              "Upload your image",
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        )),
              const SizedBox(height: 15),

              // 🏥 Facility Category Dropdown
              Text("Facility Category", style: labelStyle),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedFacilityCategory,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    dropdownColor: Colors.white,
                    hint: Text(
                      "Select Category",
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        selectedFacilityCategory = val;
                        // Reset sub-dropdown if category changes
                        if (val != "Hospitals / Government-Aided Hospitals") {
                          selectedHospitalSize = null;
                        }
                      });
                    },
                    items: facilityCategories
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // 🏥 Hospital Size Dropdown (Conditional)
              if (selectedFacilityCategory == "Hospitals / Government-Aided Hospitals") ...[
                Text("Hospital Type (Bed Count)", style: labelStyle),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedHospitalSize,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      dropdownColor: Colors.white,
                      hint: Text(
                        "Select Size",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => selectedHospitalSize = val);
                      },
                      items: hospitalSizes
                          .map(
                            (size) => DropdownMenuItem(
                              value: size,
                              child: Text(
                                size,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
              const SizedBox(height: 15),

              // 🧠 Departments (Search + Select)
              Text("Departments Available", style: labelStyle),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  onChanged: (value) =>
                      setState(() => searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: "Departments",
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView(
                  children: departments
                      .where((dept) => dept.toLowerCase().contains(searchQuery))
                      .map((dept) {
                        final isSelected = selectedDepartments.contains(dept);
                        return CheckboxListTile(
                          dense: true,
                          activeColor: Colors.blue,
                          title: Text(
                            dept,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey[800],
                            ),
                          ),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedDepartments.add(dept);
                              } else {
                                selectedDepartments.remove(dept);
                              }
                            });
                          },
                        );
                      })
                      .toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Overview
              Text("Hospital Overview", style: labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: overviewController,
                maxLines: 5,
                decoration: fieldDecoration(
                  "Brief description about the hospital",
                  null,
                ),
              ),
              const SizedBox(height: 20),

              // HR Contact
              Text("HR Contact Person Details", style: labelStyle),
              const SizedBox(height: 8),
              _contactField("Full Name", hrNameController),
              _contactField("Designation", hrDesignationController),
              _contactField("Mobile Number", hrMobileController),
              _contactField("Email Address", hrEmailController),
              const SizedBox(height: 10),

              // Website
              Text("Hospital Website", style: labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: websiteController,
                decoration: fieldDecoration("Website", Iconsax.link),
              ),
              const SizedBox(height: 10),

              // Terms Checkbox
              Row(
                children: [
                  Checkbox(
                    value: agreeTerms,
                    onChanged: (v) => setState(() => agreeTerms = v!),
                    activeColor: Colors.blue,
                  ),
                  Expanded(
                    child: Text(
                      "I agree to the terms and conditions and privacy policy of the application",
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFADE1FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Submit",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
