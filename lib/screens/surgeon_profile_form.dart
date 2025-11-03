// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'profile_view.dart'; // Placeholder for success navigation

// class SurgeonProfileForm extends StatefulWidget {
//   const SurgeonProfileForm({super.key});

//   @override
//   State<SurgeonProfileForm> createState() => _SurgeonProfileFormState();
// }

// class _SurgeonProfileFormState extends State<SurgeonProfileForm> {
//   final _formKey = GlobalKey<FormState>();
//   bool agreeToTerms = false;
//   bool isLoading = false;

//   // Controllers
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController locationController = TextEditingController();
//   final TextEditingController degreeController = TextEditingController();
//   final TextEditingController specialityController = TextEditingController();
//   final TextEditingController subSpecialityController = TextEditingController();
//   final TextEditingController summaryController = TextEditingController();
//   final TextEditingController designationController = TextEditingController();
//   final TextEditingController organizationController = TextEditingController();
//   final TextEditingController experienceLocationController =
//       TextEditingController();
//   final TextEditingController portfolioController = TextEditingController();

//   File? profileImage;
//   File? cvFile;
//   DateTime? fromDate;
//   DateTime? toDate;

//   @override
//   void initState() {
//     super.initState();
//     // --- Data now updated to be VALID ---
//     fullNameController.text = "Venkatesan Arun";
//     phoneController.text = "9876543210";
//     emailController.text = "v.arun@example.com";
//     locationController.text = "Chennai, India";

//     // Updated to professional degrees
//     degreeController.text = "MBBS, MS (General Surgery)";
//     specialityController.text = "Cardiothoracic Surgery";
//     subSpecialityController.text = "Vascular Surgery";
//     summaryController.text =
//         "Highly skilled surgeon with 10+ years of experience in complex cardiovascular procedures.";

//     // Updated to valid-looking professional details
//     designationController.text = "Consultant Surgeon";
//     organizationController.text = "Apollo Hospital";
//     experienceLocationController.text = "Chennai";

//     // *** FIX: Added HTTPS prefix to make the URL VALID ***
//     portfolioController.text =
//         "https://www.linkedin.com/in/venkatesan-arun-893775326/";

//     // Mocking the dates from the image
//     fromDate = DateTime(2025, 10, 16);
//     toDate = DateTime(2025, 10, 31);

//     // Set terms to true to pass that validation check automatically
//     agreeToTerms = true;
//   }

//   @override
//   void dispose() {
//     fullNameController.dispose();
//     phoneController.dispose();
//     emailController.dispose();
//     locationController.dispose();
//     degreeController.dispose();
//     specialityController.dispose();
//     subSpecialityController.dispose();
//     summaryController.dispose();
//     designationController.dispose();
//     organizationController.dispose();
//     experienceLocationController.dispose();
//     portfolioController.dispose();
//     super.dispose();
//   }

//   /// 🖼️ Pick Image
//   Future<void> pickProfileImage() async {
//     final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (picked != null) setState(() => profileImage = File(picked.path));
//   }

//   /// 📄 Pick CV
//   Future<void> pickCVFile() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf'],
//     );
//     if (result != null && result.files.single.path != null) {
//       setState(() => cvFile = File(result.files.single.path!));
//     }
//   }

//   /// 📅 Pick Dates
//   Future<void> pickFromDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: fromDate ?? DateTime.now(),
//       firstDate: DateTime(1980),
//       lastDate: DateTime(2100), // Allowing future date for current experience
//     );
//     if (picked != null) setState(() => fromDate = picked);
//   }

//   Future<void> pickToDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: toDate ?? DateTime.now(),
//       firstDate: DateTime(1980),
//       lastDate: DateTime(2100), // Allowing future date for current experience
//     );
//     if (picked != null) setState(() => toDate = picked);
//   }

//   /// 🚀 Submit Profile Function
//   Future<void> submitProfile() async {
//     // 1. Validate Form Fields
//     if (!_formKey.currentState!.validate()) return;

//     // 2. Validate Terms
//     if (!agreeToTerms) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Please accept terms & conditions."),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     // 3. Validate Experience Dates
//     if (fromDate == null || toDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             "Please select both 'From' and 'To' dates for experience.",
//           ),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }
//     if (fromDate!.isAfter(toDate!)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("The 'From' date cannot be after the 'To' date."),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     setState(() => isLoading = true);

//     const String apiUrl =
//         "https://surgeon-search.onrender.com/api/sugeon/create-profile";

//     try {
//       final prefs = await SharedPreferences.getInstance();

//       // FIX: Ensure profileId is neither null nor empty, which causes the BSON error.
//       // Use ?.isNotEmpty == true to safely check for non-null and non-empty.
//       final storedUserId = prefs.getString("userId");
//       final profileId = (storedUserId != null && storedUserId.isNotEmpty)
//           ? storedUserId
//           : "6908b3a4c75fe2caadcf929b"; // fallback valid ID

//       final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

//       // Basic Fields
//       request.fields['fullName'] = fullNameController.text.trim();
//       request.fields['phoneNumber'] = phoneController.text.trim();
//       request.fields['email'] = emailController.text.trim();
//       request.fields['location'] = locationController.text.trim();
//       request.fields['degree'] = degreeController.text.trim();
//       request.fields['speciality'] = specialityController.text.trim();
//       request.fields['subSpeciality'] = subSpecialityController.text.trim();
//       request.fields['summaryProfile'] = summaryController.text.trim();
//       request.fields['termsAccepted'] = agreeToTerms.toString();
//       request.fields['portfolioLinks'] = portfolioController.text.trim();

//       // Work Experience (Index 0 for single entry form)
//       request.fields['workExperience[0][designation]'] = designationController
//           .text
//           .trim();
//       request.fields['workExperience[0][healthcareOrganization]'] =
//           organizationController.text.trim();
//       request.fields['workExperience[0][from]'] = fromDate!.toIso8601String();
//       request.fields['workExperience[0][to]'] = toDate!.toIso8601String();
//       request.fields['workExperience[0][location]'] =
//           experienceLocationController.text.trim();

//       // Assign the safely determined MongoDB ID
//       request.fields['profile_id'] = profileId;

//       // Files
//       if (profileImage != null) {
//         request.files.add(
//           await http.MultipartFile.fromPath(
//             'profilePicture',
//             profileImage!.path,
//           ),
//         );
//       }
//       if (cvFile != null) {
//         request.files.add(
//           await http.MultipartFile.fromPath('cv', cvFile!.path),
//         );
//       }

//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//       debugPrint("📥 Response: ${response.statusCode}");
//       debugPrint("📄 Body: $responseBody");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final data = jsonDecode(responseBody);
//         final newProfileId =
//             data['data']?['_id'] ?? profileId; // use returned ID if any

//         // Success Popup
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (context) {
//             return Dialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.check_circle,
//                       size: 80,
//                       color: Colors.lightBlueAccent,
//                     ),
//                     const SizedBox(height: 20),
//                     const Text(
//                       "Profile Created Successfully!",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                                 ProfileView(profileId: newProfileId),
//                           ),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.lightBlueAccent,
//                       ),
//                       child: const Text(
//                         "View Profile",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       } else {
//         final err = jsonDecode(responseBody);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "Error: ${err['message'] ?? 'Profile creation failed'}. Please check your inputs.",
//             ),
//             backgroundColor: Colors.redAccent,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Network Error: $e"),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   // 🧱 UI Fields
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text(
//           "Professional Profile",
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // --- Core Contact Fields ---
//               _buildField("Full Name", "Your full name", fullNameController),
//               _buildField(
//                 "Phone Number",
//                 "Your mobile number",
//                 phoneController,
//                 isPhone: true,
//               ),
//               _buildField(
//                 "Email",
//                 "Your professional email",
//                 emailController,
//                 isEmail: true,
//               ),
//               _buildField(
//                 "Location (Current)",
//                 "City, Country",
//                 locationController,
//               ),

//               // --- Image Upload ---
//               OutlinedButton.icon(
//                 onPressed: pickProfileImage,
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   side: BorderSide(
//                     color: profileImage == null
//                         ? Colors.grey
//                         : Colors.lightBlueAccent,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 icon: const Icon(Icons.upload),
//                 label: Text(
//                   profileImage == null
//                       ? "Upload Profile Image"
//                       : "Image Selected",
//                   style: TextStyle(
//                     color: profileImage == null
//                         ? Colors.black
//                         : Colors.lightBlueAccent,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),

//               // --- Professional Details ---
//               _buildField("Degree", "e.g., MBBS, MD, PhD", degreeController),
//               _buildField(
//                 "Speciality",
//                 "e.g., Cardiology, Orthopedics",
//                 specialityController,
//               ),
//               _buildField(
//                 "Sub-speciality",
//                 "e.g., Interventional Cardiology",
//                 subSpecialityController,
//               ),
//               _buildField(
//                 "Summary",
//                 "A brief profile summary (max 3 lines)",
//                 summaryController,
//                 maxLines: 3,
//                 isRequired: false, // Make summary optional
//               ),

//               // --- Work Experience (Single Entry) ---
//               const Padding(
//                 padding: EdgeInsets.only(top: 10, bottom: 5),
//                 child: Text(
//                   "Current/Latest Work Experience",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//               _buildField(
//                 "Designation",
//                 "Your job title (e.g., Senior Surgeon)",
//                 designationController,
//               ),
//               _buildField(
//                 "Organization",
//                 "Name of Healthcare Organization",
//                 organizationController,
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                     child: GestureDetector(
//                       onTap: pickFromDate,
//                       child: _dateBox(
//                         "From Date",
//                         fromDate,
//                         isError:
//                             fromDate == null &&
//                             _formKey.currentState?.validate() == false,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: GestureDetector(
//                       onTap: pickToDate,
//                       child: _dateBox(
//                         "To Date",
//                         toDate,
//                         isError:
//                             toDate == null &&
//                             _formKey.currentState?.validate() == false,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               _buildField(
//                 "Experience Location",
//                 "City, Country of work",
//                 experienceLocationController,
//               ),

//               // --- Documents & Links ---
//               OutlinedButton.icon(
//                 onPressed: pickCVFile,
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   side: BorderSide(
//                     color: cvFile == null
//                         ? Colors.grey
//                         : Colors.lightBlueAccent,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 icon: const Icon(Icons.upload_file),
//                 label: Text(
//                   cvFile == null
//                       ? "Upload CV (PDF)"
//                       : "CV Selected: ${cvFile!.path.split('/').last}",
//                   style: TextStyle(
//                     color: cvFile == null
//                         ? Colors.black
//                         : Colors.lightBlueAccent,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               _buildField(
//                 "Portfolio Links",
//                 "Full URL (e.g., https://linkedin.com/in/...)",
//                 portfolioController,
//                 isURL: true, // Specific URL validation added
//                 isRequired: false,
//               ),

//               // --- Terms and Submit ---
//               Row(
//                 children: [
//                   Checkbox(
//                     value: agreeToTerms,
//                     onChanged: (v) => setState(() => agreeToTerms = v!),
//                   ),
//                   const Expanded(
//                     child: Text(
//                       "I agree to the terms and conditions of the application",
//                       style: TextStyle(fontSize: 13),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: isLoading ? null : submitProfile,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.lightBlueAccent,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           "Submit Profile",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Helper widget for form fields with custom validation
//   Widget _buildField(
//     String label,
//     String hint,
//     TextEditingController ctrl, {
//     int maxLines = 1,
//     bool isRequired = true,
//     bool isEmail = false,
//     bool isURL = false,
//     bool isPhone = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: ctrl,
//         maxLines: maxLines,
//         keyboardType: isEmail
//             ? TextInputType.emailAddress
//             : isPhone
//             ? TextInputType.phone
//             : TextInputType.text,
//         validator: (v) {
//           final value = v?.trim() ?? '';
//           if (isRequired && value.isEmpty) {
//             return "Please enter your $label";
//           }

//           if (isEmail && value.isNotEmpty) {
//             final emailRegex = RegExp(
//               r"^[a-zA-Z0-9.a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$",
//             );
//             if (!emailRegex.hasMatch(value)) {
//               return "Please enter a valid email address.";
//             }
//           }

//           // CRITICAL: Checks for the missing 'https://' from the user's screenshot error.
//           if (isURL && value.isNotEmpty) {
//             // Simple URL regex check, ensuring it starts with http(s)
//             final urlRegex = RegExp(
//               r'^(http|https):\/\/[\w-]+(\.[\w-]+)+([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?$',
//             );
//             if (!urlRegex.hasMatch(value)) {
//               return "Please include the full URL (e.g., https://...).";
//             }
//           }

//           return null;
//         },
//         decoration: InputDecoration(
//           labelText: label,
//           hintText: hint,
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//       ),
//     );
//   }

//   // Helper widget for date selection with matching TextFormField style
//   Widget _dateBox(String label, DateTime? date, {required bool isError}) {
//     final dateText = date == null
//         ? label
//         : "${date.day}/${date.month}/${date.year}";

//     // Use InputDecorator to mimic the TextFormField border/style
//     return InputDecorator(
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: label,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//         errorText: isError ? "Required" : null,
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(
//             color: isError ? Colors.red : Colors.grey.shade400,
//           ),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: const BorderSide(color: Colors.lightBlueAccent, width: 2),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: const BorderSide(color: Colors.red, width: 2),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             dateText,
//             style: TextStyle(
//               color: date == null ? Colors.grey.shade600 : Colors.black,
//             ),
//           ),
//           const Icon(
//             Icons.calendar_today,
//             size: 20,
//             color: Colors.lightBlueAccent,
//           ),
//         ],
//       ),
//     );
//   }
// }
