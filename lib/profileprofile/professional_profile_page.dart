import 'dart:convert';
import 'dart:io';
import 'package:doc/model/api_service.dart';
import 'package:doc/profileprofile/profile.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfessionalProfileFormPage extends StatefulWidget {
  const ProfessionalProfileFormPage({super.key});

  @override
  State<ProfessionalProfileFormPage> createState() =>
      _ProfessionalProfileFormPageState();
}

class _ProfessionalProfileFormPageState
    extends State<ProfessionalProfileFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController degreeController = TextEditingController();
  final TextEditingController specialityController = TextEditingController();
  final TextEditingController subSpecialityController = TextEditingController();
  final TextEditingController summaryController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController organizationController = TextEditingController();
  final TextEditingController fromYearController = TextEditingController();
  final TextEditingController toYearController = TextEditingController();

  File? _image;
  File? _cvFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  Future<void> _pickCV() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) setState(() => _cvFile = File(pickedFile.path));
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ApiService.createProfile(
      fullName: fullNameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      email: emailController.text.trim(),
      location: locationController.text.trim(),
      degree: degreeController.text.trim(),
      speciality: specialityController.text.trim(),
      subSpeciality: subSpecialityController.text.trim(),
      summaryProfile: summaryController.text.trim(),
      termsAccepted: true,
      profileId: "690b081aaf8f7ab1f164407b",
      portfolioLinks: "linkkk",
      workExperience: [
        {
          "designation": designationController.text.trim(),
          "healthcareOrganization": organizationController.text.trim(),
          "from": fromYearController.text.trim(),
          "to": toYearController.text.trim(),
          "location": locationController.text.trim(),
        },
      ],
      imageFile: _image,
      cvFile: _cvFile,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      final data = result['data'];
      final newProfileId = data['profile']?['_id'] ?? data['_id'] ?? data['id'];

      if (newProfileId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_id', newProfileId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Profile Created: $newProfileId')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorProfilePage(
              initialProfileJson: jsonEncode(data['profile'] ?? data),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Profile ID missing in response')),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Failed: ${result['message']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    text: "Professional ",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
                    children: [
                      TextSpan(
                        text: "profile",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildInputField(Iconsax.user, "Full Name", fullNameController),
                _buildInputField(Iconsax.call, "Phone number", phoneController),
                _buildInputField(Iconsax.sms, "Email", emailController),
                _buildInputField(
                  Iconsax.location,
                  "Location",
                  locationController,
                ),
                const SizedBox(height: 20),

                _buildLabel("Your Profile Picture"),
                GestureDetector(
                  onTap: _pickImage,
                  child: _filePickerContainer(
                    "Upload your image",
                    Iconsax.export,
                  ),
                ),
                if (_image != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: FileImage(_image!),
                      ),
                    ),
                  ),

                _buildLabel("Degree"),
                _buildContainerField("Your Degree", degreeController),
                _buildLabel("Speciality"),
                _buildContainerField("Your Speciality", specialityController),
                _buildLabel("Sub-speciality"),
                _buildContainerField(
                  "Your Sub-speciality",
                  subSpecialityController,
                ),
                _buildLabel("Summary profile"),
                _buildContainerField(
                  "Tell about yourself",
                  summaryController,
                  maxLines: 4,
                ),

                _buildLabel("Work experience"),
                _buildContainerField("Designation", designationController),
                _buildContainerField(
                  "Healthcare Organization",
                  organizationController,
                ),

                _buildLabel("Year"),
                Row(
                  children: [
                    _buildDateBox("From", fromYearController),
                    _buildDateBox("To", toYearController),
                  ],
                ),

                const SizedBox(height: 30),
                _buildLabel("Upload CV (PDF)"),
                GestureDetector(
                  onTap: _pickCV,
                  child: _filePickerContainer(
                    "Upload your CV",
                    Iconsax.document_upload,
                  ),
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB3E5FC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isLoading ? null : _submitProfile,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Submit",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Reusable UI
  Widget _buildInputField(
    IconData icon,
    String hint,
    TextEditingController c,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black45, size: 20),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 18,
          ),
        ),
      ),
    ),
  );

  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 15),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
    ),
  );

  Widget _filePickerContainer(String text, IconData icon) => Container(
    height: 50,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black26),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(text, style: const TextStyle(color: Colors.black45)),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Icon(icon, color: Colors.black45),
        ),
      ],
    ),
  );

  Widget _buildContainerField(
    String hint,
    TextEditingController c, {
    int maxLines = 1,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black26),
      borderRadius: BorderRadius.circular(10),
    ),
    child: TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, border: InputBorder.none),
    ),
  );

  Widget _buildDateBox(String label, TextEditingController c) => Expanded(
    child: GestureDetector(
      onTap: () => _selectDate(c),
      child: AbsorbPointer(
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black26),
          ),
          child: TextField(
            controller: c,
            decoration: InputDecoration(
              prefixIcon: const Icon(Iconsax.calendar_1, size: 18),
              hintText: label == "From"
                  ? "Select start date"
                  : "Select end date",
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    ),
  );
}
