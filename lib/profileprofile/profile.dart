import 'dart:convert';
import 'dart:io';
import 'package:doc/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class DoctorProfilePage extends StatefulWidget {
  final String? initialProfileJson;
  const DoctorProfilePage({super.key, this.initialProfileJson});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  Map<String, dynamic>? profile;
  bool _isLoading = true;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      if (widget.initialProfileJson != null) {
        final decoded = jsonDecode(widget.initialProfileJson!);
        setState(() {
          profile = decoded['profile'] ?? decoded;
          _isLoading = false;
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('profile_id');

      setState(() {
        profile = {'_id': savedId};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        profile = {};
      });
    }
  }

  Future<void> _logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_id');
    await prefs.remove('token');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // ✅ Image picker dialog
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Colors.blueAccent,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Pick image and upload to server
  Future<void> _pickAndUploadImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });

    try {
      final uri = Uri.parse(
        'https://surgeon-search.onrender.com/api/sugeon/upload-image',
      );

      var request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
          filename: p.basename(_selectedImage!.path),
        ),
      );

      // Attach doctor profile ID if available
      if (profile?['_id'] != null) {
        request.fields['profile_id'] = profile!['_id'];
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = profile ?? {};
    final experiences = (data['workExperience'] ?? []) as List<dynamic>;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // leading: Column(
        //   children: [
        //     IconButton(
        //       icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        //       onPressed: () => Navigator.pop(context),
        //     ),
        //     IconButton(
        //       icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        //       onPressed: () => Navigator.pop(context),
        //     ),
        //     IconButton(
        //       icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        //       onPressed: () => Navigator.pop(context),
        //     ),
        //   ],
        // ),
        title: const Text(
          "Doctor Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.logout, color: Colors.black),
            onPressed: _logoutUser,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 👤 Profile image with upload option
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : data["imageUrl"] != null
                      ? NetworkImage(data["imageUrl"])
                      : const AssetImage("assets/profile_placeholder.png")
                            as ImageProvider,
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Iconsax.camera,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),
            Text(
              data['fullName'] ?? "Doctor Name",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              data['speciality'] ?? "Speciality",
              style: const TextStyle(color: Colors.blue, fontSize: 15),
            ),

            const SizedBox(height: 25),

            // 🧠 About section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "About :",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Michael Mitc is an accomplished Neurosurgeon with over 13+ years of experience in brain, spine, and peripheral nerve surgeries. "
                    "His areas of expertise include microsurgical and endoscopic procedures, spinal trauma management, neuro-oncology, and minimally invasive neurosurgery. "
                    "Speciality: Neuro Surgery",
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: Colors.black87,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🩺 Speciality & SubSpeciality
            //
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: "Sub-Speciality: ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: data['subSpeciality'] ?? "N/A",
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // 🏥 Experience Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Experiences",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),

            if (experiences.isEmpty)
              const Text(
                "No experience information available.",
                style: TextStyle(color: Colors.black54),
              ),

            for (final exp in experiences)
              _experienceTile(
                title: exp['designation'] ?? "Designation",
                hospital: exp['healthcareOrganization'] ?? "Hospital",
                location: exp['location'] ?? "Location",
                period: "${exp['from'] ?? ''} - ${exp['to'] ?? 'Present'}",
              ),
          ],
        ),
      ),
    );
  }
}

// 🏥 Experience Item Widget
Widget _experienceTile({
  required String title,
  required String hospital,
  required String location,
  required String period,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🏢 Three Icons Column
        Column(
          children: const [
            Icon(Iconsax.buildings, color: Colors.blueAccent, size: 22),
            SizedBox(height: 6),
            Icon(Iconsax.location, color: Colors.blueAccent, size: 22),
            SizedBox(height: 6),
            Icon(Iconsax.clock, color: Colors.blueAccent, size: 22),
          ],
        ),
        const SizedBox(width: 12),

        // 🧾 Experience Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Title
              Text(
                title,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // Hospital name
              Text(
                hospital,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),

              // Location
              Row(
                children: [
                  const Icon(Iconsax.location5, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Period
              Row(
                children: [
                  const Icon(Iconsax.clock5, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    period,
                    style: const TextStyle(color: Colors.black45, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
