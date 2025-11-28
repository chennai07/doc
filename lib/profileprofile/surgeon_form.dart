import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:doc/model/api_service.dart';
import 'package:doc/profileprofile/surgeon_profile.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:doc/model/indian_states_districts.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/Subscription Plan Screen/subscription_planScreen.dart';
 
const Map<String, List<String>> surgicalSpecialities = {
  'General Surgery': [
    'Lower GI Surgery',
    'Laparoscopic Surgery',
    'Trauma Surgery',
    'Breast / Endocrine Surgery',
    'Endocrine Surgery',
    'Head and Neck Surgery',
    'Musculoskeletal Surgery',
  ],
  'Cardiothoracic & Vascular Surgery': [
    'Paediatric Cardiothoracic & Vascular Surgery',
    'Thoracic Surgery',
    'Vascular Surgery',
    'Cardiac and Lung transplant',
  ],
  'Neurosurgery': [
    'Spine Surgery',
    'Cerebrovascular Surgery',
    'Skull base surgery',
    'Stereotactic radiosurgery',
    'Pediatric Neurosurgery',
    'Neuro-oncology',
    'Functional and epilepsy Neurosurgery',
    'Peripheral nerve surgery',
  ],
  'Orthopedic Surgery': [
    'Hand Surgery',
    'Sports Medicine',
    'Arthroplasty (Joint Replacement)',
    'Pediatric Orthopedics',
    'Orthopaedic Oncology',
    'Spine Surgery',
    'Trauma Surgery',
    'Arthroscopy',
  ],
  'ENT (Otorhinolaryngology) Surgery': [
    'Otology and Neurotology',
    'Rhinology',
    'Laryngology',
    'Head & Neck Surgery',
    'Skull Base Surgery',
  ],
  'Ophthalmic Surgery': [
    'Glaucoma',
    'Corneal Surgery',
    'Vitreo-retinal Surgery',
    'Pediatric Ophthalmology',
    'Refractive Surgery',
  ],
  'Urology': [
    'Pediatric Urology',
    'Uro-oncology',
    'Reconstructive Urology',
    'Laparoscopic/Robotic Urology',
  ],
  'Pediatric Surgery': [
    'Neonatal Surgery',
    'Thoracic Surgery',
    'Pediatric Urology',
    'Pediatric Gastrointestinal Surgery',
  ],
  'Plastic and Reconstructive Surgery': [
    'Hand Surgery',
    'Microsurgery',
    'Craniofacial Surgery',
    'Aesthetic Surgery',
    'Oncoplasty',
  ],
  'Surgical Oncology': [
    'Breast Oncology',
    'Gynecological Oncology',
    'Gastrointestinal Oncology',
    'Head & Neck Oncology',
    'Thoracic oncology',
    'Robotic onco-surgery',
  ],
  'Gastrointestinal Surgery': [
    'Bariatric Surgery',
    'Upper GI',
    'Lower GI',
    'Transplant Surgery',
    'Hepatobiliary Surgery',
    'Minimally Invasive Surgery/Robotic GI surgery',
  ],
  'Trauma and Critical Care Surgery': [],
  'Vascular Surgery': [],
  'Obstetrics and Gynaecology': [],
  'Interventional Radiology': [
    'Vascular Interventions including trauma',
    'Oncology Interventions',
    'Neurointervention',
    'Musculoskeletal Interventions',
    'Thyroid/Uterine artery embolisation',
  ],
};

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

class SurgeonProfileView extends StatelessWidget {
  final Map<String, dynamic> data;
  const SurgeonProfileView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final d = data;
    final profile = d is Map && d['data'] != null ? d['data'] : d;
    final p = profile is Map && profile['profile'] != null ? profile['profile'] : profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Surgeon Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Full Name: ${p['fullName'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Speciality: ${p['speciality'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Degree: ${p['degree'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Experience: ${p['yearsOfExperience'] ?? ''}'),
          ],
        ),
      ),
    );
  }
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
  late TextEditingController phoneNumber;
  late TextEditingController email;
  late TextEditingController location;
  late TextEditingController stateCtrl;
  late TextEditingController districtCtrl;
 
  File? profilePic;
  File? cv;
  File? highestDegree;
  File? logBook;

  String? selectedSurgicalExperience;
  String? selectedState;
  String? selectedDistrict;
  List<String> districts = [];

  final List<String> expOptions = const [
    "0-10",
    "10-50",
    "50-100",
    "100-500",
    "1000-5000",
    "5000-10000",
    "More than 10000",
  ];

  final List<String> yearsOptions = List.generate(40, (index) => '${index + 1}');

  bool isLoading = false;
  bool hasProfile = false;
  bool termsAccepted = false;
  List<Map<String, dynamic>> workExperiences = [
    {"designation": "", "organization": "", "from": "", "to": "", "location": ""}
  ];
  List<List<TextEditingController>> workExpControllers = [];

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
    phoneNumber = TextEditingController(text: d['phoneNumber'] ?? '');
    email = TextEditingController(text: d['email'] ?? '');
    location = TextEditingController(text: d['location'] ?? '');
    stateCtrl = TextEditingController(text: d['state'] ?? '');
    districtCtrl = TextEditingController(text: d['district'] ?? '');
    selectedState = d['state'];
    selectedDistrict = d['district'];
    if (selectedState != null && IndianStatesAndDistricts.data.containsKey(selectedState)) {
      districts = IndianStatesAndDistricts.data[selectedState]!;
    }

    selectedSurgicalExperience = d['surgicalExperience']?.toString().isNotEmpty == true
        ? d['surgicalExperience'].toString()
        : null;

    // Initialize work experience controllers
    _initializeWorkExpControllers();
    
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
        experience.text = p['yearsOfExperience']?.toString() ?? experience.text;
        selectedSurgicalExperience = (p['surgicalExperience'] ?? selectedSurgicalExperience)?.toString();
        portfolio.text = (p['portfolioLinks'] ?? portfolio.text) as String;
        summary.text = (p['summaryProfile'] ?? summary.text) as String;
        phoneNumber.text = (p['phoneNumber'] ?? phoneNumber.text) as String;
        email.text = (p['email'] ?? email.text) as String;
        location.text = (p['location'] ?? location.text) as String;
        stateCtrl.text = (p['state'] ?? stateCtrl.text) as String;
        districtCtrl.text = (p['district'] ?? districtCtrl.text) as String;
        
        if (p['state'] != null) {
          selectedState = p['state'];
          if (IndianStatesAndDistricts.data.containsKey(selectedState)) {
            districts = IndianStatesAndDistricts.data[selectedState]!;
          }
        }
        if (p['district'] != null) {
          selectedDistrict = p['district'];
        }
        final wx = p['workExperience'];
        if (wx is List) {
          workExperiences = wx.map<Map<String, dynamic>>((e) {
            final m = (e is Map) ? e : {};
            return {
              'designation': m['designation'] ?? '',
              'organization': m['healthcareOrganization'] ?? m['organization'] ?? '',
              'from': m['from']?.toString() ?? '',
              'to': m['to']?.toString() ?? '',
              'location': m['location'] ?? '',
            };
          }).toList();
          if (workExperiences.isEmpty) {
            workExperiences = [{"designation": "", "organization": "", "from": "", "to": "", "location": ""}];
          }
        }
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
      "http://13.203.67.154:3000/api/sugeon/profile/update/${widget.profileId}",
    );

    var req = http.MultipartRequest("PUT", uri);

    req.fields.addAll({
      "fullName": fullName.text,
      "speciality": speciality.text,
      "subSpeciality": subSpeciality.text,
      "degree": degree.text,
      "yearsOfExperience": experience.text,
      "surgicalExperience": selectedSurgicalExperience ?? '',
      "portfolioLinks": portfolio.text,
      "summaryProfile": summary.text,
      "state": selectedState ?? stateCtrl.text,
      "district": selectedDistrict ?? districtCtrl.text,
    });

    if (profilePic != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "profilePicture",
          profilePic!.path,
          filename: p.basename(profilePic!.path),
        ),
      );
    }
    if (cv != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "cv",
          cv!.path,
          filename: p.basename(cv!.path),
        ),
      );
    }
    if (highestDegree != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "highestDegree",
          highestDegree!.path,
          filename: p.basename(highestDegree!.path),
        ),
      );
    }
    if (logBook != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "uploadLogBook",
          logBook!.path,
          filename: p.basename(logBook!.path),
        ),
      );
    }

    var res = await req.send();
    var msg = await res.stream.bytesToString();
 
    if (res.statusCode == 200) {
      Get.snackbar("✅ Success", "Profile Updated Successfully");
      final prof = await ApiService.fetchProfileInfo(widget.profileId);
      if (prof['success'] == true) {
        final data = prof['data'];
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfessionalProfileViewPage(profileId: widget.profileId),
          ),
        );
      } else {
        Get.snackbar("Profile", "Updated, but failed to fetch profile");
      }
    } else {
      Get.snackbar("❌ Update Failed", msg);
    }

    setState(() => isLoading = false);
  }

  Future<void> createProfile() async {
    if (!formKey.currentState!.validate()) {
      print('🔴 VALIDATION FAILED - Form not valid');
      return;
    }

    print('🟢 VALIDATION PASSED - Starting profile creation');
    setState(() => isLoading = true);
    
    // Update work experience data from controllers
    _updateWorkExperienceData();

    print('🔵 Calling ApiService.createProfile...');
    final result = await ApiService.createProfile(
      fullName: fullName.text,
      phoneNumber: phoneNumber.text,
      email: email.text,
      location: '',
      degree: degree.text,
      speciality: speciality.text,
      subSpeciality: subSpeciality.text,
      summaryProfile: summary.text,
      termsAccepted: termsAccepted,
      profileId: widget.profileId,
      portfolioLinks: portfolio.text,
      workExperience: workExperiences,
      departmentsAvailable: const [],
      imageFile: profilePic,
      cvFile: cv,
      highestDegreeFile: highestDegree,
      logBookFile: logBook,
      yearsOfExperience: experience.text,
      surgicalExperience: selectedSurgicalExperience ?? '',
      state: selectedState ?? stateCtrl.text,
      district: selectedDistrict ?? districtCtrl.text,
    );

    print('🔵 API Response received: $result');
    print('🔵 Success value: ${result['success']}');
    print('🔵 Success type: ${result['success'].runtimeType}');

    if (result['success'] == true) {
      print('✅ SUCCESS - Profile created successfully!');
      hasProfile = true;
      Get.snackbar("✅ Success", "Profile Created Successfully");
      
      // ✅ Save Free Trial Flag
      print('💾 Saving free trial flag...');
      await SessionManager.saveFreeTrialFlag(true);
      print('💾 Free trial flag saved!');

      if (!mounted) {
        print('⚠️ Widget not mounted, cannot navigate');
        return;
      }
      
      print('🚀 Navigating to SubscriptionPlanScreen...');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SubscriptionPlanScreen(),
        ),
      );
      print('✅ Navigation completed!');
    } else {
      print('❌ FAILED - Profile creation failed');
      print('❌ Error message: ${result['message']}');
      Get.snackbar("❌ Create Failed", result['message']?.toString() ?? 'Error');
    }

    setState(() => isLoading = false);
  }

// Helpers to match provided UI
InputDecoration inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
      filled: true,
      fillColor: Colors.white,
    );

Widget titleText(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
    );

Future<void> pickProfileImage() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.image);
  if (result != null) {
    setState(() => profilePic = File(result.files.single.path!));
  }
}

Future<void> pickCVFile() async {
  final result = await FilePicker.platform
      .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
  if (result != null) {
    setState(() => cv = File(result.files.single.path!));
  }
}

void _initializeWorkExpControllers() {
  workExpControllers.clear();
  for (int i = 0; i < workExperiences.length; i++) {
    workExpControllers.add([
      TextEditingController(text: workExperiences[i]['designation'] ?? ''),
      TextEditingController(text: workExperiences[i]['organization'] ?? ''),
      TextEditingController(text: workExperiences[i]['from'] ?? ''),
      TextEditingController(text: workExperiences[i]['to'] ?? ''),
      TextEditingController(text: workExperiences[i]['location'] ?? ''),
    ]);
  }
}

void addWorkExperience() {
  setState(() {
    workExperiences.add(
        {"designation": "", "organization": "", "from": "", "to": "", "location": ""});
    workExpControllers.add([
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ]);
  });
}

void removeWorkExperience(int index) {
  setState(() {
    workExperiences.removeAt(index);
    // Dispose controllers before removing
    for (var controller in workExpControllers[index]) {
      controller.dispose();
    }
    workExpControllers.removeAt(index);
  });
}

void _updateWorkExperienceData() {
  for (int i = 0; i < workExpControllers.length; i++) {
    workExperiences[i] = {
      'designation': workExpControllers[i][0].text,
      'healthcareOrganization': workExpControllers[i][1].text,
      'from': workExpControllers[i][2].text,
      'to': workExpControllers[i][3].text,
      'location': workExpControllers[i][4].text,
    };
  }
}

@override
void dispose() {
  // Dispose all text controllers
  fullName.dispose();
  speciality.dispose();
  subSpeciality.dispose();
  degree.dispose();
  experience.dispose();
  surgicalExp.dispose();
  portfolio.dispose();
  summary.dispose();
  phoneNumber.dispose();
  email.dispose();
  location.dispose();
  stateCtrl.dispose();
  districtCtrl.dispose();
  
  // Dispose work experience controllers
  for (var controllerList in workExpControllers) {
    for (var controller in controllerList) {
      controller.dispose();
    }
  }
  
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: const Text("Professional profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
      centerTitle: false,
      backgroundColor: Colors.white,
      elevation: 0,
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  "Connect with the best hospitals and build your career.",
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),

                  titleText("Full Name"),
                  TextFormField(controller: fullName, decoration: inputDecoration("Full name"), validator: (v)=> (v==null||v.isEmpty)?'Required':null),

                  titleText("Phone number"),
                  TextFormField(controller: phoneNumber, decoration: inputDecoration("Your number"), keyboardType: TextInputType.phone),

                  titleText("Email"),
                  TextFormField(controller: email, decoration: inputDecoration("Your email"), keyboardType: TextInputType.emailAddress),

                  titleText("State"),
                  DropdownSearch<String>(
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Search State",
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    items: IndianStatesAndDistricts.data.keys.toList(),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: inputDecoration("Select State"),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedState = value;
                        districts = IndianStatesAndDistricts.data[value] ?? [];
                        selectedDistrict = null; // Reset district when state changes
                      });
                    },
                    selectedItem: selectedState,
                    validator: (v) => v == null ? "Required" : null,
                  ),

                  titleText("District"),
                  DropdownSearch<String>(
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Search District",
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    items: districts,
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: inputDecoration("Select District"),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedDistrict = value;
                      });
                    },
                    selectedItem: selectedDistrict,
                    enabled: selectedState != null, // Disable if no state selected
                    validator: (v) => v == null ? "Required" : null,
                  ),

                  titleText("Your Profile Picture"),
                  GestureDetector(
                    onTap: pickProfileImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Iconsax.image, color: Colors.black54, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            profilePic != null ? "Image selected ✅" : "Upload your image",
                            style: TextStyle(color: profilePic != null ? Colors.green : Colors.black54),
                          )
                        ],
                      ),
                    ),
                  ),

                  titleText("Degree"),
                  TextFormField(controller: degree, decoration: inputDecoration("Your Degree")),

                  titleText("Highest Degree (file)"),
                  GestureDetector(
                    onTap: () async {
                      final picked = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf','jpg','jpeg','png'],
                      );
                      if (picked != null) {
                        setState(() => highestDegree = File(picked.files.single.path!));
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Iconsax.document_upload, color: Colors.black54, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            highestDegree != null ? "Highest degree uploaded " : "Upload highest degree (PDF/Image)",
                            style: TextStyle(color: highestDegree != null ? Colors.green : Colors.black54),
                          )
                        ],
                      ),
                    ),
                  ),

                  titleText("Speciality"),
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
                      dropdownSearchDecoration: inputDecoration("Select Speciality"),
                    ),
                    selectedItem: speciality.text.isEmpty ? null : speciality.text,
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    onChanged: (value) {
                      setState(() {
                        speciality.text = value ?? '';
                        subSpeciality.text = '';
                      });
                    },
                  ),

                  if ((surgicalSpecialities[speciality.text] ?? const <String>[]).isNotEmpty) ...[
                    titleText("Sub-speciality"),
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
                      items: speciality.text.isEmpty
                          ? const <String>[]
                          : (surgicalSpecialities[speciality.text] ?? const <String>[]),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: inputDecoration("Select Sub-speciality"),
                      ),
                      selectedItem: subSpeciality.text.isEmpty ? null : subSpeciality.text,
                      enabled: speciality.text.isNotEmpty,
                      validator: (v) {
                        final subs = surgicalSpecialities[speciality.text] ?? const <String>[];
                        if (subs.isEmpty) return null; // No subspecialities required
                        return v == null || v.isEmpty ? "Required" : null;
                      },
                      onChanged: (value) {
                        setState(() {
                          subSpeciality.text = value ?? '';
                        });
                      },
                    ),
                  ],

                  titleText("Years of experience"),
                  DropdownButtonFormField<String>(
                    value: yearsOptions.contains(experience.text) ? experience.text : null,
                    items: yearsOptions
                        .map((e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        experience.text = value ?? '';
                      });
                    },
                    decoration: inputDecoration("Select years of experience"),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),

                  titleText("Surgical experience"),
                  DropdownButtonFormField<String>(
                    value: selectedSurgicalExperience,
                    items: expOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => selectedSurgicalExperience = v),
                    decoration: inputDecoration("Select surgical experience"),
                  ),

                  titleText("Summary profile"),
                  TextFormField(controller: summary, maxLines: 4, decoration: inputDecoration("Tell about yourself")),

                  titleText("Work experience"),
                  ...workExpControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    List<TextEditingController> controllers = entry.value;
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black12)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: controllers[0],
                              decoration: inputDecoration("Designation"),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: controllers[1],
                              decoration: inputDecoration("Healthcare Organization"),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: TextFormField(
                                  controller: controllers[2],
                                  decoration: inputDecoration("From (Year)"),
                                )),
                                const SizedBox(width: 10),
                                Expanded(child: TextFormField(
                                  controller: controllers[3],
                                  decoration: inputDecoration("To (Year)"),
                                )),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: controllers[4],
                              decoration: inputDecoration("Location"),
                            ),
                            if (workExpControllers.length > 1)
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(Iconsax.trash, color: Colors.red),
                                  onPressed: () => removeWorkExperience(index),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: addWorkExperience,
                    icon: const Icon(Iconsax.add_square, color: Colors.blueAccent),
                    label: const Text("Add more work experience", style: TextStyle(color: Colors.blueAccent)),
                  ),

                  titleText("CV"),
                  GestureDetector(
                    onTap: pickCVFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Iconsax.document_upload, color: Colors.black54, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            cv != null ? "CV uploaded ✅" : "Upload your CV in PDF",
                            style: TextStyle(color: cv != null ? Colors.green : Colors.black54),
                          )
                        ],
                      ),
                    ),
                  ),

                  titleText("Portfolio"),
                  TextFormField(controller: portfolio, decoration: inputDecoration("URL links")),

                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(value: termsAccepted, onChanged: (v) => setState(() => termsAccepted = v!)),
                      const Expanded(
                        child: Text(
                          "I agree to the terms and conditions and privacy policy of the application",
                          style: TextStyle(fontSize: 12),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: hasProfile ? updateProfile : createProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        hasProfile ? "Update" : "Submit",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
    );
  }
}
