import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doc/model/api_service.dart';

class SurgeonForm extends StatefulWidget {
  final String profileId;
  final Map<String, dynamic>? existingData;

  const SurgeonForm({
    super.key,
    required this.profileId,
    required this.existingData,
  });

  @override
  State<SurgeonForm> createState() => _SurgeonFormState();
}

class _SurgeonFormState extends State<SurgeonForm> {
  final formKey = GlobalKey<FormState>();

  late TextEditingController fullName;
  late TextEditingController speciality;
  late TextEditingController subSpeciality;
  late TextEditingController degree;
  late TextEditingController experience;
  late TextEditingController surgicalExp;
  late TextEditingController portfolio;
  late TextEditingController summary;
 
  File? profilePic;
  File? cv;
  File? highestDegree;
  File? logBook;

  bool isLoading = false;
  bool hasProfile = false;

  @override
  void initState() {
    super.initState();

    final d = widget.existingData ?? {};

    fullName = TextEditingController(text: d['fullName'] ?? '');
    speciality = TextEditingController(text: d['speciality'] ?? '');
    subSpeciality = TextEditingController(text: d['subSpeciality'] ?? '');
    degree = TextEditingController(text: d['degree'] ?? '');
    experience = TextEditingController(
      text: d['yearsOfExperience']?.toString() ?? '',
    );
    surgicalExp = TextEditingController(text: d['surgicalExperience'] ?? '');
    portfolio = TextEditingController(text: d['portfolioLinks'] ?? '');
    summary = TextEditingController(text: d['summaryProfile'] ?? '');

    // Fetch and prefill if profile exists for given profileId
    _loadProfileIfAny();
  }

  Future<void> _loadProfileIfAny() async {
    setState(() => isLoading = true);
    final res = await ApiService.fetchProfileInfo(widget.profileId);
    if (res['success'] == true) {
      final body = res['data'];
      // Some APIs wrap data again; try common shapes
      final data = body is Map && body['data'] != null ? body['data'] : body;
      final p = data is Map && data['profile'] != null ? data['profile'] : data;
      if (p is Map) {
        hasProfile = true;
        fullName.text = (p['fullName'] ?? p['fullname'] ?? fullName.text) as String;
        speciality.text = (p['speciality'] ?? speciality.text) as String;
        subSpeciality.text = (p['subSpeciality'] ?? subSpeciality.text) as String;
        degree.text = (p['degree'] ?? degree.text) as String;
        experience.text = (p['yearsOfExperience']?.toString() ?? experience.text);
        surgicalExp.text = (p['surgicalExperience'] ?? surgicalExp.text) as String;
        portfolio.text = (p['portfolioLinks'] ?? portfolio.text) as String;
        summary.text = (p['summaryProfile'] ?? summary.text) as String;
      }
    }
    setState(() => isLoading = false);
  }

  Future<File?> pickFile(List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (result != null) return File(result.files.single.path!);
    return null;
  }

  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final uri = Uri.parse(
      "https://surgeon-search.onrender.com/api/surgeon/profile/update/${widget.profileId}",
    );

    var req = http.MultipartRequest("PUT", uri);

    req.fields.addAll({
      "fullName": fullName.text,
      "speciality": speciality.text,
      "subSpeciality": subSpeciality.text,
      "degree": degree.text,
      "yearsOfExperience": experience.text,
      "surgicalExperience": surgicalExp.text,
      "portfolioLinks": portfolio.text,
      "summaryProfile": summary.text,
    });

    if (profilePic != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "profilePicture",
          profilePic!.path,
          filename: basename(profilePic!.path),
        ),
      );
    }
    if (cv != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "cv",
          cv!.path,
          filename: basename(cv!.path),
        ),
      );
    }
    if (highestDegree != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "highestDegree",
          highestDegree!.path,
          filename: basename(highestDegree!.path),
        ),
      );
    }
    if (logBook != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "uploadLogBook",
          logBook!.path,
          filename: basename(logBook!.path),
        ),
      );
    }

    var res = await req.send();
    var msg = await res.stream.bytesToString();
 
    if (res.statusCode == 200) {
      Get.snackbar("✅ Success", "Profile Updated Successfully");
      Get.back(); // return to profile view
    } else {
      Get.snackbar("❌ Update Failed", msg);
    }

    setState(() => isLoading = false);
  }

  Future<void> createProfile() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final result = await ApiService.createProfile(
      fullName: fullName.text,
      phoneNumber: '',
      email: '',
      location: '',
      degree: degree.text,
      speciality: speciality.text,
      subSpeciality: subSpeciality.text,
      summaryProfile: summary.text,
      termsAccepted: true,
      profileId: widget.profileId,
      portfolioLinks: portfolio.text,
      workExperience: const [],
      imageFile: profilePic,
      cvFile: cv,
    );

    if (result['success'] == true) {
      hasProfile = true;
      Get.snackbar("✅ Success", "Profile Created Successfully");
    } else {
      Get.snackbar("❌ Create Failed", result['message']?.toString() ?? 'Error');
    }

    setState(() => isLoading = false);
  }

  Widget fileTile(String label, File? file, Function pick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        ElevatedButton(
          onPressed: () async {
            final f = await pick();
            if (f != null) setState(() => file = f);
          },
          child: Text(file == null ? "Choose File" : basename(file.path)),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(15),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: fullName,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                        ),
                        validator: (v) => v!.isEmpty ? "Enter name" : null,
                      ),
                      TextFormField(
                        controller: speciality,
                        decoration: const InputDecoration(
                          labelText: "Speciality",
                        ),
                      ),
                      TextFormField(
                        controller: subSpeciality,
                        decoration: const InputDecoration(
                          labelText: "Sub Speciality",
                        ),
                      ),
                      TextFormField(
                        controller: degree,
                        decoration: const InputDecoration(
                          labelText: "Highest Degree",
                        ),
                      ),
                      TextFormField(
                        controller: experience,
                        decoration: const InputDecoration(
                          labelText: "Years of Experience",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: surgicalExp,
                        decoration: const InputDecoration(
                          labelText: "Surgical Experience",
                        ),
                      ),
                      TextFormField(
                        controller: portfolio,
                        decoration: const InputDecoration(
                          labelText: "Portfolio Links",
                        ),
                      ),
                      TextFormField(
                        controller: summary,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: "Summary Profile",
                        ),
                      ),
                      const SizedBox(height: 15),

                      /// File Uploads
                      fileTile(
                        "Profile Picture",
                        profilePic,
                        () => pickFile(["jpg", "jpeg", "png"]),
                      ),
                      fileTile("CV", cv, () => pickFile(["pdf", "doc"])),
                      fileTile(
                        "Highest Degree",
                        highestDegree,
                        () => pickFile(["jpg", "png", "pdf"]),
                      ),
                      fileTile(
                        "Upload LogBook",
                        logBook,
                        () => pickFile(["jpg", "png", "pdf"]),
                      ),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: hasProfile ? updateProfile : createProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: Text(hasProfile ? "Update Profile" : "Create Profile"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
