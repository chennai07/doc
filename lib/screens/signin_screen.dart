import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://surgeon-search.onrender.com/api/sugeon'; // ✅ Make sure 'sugeon' is correct, not 'surgeon'

  /// Create or Update Profile API
  static Future<bool> createProfile(
    Map<String, String> data,
    File? imageFile,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/create-profile');
      final request = http.MultipartRequest('POST', uri);

      // ✅ Add form fields
      data.forEach((key, value) {
        if (value.isNotEmpty) request.fields[key] = value;
      });

      // ✅ Add image if present
      if (imageFile != null) {
        final file = await http.MultipartFile.fromPath(
          'profileImage',
          imageFile.path,
        );
        request.files.add(file);
      }

      // ✅ Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        // If authorization is required, uncomment next line:
        // 'Authorization': 'Bearer YOUR_TOKEN',
      });

      // ✅ Send request
      final response = await request.send();

      // ✅ Convert stream to text
      final responseBody = await response.stream.bytesToString();
      print('🔹 API Response Status: ${response.statusCode}');
      print('🔹 Response Body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Profile Created/Updated Successfully');
        return true;
      } else {
        final decoded = jsonDecode(responseBody);
        print(
          '❌ API Error: ${decoded['message'] ?? decoded['error'] ?? 'Unknown error'}',
        );
        return false;
      }
    } catch (e) {
      print('⚠️ Exception while uploading profile: $e');
      return false;
    }
  }

  /// Fetch a profile by ID
  static Future<Map<String, dynamic>?> getProfile(String profileId) async {
    try {
      final uri = Uri.parse('$baseUrl/get-profile/$profileId');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      print('🔹 GET Status: ${response.statusCode}');
      print('🔹 GET Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print('⚠️ Exception while fetching profile: $e');
      return null;
    }
  }

  /// Update profile by ID (PUT)
  static Future<bool> updateProfile(
    String profileId,
    Map<String, String> data,
    File? imageFile,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/update-profile/$profileId');
      final request = http.MultipartRequest('PUT', uri);

      data.forEach((key, value) {
        if (value.isNotEmpty) request.fields[key] = value;
      });

      if (imageFile != null) {
        final file = await http.MultipartFile.fromPath(
          'profileImage',
          imageFile.path,
        );
        request.files.add(file);
      }

      request.headers.addAll({'Accept': 'application/json'});

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('🔹 PUT Status: ${response.statusCode}');
      print('🔹 PUT Body: $responseBody');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('⚠️ Exception while updating profile: $e');
      return false;
    }
  }
}
