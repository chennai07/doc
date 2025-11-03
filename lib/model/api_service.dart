import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl =
      'https://surgeon-search.onrender.com/api/sugeon/create-profile'; // 👈 change this

  static Future<bool> createProfile(
    Map<String, String> data,
    File? imageFile,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/create-profile'),
    );

    data.forEach((key, value) {
      request.fields[key] = value;
    });

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', imageFile.path),
      );
    }

    var response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchProfile(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/get-profile/$id'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }
}
