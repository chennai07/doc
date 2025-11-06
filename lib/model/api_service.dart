import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://surgeon-search.onrender.com/api/sugeon';

  static Future<Map<String, dynamic>> createProfile({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String location,
    required String degree,
    required String speciality,
    required String subSpeciality,
    required String summaryProfile,
    required bool termsAccepted,
    required String profileId,
    required String portfolioLinks,
    required List<Map<String, dynamic>> workExperience,
    File? imageFile,
    File? cvFile,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/create-profile');
      var request = http.MultipartRequest('POST', uri);

      // ✅ Normal fields
      request.fields['fullName'] = fullName;
      request.fields['phoneNumber'] = phoneNumber;
      request.fields['email'] = email;
      request.fields['location'] = location;
      request.fields['degree'] = degree;
      request.fields['speciality'] = speciality;
      request.fields['subSpeciality'] = subSpeciality;
      request.fields['summaryProfile'] = summaryProfile;
      request.fields['termsAccepted'] = termsAccepted.toString();
      request.fields['profile_id'] = profileId;
      request.fields['portfolioLinks'] = portfolioLinks;

      // ✅ Add workExperience like array indices
      for (int i = 0; i < workExperience.length; i++) {
        final exp = workExperience[i];
        request.fields['workExperience[$i][designation]'] =
            exp['designation'] ?? '';
        request.fields['workExperience[$i][healthcareOrganization]'] =
            exp['healthcareOrganization'] ?? '';
        request.fields['workExperience[$i][from]'] = exp['from'] ?? '';
        request.fields['workExperience[$i][to]'] = exp['to'] ?? '';
        request.fields['workExperience[$i][location]'] = exp['location'] ?? '';
      }

      // ✅ Attach files
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profilePicture', imageFile.path),
        );
      }

      if (cvFile != null) {
        request.files.add(await http.MultipartFile.fromPath('cv', cvFile.path));
      }

      // ✅ Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📩 API Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': err['message'] ?? 'Server error'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch profile information by ID
  static Future<Map<String, dynamic>> fetchProfileInfo(String profileId) async {
    try {
      final url = Uri.parse('$baseUrl/profile-info/$profileId');
      final response = await http.get(url);

      print('📩 Fetch Profile Info Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Failed to fetch profile info'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}