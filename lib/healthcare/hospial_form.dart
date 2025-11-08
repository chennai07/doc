import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class HospitalForm extends StatefulWidget {
  const HospitalForm({super.key});

  @override
  State<HospitalForm> createState() => _HospitalFormState();
}

class _HospitalFormState extends State<HospitalForm> {
  final _formKey = GlobalKey<FormState>();

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
  String? selectedHospitalType;
  File? hospitalLogo;
  bool agreeTerms = false;
  String searchQuery = ""; // For search functionality

  final List<String> hospitalTypes = [
    "General Hospital",
    "Specialty Hospital",
    "Clinic",
    "Other",
  ];

  final List<String> departments = [
    "Cardiology",
    "Orthopedics",
    "Surgical oncology",
    "Neurosurgery",
    "Pediatric surgery",
    "Urology",
    "Gastroenterology",
    "Dermatology",
    "ENT",
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

    // ✅ Show success popup
    Get.dialog(
      Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 240,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade50,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Profile Submitted!",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Your hospital profile has been successfully saved.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    await Future.delayed(const Duration(seconds: 2));
    Get.back();
    Navigator.pop(context);
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
              SizedBox(
                height: 45,
                child: OutlinedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    hospitalLogo == null
                        ? "Upload your image"
                        : "Image selected",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // 🏥 Hospital Type Dropdown (Styled)
              Text("Hospital Type", style: labelStyle),
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
                    value: selectedHospitalType,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    dropdownColor: Colors.white,
                    hint: Text(
                      "Hospital Type",
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => selectedHospitalType = val);
                    },
                    items: hospitalTypes
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

              // Submit Button
              SizedBox(
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
            ],
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
